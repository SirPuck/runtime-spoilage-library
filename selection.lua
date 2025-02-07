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
--- This function selects and returns one outcome with equals chances of selection from an array of 2 strings.
--- @param possible_outcomes string[] An array of strings containing item names.
--- @return string string containing a pair {placeholder_item = selected_outcome}
function selection_funcs.select_one_result_over_n_unweighted(possible_outcomes)
    return possible_outcomes[math.random(1, #possible_outcomes)].name
end

return selection_funcs