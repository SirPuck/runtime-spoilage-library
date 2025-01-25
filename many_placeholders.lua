
--- Many placeholders functions : the following functions are meant to turn all the placeholders present in the target inventory every time they are used.
--- This could be a great optimization for belt, but there is little chance in a real scenario that they would be better to use than their single item
--- target counterpart.
-- Swaps an item in the character's inventory, in place.
--- @param entity entity (we assume source_entity and target_entity are the same).
--- @param placeholder_items string[] containing all the items that have a random spoil result.
--- @return nil
local function hotswap_stack_in_character_inventory_mp(entity, placeholder_items)
    local inventory = entity.get_inventory(defines.inventory.character_main)
    
    for i = 1, #inventory do
        local stack = inventory[i]
        if stack.valid_for_read and is_in_array(placeholder_items, stack.name) then
            stack.set_stack({ name = result, count = stack.count })
        end
    end
end

--- @param entity entity (we assume source_entity and target_entity are the same).
--- @param placeholder_items string[] containing all the items that have a random spoil result.
--- @return nil
local function hotswap_item_in_character_inventory_mp(entity, placeholder_items)
    local inventory = entity.get_inventory(defines.inventory.character_main)
    for placeholder, result in pairs(placeholder_items) do
        local _placeholder_number = inventory.get_item_count(placeholder)
        if _placeholder_number > 0 then
            inventory.remove({name = placeholder})
            inventory.insert({name = result, count = _placeholder_number})
        end
    end
end

--- @param entity entity (we assume source_entity and target_entity are the same).
--- @param placeholder_items string[] containing all the items that have a random spoil result.
--- @return nil
local function hotswap_in_belt_inventory_mp(entity, placeholder_items)
    local transport_lines = {entity.get_transport_line(1), entity.get_transport_line(2)}
    for _, line in pairs(transport_lines) do
        for placeholder, result in pairs(placeholder_items) do
            if line.get_item_count(placeholder) == 0 then
                goto continue
            end
            for i = 1, #line do
                local stack = line[i]
                if stack.valid_for_read and stack.name == placeholder then
                    stack.set_stack({name = result, count = stack.count})
                end
            end
        end
        ::continue::
    end
end

--- @param entity entity (we assume source_entity and target_entity are the same).
--- @param placeholder_items string[] containing all the items that have a random spoil result.
--- @return nil
local function hotswap_in_inserter_mp(entity, placeholder_items)
    local result = options[math.random(1, #options)]
    --local result = math.random() < 0.5 and "iron-plate" or "copper-plate"
    local current_stack = entity.held_stack
    entity.held_stack.set_stack({name = placeholder_items[current_stack.name], count = current_stack.count})
end

--- @param entity entity (we assume source_entity and target_entity are the same).
--- @param placeholder_items string[] containing all the items that have a random spoil result.
--- @return nil
local function hotswap_in_bot_mp(entity, placeholder_items)
    local inventory = entity.get_inventory(defines.inventory.robot_cargo)
    local current_stack = entity.held_stack
    inventory[1].set_stack({name = placeholder_items[current_stack], count = inventory[1].count})
end
