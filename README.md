# Presentation
---------
RSL, for Runtime Spoilage Library, is a set of tools meant to be as straightforward as possible for modders to change the spoil result of items at runtime.

For now, RSL allows you to define a spoilable item, and how and by what it should be replaced.
The goal of RSL is, at first, to allow you to specify multiple possible outcomes for a spoilable item.

# Limitations (read this, please, like, really, this is important)

If you add a spoilable ore, you will either need to set loop_spoil_safe_mode to true, or define a fallback for your ore item.

Adding a "fallback_spoilage" allows the game to still spoil the item into another item even if RSL cannot access the target inventory (if the inventory is an internal buffer, like for mining drills for instance).
If you do that, and in the case where RSL can't access the inventory, the script won't delete the placeholder, and the placeholder will turn into the fallback result you defined. I suggest you just use "spoilage" for this fallback, but you can use whatever you want, like "scrap", or "sand" or whatever.

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
---@alias RslConditionalResults table<RslConditionResult, {name: RslItemName}> Example: { ["night"] = {name="sunflower"} }

---@class rsl_definition_data
---@field original_item_name string The name of the item that will spoil.
---@field original_item_spoil_ticks integer Number of ticks before spoilage occurs.
---@field items_per_trigger? integer Optional. Number of items required to trigger spoilage.
---@field fallback_spoilage? string Optional. Item name used if no spoilage result is determined.
---@field loop_spoil_safe_mode boolean If true, the item spoils into itself if no result is available.
---@field additional_trigger? table Optional. Additional trigger conditions.
---@field random boolean If true, spoilage is chosen randomly.
---@field conditional boolean If true, spoilage depends on a condition function.
---@field condition_checker_func_name? string Name of the condition function used.
---@field random_results? RslRandomResults
---@field conditional_random_results? RslConditionalRandomResults
---@field conditional_results? RslConditionalResults
```
And here is an exemple you can copy paste and modify directly :


```lua
---@type rsl_definition_data
local definition_data = {
        original_item_name = "name of the item that will spoil",
        original_item_spoil_ticks = --int,
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

local rsl_definition = {
    type = "mod-data",
    name = "whatever, just make sure it's unique by using a prexif for instance",
    --- Data type MUST be "rsl_definition"
    data_type = "rsl_definition",
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

data:extend{my_rsl_definition}
```
and finally, here is a more advanced exemple : 

```lua

---@type rsl_definition_data
local definition_data = {
        original_item_name = "name of the item that will spoil",
        original_item_spoil_ticks = --int,
        -- DO NOT set items_per_trigger unless you REALLY know what you are doing.
        -- By default, RSL will set this field afterwards so the even only triggers ONCE per item stack.
        -- Setting an arbitrary number here WILL hinder performance.
        items_per_trigger = --? int or nil,
        fallback_spoilage = --? an item name or nil,
        loop_spoil_safe_mode = --true or false, if true, the placeholder will spoil into itself if it cannot be replaced by RSL, if false, it will simply disappear. Defaults to true if not specified.,
        additional_trigger = --? trigger,
        random = --true | false,
        conditional = --true | false,
        condition_checker_func_name = "is_in_iron_chest",
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
            ["falsetrue"] = {
                {name = "copper-ore"}, {name="stone"}
            }
        },

    }
    ```
