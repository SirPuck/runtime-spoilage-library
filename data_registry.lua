local registry = {}

local placeholder_model = {
    type = "item",
    icon = "__base__/graphics/icons/production-science-pack.png",
    subgroup = "raw-material",
    stack_size = 10,
    spoil_ticks = 120,
    hidden = true,
    hidden_in_factoriopedia = true,
}



---comment
---@param item data.ItemPrototype
---@param items_per_trigger int number of items needed to trigger the script
---@param custom_trigger TriggerItem 
function registry.create_spoilage_components(item, items_per_trigger, custom_trigger)
    --- Build placeholder item
    local placeholder = table.deepcopy(placeholder_model)
    placeholder.name = item.name .. "-rsl-placeholder"
    placeholder.stack_size = item.stack_size
    placeholder.spoil_result = placeholder.name
    placeholder.weight = item.weight

    item.spoil_to_trigger_result = 
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
                            effect_id = "rsl_" .. placeholder.name
                        },
                    }
                }
            },
        }
    }

    if items_per_trigger then
        item.spoil_to_trigger_result.items_per_trigger = items_per_trigger
    end
    if custom_trigger then
        table.insert(item.spoil_to_trigger_result.trigger, custom_trigger)
    end
    item.spoil_result = placeholder.name
    data:extend{item, placeholder}
end

return registry