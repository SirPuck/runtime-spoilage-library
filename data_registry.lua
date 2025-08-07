local registry = {}

---@class RslRegistration
---@field type string Should be "mod-data".
---@field name string The name of the item that spoils.
---@field data_type string Should be "rsl_definition".
---@field data RslRegistrationData Spoilage configuration for the item.

---@class RslRegistrationData
---@field original_item_name string The name of the item that will spoil.
---@field items_per_trigger? integer|nil Optional. Number of items required to trigger spoilage. DO NOT fill this field unless you really need to.
---@field fallback_spoilage? string|nil Optional. Name of the item to use as fallback spoilage result.
---@field loop_spoil_safe_mode boolean If true, the placeholder will spoil into itself if it cannot be replaced by RSL; if false, it will simply disappear.
---@field additional_trigger? table|nil Optional. Additional trigger for spoilage.
---@field random boolean If true, spoilage results are chosen randomly.
---@field conditional boolean If true, spoilage results are determined by a condition.
---@field condition? string|nil Name of the function used to determine conditional spoilage.
---@field random_results? table|nil List of possible random spoilage results.
---@field conditional_random_results? table|nil List of possible conditional random spoilage results.
---@field conditional_results? table|nil List of possible conditional spoilage results.
local typical_rsl_registration = {
    type = "mod-data",
    name = "the item that spoils",
    data_type = "rsl_registration",
    data = {
        original_item_name = "name of the item that will spoil",
        original_item_spoil_ticks = "int",
        items_per_trigger = "? int or nil",
        fallback_spoilage = "? an item name or nil",
        loop_spoil_safe_mode = "true or false, if true, the placeholder will spoil into itself if it cannot be replaced by RSL, if false, it will simply disappear.",
        additional_trigger = "? trigger",
        random = "true | false",
        conditional = "true | false",
        condition_checker_func_name = "function name",
        random_results = {},
        conditional_random_results = {},
        conditional_results = {}
    }
}



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