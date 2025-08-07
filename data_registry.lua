local registry = {}

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


---
--- @class DataRSLArgs
--- @field item_name string **(required)** The item name.
--- @field items_per_trigger? integer|nil Number of items per spoilage trigger. Defaults to `item.stack_size`. Set only if custom behavior is needed.
--- @field fallback_spoilage? string|nil The item name to use as fallback if the item cannot be transformed (e.g., in furnaces or miners). Defaults to `nil` (item disappears on spoil). Recommended to set to "spoilage" or another item. Not compatible with "spoil into self"
--- @field placeholder_spoil_into_self? boolean|nil If true, the item will spoil into itself as a placeholder. This is not compatible with "fallback_spoilage". When true, if RSL cannot replace the placeholder with the right item (in the case of inventories without an API access for instance), the placeholder will just spoil into itself, refreshing its spoil timer in a loop.
--- @field custom_trigger? TriggerItem|nil If you want to add yet ANOTHER trigger to the spoilage event. Not required.
---

--- Registers an item and extends the data registry with spoilage-related properties.
--- @param args DataRSLArgs Table of arguments describing the item and spoilage behavior.
function registry.register_item(args)
    -- Validate required argument
    if not args.item_name then
        error("Missing required argument: item_name")
    end

    -- Unpack arguments with defaults
    local item = data.raw["item"][args.item_name]
    local items_per_trigger = args.items_per_trigger or nil
    local fallback_spoilage = args.fallback_spoilage or nil
    local custom_trigger = args.custom_trigger or nil
    local placeholder_spoil_into_self = args.placeholder_spoil_into_self or false

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

    if not placeholder_spoil_into_self then
        placeholder.spoil_result = fallback_spoilage or nil
        placeholder.spoil_to_trigger_result = nil
    else
        placeholder.spoil_result = placeholder.name
        placeholder.spoil_to_trigger_result = item.spoil_to_trigger_result
    end
    data:extend{placeholder}
end



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

---random = true and conditional = false
---possible_results = {{name = "iron-plate", weight = 1}, {name = "copper-plate", weight = 1}}
---random = false and condition =
---
---
---
---
--[[ local my_rsl_definition = {
    type = "mod-data",
    name = "bob_is_blue",
    data_type = "rsl_registration",
    data = {
        loop_spoil_safe_mode = true,
        original_item_name = "iron-plate",
        conditional = false,
        random = true,
        random_results = {
            {name = "iron-plate", weight = 1},
            {name = "copper-plate", weight = 1},
        }
    }
}
local iron_plate = data.raw["item"]["iron-plate"]
iron_plate.spoil_ticks = 10
data:extend{my_rsl_definition}
 ]]

--[[ local function register_definition_at_runtime(definition)
    local data = definition.data

    if data.conditional then
        condition_result = "call_func(event)"
        if data.random then
            result = select_randomly(data.possible_results[condition_result])
            return result end
        else
            result = data.possible_results[condition_result]
    end
    
    
    end

    if data.random then
        result = data.possible_results

    end

end ]]



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