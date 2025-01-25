local registry = require("registry")
local placeholder_to_possible_result_mapping = registry.placeholder_to_possible_result_mapping
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
--- @param entity entity (we assume source_entity and target_entity are the same).
--- @param placeholder_items string[] containing all the items that have a random spoil result.
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

--- @param entity entity (we assume source_entity and target_entity are the same).car
--- @param placeholder_items string[] containing all the items that have a random spoil result.
--- @return nil
local function hotswap_item_in_character_inventory(entity, placeholder)
    local inventory = entity.get_main_inventory(defines.inventory.character_main)
    local _placeholder_number = inventory.get_item_count(placeholder)
    if _placeholder_number > 0 then
        inventory.remove({name = placeholder})
        inventory.insert({name = storage.spoilage_mapping[placeholder], count = _placeholder_number})
    end
    if entity.cursor_stack and entity.cursor_stack.name == placeholder then
        entity.cursor_stack.set_stack({name=storage.spoilage_mapping[placeholder], count = entity.cursor_stack.count})
    end
end

--- @param entity entity (we assume source_entity and target_entity are the same).
--- @param placeholder string containing all the items that have a random spoil result.
--- @return nil
local function hotswap_in_belt_inventory(entity, placeholder)
    local transport_lines = {entity.get_transport_line(1), entity.get_transport_line(2)}
    for _, line in pairs(transport_lines) do
        if line.get_item_count(placeholder) == 0 then
            goto continue
        end
        for i = 1, #line do
            local stack = line[i]
            if stack.valid_for_read and stack.name == placeholder then
                roll_dice()
                stack.set_stack({name = storage.spoilage_mapping[placeholder], count = stack.count})
            end
        end
        ::continue::
    end
end


--- @param entity assume source_entity and target_entity are the same).
--- @param placeholder_items string[] containing all the items that have a random spoil result.
--- @return nil
local function hotswap_in_inserter(entity, placeholder)
    local result = storage.spoilage_mapping[placeholder]
    --local result = math.random() < 0.5 and "iron-plate" or "copper-plate"
    local current_stack = entity.held_stack
    if current_stack.valid_for_read then
        entity.held_stack.set_stack({name = result, count = current_stack.count})
    end
end

--- @param entity entity (we assume source_entity and target_entity are the same).
--- @param placeholder_items string[] containing all the items that have a random spoil result.
--- @return nil
local function hotswap_in_bot(entity, placeholder_items)
    local inventory = entity.get_inventory(defines.inventory.robot_cargo)
    local current_stack = entity.held_stack
    inventory[1].set_stack({name = placeholder_items[current_stack], count = inventory[1].count})
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

local function hotswap_in_car(entity, placeholder)
    local inventory = entity.get_inventory(defines.inventory.car_trunk)
    local current_count = inventory.get_item_count(placeholder)
    if current_count > 0 then
        inventory.remove({name=placeholder})
        inventory.insert({name=storage.spoilage_mapping[placeholder], count = current_count})
    end
end

local function hotswap_in_cargo_wagon(entity, placeholder)
    local inventory = entity.get_inventory(defines.inventory.cargo_wagon)
    local current_count = inventory.get_item_count(placeholder)
    if current_count > 0 then
        inventory.remove({name=placeholder})
        inventory.insert({name=storage.spoilage_mapping[placeholder], count = current_count})
    end
end

local function hotswap_in_chest(entity, placeholder)
    local inventory = entity.get_inventory(defines.inventory.chest)
    local current_count = inventory.get_item_count(placeholder)
    if current_count > 0 then
        inventory.remove({name=placeholder})
        inventory.insert({name=storage.spoilage_mapping[placeholder], count = current_count})
    end
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
    --local trash = entity.get_inventory(defines.inventory.)
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

local function hotswap_in_space_platform(entity, placeholder)
    local inventory = entity.get_inventory(defines.inventory.hub_main)
    local current_count = inventory.get_item_count(placeholder)
    if current_count > 0 then
        inventory.remove({name=placeholder})
        inventory.insert({name=storage.spoilage_mapping[placeholder], count = current_count})
    end
end

local function hotswap_in_space_platform_in_place(entity, placeholder)
    local inventory = entity.get_inventory(defines.inventory.hub_main)
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

local function hotswap_in_rocket_silo(entity, placeholder)
    local inventory = entity.get_inventory(defines.inventory.rocket_silo_rocket)
    local current_count = inventory.get_item_count(placeholder)
    if current_count > 0 then
        inventory.remove({name=placeholder})
        inventory.insert({name=storage.spoilage_mapping[placeholder], count = current_count})
    end
end

local function hotswap_in_rocket_silo_in_place(entity, placeholder)
    local inventory = entity.get_inventory(defines.inventory.rocket_silo_rocket)
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


local source_handler = {
    ["character"] = function(entity, placeholder_name) return hotswap_item_in_character_inventory(entity, placeholder_name) end,
    ["inserter"] = function(entity, placeholder_name) return hotswap_in_inserter(entity, placeholder_name) end,
    ["logistic-robot"] = function(entity, placeholder_name) return hotswap_in_bot(entity, placeholder_name) end,
    ["car"] = function(entity, placeholder_name) return hotswap_in_car(entity, placeholder_name) end,
    ["cargo-wagon"] = function(entity, placeholder_name) return hotswap_in_cargo_wagon(entity, placeholder_name) end,
    ["transport-belt"] = function(entity, placeholder_name) return hotswap_in_belt_inventory(entity, placder_name) end,
    ["container"] = function(entity, placeholder_name) return hotswap_in_chest(entity, placeholder_name) end,
    ["assembling-machine"] = function(entity, placeholder_name) return hotswap_in_machine(entity, placeholder_name) end,
    ["space-platform-hub"] = function(entity, placeholder_name) return hotswap_in_space_platform(entity, placeholder_name) end,
}

script.on_event(defines.events.on_script_trigger_effect, function(event)
    local prefix_suffix = get_suffix_and_prefix_from_effect_id(event.effect_id)
    if prefix_suffix[1] == PREFIX then
        local swap_func = source_handler[event.source_entity.type]
        if swap_func ~= nil then
            swap_func(event.source_entity, prefix_suffix[2])
        end
    end
end)

script.on_event(defines.events.on_tick, function(event)
    if event.tick % 20 == 0 then
        roll_dice()
    end
end)

script.on_init(function()
    storage.belt_mutator_counter = storage.belt_mutator_counter or 0
    storage.spoilage_mapping = storage.spoilage_mapping or {}
end
)

script.on_configuration_changed(function()
    storage.belt_mutator_counter = storage.belt_mutator_counter or 0
    storage.spoilage_mapping = storage.spoilage_mapping or {}
end)

