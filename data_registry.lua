local registry = {}
local placeholder_spoil_into_self_override = false

--- !!! README !!! \
--- This is a general override settings. You should use it only for debugging or if you are sure that you want all the items you registered with RSL to try to trigger their hotswap script again in the case they failed.
---@param value boolean
function registry.set_placeholder_spoil_into_self(value)
    if type(value) == "boolean" then
        placeholder_spoil_into_self_override = value
    else
        error("Invalid value: 'placeholder_spoil_into_self' must be a boolean.")
    end
end

---@type data.ItemPrototype
---@diagnostic disable-next-line: missing-fields
local placeholder_model = {
    type = "item",
    --icon = "__base__/graphics/icons/production-science-pack.png",
    icon = "__base__/graphics/icons/signal/signal-question-mark.png",
    subgroup = "raw-material",
    stack_size = 10,
    spoil_ticks = 120,
    hidden = true,
    hidden_in_factoriopedia = true,
}


---comment
---@param item data.ItemPrototype
---@param items_per_trigger? int | nil nil this unless you know what you are doing. A spoiling stack will raise only one event if items_per_trigger == item.stack_size, which is the default wanted behavior.
---@param fallback_spoilage? string the item that will be used if the script cannot transform your item. (Like in furnaces or assembling machines). Default is nil (the item will just disappear on spoil) but you should either put "spoilage" or any item of your choice.
---@param custom_trigger? TriggerItem
---@param placeholder_spoil_into_self? boolean if set to true, in the case where the placeholder intermediary fails to be replaced by RSL for any reason, it will spoil into itself, giving it another change to trigger its script. Use with caution.
function registry.register_spoilable_item(item, items_per_trigger, fallback_spoilage, custom_trigger, placeholder_spoil_into_self)
    --- Build placeholder item
    local placeholder = table.deepcopy(placeholder_model)
    placeholder.name = item.name .. "-rsl-placeholder"
    placeholder.stack_size = item.stack_size

    placeholder.weight = item.weight

    item.spoil_to_trigger_result =
        {
            items_per_trigger = item.stack_size, --This allows to trigger only one event by default for the entire stack.
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

    if items_per_trigger ~= nil then
        item.spoil_to_trigger_result.items_per_trigger = items_per_trigger
    end
    if custom_trigger then
        table.insert(item.spoil_to_trigger_result.trigger, custom_trigger)
    end
    item.spoil_result = placeholder.name

    if not placeholder_spoil_into_self and not placeholder_spoil_into_self_override then
        placeholder.spoil_result = fallback_spoilage or nil
        placeholder.spoil_to_trigger_result = nil
    else
        placeholder.spoil_result = placeholder.name
        placeholder.spoil_to_trigger_result = item.spoil_to_trigger_result
    end

    data:extend{item, placeholder}
end

return registry