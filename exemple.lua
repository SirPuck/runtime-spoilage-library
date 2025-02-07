




local mutation_a = {
    type = "item",
    name = "mutation-a",
    icon = "__base__/graphics/icons/automation-science-pack.png",
    subgroup = "raw-material",
    stack_size = 10,
    spoil_ticks = 20,
    spoil_result = "mutation-d",
}

local mutation_b = {
    type = "item",
    name = "mutation-b",
    icon = "__base__/graphics/icons/utility-science-pack.png",
    subgroup = "raw-material",
    stack_size = 10,
    spoil_ticks = 6,
    spoil_result = "mutation-a"
}

local mutation_c = {
    type = "item",
    name = "mutation-c",
    icon = "__base__/graphics/icons/production-science-pack.png",
    subgroup = "raw-material",
    stack_size = 10,
    spoil_ticks = 120,
    spoil_result = "mutation-a"
}

local mutation_e = {
    type = "item",
    name = "mutation-e",
    icon = "__base__/graphics/icons/chemical-science-pack.png",
    subgroup = "raw-material",
    stack_size = 10,
    spoil_ticks = 10,
    spoil_result = "mutation-e",
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
                        effect_id = "rsl_mutation-e",
                    },

                }
            }
        }
    }
}


local mutation_d = {
    type = "item",
    name = "mutation-d",
    icon = "__base__/graphics/icons/production-science-pack.png",
    subgroup = "raw-material",
    stack_size = 10,
    spoil_ticks = 120,
    spoil_result = "mutation-e",
    spoil_to_trigger_result = 
    {
        items_per_trigger = 1,
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
                            effect_id = "rsl_mutation-e",
                        },

                    }
                }
            },
        }
    }
}
