require("exemple")





local placeholder_reference = {
    type = "item",
    name = "placeholder-reference",
    icon = "__base__/graphics/icons/chemical-science-pack.png",
    subgroup = "raw-material",
    stack_size = 10,
    spoil_ticks = 10,
    spoil_result = "mutation-e",
    weight = 1,
    hidden = true,
    hidden_in_factoriopedia = true,
    spoil_to_trigger_result = 
    {
        items_per_trigger = 1,
        trigger = 
        {
            type = "direct",
            action_delivery =
            {
                type = "instant",
                source_effects = 
                {
                    {
                        type = "script",
                        effect_id = "conditional_spoil_placeholder-reference",
                    },

                }
            }
        }
    }
}

local placeholder_to_possible_result_mapping = {
    ["mutation-a"] = 
    {
        effect_name = "random_spoil_mutation-e",
        possible_results = {"iron-plate", "copper-plate"},
    },
}

local placeholder_to_result_conditional = {
    ["mutation-e"] = 
    {
        effect_name = "conditional_spoil_mutation-e",
        condition = function(event) return check_if_evening(event) end,
        result_true = "iron-plate",
        result_false = nil
    },
}



--local args_exemple = {
  --  mode = "random" | "weighted" | "conditional",
    --possible_results = {"item-1", "item-2"}
--}

local function set_spoilage(item, args)

    local placeholder = item
    placeholder.name = item.name .. "-placeholder"
    placeholder.icon = "__base__/graphics/icons/chemical-science-pack.png"
    placeholder.spoil_ticks = 120
    placeholder.spoil_result = placeholder.name

    return placeholder.name
end