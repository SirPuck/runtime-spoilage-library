local selection_funcs = require("selection")

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

local wip_exemple = {
    ["mutation-e"] = 
        {
            selection_mode = function(item) return selection_funcs.weighted_choice(item) end,
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
            [true] = {
                {name = "something"}
            },
            [false] = {}
        },
        }
    }

local placeholder_model = {
    type = "item",
    icon = "__base__/graphics/icons/production-science-pack.png",
    subgroup = "raw-material",
    stack_size = 10,
    spoil_ticks = 120,
    hidden = true,
    hidden_in_factoriopedia = true,
}

---@class ModeType
---@field random boolean
---@field conditional boolean
---@field weighted boolean

---@class RslArgs
---@field mode ModeType
---@field condition? any  # Optional, replace 'any' with specific type if known
---@field possible_results table<boolean, table>

-- Example args_model following the RslArgs structure
local args_model = {
    mode = {random = false, conditional = false, weighted = false},
    condition = nil,
    possible_results = {
        [true] = {},
        [false] = {}
    }

}

---comment
---@param item LuaItemPrototype your custom item
---@param items_per_trigger int number of items needed to trigger the script
---@param custom_trigger TriggerItem 
local function create_spoilage_components(item, items_per_trigger, custom_trigger)
    --- Build placeholder item
    local placeholder = table.deepcopy(placeholder_model)
    placeholder.name = item.name .. "-rsl-placeholder"
    placeholder.stack_size = item.stack_size
    placeholder.spoil_result = placeholder.name

    item.spoil_to_trigger_result = 
    {
        items_per_trigger = 1,
        trigger = 
        {
            {
                type = "direct",
                action_delivery =
                    {
                    type = "instant",
                    source_effects = 
                    {
                        {
                            type = "script",
                            effect_id = "rsl_" .. placeholder.name
                        },
                    }
                }
            },
        }
    }

    if items_per_trigger then
        item.spoil_to_trigger_result.items_per_trigger = items_per_trigger
    end
    if custom_trigger then
        table.insert(item.spoil_to_trigger_result.trigger, custom_trigger)
    end

    data:extend{item, placeholder}
end
