# Presentation
---------
RSL, for Runtime Spoilage Library, is a set of tools meant to be as straightforward as possible for modders to change the spoil result of items at runtime.
As you can guess, this can cause serious performance issues if a great many number of items ALL spoil at the same tick. But don't let yourself be discouraged by that because this scenario is quite unlikely to happen in real life use.

For now, RSL allows you to define a spoilable item, and how and by what it should be replaced.
The goal of RSL is, at first, to allow you to specify multiple possible outcomes for a spoilable item.

You will need to use 2 functions : 
- register_spoilable_item : At data stage, this function allows you to pass an item for preprocessing and registration.
DO NOT data:extend the item yourself ! RSL will do it for you because it needs to modify your item to make it bend to its rules.

- registry_rsl_definition : accessible via remote interface, this allows you to build a set of rules to define how your item should spoil.
There are many possibilities : you may want your item to be able to spoil into any N number of other items, with weighted probabilities.
You may want to make your item spoil into something... if it's day on the surface, and into something else if it's night !
You may want to make your item spoil into something only if there is a destroyer worm nearby... and into nothing if there is none.

All these things are possible.

# Limitations (read this, please, like, really, this is important)

I included two switches : "placeholder_spoil_into_self" in the data_registry module, and "enable_swap_in_assembler" in the swap_inventories module. They are both set to false by default.

For assembling machines, and furnaces, for instance, it's impossible to insert "any item I want" at runtime. Meaning... if you try to use RSL on an item that's inside an assembling machine,
the mod will simply delete it, if the switch enable_swap_in_assembler is TRUE, because it cannot insert another item in its place if it's not part of the recipe currently setup on the machine. 
If you let the "enable_swap_in_assembler" to its default value, which is false, your item, while spoiling into an assembling machine, will turn
into the "fallback_spoilage" you have defined at data stage on the register_spoilable_item function. This is up to you to chose wether your item should be delted when it fails to be replaced by RSL or if it should be turned into a fallback item.

Of course, I think there are ways to circumvent this, like rapidly switching the machine's current recipe,
or including all the possible spoils into the recipe with an amount of 0,
but I wanted this mod to be as lightweight as possible and NOT tinker with things like assembling machines that may or may not have been heavily tinkered with by another mod.
You can change this behavior by switching the variable "placeholder_spoil_into_self" accessible through data_registry -> if the script fails for any reason, your custom item will turn into a placeholder and spoil into the placeholder every 2 seconds. I advise you use this ONLY for debugging purposes. Prefer the other solutions :

Adding a "fallback_spoilage" when you register your item at data stage, and let the assembling machine switch off is the prefered behavior.
If you do that, the script won't delete the placeholder, and the placeholder will turn into the fallback result you defined. I suggest you just use "spoilage" for this fallback, but you can use whatever you want, like "scrap", or "sand" or whatever.
If you put this to true, then, the placeholder that replaces your item when it spoils "naturally" will spoil into itself, meaning that resources "stuck" in an assembling machine will never disappear.
At this point you may be asking yourself "what ? you just told me you could not insert any item you wanted into an assembling machine !" and yeah, that's true, however, the placeholder is the "spoil_result" of your custom item.
And the "spoil_result" is the item that the engine replaces your original item with. It's just how it works. Any spoil result defined at data stage just works, because it's the result of the TRUE VANILLA spoilage mechanic.

---------
How do use RSL in your mods :

In your data.lua, you will need to 
```lua
local rsl = require("__runtime-spoilage-library__/data_registry")

```
You can then call the registry doing :
```lua
rsl.register_spoilable_item(youritemtable, number of items to trigger, fallback_item_name (optional), custom script (optional) )
```
In your control.lua, you will need to make a remote call to RSL and pass it your item name and a list of args :

```lua
--- Defines the mode in which results are selected.
---@class ModeType
---@field random boolean
---@field conditional boolean
---@field weighted boolean

--- Represents a remote function call structure.
---@class RemoteCall
---@field remote_mod string The name of the mod exposing the function.
---@field remote_function string The name of the function to call.

--- Arguments for registering an RSL definition.
---@class RslArgs
---@field mode ModeType The mode settings for result selection.
---@field condition nil|boolean|RemoteCall The condition can be true, false, or a remote call structure.
---@field possible_results table<boolean, {name: string, weight?: number}[]> The possible outcomes based on condition results.
local args_model = {
    mode = {random = false, conditional = false, weighted = false},
    condition = nil,
    possible_results = {
        [true] = {
            {name = "", weight = 1}
        },
        [false] = {}
    }
}
```

To register a remote call to your mod as a condition, do       
```lua
condition = { -- Example condition
              remote_mod = "your-mod-name",      -- Your mod name here
              remote_function = "func_name",         -- The function name to call
          },

```

------------------
An exemple is better than a thousand words, so here is the bare minimum you need to do :

In your data.lua :
```lua
local rsl = require("__runtime-spoilage-library__/data_registry")


local mutation_a = {
    type = "item",
    name = "mutation-a",
    icon = "__base__/graphics/icons/automation-science-pack.png",
    subgroup = "raw-material",
    stack_size = 10,
    spoil_ticks = 200,
}
---Params :
1) item
2) number of items needed to trigger a runtime spoilage replacement / script effect
3) placeholder fallback spoiling result (used in case the script cannot replace the item at runtime. If you don't set anything, the item will just be deleted like if it spoiled into nothing if this happens. For instance, unless you are an advanced user and know how you can handle furnaces and assembling machines, you better set something here like "spoilage")
4) trigger (optional) you may add another triggered effect
 
rsl.register_spoilable_item(mutation_a, 1)

```
Exemple of additional trigger effect :
```lua
local effect =
{
      type = "direct",
      action_delivery =
          {
          type = "instant",
          source_effects = 
          {
              {
                  type = "script",
                  effect_id = "name-of-script"
              },
          }
      }
}
```

In your control.lua :
Simple exemple : 
```lua

local function call_remote()
    remote.call("rsl_registry", "register_rsl_definition", "mutation-a", { -- You call the "rsl_registry" to use "register_rsl_definition" and pass it the name of your custom item "mutation-a"
    mode = { random = true, conditional = true, weighted = false },
    condition = true,
    possible_results = {
        [true] = {{ name = "iron-plate"}, { name = "copper-plate"}},
        [false] = {{ name = "copper-plate"}}
        }
    }
)
end

script.on_load(
    call_remote()
)


script.on_init(
    call_remote()
)

script.on_configuration_changed(
    call_remote()
)
```



Advanced :
```lua
--- Optional : A function of yours to check if a condition is true for your item to spoil.
local function check_if_evening(event)
    local surface = event.source_entity.surface
    return surface.dusk < surface.daytime and surface.daytime < surface.dawn
end


--- If you use a function like the one writte above, you will need to provide a remote interface to RSL
remote.add_interface("your-mod-name", {
    --- Custom condition function to check if it's evening
    --- @return boolean
    is_evening = function(event)
        local surface = event.source_entity.surface
        return surface.dusk < surface.daytime and surface.daytime < surface.dawn
    end
})

local function call_remote()
    remote.call("rsl_registry", "register_rsl_definition", "mutation-a", { -- You call the "rsl_registry" to use "register_rsl_definition" and pass it the name of your custom item "mutation-a"
    mode = { random = true, conditional = true, weighted = false },
    condition = {
            remote_mod = "your-mod-name",      -- Your mod name here
            remote_function = "is_evening",         -- The function name to call
        },  -- Example condition
    possible_results = {
        [true] = {{ name = "iron-plate"}, { name = "copper-plate"}},
        [false] = {{ name = "copper-plate"}}
        }
    }
)
end


script.on_load(
    call_remote()
)


script.on_init(
    call_remote()
)

script.on_configuration_changed(
    call_remote()
)

```
