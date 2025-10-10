# Presentation
---------
RSL, for Runtime Spoilage Library, is a set of tools meant to be as straightforward as possible for modders to change the spoil result of items at runtime.

For now, RSL allows you to define a spoilable item, and how and by what it should be replaced.
The goal of RSL is, at first, to allow you to specify multiple possible outcomes for a spoilable item.

# Quality Upscale

RSL now handles quality upscale, and deterministic quality spoiling !
See exemple below.

# Limitations (read this, please, like, really, this is important)

If you add a spoilable ore, you will either need to set loop_spoil_safe_mode to true, or define a fallback for your ore item.

Adding a "fallback_spoilage" allows the game to still spoil the item into another item even if RSL cannot access the target inventory (if the inventory is an internal buffer, like for mining drills for instance).
If you do that, and in the case where RSL can't access the inventory, the script won't delete the placeholder, and the placeholder will turn into the fallback result you defined. I suggest you just use "spoilage" for this fallback, but you can use whatever you want, like "scrap", or "sand" or whatever.

# loop_spoil_safe_mode

In the rsl_registration_data, you can use loop_spoil_safe_mode, this is nigh mandatory, unless you know what you are doing.
Setting this option to true will make the placeholder item spoil into itself and try to trigger RSL replacement every time
it spoils again.

This is very useful because, by default, when a crafting machine is crafting an item, it remembers the tick when the crafting began. When the craft is finished, if the resulting item can spoil, the engine will check if it should be spoiled or not, by comparing the current tick whith the tick when the crafting began. The resulting item could therefore "spoil instantly".
This is an issue for RSL, because when an item spoils inside a crafting buffer, the RSL script cannot trigger. And when the item "spoils instantly", it doesn't trigger RSL scripts either.

There are two ways around this : making the placeholder spoil into itself : this way, even if the original item spoils during crafting, we are sure that a placeholder will be present in the output. This way, the original item spoils inside the buffer, but spawns a placeholder, and event if the placeholder spoils, it spoils into itself in a loop, meaning it will exist until it can trigger the script.

The other way around this, that is not currently handled by RSL (but could) is to set every recipe producing the original item to use the option "result_is_always_fresh". Currently, RSL doesn't allow you to bruteforce this option to every recipe producing the original item. It could do it, in fact, it's a pretty simple code to implement, but I could cause side effects. Therefore, it's your responsability to update the recipes that need updating IF you consider it necessary. You probably don't want to bruteforce update every recipe that produce your original item because the player using your mod may use other mods that may or may not require these recipes, or some of them, to be untouched. If you update all recipes producing the original item without thinking much about it, you may also break other things (for instance, maybe some of these recipes also produce "normal" spoilable items that are supposed to be able to spoil inside the buffer, and changing this behavior could break balance and game functionalities.).



------
How to use RSL :

Simply add a RSL definition to your mod data.lua. You can copy paste the following documentation snippet in your code in order to get type hints.
Please note that "original_item_name" must refer to an item that spoils. RSL won't transform your item into a spoilable item, you need to do this yourself.

```lua
---@alias RslItemName string
---@alias RslConditionResult string

---@class RslRandomResult
---@field name RslItemName
---@field weight? number Optional. If omitted, all results are equally weighted.

---@alias RslRandomResults RslRandomResult[] Example: {{name="iron-plate"}, {name="copper-plate"}} or {{name="iron-plate", weight = 1}, {name="copper-plate", weight = 3}}
---@alias RslConditionalRandomResults table<RslConditionResult, RslRandomResults> Example: { ["day"] = {{name="ice", weight=10}, {name = "stone", weight=1}} }
---@alias RslConditionalResults table<RslConditionResult, {name: RslItemName}> Example: { ["night"] = "sunflower" }

---@class RslRegistrationData
---@field original_item_type string item, module etc... The value of the `type` field in the original prototype definition.
---@field original_item_name string The name of the item that will spoil.
---@field items_per_trigger? integer Optional. Number of items required to trigger spoilage.
---@field fallback_spoilage? string Optional. Item name used if no spoilage result is determined only works if loop_spoil_safe_mode is explicitly set to false.
---@field loop_spoil_safe_mode boolean If true, the item spoils into itself if no result is available.
---@field additional_trigger? table Optional. Additional trigger conditions.
---@field random boolean If true, spoilage is chosen randomly.
---@field conditional boolean If true, spoilage depends on a condition function.
---@field condition_checker_func_name? string Name of the condition function used.
---@field condition_checker_func? string the function to check the condition
---@field random_results? RslRandomResults
---@field conditional_random_results? RslConditionalRandomResults
---@field conditional_results? RslConditionalResults
```
And here is an example you can copy paste and modify directly :


```lua
---@type RslRegistrationData
local registration_data = {
        original_item_type = "item",
        original_item_name = "name of the item that will spoil",
        -- DO NOT set items_per_trigger unless you REALLY know what you are doing.
        -- By default, RSL will set this field afterwards so the even only triggers ONCE per item stack.
        -- Setting an arbitrary number here WILL hinder performance.
        items_per_trigger = --? int or nil,
        fallback_spoilage = --? an item name or nil,
        loop_spoil_safe_mode = --true or false, if true, the placeholder will spoil into itself if it cannot be replaced by RSL, if false, it will simply disappear. Defaults to true if not specified.,
        additional_trigger = --? trigger,
        random = --true | false,
        conditional = --true | false,
        --- Only one of the following 3 tables is needed
        random_results = {},
        conditional_random_results = {},
        conditional_results = {}
    }

local rsl_registration = {
    type = "mod-data",
    name = "whatever, just make sure it's unique by using a prexif for instance",
    --- Data type MUST be "rsl_registration"
    data_type = "rsl_registration",
    data = definition_data
}
```

and here is a concrete lightweight exemple :

```lua
local my_rsl_registration = {
    type = "mod-data",
    name = "bob_is_blue",
    data_type = "rsl_registration",
    data = {
        original_item_type = "item",
        loop_spoil_safe_mode = true,
        original_item_name = "iron-plate",
        conditional = false,
        random = true,
        random_results = {
            {name = "iron-plate", weight = 1},
            {name = "copper-plate", weight = 10},
        }
    }
}

data:extend{my_rsl_registration}
```
and finally, here is a more advanced exemple : 

```lua

---@type RslRegistrationData
local registration_data = {
        original_item_type = "item",
        original_item_name = "name of the item that will spoil",
        -- DO NOT set items_per_trigger unless you REALLY know what you are doing.
        -- By default, RSL will set this field afterwards so the even only triggers ONCE per item stack.
        -- Setting an arbitrary number here WILL hinder performance.
        items_per_trigger = --? int or nil,
        fallback_spoilage = --? an item name or nil,
        loop_spoil_safe_mode = --true or false, if true, the placeholder will spoil into itself if it cannot be replaced by RSL, if false, it will simply disappear. Defaults to true if not specified.,
        additional_trigger = --? trigger,
        random = --true | false,
        conditional = --true | false,
        condition_checker_func_name = "is_in_iron_chest", -- this can be anything, just give your function a unique name
        -- `condition_checker_func` must be a string, but that string should be a function that takes a single parameter of type EventData.on_script_trigger_effect and returns a value.
        -- The return value will be converted to a string and used to look up a set of results in `conditional_random_results`.
        condition_checker_func = [[
        function(event)
          local e = event.source_entity
          return e and e.valid and e.name == "iron-chest"
        end
      ]],
        conditional_random_results = {
            ["true"] = {
                {name = "iron-ore"}, {name="copper-cable"}
            },
            ["false"] = {
                {name = "copper-ore"}, {name="stone"}
            }
        },

    }

    local my_rsl_registration = {
    type = "mod-data",
    name = "bob_is_blue",
    data_type = "rsl_registration",
    data = rsl_registration_data
}

data:extend{my_rsl_registration}
```

# Quality cycling/upscale and deterministic exemples


To simply cycle up quality in a loop normal -> max quality -> normal and so on

```lua
data.raw.item["copper-ore"].spoil_ticks = 100
data:extend{
    {
    type = "mod-data",
    name = "john",
    data_type = "rsl_registration",
    data = {
        data_raw_table = "item",
        loop_spoil_safe_mode = true,
        original_item_name = "copper-ore",
        conditional = false,
        random = false,
        quality_cycling = true
    }
    }
}
```

To chose an arbitrary quality :

```lua
data.raw.item["copper-ore"].spoil_ticks = 100
data:extend{
    {
    type = "mod-data",
    name = "john",
    data_type = "rsl_registration",
    data = {
        data_raw_table = "item",
        loop_spoil_safe_mode = true,
        original_item_name = "copper-ore",
        conditional = false,
        random = false,
        quality_change = true,
        deterministic_result = {name = "copper-ore", quality = "rare"}
    }
    }
}
```



Thanks to : 
- PennyJim for introducing data validation in this mod.
- Majoca22 for finding a handful of bugs and offering a solution.