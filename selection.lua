local selection_funcs = {}

function selection_funcs.weighted_choice(possible_results)
    if not possible_results then return nil end

    local r = math.random() * possible_results.cumulative_weight
    local options = possible_results.options
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

-- Random selection functions
-----------------------------
--- @param placeholder_item string A string with the name of the item linked that will be linked to an outcome.
--- @param possible_outcomes string[] An arra of two strings containing item names
--- @param weights number[] An array of two numbers representing weights for the items
--- @return string[] A table containing a pair {placeholder_item = selected_outcome}
function selection_funcs.select_one_result_over_two(placeholder_item, possible_outcomes, weights)
    assert(#possible_outcomes == 2 and #weights == 2, "Two outcomes and two weights required")
    local weight_sum = weights[1] + weights[2]
    return {placeholder_item = math.random() < (weights[1] / weight_sum) and possible_outcomes[1] or possible_outcomes[2]}
end



--- This function selects and returns one outcome with equals chances of selection from an array of 2 strings.
--- @param possible_outcomes string[] An array of strings containing item names.
--- @return string string containing a pair {placeholder_item = selected_outcome}
function selection_funcs.select_one_result_over_n_unweighted(possible_outcomes)
    return possible_outcomes[math.random(1, #possible_outcomes)].name
end

return selection_funcs