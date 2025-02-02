local function check_if_evening(event)
    local surface = event.source_entity.surface
    return surface.dusk < surface.daytime and surface.daytime < surface.dawn
end




local placeholder_to_possible_result_mapping = {
    ["mutation-e"] = 
    {
        effect_name = "random_spoil_mutation-e",
        possible_results = {"iron-plate", "copper-plate"},
        condition = true,
        random = true,
    },
}

local placeholder_to_result_conditional = {
    ["mutation-e"] = 
    {
        effect_name = "conditional_spoil_mutation-e",
        condition = function(event) return check_if_evening(event) end,
        result = { [true] = "iron-plate", [false] = nil}
    },
}

local function build_registry(condition)
    -- if a function is associated to the variable condition, then return { condition = function} else return { condition = true}
end

-- I can make the control stage set the key value pairs as ["placeholder"] = {[true] = result1, [false] = result2} for every item
-- even if their result is random. To set this up all I need to do, for instance, for a random item :
--[[local ex_random_item = {
    ["item-placeholdername"] =
    {
        condition = true
    }
}]]
local item_params = {
    ["rsl-itemtospoil"] = 
    {
        mode = {random = true, conditional = false, weighted = true},
        placeholder_name = "placeholdername",
        possible_results = {
            {name = "iron-plate", weight = 1},
            {name = "copper-plate", weight = 2}
        },
    }

}

local placeholder_to_possible_result_mapping = {
    ["mutation-e"] = 
        {
            mode = {random = true, conditional = false, weighted = true},
            name = "mutation-e",
            condition = true,
            possible_results_true = {
                {name = "iron-plate", weight = 1},
                {name = "copper-plate", weight = 2}
            },
            possible_results_false = {}
        }
    }
--local function set_spoilage






return {
    spoilage_definitions = placeholder_to_possible_result_mapping,
    placeholder_to_result_conditional = placeholder_to_result_conditional,
}

