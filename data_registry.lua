local registry = {}
local placeholder_spoil_into_self = false

--- !!! README !!! \
--- When you want to control the behavior of a spoiling item at runtime, you need a placeholder intermediary.
--- When your item spoils, it is replaced by the placeholder that is then targeted by the runtime script.\
--- However, some things cannot have their inventory written into arbitrarly (like assembling machines).
--- If placeholder_spoil_into_self is set to false, the placeholder will disappear after 2 seconds of life. \
--- it will be like your item just fanished on spoil if for any reason, the script wasn't able to replace it properly.\
--- If it is set to true, then the placeholder will spoil into itself and await for a valid state where it can be replaced. \
--- I would advise to let this at false because having a LOT of placeholders accumulate somewhere they cannot spoil will hinder
--- performance by triggering a remplacement attempt every 2 seconds.
--- Use it for debugging only (to see where items are stuck and cannot be replaced).
---@param value boolean
function registry.set_placeholder_spoil_into_self(value)
    if type(value) == "boolean" then
        placeholder_spoil_into_self = value
    else
        error("Invalid value: 'placeholder_spoil_into_self' must be a boolean.")
    end
end

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

    if not placeholder_spoil_into_self then
        placeholder.spoil_result = nil
        placeholder.spoil_to_trigger_result = nil
    end

    data:extend{item, placeholder}
end

return {
    registry,
    placeholder_spoil_into_self
}