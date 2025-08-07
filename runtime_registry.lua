---@class LuaRslDefinition
---@field name string
---@field original_item_name string
---@field selector string
---@field possible_results table
---@field condition_checker_func_name string

--- Represents a remote function call structure.
---@class RemoteCall
---@field remote_mod string The name of the mod exposing the function.
---@field remote_function string The name of the function to call.


local registry = {}

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
                condition_checker_func_name = proto.data.condition_checker_func_name
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
            ---@cast proto LuaRslDefinition
            storage.rsl_definitions[proto.name] = rsl_definition
        end
    end
end

registry.condition_check_functions = {}

function registry.register_condition_check(name, func)
    --- Register an external function that takes a single `event` argument
    ---@param name string A unique name to register the function under
    ---@param func function The actual function to store
    register = function(name, func)
        if type(name) ~= "string" then
            error("First argument to register must be a string (function name)")
        end
        if type(func) ~= "function" then
            error("Second argument to register must be a function")
        end
        if registry.condition_check_functions[name] then
            log("[RSL] Warning: Overwriting previously registered function '" .. name .. "'")
        end
        registry.condition_check_functions[name] = func
        log("[RSL] External function '" .. name .. "' registered successfully.")
    end
end


return {
    registry = registry,
}