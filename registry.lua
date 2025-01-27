local function check_if_evening(event)
    local surface = event.source_entity.surface
    return surface.dusk < surface.daytime and surface.daytime < surface.dawn
end




local placeholder_to_possible_result_mapping = {
    ["mutation-e"] = {"iron-plate", "copper-plate"},
}

local placeholder_to_result_conditional = {
    ["mutation-e"] = 
    {
        condition = function(event) return check_if_evening(event) end,
        result_true = "iron-plate",
        result_false = nil
    },
}


return {
    placeholder_to_possible_result_mapping = placeholder_to_possible_result_mapping,
    placeholder_to_result_conditional = placeholder_to_result_conditional,
}

