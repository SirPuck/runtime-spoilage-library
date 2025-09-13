local selection_funcs = {}
local condition_check_functions = require("runtime_registry").registry.condition_check_functions

local qualities = prototypes.quality

---@class PossibleResults
---@field [string] table

---@class ResultMapping
---@field possible_results PossibleResults

---@param result_mapping ResultMapping
function selection_funcs.weighted_choice(result_mapping)
    local possible_results = result_mapping.possible_results
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

    return possible_results[low]  -- Correctly selected option
end

function selection_funcs.quality_upscale(result_mapping, event)
    local result_quality = qualities[event.quality].next
    if result_quality == nil then result_quality = "normal" end
    --return {name=result_mapping.original_item_name, quality=result_quality}
    return {name=result_mapping.possible_results.name, quality=result_quality}
end

-- Random selection functions
-----------------------------
--- This function selects and returns one outcome with equals chances of selection from an array of possible items
---@param result_mapping ResultMapping
function selection_funcs.select_one_result_over_n_unweighted(result_mapping, _)
    if #result_mapping.possible_results == 0 then return nil end
    return result_mapping.possible_results[math.random(1, #result_mapping.possible_results)]
end

---@param rsl_definition RtRslDefinition
---@param event EventData.on_script_trigger_effect
local function check_condition(rsl_definition, event)
    local condition_check_func = condition_check_functions[rsl_definition.condition_checker_func_name]
    return tostring(condition_check_func(event))
end

---@param rsl_definition RtRslDefinition
---@param event EventData.on_script_trigger_effect
function selection_funcs.deterministic(rsl_definition, event)
    return rsl_definition.possible_results[check_condition(rsl_definition, event)]
end

---@param rsl_definition RtRslDefinition
---@param event EventData.on_script_trigger_effect
function selection_funcs.condition_random_unweighted(rsl_definition, event)
    local check_result = check_condition(rsl_definition, event)
    local result_mapping = {possible_results = rsl_definition.possible_results[check_result]}
    return selection_funcs.select_one_result_over_n_unweighted(result_mapping) -- function expects a table with `possible_results` element
end

---@param rsl_definition RtRslDefinition
---@param event EventData.on_script_trigger_effect
function selection_funcs.condition_random_weighted(rsl_definition, event)
    local check_result = check_condition(rsl_definition, event)
    local result_mapping = {possible_results = rsl_definition.possible_results[tostring(check_result)]}
    return selection_funcs.weighted_choice(result_mapping) -- function expects a table with `possible_results` element
end

---@param rsl_definition RtRslDefinition
---@param event EventData.on_script_trigger_effect
local function select_result(rsl_definition, event)
    return selection_funcs[rsl_definition.selector](rsl_definition, event)
end

return select_result