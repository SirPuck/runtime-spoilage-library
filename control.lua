local registry = require("registry")
local placeholder_to_possible_result_mapping = registry.placeholder_to_possible_result_mapping
local placeholder_to_possible_result_mapping_v2 = registry.placeholder_to_possible_result_mapping_v2
local enable_swap_in_assembler = false

-- Helper functions, will be moved later
-----------------------------------

-- Returns true if the given value is in the given array.
--- @param value any
--- @param array any
local function is_in_array(value, array)
    for _, v in ipairs(array) do
        if v == value then
            return true
        end
    end
    return false
end


local function select_result(placeholder)
    local options = placeholder_to_possible_result_mapping[placeholder]
    local mode = options
    if mode.random then
        if mode.weighted then
            return "function_with_weights"
        else
            return "function_unweighted"
        end
    end

end


-- Random selection functions
-----------------------------
--- @param placeholder_item string A string with the name of the item linked that will be linked to an outcome.
--- @param possible_outcomes string[] An arra of two strings containing item names
--- @param weights number[] An array of two numbers representing weights for the items
--- @return string[] A table containing a pair {placeholder_item = selected_outcome}
local function select_one_result_over_two(placeholder_item, possible_outcomes, weights)
    assert(#possible_outcomes == 2 and #weights == 2, "Two outcomes and two weights required")
    local weight_sum = weights[1] + weights[2]
    return {placeholder_item = math.random() < (weights[1] / weight_sum) and possible_outcomes[1] or possible_outcomes[2]}
end

--- @param placeholder_item string A string with the name of the item linked that will be linked to an outcome.
--- @param possible_outcomes string[] An array of strings containing item names.
--- @param weights integer[] An array of integers representing weights for the items.
--- @return string string containing a pair {placeholder_item = selected_outcome}
local function select_one_result_over_n_weighted(placeholder_item, possible_outcomes, weights)
    assert(#possible_outcomes == #weights, "Outcomes and weights must have the same length")

    -- Compute the total weight
    local total_weight = 0
    for _, weight in ipairs(weights) do
        total_weight = total_weight + weight
    end

    -- Generate a random integer in the range [1, total_weight]
    local random_weight = math.random(1, total_weight)

    -- Find which outcome corresponds to the random weight
    local cumulative_weight = 0
    for i, weight in ipairs(weights) do
        cumulative_weight = cumulative_weight + weight
        if random_weight <= cumulative_weight then
            return possible_outcomes[i]
        end
    end
end


--- This function selects and returns one outcome with equals chances of selection from an array of 2 strings.
--- @param possible_outcomes string[] An array of strings containing item names.
--- @return string string containing a pair {placeholder_item = selected_outcome}
local function select_one_result_over_n_unweighted(placeholder_item, possible_outcomes)
    return possible_outcomes[math.random(1, #possible_outcomes)]
end

local function roll_dice()
    for placeholder, outcomes in pairs(placeholder_to_possible_result_mapping) do
        local result = select_one_result_over_n_unweighted(placeholder, outcomes)
        storage.spoilage_mapping[placeholder] = result
    end
end



-- Inventory swapping functions
--------------------------------
-- Ex of spoil_mapping : {["placeholder"] = "result"}
--- Single placeholder_item functions. These functions will only check if there is the placeholder_item triggering the event in the target inventory.
--- target counterpart.
-- Swaps an item in the character's inventory, in place.
--- @param entity LuaEntity (we assume source_entity and target_entity are the same).
--- @param placeholder string the name of the placeholder item.
--- @return nil
local function hotswap_stack_in_character_inventory(entity, placeholder)
    local inventory = entity.get_inventory(defines.inventory.character_main)
    for i = 1, #inventory do
        local stack = inventory[i]
        if stack.valid_for_read and stack.name == placeholder then
            stack.set_stack({ name = storage.spoilage_mapping[placeholder], count = stack.count })
        end
    end
end

--- @param entity LuaEntity (we assume source_entity and target_entity are the same).
--- @param placeholder string the name of the placeholder item.
--- @return nil
local function hotswap_item_in_character_inventory(entity, placeholder)
    local inventory = entity.get_main_inventory(defines.inventory.character_main)
    if inventory then
        local _placeholder_number = inventory.get_item_count(placeholder)
        if _placeholder_number > 0 then
            inventory.remove({name=placeholder, count=_placeholder_number})
            inventory.insert({name = storage.spoilage_mapping[placeholder], count = _placeholder_number})
        end
        if entity.cursor_stack and entity.cursor_stack.valid_for_read and entity.cursor_stack.name == placeholder then
            entity.cursor_stack.set_stack({name=storage.spoilage_mapping[placeholder], count = entity.cursor_stack.count})
        end
    end
end

--- @param entity LuaEntity (we assume source_entity and target_entity are the same).
--- @param placeholder string the name of the placeholder item.
--- @return nil
local function hotswap_in_belt(entity, placeholder)
    local transport_lines = {entity.get_transport_line(1), entity.get_transport_line(2)}
    for _, line in pairs(transport_lines) do
        if line.get_item_count(placeholder) == 0 then
            goto continue
        end
        for i = 1, #line do
            local stack = line[i]
            if stack.valid_for_read and stack.name == placeholder then
                stack.set_stack({name = storage.spoilage_mapping[placeholder], count = stack.count})
            end
        end
        ::continue::
    end
end

--- @param entity LuaEntity (we assume source_entity and target_entity are the same).
--- @param placeholder string the name of the placeholder item.
--- @return nil
local function hotswap_in_underground_belt(entity, placeholder)
    local transport_lines = {
        entity.get_transport_line(defines.transport_line.left_line),
        entity.get_transport_line(defines.transport_line.left_underground_line),
        entity.get_transport_line(defines.transport_line.secondary_left_line),
        entity.get_transport_line(defines.transport_line.right_line),
        entity.get_transport_line(defines.transport_line.right_underground_line),
        entity.get_transport_line(defines.transport_line.secondary_right_line),
    }
    for _, line in pairs(transport_lines) do
        if line.get_item_count(placeholder) == 0 then
            goto continue
        end
        for i = 1, #line do
            local stack = line[i]
            if stack.valid_for_read and stack.name == placeholder then
                stack.set_stack({name = storage.spoilage_mapping[placeholder], count = stack.count})
            end
        end
        ::continue::
    end
end

local function _hotswap_in_splitter_lines(lines, placeholder)
    for _, line in pairs(lines) do
        for i = 1, #line do
            local stack = line[i]
            if stack.valid_for_read and stack.name == placeholder then
                stack.set_stack({name = storage.spoilage_mapping[placeholder], count = stack.count})
            end
        end
    end
end

--- @param entity LuaEntity (we assume source_entity and target_entity are the same).
--- @param placeholder string the name of the placeholder item.
--- @return nil
local function hotswap_in_splitter(entity, placeholder)
    local transport_lines = {entity.get_transport_line(1), entity.get_transport_line(2)}
    for _, line in pairs(transport_lines) do
        if #line.input_lines == 0 then
            goto continue
        end
        for i = 1, #line.input_lines do
            _hotswap_in_splitter_lines(line.input_lines, placeholder)
        end
        ::continue::
        if #line.output_lines == 0 then
            goto next_iter
        end
        for i = 1, #line.output_lines do
            _hotswap_in_splitter_lines(line.output_lines, placeholder)
        end
        ::next_iter::
    end
end


--- @param entity LuaEntity (we assume source_entity and target_entity are the same).
--- @param placeholder string containing all the items that have a random spoil result.
--- @return nil
local function hotswap_in_inserter_or_bot(entity, placeholder)
    local result = storage.spoilage_mapping[placeholder]
    --local result = math.random() < 0.5 and "iron-plate" or "copper-plate"
    if entity.held_stack.valid_for_read then
        entity.held_stack.set_stack({name = result, count = entity.held_stack.count})
    end
end


local PREFIX = "random_spoil_"

-- Function to validate prefix and extract suffix
local function get_suffix_and_prefix_from_effect_id(effect_id)
    if string.sub(effect_id, 1, #PREFIX) == PREFIX then
        local suffix = string.sub(effect_id, #PREFIX + 1)
        return {PREFIX, suffix} -- Return both the prefix and the suffix
    end
    return nil, nil -- Return nil values if the prefix doesn't match
end


-- /!\ ATTENTION /!\ Cannot write arbitrary items into the output nor dump stacks of the assembling machine.
-- Tried both remove/insert and set stack. Only the results of the recipe are allowed.
-- Since this mod's goal is to control the spoil results at runtime, it would make
-- no sense to integrate these results in the recipes, unless you really want to.
local function hotswap_in_machine(entity, placeholder)
    if enable_swap_in_assembler == false then
        return
    end
    local input = entity.get_inventory(defines.inventory.assembling_machine_input)
    local output = entity.get_inventory(defines.inventory.assembling_machine_output)
    local dump = entity.get_inventory(defines.inventory.assembling_machine_dump)
--    local trash = entity.get_inventory(8)
    local inventories = {input, output, dump}
    for _, inventory in pairs(inventories) do
        local item_count = inventory.get_item_count(placeholder)
        if item_count > 0 then
            for i = 1, #inventory do
                local stack = inventory[i]
                if stack.valid_for_read and stack.name == placeholder then
                    --inventory.remove({name="mutation-e"})
                    --inventory.insert({name=storage.spoilage_mapping[placeholder], count=item_count})
                    stack.set_stack({name=storage.spoilage_mapping[placeholder], count=item_count})
                end
            end
        end
    end
end

--- @param entity LuaEntity (we assume source_entity and target_entity are the same).
--- @param placeholder string the name of the placeholder item.
--- @param inventory_definition defines.inventory.car_trunk|defines.inventory.cargo_wagon|defines.inventory.chest|defines.inventory.hub_main|defines.inventory.rocket_silo_rocket
--- @return nil
local function hotswap_in_generic_inventory(entity, placeholder, inventory_definition)
    local inventory = entity.get_inventory(inventory_definition)
    if inventory then
        local current_count = inventory.get_item_count(placeholder)
        if current_count > 0 then
            inventory.remove({name=placeholder, count=current_count})
            inventory.insert({name=storage.spoilage_mapping[placeholder], count = current_count})
        end
    end
end

--- @param entity LuaEntity (we assume source_entity and target_entity are the same).
--- @param placeholder string the name of the placeholder item.
--- @return nil
local function hotswap_in_logistic_inventory(entity, placeholder)
    local inventories = {entity.get_inventory(defines.inventory.chest), entity.get_inventory(defines.inventory.logistic_container_trash)}
    for _, inventory in pairs(inventories) do
        local current_count = inventory.get_item_count(placeholder)
        if current_count > 0 then
            inventory.remove({name=placeholder, count=current_count})
            inventory.insert({name=storage.spoilage_mapping[placeholder], count = current_count})
        end
    end
end


--- @param entity LuaEntity (we assume source_entity and target_entity are the same).
--- @param placeholder string the name of the placeholder item.
--- @param inventory_definition defines.inventory.car_trunk|defines.inventory.cargo_wagon|defines.inventory.chest|defines.inventory.hub_main|defines.inventory.rocket_silo_rocket
local function hotswap_in_generic_inventory_in_place(entity, placeholder, inventory_definition)
    local inventory = entity.get_inventory(inventory_definition)
    if inventory then
        local current_count = inventory.get_item_count(placeholder)
        if current_count > 0 then
            for i = 1, #inventory do
                local stack = inventory[i]
                if stack.valid_for_read and stack.name == placeholder then
                    stack.set_stack({ name = storage.spoilage_mapping[placeholder], count = stack.count })
                end
            end
        end
    end
end

--- @param entity LuaEntity (we assume source_entity and target_entity are the same).
--- @param placeholder string the name of the placeholder item.
--- @return nil
local function hotswap_on_ground(entity, placeholder)
    return entity.stack.set_stack({name=storage.spoilage_mapping[placeholder], count=entity.stack.count})
end

--- @param event EventData.on_script_trigger_effect
--- @param placeholder string the name of the placeholder item.
local function hotswap_on_position(event, placeholder)
    local surface = game.surfaces[event.surface_index]
    local entity = surface.find_entities_filtered(
        {
            position = event.source_position,
            name = "item-on-ground",
            radius=2
        }
    )
    if entity and entity[1] and entity[1].stack.name == placeholder then
        entity[1].stack.set_stack({name=storage.spoilage_mapping[placeholder], count=entity[1].stack.count})
    end

end

local generic_source_handler = {
    ["inserter"] = function(entity, placeholder_name) return hotswap_in_inserter_or_bot(entity, placeholder_name) end,
    ["logistic-robot"] = function(entity, placeholder_name) return hotswap_in_inserter_or_bot(entity, placeholder_name) end,
    ["transport-belt"] = function(entity, placeholder_name) return hotswap_in_belt(entity, placeholder_name) end,
    ["loader"] = function(entity, placeholder_name) return hotswap_in_belt(entity, placeholder_name) end,
    ["underground-belt"] = function(entity, placeholder_name) return hotswap_in_underground_belt(entity, placeholder_name) end,
    ["splitter"] = function(entity, placeholder_name) return hotswap_in_splitter(entity, placeholder_name) end,
    ["assembling-machine"] = function(entity, placeholder_name) return hotswap_in_machine(entity, placeholder_name) end,
    ["character"] = function(entity, placeholder_name) return hotswap_item_in_character_inventory(entity, placeholder_name) end,
    ["logistic-container"] = function(entity, placname) return hotswap_in_logistic_inventory(entity, placeholder_name) end,
    ["cargo-landing-pad"] = function(entity, placeholder_name) return hotswap_in_logistic_inventory(entity, placeholder_name) end,
    ["item-entity"] = function(entity, placeholder_name) return hotswap_on_ground(entity, placeholder_name) end,
}

local defined_inventories = {
    ["car"] = defines.inventory.car_trunk,
    ["cargo-wagon"] = defines.inventory.cargo_wagon,
    ["container"] = defines.inventory.chest,
    ["space-platform-hub"] = defines.inventory.hub_main,
    ["rocket-silo"] = defines.inventory.rocket_silo_rocket,
}



local function on_spoil(event)
    local prefix_suffix = get_suffix_and_prefix_from_effect_id(event.effect_id)
    if event.source_entity then
        if prefix_suffix[1] == PREFIX then
            local swap_func = generic_source_handler[event.source_entity.type]
            if swap_func ~= nil then
                swap_func(event.source_entity, prefix_suffix[2])
            else
                hotswap_in_generic_inventory(event.source_entity, prefix_suffix[2], defined_inventories[event.source_entity.type])
            end
        end
    else
        hotswap_on_position(event, prefix_suffix[2])
    end
end



script.on_event(defines.events.on_tick, function(event)
    if event.tick % 20 == 0 then
        roll_dice()
    end
end)

script.on_event(defines.events.on_script_trigger_effect, on_spoil)


script.on_init(function()
    storage.belt_mutator_counter = storage.belt_mutator_counter or 0
    storage.spoilage_mapping = storage.spoilage_mapping or {}
end
)

script.on_configuration_changed(function()
    storage.belt_mutator_counter = storage.belt_mutator_counter or 0
    storage.spoilage_mapping = storage.spoilage_mapping or {}
end)

