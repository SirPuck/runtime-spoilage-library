local select_result = require("selection")
local swap_funcs = {}

local enable_swap_in_assembler = false

---@type QualityID[]
local qualities = {}
local _quality = prototypes.quality.normal
while _quality do
    table.insert(qualities, _quality.name)
    _quality = _quality.next
end


remote.add_interface("rsl_library", {
    --- Enable or disable swap in assembler functionality.
    --- To be clear : this doesn't work. We can replace items arbitrarly at runtime in an assembler
    --- because its slots only accepts items based on the selected recipe. If you want the script to work, you NEED to add all the possible spoiled
    --- outcomes controlles by RSL of all the subsequent steps to the recipe of the spoilable item, but giving 0.
    --- ex:  (recipe)   results = {
        --{type = "item", name = "your-spoilable-item", amount = 1},
        --  {type = "item", name = "steel-plate", amount = 0}, --one possible rsl outcome
        --  {type = "item", name = "copper-plate", amount = 0}, --another possible rsl outcome
        --},
    ---@param state boolean Whether to enable (true) or disable (false) the feature.
    set_swap_in_assembler_BROKEN = function(state)
        if type(state) ~= "boolean" then
            error("Invalid parameter: 'state' must be a boolean.")
        end
        enable_swap_in_assembler = state
    end,

    --- Get the current state of swap in assembler functionality.
    ---@return boolean The current state of the feature.
    get_swap_in_assembler = function()
        return enable_swap_in_assembler
    end
})

---@class RslItems : {[number]:RslWeightedItem}
---@class RslWeightedItems : RslItems
---@field cumulative_weight number

--- Represents the structure of an RSL definition.
---@class RslDefinition
---@field selection_mode RslSelectionMode Function to determine selection logic.
---@field name string The unique name of the RSL definition.
---@field condition true|RemoteCall Condition to trigger the RSL result; can be a boolean or a function.
---@field possible_results table<any, RslItems|RslWeightedItems?> A table mapping outcomes (true/false) to lists of result items.
---@field event? EventData.on_script_trigger_effect Just for smuggling the event to the remote function


---@param stack LuaItemStack
---@param result string|nil
function swap_funcs.set_or_nil_stack(stack, result)
    if result ~= nil then
        stack.set_stack({ name = result, count = stack.count, quality=stack.quality })
    else
        stack.set_stack(nil)
    end
end


--- @param entity LuaEntity (we assume source_entity and target_entity are the same).
--- @param rsl_definition RslDefinition the name of the placeholder item.
--- @return nil
function swap_funcs.hotswap_item_in_character_inventory(entity, rsl_definition)
    local inventory = entity.get_main_inventory()
    local placeholder_name = rsl_definition.name
    if inventory then
        --local _placeholder_number = inventory.get_item_count(placeholder_name)
        for _, quality in pairs(qualities) do
            local removed = inventory.remove({name=placeholder_name, count=9999999, quality=quality})
            if removed > 0 then
                local result = select_result(rsl_definition)
                if result ~= nil then
                    inventory.insert({name=result, count=removed, quality=quality})
                end
                goto continue
            end
        end
        ::continue::
        if entity.cursor_stack and entity.cursor_stack.valid_for_read and entity.cursor_stack.name == placeholder_name then
            local result = select_result(rsl_definition)
            swap_funcs.set_or_nil_stack(entity.cursor_stack, result)
        end
    end
end

--- @param entity LuaEntity (we assume source_entity and target_entity are the same).
--- @param rsl_definition RslDefinition the name of the placeholder item.
--- @return nil
function swap_funcs.hotswap_in_belt(entity, rsl_definition)
    local transport_lines = {entity.get_transport_line(1), entity.get_transport_line(2)}
    local placeholder_name = rsl_definition.name
    for _, line in pairs(transport_lines) do
        for i = 1, #line do
            local success, stack = pcall(function() return line[i] end)
            if stack.valid_for_read and stack.name == placeholder_name then
                local result = select_result(rsl_definition)
                swap_funcs.set_or_nil_stack(stack, result)
            end
        end
    end
end

--- @param entity LuaEntity (we assume source_entity and target_entity are the same).
--- @param rsl_definition RslDefinition the name of the placeholder item.
--- @return nil
function swap_funcs.hotswap_in_underground_belt(entity, rsl_definition)
    local placeholder_name = rsl_definition.name
    
    for i = 1, entity.get_max_transport_line_index() do
        local line = entity.get_transport_line(i)

        for i = 1, #line do
            local stack = line[i]
            if stack.valid_for_read and stack.name == placeholder_name then
                local result = select_result(rsl_definition)
                swap_funcs.set_or_nil_stack(stack, result)
                return
            end
        end
    end
end

---@param lines LuaTransportLine[]
---@param placeholder string
---@param rsl_definition RslDefinition
local function _hotswap_in_splitter_lines(lines, placeholder, rsl_definition)
    for _, line in pairs(lines) do
        for i = 1, #line do
            local stack = line[i]
            if stack.valid_for_read and stack.name == placeholder then
                local result = select_result(rsl_definition)
                swap_funcs.set_or_nil_stack(stack, result)
                return
            end
        end
    end
end

--- @param entity LuaEntity (we assume source_entity and target_entity are the same).
--- @param rsl_definition RslDefinition the name of the placeholder item.
--- @return nil
function swap_funcs.hotswap_in_splitter(entity, rsl_definition)
    local placeholder_name = rsl_definition.name
    local transport_lines = {entity.get_transport_line(1), entity.get_transport_line(2)}

    for _, line in pairs(transport_lines) do
        if #line.input_lines == 0 then
            goto continue
        end
        for i = 1, #line.input_lines do
            _hotswap_in_splitter_lines(line.input_lines, placeholder_name, rsl_definition)
        end
        ::continue::
        if #line.output_lines == 0 then
            goto next_iter
        end
        for i = 1, #line.output_lines do
            _hotswap_in_splitter_lines(line.output_lines, placeholder_name, rsl_definition)
        end
        ::next_iter::
    end
end


--- @param entity LuaEntity (we assume source_entity and target_entity are the same).
--- @param rsl_definition RslDefinition the name of the placeholder item.
--- @return nil
function swap_funcs.hotswap_in_inserter(entity, rsl_definition)
    --local result = math.random() < 0.5 and "iron-plate" or "copper-plate"
    if entity.held_stack.valid_for_read then
        local result = select_result(rsl_definition)
        swap_funcs.set_or_nil_stack(entity.held_stack, result)
    end
end

--- @param entity LuaEntity (we assume source_entity and target_entity are the same).
--- @param rsl_definition RslDefinition the name of the placeholder item.
--- @return nil
function swap_funcs.hotswap_in_bot(entity, rsl_definition)
    local stack = entity.get_inventory(defines.inventory.robot_cargo)[1]
    if stack.valid_for_read then
        local result = select_result(rsl_definition)
        swap_funcs.set_or_nil_stack(stack, result)
    end
end

--- @param entity LuaEntity (we assume source_entity and target_entity are the same).
--- @param rsl_definition RslDefinition the name of the placeholder item.
--- @return nil
function swap_funcs.hotswap_in_cargo_pod(entity, rsl_definition)
    local stack = entity.get_inventory(defines.inventory.cargo_unit)[1]
    if stack.valid_for_read then
        local result = select_result(rsl_definition)
        swap_funcs.set_or_nil_stack(stack, result)
    end
end


--- @param entity LuaEntity (we assume source_entity and target_entity are the same).
--- @param rsl_definition RslDefinition the name of the placeholder item.
--- @return nil
function swap_funcs.hotswap_in_machine(entity, rsl_definition)
    local placeholder_name = rsl_definition.name
    local input = entity.get_inventory(defines.inventory.assembling_machine_input)
    local output = entity.get_inventory(defines.inventory.assembling_machine_output)
    local dump = entity.get_inventory(defines.inventory.assembling_machine_dump)
    local trash = entity.get_inventory(defines.inventory.assembling_machine_trash)
    local modules = entity.get_inventory(defines.inventory.assembling_machine_modules)
    local inventories = {input, output, dump, trash}
    if modules then
        table.insert(inventories, modules)
    end
    for _, inventory in pairs(inventories) do
        for _, quality in pairs(qualities) do
            local item_count = inventory.get_item_count({name=placeholder_name, quality=quality})
            if item_count > 0 then
                local removed = inventory.remove({name=placeholder_name, count=9999999, quality=quality})
                if removed > 0 then
                    local result = select_result(rsl_definition)
                    if result ~= nil and trash ~= nil then
                        trash.insert({name=result, count=removed, quality=quality})
                    end
                    return
                end
            end
        end
    end
end

--- @param entity LuaEntity (we assume source_entity and target_entity are the same).
--- @param rsl_definition RslDefinition the name of the placeholder item.
--- @param inventory_definition defines.inventory
--- @return nil
function swap_funcs.hotswap_in_generic_inventory(entity, rsl_definition, inventory_definition)
    local placeholder_name = rsl_definition.name
    if inventory_definition then
        local inventory = entity.get_inventory(inventory_definition)
        if inventory then
            for _, quality in pairs(qualities) do
                local removed = inventory.remove({name=placeholder_name, count=9999999, quality=quality})
                if removed > 0 then
                    local result = select_result(rsl_definition)
                    if result ~= nil then
                        inventory.insert({name=result, count=removed, quality=quality})
                    end
                    return
                end
            end
        end
    else
        game.print("PLEASE REPORT TO RSL AUTHOR : Unhandled inventory type for")
        game.print(entity.type)
        return
    end
end


--- If the output is full, the spoiling item will just be deleted
--- @param entity LuaEntity (we assume source_entity and target_entity are the same).
--- @param rsl_definition RslDefinition the name of the placeholder item.
--- @return nil
function swap_funcs.hotswap_in_boiler_inventory(entity, rsl_definition)
    local placeholder_name = rsl_definition.name
    local input_inventory = entity.get_inventory(defines.inventory.fuel)
    local output_inventory = entity.get_inventory(defines.inventory.burnt_result)
    for _, inventory in pairs({input_inventory, output_inventory}) do
        if inventory then
            for _, quality in pairs(qualities) do
                local removed = inventory.remove({name=placeholder_name, count=9999999, quality=quality})
                if removed > 0 then
                    local result = select_result(rsl_definition)
                    if result ~= nil then
                        inventory.insert({name=result, count=removed, quality=quality})
                    end
                    return
                end
            end
        end
    end
end

--- @param entity LuaEntity (we assume source_entity and target_entity are the same).
--- @param rsl_definition RslDefinition the name of the placeholder item.
--- @return nil
function swap_funcs.hotswap_in_lab_inventory(entity, rsl_definition)
    local placeholder_name = rsl_definition.name
    --local inventory = entity.get_inventory(defines.inventory.lab_input)
    local trash_inventory = entity.get_inventory(defines.inventory.assembling_machine_trash)
    -- Currently, trash_inventory_size does nothing for labs so there is only one slot available. Excess spoiled items will be deleted. 
    if trash_inventory then
        for _, quality in pairs(qualities) do
            local removed = trash_inventory.remove({name=placeholder_name, count=9999999, quality=quality})
            if removed > 0 then
                local result = select_result(rsl_definition)
                if result ~= nil then
                    trash_inventory.insert({name=result, count=removed, quality=quality})
                end
                return
            end
        end
    end
end

--- Mining drills do not have an inventory, they have an internal buffer that is not accessible
--- @param entity LuaEntity (we assume source_entity and target_entity are the same).
--- @param rsl_definition RslDefinition the name of the placeholder item.
--- @return nil
function swap_funcs.hotswap_in_mining_drill(entity, rsl_definition)
    -- The current behavior of mining drills don't allow runtime item replacement. So, if the modder
    -- wants to add a spoilable ore, either a fallback is needed for this item, either placeholder_spoil_into_self
    -- must be set to true
    --local placeholder_name = rsl_definition.name
    --local inventory = "..."
    return
end


--- @param entity LuaEntity (we assume source_entity and target_entity are the same).
--- @param rsl_definition RslDefinition the name of the placeholder item.
--- @return nil
function swap_funcs.hotswap_in_furnace(entity, rsl_definition)
    local placeholder_name = rsl_definition.name
    local inventory_result = entity.get_inventory(defines.inventory.furnace_result)
    local inventory_input = entity.get_inventory(defines.inventory.furnace_source)
    local modules = entity.get_inventory(defines.inventory.furnace_modules)
    local inventories = {inventory_input, inventory_result}

    if modules then
        table.insert(inventories, modules)
    end

    for _, inventory in pairs(inventories) do
        if inventory then
            for _, quality in pairs(qualities) do
                local removed = inventory.remove({name=placeholder_name, count=9999999, quality=quality})
                if removed > 0 then
                    local result = select_result(rsl_definition)
                    if result ~= nil then
                        inventory.insert({name=result, count=removed, quality=quality})
                    end
                    return
                end
            end
        end
    end
end

--- @param entity LuaEntity (we assume source_entity and target_entity are the same).
--- @param rsl_definition RslDefinition the name of the placeholder item.
--- @return nil
function swap_funcs.hotswap_in_logistic_inventory(entity, rsl_definition)
    local placeholder_name = rsl_definition.name
    local inventories = {entity.get_inventory(defines.inventory.chest), entity.get_inventory(defines.inventory.logistic_container_trash)}
    for _, inventory in pairs(inventories) do
        if inventory then
            for _, quality in pairs(qualities) do
                local removed = inventory.remove({name=placeholder_name, count=9999999, quality=quality})
                if removed > 0 then
                    local result = select_result(rsl_definition)
                    if result ~= nil then
                        inventory.insert({name=result, count=removed, quality=quality})
                    end
                    return
                end
            end
        end
    end
end

--- @param entity LuaEntity (we assume source_entity and target_entity are the same).
--- @param rsl_definition RslDefinition the name of the placeholder item.
--- @return nil
function swap_funcs.hotswap_in_roboport(entity, rsl_definition)
    local placeholder_name = rsl_definition.name
    local inventories = {entity.get_inventory(defines.inventory.roboport_robot), entity.get_inventory(defines.inventory.roboport_material)}
    for _, inventory in pairs(inventories) do
        if inventory then
            for _, quality in pairs(qualities) do
                local removed = inventory.remove({name=placeholder_name, count=9999999, quality=quality})
                if removed > 0 then
                    local result = select_result(rsl_definition)
                    if result ~= nil then
                        inventory.insert({name=result, count=removed, quality=quality})
                    end
                    return
                end
            end
        end
    end
end

--- @param entity LuaEntity (we assume source_entity and target_entity are the same).
--- @param rsl_definition RslDefinition the name of the placeholder item.
--- @return nil
function swap_funcs.hotswap_in_agricultural_tower(entity, rsl_definition)
    local placeholder_name = rsl_definition.name
    local inventories = {entity.get_inventory(defines.inventory.assembling_machine_input), entity.get_inventory(defines.inventory.assembling_machine_output)}
    for _, inventory in pairs(inventories) do
        if inventory then
            for _, quality in pairs(qualities) do
                local removed = inventory.remove({name=placeholder_name, count=9999999, quality=quality})
                if removed > 0 then
                    local result = select_result(rsl_definition)
                    if result ~= nil then
                        inventory.insert({name=result, count=removed, quality=quality})
                    end
                    return
                end
            end
        end
    end
end

--- @param entity LuaEntity (we assume source_entity and target_entity are the same).
--- @param rsl_definition RslDefinition the name of the placeholder item.
--- @return nil
function swap_funcs.hotswap_in_spider(entity, rsl_definition)
    local placeholder_name = rsl_definition.name
    local inventories = {entity.get_inventory(defines.inventory.spider_ammo), entity.get_inventory(defines.inventory.spider_trash), entity.get_inventory(defines.inventory.spider_trunk)}
    for _, inventory in pairs(inventories) do
        if inventory then
            for _, quality in pairs(qualities) do
                local removed = inventory.remove({name=placeholder_name, count=9999999, quality=quality})
                if removed > 0 then
                    local result = select_result(rsl_definition)
                    if result ~= nil then
                        inventory.insert({name=result, count=removed, quality=quality})
                    end
                    return
                end
            end
        end
    end
end



--- @param entity LuaEntity (we assume source_entity and target_entity are the same).
--- @param rsl_definition RslDefinition the name of the placeholder item.
--- @param inventory_definition defines.inventory.car_trunk|defines.inventory.cargo_wagon|defines.inventory.chest|defines.inventory.hub_main|defines.inventory.rocket_silo_rocket
function swap_funcs.hotswap_in_generic_inventory_in_place(entity, rsl_definition, inventory_definition)
    local placeholder_name = rsl_definition.name
    local inventory = entity.get_inventory(inventory_definition)
    if inventory then
        local current_count = inventory.get_item_count(placeholder_name)
        if current_count > 0 then
            for i = 1, #inventory do
                local stack = inventory[i]
                if stack.valid_for_read and stack.name == placeholder_name then
                    local result = select_result(rsl_definition)
                    swap_funcs.set_or_nil_stack(stack, result)
                    return
                end
            end
        end
    end
end

--- @param entity LuaEntity (we assume source_entity and target_entity are the same).
--- @param rsl_definition RslDefinition the name of the placeholder item.
--- @return nil
function swap_funcs.hotswap_on_ground(entity, rsl_definition)
    return swap_funcs.set_or_nil_stack(entity.stack, select_result(rsl_definition) or nil)
end

--- @param event EventData.on_script_trigger_effect
--- @param rsl_definition RslDefinition the name of the placeholder item.
function swap_funcs.hotswap_in_position(event, rsl_definition)
    local surface = game.surfaces[event.surface_index]
    local entity = surface.find_entities_filtered(
        {
            position = event.source_position,
            name = "item-on-ground",
            radius=2
        }
    )
    if entity and entity[1] and entity[1].stack.name == rsl_definition.name then
        swap_funcs.set_or_nil_stack(entity[1].stack, select_result(rsl_definition) or nil)
    end
end

return swap_funcs