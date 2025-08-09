local registry = {}

--- !!! DEPRECATED !!! Read the documentation
---comment
---@deprecated
---@param item data.ItemPrototype
---@param items_per_trigger? int | nil nil this unless you know what you are doing. A spoiling stack will raise only one event if items_per_trigger == item.stack_size, which is the default wanted behavior.
---@param fallback_spoilage? string the item that will be used if the script cannot transform your item. (Like in furnaces or assembling machines). Default is nil (the item will just disappear on spoil) but you should either put "spoilage" or any item of your choice.
---@param custom_trigger? TriggerItem
---@param placeholder_spoil_into_self? boolean if set to true, in the case where the placeholder intermediary fails to be replaced by RSL for any reason, it will spoil into itself, giving it another change to trigger its script. Use with caution.
function registry.register_spoilable_item(item, items_per_trigger, fallback_spoilage, custom_trigger, placeholder_spoil_into_self)
    error(
        "A mod using Runtime Spoilage Library is trying to register an item using the old registration system.\n" ..
        "Downgrade RSL to a version compatible with this mod (inferior to 2.0.0).\n" ..
        "I also recommend you contact the author of the mod in question to let him/her/it know \n"..
        "that either the requirements of this mod need to be updated, or the mod should be updated to be compatible with a more recent version of RSL."
    )
end

return registry