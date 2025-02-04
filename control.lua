local registry = require("registry")
local swap_funcs = require("swap_inventories")
local spoilage_definitions = registry.spoilage_definitions
local placeholder_to_result_conditional = registry.placeholder_to_result_conditional
local enable_swap_in_assembler = false
local possible_results = {[true] = {}, [false] = {}}


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

local wip_exemple = {
    ["mutation-e"] = 
        {
            selection_mode = function(item) return weighted_choice(item) end,
            name = "mutation-e",
            condition = true,
            possible_results= {
            [true] = {
                cumulative_weight = 3,
                {name = "iron-plate", cumulative_weight = 1},
                {name = "copper-plate", cumulative_weight = 3}
            },
            [false] = {}
        },
        }
    }
local wip_exemple2 = {
    ["mutation-e"] = 
        {
            selection_mode = function(item) return item[1] end,
            name = "mutation-e",
            condition = true,
            possible_results= {
            [true] = {"something"},
            [false] = {}
        },
        }
    }


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


local generic_source_handler = {
    ["inserter"] = function(entity, placeholder_definition) return swap_funcs.hotswap_in_inserter_or_bot(entity, placeholder_definition) end,
    ["logistic-robot"] = function(entity, placeholder_definition) return swap_funcs.hotswap_in_inserter_or_bot(entity, placeholder_definition) end,
    ["transport-belt"] = function(entity, placeholder_definition) return swap_funcs.hotswap_in_belt(entity, placeholder_definition) end,
    ["loader"] = function(entity, placeholder_definition) return swap_funcs.hotswap_in_belt(entity, placeholder_definition) end,
    ["underground-belt"] = function(entity, placeholder_definition) return swap_funcs.hotswap_in_underground_belt(entity, placeholder_definition) end,
    ["splitter"] = function(entity, placeholder_definition) return swap_funcs.hotswap_in_splitter(entity, placeholder_definition) end,
    ["assembling-machine"] = function(entity, placeholder_definition) return swap_funcs.hotswap_in_machine(entity, placeholder_definition) end,
    ["character"] = function(entity, placeholder_definition) return swap_funcs.hotswap_item_in_character_inventory(entity, placeholder_definition) end,
    ["logistic-container"] = function(entity, placeholder_definition) return swap_funcs.hotswap_in_logistic_inventory(entity, placeholder_definition) end,
    ["cargo-landing-pad"] = function(entity, placeholder_definition) return swap_funcs.hotswap_in_logistic_inventory(entity, placeholder_definition) end,
    ["item-entity"] = function(entity, placeholder_definition) return swap_funcs.hotswap_on_ground(entity, placeholder_definition) end,
}

local defined_inventories = {
    ["car"] = defines.inventory.car_trunk,
    ["cargo-wagon"] = defines.inventory.cargo_wagon,
    ["container"] = defines.inventory.chest,
    ["space-platform-hub"] = defines.inventory.hub_main,
    ["rocket-silo"] = defines.inventory.rocket_silo_rocket,
}


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
            swap_funcs.hotswap_in_generic_inventory(event.source_entity, placeholder_definition, defined_inventories[event.source_entity.type])
        end
    else
        swap_funcs.hotswap_on_position(event, placeholder_definition)
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

script.on_event(defines.events.on_tick, function(event)
    if event.tick % 200 == 0 then
        roll_dice()
    end
end)

script.on_event(defines.events.on_script_trigger_effect, on_spoil)


script.on_init(function()
    storage.belt_mutator_counter = storage.belt_mutator_counter or 0
    storage.spoilage_mapping = storage.spoilage_mapping or {[true] = {}, [false] = {}}
end
)

script.on_configuration_changed(function()
    storage.belt_mutator_counter = storage.belt_mutator_counter or 0
    storage.spoilage_mapping = storage.spoilage_mapping or {[true] = {}, [false] = {}}
end)

