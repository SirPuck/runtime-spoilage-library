local function check_if_evening(entity)
    local surface = entity.surface
    return surface.evening < surface.daytime < surface.dusk
end




local placeholder_to_possible_result_mapping = {
    ["mutation-e"] = {"iron-plate", "copper-plate"},
}

local placeholder_to_possible_result_mapping_v2 = {
    ["mutation-e"] = 
    {   mode = {random = true, weighted = false, conditional = true},
        random = {"iron-plate", "copper-plate"},
        conditional = {
            condition = function(entity) return check_if_evening(entity) end,
            result_true = "iron-plate",
            result_false = "copper-plate",
            delete_on_failure = false
        }
    },
}


return {
    placeholder_to_possible_result_mapping = placeholder_to_possible_result_mapping,
    placeholder_to_possible_result_mapping_v2 = placeholder_to_possible_result_mapping_v2,
}

