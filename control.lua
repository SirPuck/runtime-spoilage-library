local runtime_registry = require("runtime_registry")
local swap_funcs = require("swap_inventories")
local registry = runtime_registry.registry

local rsl_definitions = storage.rsl_definitions
--- Note, that does not actually work because storage will
--- not have been set up by the point this runs. It's purely symbolic

remote.add_interface("rsl_registry",
    {
    ---Register a new RSL definition remotely.
    ---@param item_name string The name of the item the will spoil.
    ---@param args RslArgs The arguments for the RSL definition.
    register_rsl_definition = function(item_name, args)
        registry.register_rsl_definition(item_name, args)
    end}
)


---@type table<string,fun(entity:LuaEntity,rsl_definition:RslDefinition)>
local generic_source_handler = {
    ["inserter"] = function(entity, rsl_definition) return swap_funcs.hotswap_in_inserter(entity, rsl_definition) end,
    ["logistic-robot"] = function(entity, rsl_definition) return swap_funcs.hotswap_in_bot(entity, rsl_definition) end,
    ["construction-robot"] = function(entity, rsl_definition) return swap_funcs.hotswap_in_bot(entity, rsl_definition) end,
    ["transport-belt"] = function(entity, rsl_definition) return swap_funcs.hotswap_in_belt(entity, rsl_definition) end,
    ["loader"] = function(entity, rsl_definition) return swap_funcs.hotswap_in_belt(entity, rsl_definition) end,
    ["underground-belt"] = function(entity, rsl_definition) return swap_funcs.hotswap_in_underground_belt(entity, rsl_definition) end,
    ["splitter"] = function(entity, rsl_definition) return swap_funcs.hotswap_in_splitter(entity, rsl_definition) end,
    ["assembling-machine"] = function(entity, rsl_definition) return swap_funcs.hotswap_in_machine(entity, rsl_definition) end,
    ["character"] = function(entity, rsl_definition) return swap_funcs.hotswap_item_in_character_inventory(entity, rsl_definition) end,
    ["logistic-container"] = function(entity, rsl_definition) return swap_funcs.hotswap_in_logistic_inventory(entity, rsl_definition) end,
    ["cargo-landing-pad"] = function(entity, rsl_definition) return swap_funcs.hotswap_in_logistic_inventory(entity, rsl_definition) end,
    ["item-entity"] = function(entity, rsl_definition) return swap_funcs.hotswap_on_ground(entity, rsl_definition) end,
    ["furnace"] = function(entity, rsl_definition) return swap_funcs.hotswap_in_furnace(entity, rsl_definition) end,
    ["mining-drill"] = function(entity, rsl_definition) return swap_funcs.hotswap_in_mining_drill(entity, rsl_definition) end,
    ["boiler"] = function(entity, rsl_definition) return swap_funcs.hotswap_in_boiler_inventory(entity, rsl_definition) end,
    ["lab"] = function(entity, rsl_definition) return swap_funcs.hotswap_in_lab_inventory(entity, rsl_definition) end,
    ["cargo-pod"] = function(entity, rsl_definition) return swap_funcs.hotswap_in_cargo_pod(entity, rsl_definition) end,
    ["roboport"] = function(entity, rsl_definition) return swap_funcs.hotswap_in_roboport(entity, rsl_definition) end,
    ["agricultural-tower"] = function(entity, rsl_definition) return swap_funcs.hotswap_in_agricultural_tower(entity, rsl_definition) end,
    ["spider-vehicle"] = function(entity, rsl_definition) return swap_funcs.hotswap_in_spider(entity, rsl_definition) end,
}

---@type table<string,defines.inventory>
local defined_inventories = {
    ["car"] = defines.inventory.car_trunk,
    ["cargo-wagon"] = defines.inventory.cargo_wagon,
    ["container"] = defines.inventory.chest,
    ["space-platform-hub"] = defines.inventory.hub_main,
    ["rocket-silo"] = defines.inventory.rocket_silo_rocket,
    ["locomotive"] = defines.inventory.fuel,
    ["beacon"] = defines.inventory.beacon_modules,
    ["asteroid-collector"] = defines.inventory.chest, -- Currently does not exist? Just using chest for the warning
    ["reactor"] = defines.inventory.fuel,
    ["fusion-reactor"] = defines.inventory.fuel,
}


local function split_suffix_and_prefix(effect_id)
    -- Check if the effect_id starts with "rsl_" and extract the suffix
    local prefix, suffix = string.match(effect_id, "^(rsl_)(.+)$")

    if prefix and suffix then
        return prefix, suffix -- Return the prefix and the remaining part as the suffix
    end

    return nil, nil -- Return nil if no match
end

---@type table<string, boolean|{prefix:string, suffix:string}>
local cached_event_ids = {}

---@param effect_id string
---@return string?
---@return string?
local function get_suffix_and_prefix_from_effect_id(effect_id)
    local cached_value =  cached_event_ids[effect_id]
    if cached_value == false then
        return nil, nil

    elseif cached_value == nil then
        local prefix, suffix = split_suffix_and_prefix(effect_id)

        if prefix ~= nil and suffix ~= nil then
            ---@cast prefix string
            ---@cast suffix string
            cached_value = {prefix = prefix, suffix = suffix}
            cached_event_ids[effect_id] = cached_value
        else
            cached_event_ids[effect_id] = false
            return nil, nil
        end

    end

    return cached_value.prefix, cached_value.suffix

end

---@param event EventData.on_script_trigger_effect
---@param placeholder string
local function swap_item(event, placeholder)
    local rsl_definition = rsl_definitions[placeholder]
    rsl_definition.event = event
    if event.source_entity then
        local swap_func = generic_source_handler[event.source_entity.type]
        if swap_func ~= nil then
            swap_func(event.source_entity, rsl_definition)
        else
            swap_funcs.hotswap_in_generic_inventory(event.source_entity, rsl_definition, defined_inventories[event.source_entity.type])
        end
    else
        swap_funcs.hotswap_in_position(event, rsl_definition)
    end
end

local current_event = {id = "", tick = nil, unit_number = nil}

---@param event EventData.on_script_trigger_effect
local function on_spoil(event)
    if event.source_entity ~= nil then
        if event.effect_id == current_event.id
            and event.tick == current_event.tick
            and event.source_entity.unit_number == current_event.unit_number
                then
                    return
        else
            current_event.id = event.effect_id
            current_event.tick = event.tick
            current_event.unit_number = event.source_entity.unit_number
        end
    end

    local prefix, suffix = get_suffix_and_prefix_from_effect_id(event.effect_id)

    if prefix == nil or suffix == nil then
        return
    end

    if prefix == "rsl_" then
        swap_item(event, suffix)
    end
end


script.on_event(defines.events.on_script_trigger_effect, on_spoil)

---@class RslStorage
---@field rsl_definitions table<string,RslDefinition>
storage = storage

---Will set up the storage for after init or configuration changed.
---Clears the registry because if the mods change or a startup setting changed
---The registry is likely to not be valid anymore, so just force everyone to re-register
---
---This is similar to what was already being done, but ***NOT ABUSING ON_LOAD!***
---`on_load` has a very limit use case. Setting things up in it is not one of them!
---
---This also means that mods *have* to require us as a dependency instead of just ignoring that entirely.
---Because if they run their configuration changed before ours, we'll just clear their registrations.
local function setup_storage()
    rsl_definitions = {}
    storage.rsl_definitions = rsl_definitions
end
--- THIS is how you use on_load
--- to restore references to objects in storage
script.on_load(function ()
    rsl_definitions = storage.rsl_definitions
end)

script.on_init(setup_storage)
script.on_configuration_changed(setup_storage)