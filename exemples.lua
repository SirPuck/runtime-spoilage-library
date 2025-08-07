local expected_structure = {
    ["string"] = {
        {name="item_name", weight=int},
        {name="another_item_name", weight=int},
                },
        ["another_string"] = {
        {name="item_name", weight=int},
        {name="another_item_name", weight=int},
                }
            }

local expected_2 = {
    ["string"] = "string",
    ["string2"] = "string"
}

local random_results = {
    {name = "iron-plate"}, {name = "copper-plate"}
}
local random_results_other_exemple = {
    {name = "iron-plate", weight = 1}, {name = "copper-plate", weight = 10}
}
local conditional_random_results = {
    ["cyour condition result 1"] = {
        {name = "iron-plate", weight = 1}, {name = "copper-plate", weight = 10}
    },
    ["your condition result 2"] = {
        {name = "iron-plate", weight = 10}, {name = "copper-plate", weight = 1}
    }
}

local conditional_random_results_other_ex = {
    ["cyour condition result 1"] = {
        {name = "iron-plate"}, {name = "copper-plate"}
    },
    ["your condition result 2"] = {
        {name = "iron-plate"}, {name = "copper-plate"}
    }
}
local conditional_results = {
    ["your condition result 1"] = {name = "iron_plate"},
    ["your condition result 2"] = {name = "copper-plate"}
}