local registry = require("registry")
local spoilage_definitions = registry.spoilage_definitions
local placeholder_to_result_conditional = registry.placeholder_to_result_conditional
local enable_swap_in_assembler = false
local possible_results = {}
local precomputed_weights = {}

--[[local item_params = {
    ["rsl-itemtospoil"] = 
    {
        mode = {random = true, conditional = false, weighted = true},
        placeholder_name = "placeholdername",
        possible_results = {
            {name = "iron-plate", weight = 1},
            {name = "copper-plate", weight = 2}
        },
    }

}]]

local function preprocess_weights(original_item, possible_results, bool)
    local cumulative_weight = 0
    local sorted_options = {}

    -- Build sorted list of cumulative weights
    for _, option in ipairs(possible_results) do
        cumulative_weight = cumulative_weight + option.weight
        table.insert(sorted_options, { cumulative_weight = cumulative_weight, name = option.name})
    end

    -- Ensure sorting is correct (ascending order)
    table.sort(sorted_options, function(a, b)
        return a.cumulative_weight < b.cumulative_weight
    end)
    if not precomputed_weights[original_item] then
        precomputed_weights[original_item] = {}
    end

    precomputed_weights[original_item][bool] = 
        {
            cumulative_weight = cumulative_weight,
            options = sorted_options
        }

end



local function build_random_spoils()
    for _, definition in pairs(spoilage_definitions) do
        if definition.mode.random and not definition.mode.weighted then
            local options = {}
            for _, name in pairs(definition.possible_results) do
                table.insert(options, name)
            end
        end
        if definition.mode.random and definition.mode.weighted then
            preprocess_weights(definition.name, definition.possible_results_true, true)
            if definition.possible_results_false ~= nil then
                preprocess_weights(definition.name, definition.possible_results_true, false)
            end
        end
    end
end


local function weighted_choice(item)
    if not item then return nil end

    local r = math.random() * item.cumulative_weight
    local options = item.options
    local low, high = 1, #options

    -- Binary search for correct cumulative weight
    while low < high do
        local mid = math.floor((low + high) / 2)
        if options[mid].cumulative_weight < r then
            low = mid + 1
        else
            high = mid
        end
    end

    return options[low].name  -- Correctly selected option
end
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

--[[local function roll_dice()
    for placeholder, parameters in pairs(placeholder_to_possible_result_mapping) do
        local result = select_one_result_over_n_unweighted(placeholder, parameters.possible_results)
        storage.spoilage_mapping[placeholder] = result
    end
end]]

local function roll_dice()
    for placeholder, bool in pairs(precomputed_weights) do
        for state, placeholder_data in pairs(bool) do
            storage.spoilage_mapping[state][placeholder] = weighted_choice(placeholder_data)
        end
    end
end


-- Inventory swapping functions
--------------------------------


---comment
---@param stack LuaItemStack
---@param result string|nil
local function set_or_nil_stack(stack, result)
    if result ~= nil then
        stack.set_stack({ name = result, count = stack.count })
    else
        stack.set_stack(nil)
    end
end





-- Ex of spoil_mapping : {["placeholder"] = "result"}
--- Single placeholder_item functions. These functions will only check if there is the placeholder_item triggering the event in the target inventory.
--- target counterpart.
-- Swaps an item in the character's inventory, in place.
--- @param entity LuaEntity (we assume source_entity and target_entity are the same).
--- @param placeholder string the name of the placeholder item.
--- @return nil
local function hotswap_stack_in_character_inventory(entity, placeholder)
    local inventory = entity.get_inventory(defines.inventory.character_main)
    local result = storage.spoilage_mapping[placeholder] or nil
    for i = 1, #inventory do
        local stack = inventory[i]
        if stack.valid_for_read and stack.name == placeholder then
            set_or_nil_stack(stack, result)
        end
    end
end

--- @param entity LuaEntity (we assume source_entity and target_entity are the same).
--- @param placeholder string the name of the placeholder item.
--- @return nil
local function hotswap_item_in_character_inventory(entity, placeholder_definition)
    local inventory = entity.get_main_inventory(defines.inventory.character_main)
    local placeholder_name = placeholder_definition.name
    local result = storage.spoilage_mapping[placeholder_definition.condition][placeholder_definition.name]
    if inventory then
        local _placeholder_number = inventory.get_item_count(placeholder_name)
        if _placeholder_number > 0 then
            inventory.remove({name=placeholder_name, count=_placeholder_number})
            if result ~= nil then
                inventory.insert({name = result, count = _placeholder_number})
            end
        end
        if entity.cursor_stack and entity.cursor_stack.valid_for_read and entity.cursor_stack.name == placeholder_name then
            set_or_nil_stack(entity.cursor_stack, result, entity.cursor_stack.count)
        end
    end
end

--- @param entity LuaEntity (we assume source_entity and target_entity are the same).
--- @param placeholder string the name of the placeholder item.
--- @return nil
local function hotswap_in_belt(entity, placeholder_definition)
    local transport_lines = {entity.get_transport_line(1), entity.get_transport_line(2)}
    local placeholder_name = placeholder_definition.name
    local result = storage.spoilage_mapping[placeholder_definition.condition][placeholder_definition.name]
    for _, line in pairs(transport_lines) do
        if line.get_item_count(placeholder_name) == 0 then
            goto continue
        end
        for i = 1, line.line_length do
            local stack = line[i]
            if stack.valid_for_read and stack.name == placeholder_name then
                set_or_nil_stack(stack, result)
            end
        end
        ::continue::
    end
end

--- @param entity LuaEntity (we assume source_entity and target_entity are the same).
--- @param placeholder string the name of the placeholder item.
--- @return nil
local function hotswap_in_underground_belt(entity, placeholder_definition)
    local placeholder_name = placeholder_definition.name
    local result = storage.spoilage_mapping[placeholder_definition.condition][placeholder_definition.name]
    local transport_lines = {
        entity.get_transport_line(defines.transport_line.left_line),
        entity.get_transport_line(defines.transport_line.left_underground_line),
        entity.get_transport_line(defines.transport_line.secondary_left_line),
        entity.get_transport_line(defines.transport_line.right_line),
        entity.get_transport_line(defines.transport_line.right_underground_line),
        entity.get_transport_line(defines.transport_line.secondary_right_line),
    }
    for _, line in pairs(transport_lines) do
        if line.get_item_count(placeholder_name) == 0 then
            goto continue
        end
        for i = 1, #line do
            local stack = line[i]
            if stack.valid_for_read and stack.name == placeholder_name then
                set_or_nil_stack(stack, result)
            end
        end
        ::continue::
    end
end

local function _hotswap_in_splitter_lines(lines, placeholder, result)
    for _, line in pairs(lines) do
        for i = 1, #line do
            local stack = line[i]
            if stack.valid_for_read and stack.name == placeholder then
                set_or_nil_stack(stack, result)
            end
        end
    end
end

--- @param entity LuaEntity (we assume source_entity and target_entity are the same).
--- @param placeholder string the name of the placeholder item.
--- @return nil
local function hotswap_in_splitter(entity, placeholder_definition)
    local placeholder_name = placeholder_definition.name
    local result = storage.spoilage_mapping[placeholder_definition.condition][placeholder_definition.name]
    local transport_lines = {entity.get_transport_line(1), entity.get_transport_line(2)}

    for _, line in pairs(transport_lines) do
        if #line.input_lines == 0 then
            goto continue
        end
        for i = 1, #line.input_lines do
            _hotswap_in_splitter_lines(line.input_lines, placeholder_name, result)
        end
        ::continue::
        if #line.output_lines == 0 then
            goto next_iter
        end
        for i = 1, #line.output_lines do
            _hotswap_in_splitter_lines(line.output_lines, placeholder_name, result)
        end
        ::next_iter::
    end
end


--- @param entity LuaEntity (we assume source_entity and target_entity are the same).
--- @param placeholder string containing all the items that have a random spoil result.
--- @return nil
local function hotswap_in_inserter_or_bot(entity, placeholder_definition)
    local result = storage.spoilage_mapping[placeholder_definition.condition][placeholder_definition.name]
    --local result = math.random() < 0.5 and "iron-plate" or "copper-plate"
    if entity.held_stack.valid_for_read then
        set_or_nil_stack(entity.held_stack, result)
    end
end







-- /!\ ATTENTION /!\ Cannot write arbitrary items into the output nor dump stacks of the assembling machine.
-- Tried both remove/insert and set stack. Only the results of the recipe are allowed.
-- Since this mod's goal is to control the spoil results at runtime, it would make
-- no sense to integrate these results in the recipes, unless you really want to.
local function hotswap_in_machine(entity, placeholder_definition)
    if enable_swap_in_assembler == false then
        return
    end
    local placeholder_name = placeholder_definition.name
    local input = entity.get_inventory(defines.inventory.assembling_machine_input)
    local output = entity.get_inventory(defines.inventory.assembling_machine_output)
    local dump = entity.get_inventory(defines.inventory.assembling_machine_dump)
--    local trash = entity.get_inventory(8)
    local inventories = {input, output, dump}
    for _, inventory in pairs(inventories) do
        local item_count = inventory.get_item_count(placeholder_name)
        if item_count > 0 then
            for i = 1, #inventory do
                local stack = inventory[i]
                if stack.valid_for_read and stack.name == placeholder_name then
                    --inventory.remove({name="mutation-e"})
                    --inventory.insert({name=storage.spoilage_mapping[placeholder], count=item_count})
                    stack.set_stack({name=storage.spoilage_mapping[placeholder_definition.condition][placeholder_definition.name], count=item_count})
                end
            end
        end
    end
end

--- @param entity LuaEntity (we assume source_entity and target_entity are the same).
--- @param placeholder string the name of the placeholder item.
--- @param inventory_definition defines.inventory.car_trunk|defines.inventory.cargo_wagon|defines.inventory.chest|defines.inventory.hub_main|defines.inventory.rocket_silo_rocket
--- @return nil
local function hotswap_in_generic_inventory(entity, placeholder_definition, inventory_definition)
    local placeholder_name = placeholder_definition.name
    local inventory = entity.get_inventory(inventory_definition)
    local result = storage.spoilage_mapping[placeholder_definition.condition][placeholder_definition.name]
    if inventory then
        local current_count = inventory.get_item_count(placeholder_name)
        if current_count > 0 then
            inventory.remove({name=placeholder_name, count=current_count})
            if result ~= nil then
                inventory.insert({name=result, count = current_count})
            end
        end
    end
end

--- @param entity LuaEntity (we assume source_entity and target_entity are the same).
--- @param placeholder string the name of the placeholder item.
--- @return nil
local function hotswap_in_logistic_inventory(entity, placeholder_definition)
    local placeholder_name = placeholder_definition.name
    local inventories = {entity.get_inventory(defines.inventory.chest), entity.get_inventory(defines.inventory.logistic_container_trash)}
    local result = storage.spoilage_mapping[placeholder_definition.condition][placeholder_definition.name]
    for _, inventory in pairs(inventories) do
        local current_count = inventory.get_item_count(placeholder_name)
        if current_count > 0 then
            inventory.remove({name=placeholder_name, count=current_count})
            if result ~= nil then
                inventory.insert({name=result, count = current_count})
            end
        end
    end
end


--- @param entity LuaEntity (we assume source_entity and target_entity are the same).
--- @param placeholder string the name of the placeholder item.
--- @param inventory_definition defines.inventory.car_trunk|defines.inventory.cargo_wagon|defines.inventory.chest|defines.inventory.hub_main|defines.inventory.rocket_silo_rocket
local function hotswap_in_generic_inventory_in_place(entity, placeholder_definition, inventory_definition)
    local placeholder_name = placeholder_definition.name
    local inventory = entity.get_inventory(inventory_definition)
    local result = storage.spoilage_mapping[placeholder_definition.condition][placeholder_definition.name]
    if inventory then
        local current_count = inventory.get_item_count(placeholder_name)
        if current_count > 0 then
            for i = 1, #inventory do
                local stack = inventory[i]
                if stack.valid_for_read and stack.name == placeholder_name then
                    stack.set_stack({ name = result, count = stack.count })
                end
            end
        end
    end
end

--- @param entity LuaEntity (we assume source_entity and target_entity are the same).
--- @param placeholder string the name of the placeholder item.
--- @return nil
local function hotswap_on_ground(entity, placeholder_definition)
    return set_or_nil_stack(entity.stack, storage.spoilage_mapping[placeholder_definition.condition][placeholder_definition.name] or nil)
end

--- @param event EventData.on_script_trigger_effect
--- @param placeholder_definition table
local function hotswap_on_position(event, placeholder_definition)
    local surface = game.surfaces[event.surface_index]
    local entity = surface.find_entities_filtered(
        {
            position = event.source_position,
            name = "item-on-ground",
            radius=2
        }
    )
    if entity and entity[1] and entity[1].stack.name == placeholder_definition.name then
        set_or_nil_stack(entity[1].stack, storage.spoilage_mapping[placeholder_definition.condition][placeholder_definition.name] or nil)
    end

end

local generic_source_handler = {
    ["inserter"] = function(entity, placeholder_definition) return hotswap_in_inserter_or_bot(entity, placeholder_definition) end,
    ["logistic-robot"] = function(entity, placeholder_definition) return hotswap_in_inserter_or_bot(entity, placeholder_definition) end,
    ["transport-belt"] = function(entity, placeholder_definition) return hotswap_in_belt(entity, placeholder_definition) end,
    ["loader"] = function(entity, placeholder_definition) return hotswap_in_belt(entity, placeholder_definition) end,
    ["underground-belt"] = function(entity, placeholder_definition) return hotswap_in_underground_belt(entity, placeholder_definition) end,
    ["splitter"] = function(entity, placeholder_definition) return hotswap_in_splitter(entity, placeholder_definition) end,
    ["assembling-machine"] = function(entity, placeholder_definition) return hotswap_in_machine(entity, placeholder_definition) end,
    ["character"] = function(entity, placeholder_definition) return hotswap_item_in_character_inventory(entity, placeholder_definition) end,
    ["logistic-container"] = function(entity, placeholder_definition) return hotswap_in_logistic_inventory(entity, placeholder_definition) end,
    ["cargo-landing-pad"] = function(entity, placeholder_definition) return hotswap_in_logistic_inventory(entity, placeholder_definition) end,
    ["item-entity"] = function(entity, placeholder_definition) return hotswap_on_ground(entity, placeholder_definition) end,
}

local defined_inventories = {
    ["car"] = defines.inventory.car_trunk,
    ["cargo-wagon"] = defines.inventory.cargo_wagon,
    ["container"] = defines.inventory.chest,
    ["space-platform-hub"] = defines.inventory.hub_main,
    ["rocket-silo"] = defines.inventory.rocket_silo_rocket,
}

---local PREFIX_RS = "random_spoil"
---local PREFIX_RSW = "weighted_spoil"
---local PREFIX_CS = "conditional_spoil"

local function split_suffix_and_prefix(effect_id)
    -- Check if the effect_id starts with "rsl_" and extract the suffix
    local prefix, suffix = string.match(effect_id, "^(rsl_)(.+)$")

    if prefix and suffix then
        return prefix, suffix -- Return the prefix and the remaining part as the suffix
    end
    
    return nil, nil -- Return nil if no match
end


---@type table<string, boolean|{prefix:string, suffix:string}>
local cached_event_ids = {}

local function get_suffix_and_prefix_from_effect_id(effect_id)
    local cached_value =  cached_event_ids[effect_id]
    if cached_value == false then
        return nil, nil
    elseif cached_value == nil then
        local prefix, suffix = split_suffix_and_prefix(effect_id)
        if prefix ~= nil and suffix ~= nil then
            cached_event_ids[effect_id] = {prefix = prefix, suffix = suffix}
            cached_value = {prefix = prefix, suffix = suffix}
        else
            cached_event_ids[effect_id] = false
            return nil, nil
        end
    end
    return cached_value.prefix, cached_value.suffix
end



local function swap_item(event, placeholder)
    local placeholder_definition = spoilage_definitions[placeholder]
    if event.source_entity then
        local swap_func = generic_source_handler[event.source_entity.type]
        if swap_func ~= nil then
            swap_func(event.source_entity, placeholder_definition)
        else
            hotswap_in_generic_inventory(event.source_entity, placeholder_definition, defined_inventories[event.source_entity.type])
        end
    else
        hotswap_on_position(event, placeholder_definition)
    end
end

local function on_spoil(event)
    if event.effect_id then
        local prefix, suffix = get_suffix_and_prefix_from_effect_id(event.effect_id)

        if prefix == nil or suffix == nil then
            return
        end
        --local spoilage_definition = spoilage_definitions[suffix]
        --local result = storage.spoilage_mapping[suffix][spoilage_definition.condition]
        if prefix == "rsl_" then
            swap_item(event, suffix)
        end
    end
end
--[[        if prefix == PREFIX_RS then
            swap_item(event, suffix, spoilage_definition)
        elseif prefix == PREFIX_CS then
            local spoilage_definition = placeholder_to_result_conditional[suffix]
            storage.spoilage_mapping[suffix] = spoilage_definition.result[spoilage_definition.condition(event)]
            swap_item(event, suffix)
        end
    end
end
]]
local function cache_effects_ids()
    for placeholder, parameters in pairs(placeholder_to_possible_result_mapping) do
        local prefix_suffix = get_suffix_and_prefix_from_effect_id(parameters.effect_name)
        cached_event_ids[placeholder] = {prefix = prefix_suffix[1], suffix = prefix_suffix[2]}
    end
    for placeholder, parameters in pairs(placeholder_to_result_conditional) do
        local prefix_suffix = get_suffix_and_prefix_from_effect_id(parameters.effect_name)
        cached_event_ids[placeholder] = {prefix = prefix_suffix[1], suffix = prefix_suffix[2]}
    end
end


script.on_event(defines.events.on_tick, function(event)
    if event.tick % 200 == 0 then
        roll_dice()
    end
end)

script.on_event(defines.events.on_script_trigger_effect, on_spoil)


script.on_init(function()
    build_random_spoils()
    storage.belt_mutator_counter = storage.belt_mutator_counter or 0
    storage.spoilage_mapping = storage.spoilage_mapping or {[true] = {}, [false] = {}}
end
)

script.on_configuration_changed(function()
    build_random_spoils()
    storage.belt_mutator_counter = storage.belt_mutator_counter or 0
    storage.spoilage_mapping = storage.spoilage_mapping or {[true] = {}, [false] = {}}
end)

