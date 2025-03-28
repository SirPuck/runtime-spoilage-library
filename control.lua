local runtime_registry = require("runtime_registry")
local swap_funcs = require("swap_inventories")
local registry = runtime_registry.registry

local rsl_definitions = storage.rsl_definitions
--- Note, that does not actually work because storage will
--- not have been set up by the point this runs. It's purely symbolic

remote.add_interface("rsl_registry", {
    register_rsl_definition = registry.register_rsl_definition
})


---@type table<string,fun(entity:LuaEntity,rsl_definition:RslDefinition)>
local generic_source_handler = {
    ["inserter"] = swap_funcs.hotswap_in_inserter,
    ["logistic-robot"] = swap_funcs.hotswap_in_bot,
    ["construction-robot"] = swap_funcs.hotswap_in_bot,
    ["transport-belt"] = swap_funcs.hotswap_in_belt,
    ["loader"] = swap_funcs.hotswap_in_belt,
    ["underground-belt"] = swap_funcs.hotswap_in_underground_belt,
    ["splitter"] = swap_funcs.hotswap_in_splitter,
    ["assembling-machine"] = swap_funcs.hotswap_in_machine,
    ["character"] = swap_funcs.hotswap_item_in_character_inventory,
    ["logistic-container"] = swap_funcs.hotswap_in_logistic_inventory,
    ["cargo-landing-pad"] = swap_funcs.hotswap_in_logistic_inventory,
    ["item-entity"] = swap_funcs.hotswap_on_ground,
    ["furnace"] = swap_funcs.hotswap_in_furnace,
    ["mining-drill"] = swap_funcs.hotswap_in_mining_drill,
    ["boiler"] = swap_funcs.hotswap_in_boiler_inventory,
    ["lab"] = swap_funcs.hotswap_in_lab_inventory,
    ["cargo-pod"] = swap_funcs.hotswap_in_cargo_pod,
    ["roboport"] = swap_funcs.hotswap_in_roboport,
    ["agricultural-tower"] = swap_funcs.hotswap_in_agricultural_tower,
    ["spider-vehicle"] = swap_funcs.hotswap_in_spider,
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


local function get_suffix(str)
    if string.sub(str, 1, 4) == "rsl_" then
        return string.sub(str, 5)
    end
end

local function on_spoil(event)
    local suffix = get_suffix(event.effect_id)
    if suffix then swap_item(event, suffix) end
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

local function advert()
    for _, player in pairs(game.players) do
        player.print("[color=154,255,0][item=spoilage] A mod you are using is powered by RSL: Runtime Spoilage Library![/color]")
    end
end

script.on_init(function()
    setup_storage()
    advert()
end)
script.on_configuration_changed(setup_storage)