local selection_funcs = require("selection")

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
---@param args RslArgs
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
        rsl_definition.selection_mode = function(x) return selection_funcs.weighted_choice(x) end
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

local rsl_definitions = {
    ["mutation-e"] = 
        {
            selection_mode = function(item) return selection_funcs.weighted_choice(item) end,
            name = "mutation-e",
            condition = true,
            possible_results= {
            [true] = {
                cumulative_weight = 3,
                options = {
                {name = "iron-plate", cumulative_weight = 1},
                {name = "copper-plate", cumulative_weight = 3}
                }
            },
            [false] = {}
        },
        }
    }

return {
    spoilage_definitions = rsl_definitions,
}

