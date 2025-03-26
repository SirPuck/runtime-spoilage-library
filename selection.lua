---@alias selection_funcs
---| "weighted_choice"
---| "select_one_result_over_n_unweighted"
---| "nonrandom"

---@type table<selection_funcs,fun(possible_results:RslWeightedItem[]):string?>
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
    return possible_outcomes[math.random(1, #possible_outcomes)].name
end

---Just blindly choose the name of the first result
function selection_funcs.nonrandom(possible_results)
    return possible_results[1].name
end

return selection_funcs