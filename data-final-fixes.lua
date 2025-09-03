---@class RslDefinition
---@field type string Should be "mod-data".
---@field name string The name of the item that spoils.
---@field data_type string Should be "rsl_definition".
---@field data RslDefinitionData Spoilage configuration for the item.

---@class RslDefinitionData
---@field original_item_name string The name of the item that will spoil.
---@field items_per_trigger? integer|nil Optional. Number of items required to trigger spoilage. DO NOT fill this field unless you really need to.
---@field fallback_spoilage? string|nil Optional. Name of the item to use as fallback spoilage result.
---@field loop_spoil_safe_mode boolean If true, the placeholder will spoil into itself if it cannot be replaced by RSL; if false, it will simply disappear.
---@field additional_trigger? table|nil Optional. Additional trigger for spoilage.
---@field random boolean If true, spoilage results are chosen randomly.
---@field conditional boolean If true, spoilage results are determined by a condition.
---@field condition? string|nil Name of the function used to determine conditional spoilage.
---@field selector string Name of the selector function.
---@field possible_results table List of possible random spoilage results.

local function preprocess_weights(possible_results)
    local cumulative_weight = 0
    local sorted_options = {}

    -- Build sorted list of cumulative_weights
    for _, option in ipairs(possible_results) do
        cumulative_weight = cumulative_weight + option.weight
        table.insert(sorted_options, {name = option.name, weight = cumulative_weight})
    end

    -- Ensure sorting is correct (ascending order)
    table.sort(sorted_options, function(a, b)
        return a.weight < b.weight
    end)

    sorted_options.cumulative_weight = cumulative_weight
    return sorted_options
end


local function flatten_conditional_results(nested)
    local flat = {}
    for _, result_list in pairs(nested) do
        for _, entry in ipairs(result_list) do
            flat[#flat+1] = entry
        end
    end
    return flat
end

--- Validates whether the given results table is weighted.
-- @param prototype_name (string) The name of the prototype being validated.
-- @param results (table) The results table to check for weighting.
-- @return (boolean) Returns true if the results are weighted, false otherwise.
local function validate_is_weighted(prototype_name, results, nested)
    local weighted = false
    local all_weighted = true

    if nested then
        results = flatten_conditional_results(results)
    end

    for key, value in pairs(results) do
            
            if value.weight ~= nil then
                weighted = true
                if type(value.weight) ~= "number" or value.weight % 1 ~= 0 then
                    error("validate_is_weighted: In prototype '" .. tostring(prototype_name) .. "', weight must be an integer.")
                end
            else
                all_weighted = false
            end

    end

    if weighted and not all_weighted then
        error("validate_is_weighted: In prototype '" .. tostring(prototype_name) .. "', if at least one result is weighted, all must be weighted.")
    end

    return weighted
end


local function validate_rc_results(prototype_name, input_results)
    if type(input_results) ~= "table" then
        error("validate_results: conditional_random_results must be a table, got " .. type(input_results))
    end

    for key, value in pairs(input_results) do
        if type(key) ~= "string" and type(key) ~= "number" then
            error("validate_results: in prototype "..prototype_name..", key '" .. tostring(key) .. "' is not a string|int|bool.")
        end
        if type(value) ~= "table" then
            error("validate_results: in prototype "..prototype_name..", value for key '" .. key .. "' must be a table, got " .. type(value))
        end
        for i, entry in ipairs(value) do
            if type(entry) ~= "table" then
                error("validate_results: in prototype "..prototype_name..", entry #" .. i .. " in '" .. key .. "' must be a table, got " .. type(entry))
            end
            if type(entry.name) ~= "string" then
                error("validate_results: in prototype "..prototype_name..", entry #" .. i .. " in '" .. key .. "' is missing a string 'name' field")
            end
        end
    end

end

local function validate_c_deterministic_results(prototype_name, input_results)
    if type(input_results) ~= "table" then
        error("validate_results: in prototype "..prototype_name..", conditional_results must be a table, got " .. type(input_results))
    end

    for key, value in pairs(input_results) do
        if type(key) ~= "string" and type(key) ~= "number" then
            error("validate_results: in prototype "..prototype_name..", key '" .. tostring(key) .. "' is not a string|int|bool.")
        end
        if type(value) ~= "string" then
             error("validate_results: in prototype "..prototype_name..", value for key '" .. key .. "' must be a string (item name), got " .. type(value))
        end
    end

end


local function make_rsl_definition(rsl_registration)

    rsl_registration.hidden = true
    rsl_registration.hidden_in_factoriopedia = true

    local rsl_definition = table.deepcopy(rsl_registration)

    local original_item = data.raw[rsl_definition.data.data_raw_table][rsl_definition.data.original_item_name]

    local placeholder = {
            type = "item",
            name = original_item.name .. "-rsl-placeholder",
            icon = "__base__/graphics/icons/signal/signal-question-mark.png",
            subgroup = "raw-material",
            stack_size = original_item.stack_size,
            spoil_ticks = 10,
            weight = original_item.weight,

            hidden = true,
            hidden_in_factoriopedia = true,
        }


    original_item.spoil_to_trigger_result =
    {
        items_per_trigger = rsl_definition.data.items_per_trigger or original_item.stack_size, --This allows to trigger only one event by default for the entire stack.
        trigger =
        {
            {
                type = "direct",
                action_delivery =
                    {
                    type = "instant",
                    source_effects = 
                    {
                        {
                            type = "script",
                            effect_id = placeholder.name
                        },
                    }
                }
            },
        }
    }

    original_item.spoil_result = placeholder.name

    if rsl_registration.data.loop_spoil_safe_mode or rsl_registration.data.loop_spoil_safe_mode == nil then
        placeholder.spoil_result = placeholder.name
        placeholder.spoil_to_trigger_result = original_item.spoil_to_trigger_result
    end

    data:extend{
        placeholder
    }

    rsl_definition.name = placeholder.name
    rsl_definition.data_type = "rsl_definition"

    local prototype_name = rsl_registration.name

    rsl_definition.data["possible_results"] = {}

    if rsl_definition.data.conditional and rsl_definition.data.random then
        validate_rc_results(prototype_name, rsl_definition.data.conditional_random_results)

        local weighted = validate_is_weighted(prototype_name, rsl_definition.data.conditional_random_results, true)
        
        if weighted then
            
            for condition_result, results in pairs(rsl_definition.data.conditional_random_results) do
                rsl_definition.data["possible_results"][condition_result] = preprocess_weights(results)
            end

            rsl_definition.data["selector"] = "condition_random_weighted"
            data:extend{rsl_definition}
            return
        else
            rsl_definition.data["possible_results"] = rsl_definition.data.conditional_random_results
            rsl_definition.data["selector"] = "condition_random_unweighted"
            return
        end
    end

    if rsl_definition.data.conditional then
        validate_c_deterministic_results(prototype_name, rsl_definition.data.conditional_results)
        rsl_definition.data["selector"] = "deterministic"
        rsl_definition.data["possible_results"] = rsl_definition.data.conditional_results
        data:extend{rsl_definition}
        return
    end

    if rsl_definition.data.random then
        local weighted = validate_is_weighted(prototype_name, rsl_definition.data.random_results)
        if weighted then
            rsl_definition.data["selector"] = "weighted_choice"
            rsl_definition.data["possible_results"] = preprocess_weights(rsl_definition.data.random_results)
        else
            rsl_definition.data["selector"] = "select_one_result_over_n_unweighted"
            rsl_definition.data["possible_results"] = rsl_definition.data.random_results
        end
        data:extend{rsl_definition}
    end


end

if data.raw["mod-data"] then for _, content in pairs(data.raw["mod-data"]) do
        if content and content.data_type == "rsl_registration" then make_rsl_definition(content) end
    end
end
