local selection_funcs = require("selection")

--- Defines the mode in which results are selected.
---@class ModeType
---@field random boolean
---@field conditional boolean
---@field weighted boolean

--- Represents a remote function call structure.
---@class RemoteCall
---@field remote_mod string The name of the mod exposing the function.
---@field remote_function string The name of the function to call.

--- Arguments for registering an RSL definition.
---@class RslArgs
---@field mode ModeType The mode settings for result selection.
---@field condition nil|boolean|RemoteCall The condition can be true, false, or a remote call structure.
---@field possible_results table<boolean, {name: string, weight?: number}[]> The possible outcomes based on condition results.
local args_model = {
    mode = {random = false, conditional = false, weighted = false},
    condition = nil,
    possible_results = {
        [true] = {
            {name = "", weight = 1}
        },
        [false] = {}
    }
}

local registry = {}

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

registry.rsl_definitions = registry.rsl_definitions or {}
---comment
---@param item_name string
---@param args RslArgs
function registry.register_rsl_definition(item_name, args)
    local placeholder_name = item_name .. "-rsl-placeholder"
    local rsl_definition =  {
            name = placeholder_name,
            possible_results = {
                [true] = {},
                [false] = {}
            },
            event = nil
        }

    --- Build the outcomes
    if args.mode.random == false then
        rsl_definition.condition = args.condition
        rsl_definition.possible_results[true] = args.possible_results[true]
        rsl_definition.possible_results[false] = args.possible_results[true]
        rsl_definition.selection_mode = function(x) return x[1].name end
        registry.rsl_definitions[placeholder_name] = rsl_definition
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
    else
        rsl_definition.selection_mode = function(x) return selection_funcs.select_one_result_over_n_unweighted(x) end
    end
    if args.mode.conditional then
        rsl_definition.condition = args.condition
    else
        rsl_definition.condition = true
    end
    registry.rsl_definitions[placeholder_name] = rsl_definition
    return
end


local registered_rsl_def_exemple = {
    ["iron-plate-rsl-placeholder"] = 
        {
            selection_mode = function(item) return selection_funcs.weighted_choice(item) end,
            name = "iron-plate-rsl-placeholder",
            condition = true,
            possible_results= {
            [true] = {
                cumulative_weight = 3,
                {name = "iron-ore", cumulative_weight = 1},
                {name = "copper-plate", cumulative_weight = 3}
            },
            [false] = {}
        },
        }
    }

return {
    registry = registry,
}