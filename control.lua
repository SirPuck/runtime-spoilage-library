local runtime_registry = require("runtime_registry")
local swap_funcs = require("swap_inventories")
local registry = runtime_registry.registry
local rsl_definitions = registry.rsl_definitions

remote.add_interface("rsl_registry",
    {
    ---Register a new RSL definition remotely.
    ---@param item_name string The name of the item the will spoil.
    ---@param args RslArgs The arguments for the RSL definition.
    register_rsl_definition = function(item_name, args)
        registry.register_rsl_definition(item_name, args)
    end}
)


local generic_source_handler = {
    ["inserter"] = function(entity, rsl_definition) return swap_funcs.hotswap_in_inserter(entity, rsl_definition) end,
    ["logistic-robot"] = function(entity, rsl_definition) return swap_funcs.hotswap_in_bot(entity, rsl_definition) end,
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
}

local defined_inventories = {
    ["car"] = defines.inventory.car_trunk,
    ["cargo-wagon"] = defines.inventory.cargo_wagon,
    ["container"] = defines.inventory.chest,
    ["space-platform-hub"] = defines.inventory.hub_main,
    ["rocket-silo"] = defines.inventory.rocket_silo_rocket,
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

local function on_spoil(event)
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


script.on_init(function()
    storage.qualities = {}

    for quality in string.gmatch(settings.startup["qualities"].value, "([^,]+)") do
        table.insert(storage.qualities, quality)
    end

    game.print("storage.qualities initialized from startup settings!")
end)

script.on_configuration_changed(function(event)
    if event.mod_changes["runtime-spoilage-library"] then
        storage.qualities = {}

        for quality in string.gmatch(settings.startup["qualities"].value, "([^,]+)") do
            table.insert(storage.qualities, quality)
        end

        game.print("storage.qualities updated after mod configuration change!")
    end
end)