local swap_funcs = {}
-- Inventory swapping functions
------------------------


---comment
---@param stack LuaItemStack
---@param result string|nil
function swap_funcs.set_or_nil_stack(stack, result)
    if result ~= nil then
        stack.set_stack({ name = result, count = stack.count })
    else
        stack.set_stack(nil)
    end
end





-- Ex of spoil_mapping : {["placeholder"] = "result"}
--- Single placeholder_item functions. These functions will only check if there is the placeholder_item triggering the event in the target inventory.
--- target counterpart.
-- Swaps an item in the character's inventory, in place.
--- @param entity LuaEntity (we assume source_entity and target_entity are the same).
--- @param placeholder string the name of the placeholder item.
--- @return nil
function swap_funcs.hotswap_stack_in_character_inventory(entity, placeholder)
    local inventory = entity.get_inventory(defines.inventory.character_main)
    local result = storage.spoilage_mapping[placeholder] or nil
    for i = 1, #inventory do
        local stack = inventory[i]
        if stack.valid_for_read and stack.name == placeholder then
            set_or_nil_stack(stack, result)
        end
    end
end

--- @param entity LuaEntity (we assume source_entity and target_entity are the same).
--- @param placeholder string the name of the placeholder item.
--- @return nil
function swap_funcs.hotswap_item_in_character_inventory(entity, placeholder_definition)
    local inventory = entity.get_main_inventory(defines.inventory.character_main)
    local placeholder_name = placeholder_definition.name
    local result = storage.spoilage_mapping[placeholder_definition.condition][placeholder_definition.name]
    if inventory then
        local _placeholder_number = inventory.get_item_count(placeholder_name)
        if _placeholder_number > 0 then
            inventory.remove({name=placeholder_name, count=_placeholder_number})
            if result ~= nil then
                inventory.insert({name = result, count = _placeholder_number})
            end
        end
        if entity.cursor_stack and entity.cursor_stack.valid_for_read and entity.cursor_stack.name == placeholder_name then
            swap_funcs.set_or_nil_stack(entity.cursor_stack, result, entity.cursor_stack.count)
        end
    end
end

--- @param entity LuaEntity (we assume source_entity and target_entity are the same).
--- @param placeholder string the name of the placeholder item.
--- @return nil
function swap_funcs.hotswap_in_belt(entity, placeholder_definition)
    local transport_lines = {entity.get_transport_line(1), entity.get_transport_line(2)}
    local placeholder_name = placeholder_definition.name
    local result = storage.spoilage_mapping[placeholder_definition.condition][placeholder_definition.name]
    for _, line in pairs(transport_lines) do
        if line.get_item_count(placeholder_name) == 0 then
            goto continue
        end
        for i = 1, line.line_length do
            local stack = line[i]
            if stack.valid_for_read and stack.name == placeholder_name then
                swap_funcs.set_or_nil_stack(stack, result)
            end
        end
        ::continue::
    end
end

--- @param entity LuaEntity (we assume source_entity and target_entity are the same).
--- @param placeholder string the name of the placeholder item.
--- @return nil
function swap_funcs.hotswap_in_underground_belt(entity, placeholder_definition)
    local placeholder_name = placeholder_definition.name
    local result = storage.spoilage_mapping[placeholder_definition.condition][placeholder_definition.name]
    local transport_lines = {
        entity.get_transport_line(defines.transport_line.left_line),
        entity.get_transport_line(defines.transport_line.left_underground_line),
        entity.get_transport_line(defines.transport_line.secondary_left_line),
        entity.get_transport_line(defines.transport_line.right_line),
        entity.get_transport_line(defines.transport_line.right_underground_line),
        entity.get_transport_line(defines.transport_line.secondary_right_line),
    }
    for _, line in pairs(transport_lines) do
        if line.get_item_count(placeholder_name) == 0 then
            goto continue
        end
        for i = 1, #line do
            local stack = line[i]
            if stack.valid_for_read and stack.name == placeholder_name then
                swap_funcs.set_or_nil_stack(stack, result)
            end
        end
        ::continue::
    end
end

local function _hotswap_in_splitter_lines(lines, placeholder, result)
    for _, line in pairs(lines) do
        for i = 1, #line do
            local stack = line[i]
            if stack.valid_for_read and stack.name == placeholder then
                swap_funcs.set_or_nil_stack(stack, result)
            end
        end
    end
end

--- @param entity LuaEntity (we assume source_entity and target_entity are the same).
--- @param placeholder string the name of the placeholder item.
--- @return nil
function swap_funcs.hotswap_in_splitter(entity, placeholder_definition)
    local placeholder_name = placeholder_definition.name
    local result = storage.spoilage_mapping[placeholder_definition.condition][placeholder_definition.name]
    local transport_lines = {entity.get_transport_line(1), entity.get_transport_line(2)}

    for _, line in pairs(transport_lines) do
        if #line.input_lines == 0 then
            goto continue
        end
        for i = 1, #line.input_lines do
            _hotswap_in_splitter_lines(line.input_lines, placeholder_name, result)
        end
        ::continue::
        if #line.output_lines == 0 then
            goto next_iter
        end
        for i = 1, #line.output_lines do
            _hotswap_in_splitter_lines(line.output_lines, placeholder_name, result)
        end
        ::next_iter::
    end
end


--- @param entity LuaEntity (we assume source_entity and target_entity are the same).
--- @param placeholder string containing all the items that have a random spoil result.
--- @return nil
function swap_funcs.hotswap_in_inserter_or_bot(entity, placeholder_definition)
    local result = storage.spoilage_mapping[placeholder_definition.condition][placeholder_definition.name]
    --local result = math.random() < 0.5 and "iron-plate" or "copper-plate"
    if entity.held_stack.valid_for_read then
        swap_funcs.set_or_nil_stack(entity.held_stack, result)
    end
end







-- /!\ ATTENTION /!\ Cannot write arbitrary items into the output nor dump stacks of the assembling machine.
-- Tried both remove/insert and set stack. Only the results of the recipe are allowed.
-- Since this mod's goal is to control the spoil results at runtime, it would make
-- no sense to integrate these results in the recipes, unless you really want to.
function swap_funcs.hotswap_in_machine(entity, placeholder_definition)
    if enable_swap_in_assembler == false then
        return
    end
    local placeholder_name = placeholder_definition.name
    local input = entity.get_inventory(defines.inventory.assembling_machine_input)
    local output = entity.get_inventory(defines.inventory.assembling_machine_output)
    local dump = entity.get_inventory(defines.inventory.assembling_machine_dump)
--    local trash = entity.get_inventory(8)
    local inventories = {input, output, dump}
    for _, inventory in pairs(inventories) do
        local item_count = inventory.get_item_count(placeholder_name)
        if item_count > 0 then
            for i = 1, #inventory do
                local stack = inventory[i]
                if stack.valid_for_read and stack.name == placeholder_name then
                    --inventory.remove({name="mutation-e"})
                    --inventory.insert({name=storage.spoilage_mapping[placeholder], count=item_count})
                    stack.set_stack({name=storage.spoilage_mapping[placeholder_definition.condition][placeholder_definition.name], count=item_count})
                end
            end
        end
    end
end

--- @param entity LuaEntity (we assume source_entity and target_entity are the same).
--- @param placeholder string the name of the placeholder item.
--- @param inventory_definition defines.inventory.car_trunk|defines.inventory.cargo_wagon|defines.inventory.chest|defines.inventory.hub_main|defines.inventory.rocket_silo_rocket
--- @return nil
function swap_funcs.hotswap_in_generic_inventory(entity, placeholder_definition, inventory_definition)
    local placeholder_name = placeholder_definition.name
    local inventory = entity.get_inventory(inventory_definition)
    local result = storage.spoilage_mapping[placeholder_definition.condition][placeholder_definition.name]
    if inventory then
        local current_count = inventory.get_item_count(placeholder_name)
        if current_count > 0 then
            inventory.remove({name=placeholder_name, count=current_count})
            if result ~= nil then
                inventory.insert({name=result, count = current_count})
            end
        end
    end
end

--- @param entity LuaEntity (we assume source_entity and target_entity are the same).
--- @param placeholder string the name of the placeholder item.
--- @return nil
function swap_funcs.hotswap_in_logistic_inventory(entity, placeholder_definition)
    local placeholder_name = placeholder_definition.name
    local inventories = {entity.get_inventory(defines.inventory.chest), entity.get_inventory(defines.inventory.logistic_container_trash)}
    local result = storage.spoilage_mapping[placeholder_definition.condition][placeholder_definition.name]
    for _, inventory in pairs(inventories) do
        local current_count = inventory.get_item_count(placeholder_name)
        if current_count > 0 then
            inventory.remove({name=placeholder_name, count=current_count})
            if result ~= nil then
                inventory.insert({name=result, count = current_count})
            end
        end
    end
end


--- @param entity LuaEntity (we assume source_entity and target_entity are the same).
--- @param placeholder string the name of the placeholder item.
--- @param inventory_definition defines.inventory.car_trunk|defines.inventory.cargo_wagon|defines.inventory.chest|defines.inventory.hub_main|defines.inventory.rocket_silo_rocket
function swap_funcs.hotswap_in_generic_inventory_in_place(entity, placeholder_definition, inventory_definition)
    local placeholder_name = placeholder_definition.name
    local inventory = entity.get_inventory(inventory_definition)
    local result = storage.spoilage_mapping[placeholder_definition.condition][placeholder_definition.name]
    if inventory then
        local current_count = inventory.get_item_count(placeholder_name)
        if current_count > 0 then
            for i = 1, #inventory do
                local stack = inventory[i]
                if stack.valid_for_read and stack.name == placeholder_name then
                    stack.set_stack({ name = result, count = stack.count })
                end
            end
        end
    end
end

--- @param entity LuaEntity (we assume source_entity and target_entity are the same).
--- @param placeholder string the name of the placeholder item.
--- @return nil
function swap_funcs.hotswap_on_ground(entity, placeholder_definition)
    return swap_funcs.set_or_nil_stack(entity.stack, storage.spoilage_mapping[placeholder_definition.condition][placeholder_definition.name] or nil)
end

--- @param event EventData.on_script_trigger_effect
--- @param placeholder_definition table
function swap_funcs.hotswap_on_position(event, placeholder_definition)
    local surface = game.surfaces[event.surface_index]
    local entity = surface.find_entities_filtered(
        {
            position = event.source_position,
            name = "item-on-ground",
            radius=2
        }
    )
    if entity and entity[1] and entity[1].stack.name == placeholder_definition.name then
        swap_funcs.set_or_nil_stack(entity[1].stack, storage.spoilage_mapping[placeholder_definition.condition][placeholder_definition.name] or nil)
    end
end

return swap_funcs