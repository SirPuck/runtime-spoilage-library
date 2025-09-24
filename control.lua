local runtime_registry = require("runtime_registry")
local swap_funcs = require("swap_inventories")
local registry = runtime_registry.registry
local select_result = require("selection")

remote.add_interface("rsl_registry", {
    register_condition_check = registry.register_condition_check
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
    ["asteroid-collector"] = defines.inventory.asteroid_collector_output, -- Currently does not exist? Just using chest for the warning
    ["reactor"] = defines.inventory.fuel,
    ["fusion-reactor"] = defines.inventory.fuel,
}

---@param event EventData.on_script_trigger_effect
---@param rsl_definition RtRslDefinition
local function swap_item(event, rsl_definition)

    local result = select_result(rsl_definition, event)

    if event.source_entity then
        local swap_func = generic_source_handler[event.source_entity.type]
        if swap_func ~= nil then
            swap_func(
                result,
                event.source_entity,
                rsl_definition,
                event.quality
            )
        else
            swap_funcs.hotswap_in_generic_inventory(
                result,
                event.source_entity,
                rsl_definition,
                defined_inventories[event.source_entity.type],
                event.quality
                )
        end
    else
        swap_funcs.hotswap_in_position(result, event, rsl_definition)
    end
end

registry.make_registry()

local function on_spoil(event)
    local definition = registry.rsl_definitions[event.effect_id]
    if definition then swap_item(event, definition) end
end


script.on_event(defines.events.on_script_trigger_effect, on_spoil)

local function setup_storage()
    --rsl_definitions = {}
    --storage.rsl_definitions = rsl_definitions
    --registry.make_registry()
    registry.compile_functions()
end

local function advert()
    for _, player in pairs(game.players) do
        player.print("[color=154,255,0][item=spoilage] A mod you are using is powered by RSL: Runtime Spoilage Library![/color]")
    end
end

script.on_init(function()
    setup_storage()
    advert()
end)
script.on_configuration_changed(
    setup_storage
)
script.on_load(
    registry.compile_functions
)

