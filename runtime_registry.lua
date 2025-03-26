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
---@field condition? RemoteCall The remote call used if the mode is conditional. If it's not conditional, it'll just use `true`.
---@field possible_results table<boolean, RslItems> The possible outcomes based on condition results.
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

---@param possible_results RslItems
---@return RslWeightedItems
local function preprocess_weights(possible_results)
    local cumulative_weight = 0
    ---@type RslItems
    local sorted_options = {}

    -- Build sorted list of cumulative weights
    for _, option in pairs(possible_results) do
        if not option.weight then error("Chose to weight the random results, but results did not have weights", 3) end
        cumulative_weight = cumulative_weight + option.weight--[[@as number]]
        table.insert(sorted_options, { weight = cumulative_weight, name = option.name})
    end

    -- Ensure sorting is correct (ascending order)
    table.sort(sorted_options, function(a, b)
        return a.weight < b.weight
    end)

    ---@cast sorted_options RslWeightedItems
    sorted_options.cumulative_weight = cumulative_weight
    return sorted_options
end

--- Do not allow a possible_results table to accept table indexes
--- We want them *accessible*. Maybe *you* can pass a table around as an index
--- but I do not trust the remote interface to keep the references the same across different passes
---@type table<type,true>
local index_by_value_types = {
    ["boolean"] = true,
    ["number"] = true,
    ["string"] = true,
}

---@param result RslWeightedItem
local function validate_result(result)
    if type(result) ~= "table" then
        error("Expected a result item table. Got a '"..type(result).."' instead", 3)
    elseif type(result.name) ~= "string" then
        error("Expected a string for the name of the result item. Got a '"..type(result.name).."' instead", 3)
    elseif result.weight ~= nil and type(result.weight) ~= "number" then
        error("Expected a number for the weight of the result item. Got a '"..type(result.weight).."' instead", 3)
    end

    local prototype = prototypes.item[result.name]
    if not prototype then
        error("The given item name, did not exist: "..result.name, 3)
    end
end

--- Validates the given remote call parameters
---@param remote_call RemoteCall
local function validate_remote_call(remote_call)
    if type(remote_call.remote_function) ~= "string" then
        error("Expected a string for the remote_function field. Got a '"..type(remote_call.remote_function).."' instead", 3)
    elseif type(remote_call.remote_mod) ~= "string" then
        error("Expected a string for the remote_mod field. Got a '"..type(remote_call.remote_mod).."' instead", 3)
    end

    local interface = remote.interfaces[remote_call.remote_mod]
    if not interface then
        error("Remote call's interface did not exist.", 3)
    elseif not interface[remote_call.remote_function] then
        error("Remote call's function did not exist in given interface.", 3)
    end
end

---Register a new RSL definition remotely.
---@param item_name string The name of the item the will spoil.
---@param args RslArgs The arguments for the RSL definition.
function registry.register_rsl_definition(item_name, args)
    if not game then
        return error("Runtime Spoilage Library has been updated and registering in on_load is no longer necessary, or valid.", 2)
    end
    local placeholder_name = item_name .. "-rsl-placeholder"

    --- Complain about inane mode combinations
    if args.mode.random == false and args.mode.weighted then
        error("Random was set to false, and weighted true.. These are conflicting options.", 2)
    end

    -- Process the given results to make sure they are not malformed
    local possible_results = args.possible_results
    for key, results in pairs(possible_results) do
        if not index_by_value_types[type(key)] then
            error("The key to some of the possible results are impossible to re-index by. Prove your case if you disagree about '"..type(key).."' being unusable", 2)
        end
        for _, result in pairs(results) do
            validate_result(result)
        end
    end

    --- Selection mode selection
    --- Also react to the mode by affecting results if need be
    ---@type RslSelectionMode
    local selection_mode
    if not args.mode.random then
        selection_mode = "nonrandom"
    elseif args.mode.weighted then
        selection_mode = "weighted_choice"
        -- Preprocess all the results to allow for the weighted choice function to work properly
        for key, results in pairs(possible_results) do
            possible_results[key] = preprocess_weights(results)
        end
    else
        selection_mode = "select_one_result_over_n_unweighted"
    end

    --- Condition evaluation
    ---@type RemoteCall|true?
    local condition = args.condition
    if args.mode.conditional then
        if type(condition) ~= "table" then
            error("Set to conditional, and didn't provide a remote call.", 2)
        end

        validate_remote_call(condition)
    else
        condition = true
        --- Limit possible results to `true` since the condition will always be true
        possible_results = {
            [true] = possible_results[true]
        }
    end

    storage.rsl_definitions[placeholder_name] = {
        name = placeholder_name,
        possible_results = possible_results,
        event = nil,
        condition = condition,
        selection_mode = selection_mode
    }
end

--FIXME: This example is out of date
local registered_rsl_def_exemple = {
    ["iron-plate-rsl-placeholder"] = 
        {
---@diagnostic disable-next-line: undefined-global, no-unknown
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