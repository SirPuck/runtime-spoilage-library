---@class RtRslDefinition
---@field name string
---@field original_item_name string
---@field selector string
---@field possible_results table
---@field condition_checker_func_name string
---@field condition_checker_func string

local registry = {}
registry.condition_check_functions = {}

local function compile_function_from_string(name, code_str)
  if type(code_str) ~= "string" then
    error("["..name.."] conditional_func_check must be a string, got "..type(code_str))
  end

  -- Prefer expression form: "function(event) ... end"
  -- Wrap with `return (...)` so the chunk evaluates to the function value.
  local wrapped = "return (" .. code_str .. ")"

  local chunk, err = load(wrapped, name .. "::<rsl-func>", "t", _ENV)
  if not chunk then
    -- As a fallback, try raw (maybe author wrote "return function(event) ... end")
    chunk, err = load(code_str, name .. "::<rsl-func>", "t", _ENV)
    if not chunk then
      error("["..name.."] failed to compile conditional_func_check: "..tostring(err))
    end
  end

  local ok, fn_or_val = pcall(chunk)
  if not ok then
    error("["..name.."] runtime error evaluating conditional_func_check: "..tostring(fn_or_val))
  end
  if type(fn_or_val) ~= "function" then
    error("["..name.."] conditional_func_check did not evaluate to a function")
  end

  registry.condition_check_functions[name] =  fn_or_val
end

---Yes it's... not great. But Factorio serializes table indexes to strings.
---And I don't want that. Moreover, this allows to only keep the minimal info needed.
function registry.make_registry()
    
    local mod_data = prototypes.mod_data

    for _, proto in pairs(mod_data) do
        if proto.data_type == "rsl_definition" then

            local rsl_definition = {
                name = proto.name,
                original_item_name = proto.data.original_item_name,
                selector = proto.data.selector,
                possible_results = {},
                condition_checker_func_name = proto.data.condition_checker_func_name or nil,
                condition_checker_func = proto.data.condition_checker_func or nil
            }

            if proto.data.selector == ("weighted_choice" or "select_one_result_over_n_unweighted") then
                for key, value in pairs(proto.data.possible_results) do
                    if key == "cumulative_weight" then rsl_definition.possible_results[key] = value
                    else rsl_definition.possible_results[tonumber(key)] = value end
                end
            elseif proto.data.selector == ("condition_random_weighted" or "condition_random_unweighted") then
                for condition, conditional_results in pairs(proto.data.possible_results) do
                    local results_ = {}
                    for key, value in pairs(conditional_results) do
                        if key == "cumulative_weight" then results_[key] = value
                        else results_[tonumber(key)] = value end
                    end
                    
                    rsl_definition.possible_results[condition] = results_
                end
            elseif proto.data.selector == "deterministic" then
                rsl_definition.possible_results = proto.data.possible_results
            end
            storage.rsl_definitions[proto.name] = rsl_definition
        end
    end
end

function registry.compile_functions()
    for _, definition in pairs(storage.rsl_definitions) do
        if definition.condition_checker_func then
            compile_function_from_string(definition.condition_checker_func_name, definition.condition_checker_func)
        end
    end
end

return {
    registry = registry,
}