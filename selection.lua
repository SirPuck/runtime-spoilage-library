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

return selection_funcs