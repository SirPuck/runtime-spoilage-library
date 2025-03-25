local runtime_registry = require("runtime_registry")
local swap_funcs = require("swap_inventories")
local registry = runtime_registry.registry
local rsl_definitions = registry.rsl_definitions

remote.add_interface("rsl_registry", {
    register_rsl_definition = registry.register_rsl_definition
})


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

local defined_inventories = {
    ["car"] = defines.inventory.car_trunk,
    ["cargo-wagon"] = defines.inventory.cargo_wagon,
    ["container"] = defines.inventory.chest,
    ["space-platform-hub"] = defines.inventory.hub_main,
    ["rocket-silo"] = defines.inventory.rocket_silo_rocket,
    ["locomotive"] = defines.inventory.fuel,
    ["beacon"] = defines.inventory.beacon_modules,
    ["asteroid-collector"] = 1,
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

local function get_suffix_and_prefix_from_effect_id(effect_id)
    local cached_value =  cached_event_ids[effect_id]
    if cached_value == false then
        return nil, nil

    elseif cached_value == nil then
        local prefix, suffix = split_suffix_and_prefix(effect_id)

        if prefix ~= nil and suffix ~= nil then
            cached_event_ids[effect_id] = {prefix = prefix, suffix = suffix}
            cached_value = {prefix = prefix, suffix = suffix}
        else
            cached_event_ids[effect_id] = false
            return nil, nil
        end

    end

    return cached_value.prefix, cached_value.suffix

end

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

    if event.effect_id then
        local prefix, suffix = get_suffix_and_prefix_from_effect_id(event.effect_id)

        if prefix == nil or suffix == nil then
            return
        end

        if prefix == "rsl_" then
            swap_item(event, suffix)
        end
    end
end


script.on_event(defines.events.on_script_trigger_effect, on_spoil)


--script.on_init(function()end)

--script.on_configuration_changed(function(event)end)