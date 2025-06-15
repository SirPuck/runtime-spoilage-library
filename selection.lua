---@alias RslSelectionMode
---| "weighted_choice"
---| "select_one_result_over_n_unweighted"
---| "nonrandom"

---@type table<RslSelectionMode,fun(possible_results:RslItems):string?>
local selection_funcs = {}

---@param possible_results RslWeightedItems
function selection_funcs.weighted_choice(possible_results)
    if not possible_results then return nil end

    local r = math.random() * possible_results.cumulative_weight
    local low, high = 1, #possible_results

    -- Binary search for correct cumulative weight
    while low < high do
        local mid = math.floor((low + high) / 2)
        if possible_results[mid].weight < r then
            low = mid + 1
        else
            high = mid
        end
    end

    return possible_results[low].name  -- Correctly selected option
end

-- Random selection functions
-----------------------------
--- This function selects and returns one outcome with equals chances of selection from an array of possible items
function selection_funcs.select_one_result_over_n_unweighted(possible_outcomes)
    if #possible_outcomes == 0 then return nil end
    return possible_outcomes[math.random(1, #possible_outcomes)].name
end

---Just blindly choose the name of the first result
function selection_funcs.nonrandom(possible_results)
    return possible_results[1].name
end

---@param mode RslSelectionMode
---@param results RslItems?
---@return string?
local function call_selection(mode, results)
    if not results then return end -- There's no possible results. Give up
    local func = selection_funcs[mode]
    if not func then error("Somehow the selection mode had an invalid value") end
    return func(results)
end

-- Inventory swapping functions
------------------------
---@param rsl_definition RslDefinition
---@return string?
local function select_result(rsl_definition)
    local condition = rsl_definition.condition

    if condition == true then
        return call_selection(rsl_definition.selection_mode, rsl_definition.possible_results[true])
    end

    local event = rsl_definition.event
    if type(condition) == "table" then
        local success, result = pcall(remote.call, condition.remote_mod, condition.remote_function, event)
        if not success then
            if type(result) == "string" then
                log("Remote call errored. Continuing without a result. Err:\n"..result)
            else
                log("Remote call errored. Continuing without a result.")
            end
            return
        end
        local options_list = rsl_definition.possible_results[result]
        return call_selection(rsl_definition.selection_mode, options_list)
    end

    --local options_list = rsl_definition.possible_results[success]
    --return rsl_definition.selection_mode(options_list)
end

return select_result