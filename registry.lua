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

local args_model = {
    mode = {random = false, conditional = false, weighted = false},
    condition = nil,
    possible_results = {
        [true] = {},
        [false] = {}
    }

}

---comment
---@param item LuaItemPrototype
local function create_spoilage_script(item)
    --- Build placeholder item
    local placeholder = table.deepcopy(placeholder_model)
    placeholder.name = item.name .. "-rsl-placeholder"
    placeholder.stack_size = item.stack_size
    placeholder.spoil_result = placeholder.name
    placeholder.spoil_to_trigger_result = 
    {
        items_per_trigger = 1,
        trigger = 
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
        }
    }
    return placeholder
end

local function preprocess_weights(possible_results)
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

    return {
            cumulative_weight = cumulative_weight,
            options = sorted_options
        }

end

local rsl_definitions = {}
---comment
---@param item_name string
---@param args any
local function register_rsl_definition(item_name, args)
    local placeholder_name = item_name .. "-rsl-placeholder"
    local rsl_definition =  {
            possible_results = {
                [true] = {},
                [false] = {}
            }
        }

    --- Build the outcomes
    if args.mode.random == false then
        rsl_definition.condition = args.condition
        rsl_definition.possible_results[true] = args.possible_results[true]
        rsl_definition.possible_results[false] = args.possible_results[true]
        rsl_definition.selection_mode = function(x) return x[1].name end
        rsl_definitions[placeholder_name] = rsl_definition
        return
    end
    if args.mode.random then
        rsl_definition.possible_results[true] = args.possible_results[true]
        rsl_definition.possible_results[false] = args.possible_results[false] or {}
    end
    if args.mode.weighted then
        rsl_definition.selection_mode = function(x) return weighted_choice(x) end
        rsl_definition.possible_results[true] =  preprocess_weights(args.possible_results[true])
        if args.possible_results[false] ~= nil then
            rsl_definition.possible_results[false] = preprocess_weights(args.possible_results[false])
        end
    end
    if args.mode.conditional then
        rsl_definition.condition = args.condition
    else
        rsl_definition.condition = true
    end
    return
end

return {
    spoilage_definitions = rsl_definitions,
}

