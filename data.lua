require("data_registry")

data.raw.item["concrete"].spoil_ticks = 2
---@type RslRegistrationData
local reg_data_concrete = {
    original_item_type = "item",
    original_item_name = "concrete",
    loop_spoil_safe_mode = true,
    random = true,
    conditional = true,
    condition_checker_func_name = "spoil_by_quality",
    condition_checker_func = [[
        function(event)
            local e = event.quality
            return e or "normal"
        end
    ]],
    conditional_random_results = {
        ["normal"]    = { { name = "iron-ore", quality = "normal", weight = 1 } },
        ["uncommon"]  = { { name = "stone", quality = "normal", weight = 1 } },
        ["rare"]      = { { name = "stone", quality = "normal", weight = 1 } },
        ["epic"]      = { { name = "stone", quality = "normal", weight = 1 } },
        ["legendary"] = { { name = "stone", quality = "normal", weight = 1 } },
    },
    placeholder_overrides = {
        icon = data.raw.item["concrete"].icon,
        localised_name = {"", "Yo baby"}
    }
}

local my_rsl_registration_concrete = {
    type = "mod-data",
    name = "rsl_" .. "concrete",
    data_type = "rsl_registration",
    data = reg_data_concrete
}

data:extend { my_rsl_registration_concrete }