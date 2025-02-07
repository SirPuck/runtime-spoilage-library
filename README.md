How do use RSL in your mods :

In your data.lua, you will need to 
```lua
local rsl = require("__runtime-spoilage-library__/data_registry")

```
You can then call the registry doing :
```lua
rsl.register_spoilable_item(youritemtable, number of items to trigger)
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
```lua
To register a remote call to your mod as a condition, do       
condition = { -- Example condition
              remote_mod = "exemple-rsl",      -- Your mod name here
              remote_function = "func_name",         -- The function name to call
          },

```
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
2) trigger (optional) you may add another triggered effect
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
script.on_init(function()
  remote.call("rsl_registry", "register_rsl_definition", "mutation-a", { -- You call the "rsl_registry" to use "register_rsl_definition" and pass it the name of your custom item "mutation-a"
      mode = { random = true, conditional = true, weighted = true },
      condition = true,  -- There is no check, this is always true
      possible_results = {
          [true] = {
                      { name = "iron-plate", weight = 1}, -- Possible result 1
                      { name = "copper-plate", weight = 4} -- Possible result 2
                    },
          [false] = {} -- We don't care about that because our condition key has the value true at all times
          }
      }
  )
end
)

script.on_configuration_changed(function()
  remote.call("rsl_registry", "register_rsl_definition", "mutation-a", { 
      mode = { random = true, conditional = true, weighted = true },
      condition = true,  -- There is no check, this is always true
      possible_results = {
          [true] = {
                      { name = "iron-plate", weight = 1},
                      { name = "copper-plate", weight = 4}
                    },
          [false] = {} 
          }
      }
  )
end
)
```



Advanced :
```lua
--- Optional : A function of your to check if a condition is true for your item to spoil.
local function check_if_evening(event)
    local surface = event.source_entity.surface
    return surface.dusk < surface.daytime and surface.daytime < surface.dawn
end


--- If you use a function like the one writte above, you will need to provide a remote interface to RSL
remote.add_interface("exemple-rsl", {
    --- Custom condition function to check if it's evening
    --- @return boolean
    is_evening = function(event)
        local surface = event.source_entity.surface
        return surface.dusk < surface.daytime and surface.daytime < surface.dawn
    end
})


script.on_init(function()
  remote.call("rsl_registry", "register_rsl_definition", "mutation-a", { -- You call the "rsl_registry" to use "register_rsl_definition" and pass it the name of your custom item "mutation-a"
      mode = { random = true, conditional = true, weighted = false },
      condition = {
              remote_mod = "exemple-rsl",      -- Your mod name here
              remote_function = "is_evening",         -- The function name to call
          },  -- Example condition
      possible_results = {
          [true] = {{ name = "iron-plate"}, { name = "copper-plate"}},
          [false] = {{ name = "copper-plate"}}
          }
      }
  )
end
)

script.on_configuration_changed(function()
  remote.call("rsl_registry", "register_rsl_definition", "mutation-a", { -- You call the "rsl_registry" to use "register_rsl_definition" and pass it the name of your custom item "mutation-a"
      mode = { random = true, conditional = true, weighted = false },
      condition = {
              remote_mod = "exemple-rsl",      -- Your mod name here
              remote_function = "is_evening",         -- The function name to call
          },  -- Example condition
      possible_results = {
          [true] = {{ name = "iron-plate"}, { name = "copper-plate"}},
          [false] = {{ name = "copper-plate"}}
          }
      }
  )
end
)

```
