-- Helper functions, will be moved later
-----------------------------------

local function is_in_array(array, value)
    for _, v in ipairs(array) do
        if v == value then
            return true
        end
    end
    return false
end



-- Random selection functions
-----------------------------

--- @param possible_outcomes string[] An arra of two strings containing item names
--- @param weights number[] An array of two numbers representing weights for the items
--- @return string The randomly selected item
local function select_one_result_over_two(possible_outcomes, weights)
    assert(#possible_outcomes == 2 and #weights == 2, "Two outcomes and two weights required")
    local weight_sum = weights[1] + weights[2]
    return math.random() < (weights[1] / weight_sum) and possible_outcomes[1] or possible_outcomes[2]
end


--- @param possible_outcomes string[] An array of strings containing item names.
--- @param weights integer[] An array of integers representing weights for the items.
--- @return string The randomly selected item.
local function select_one_result_over_n_weighted(possible_outcomes, weights)
    assert(#possible_outcomes == #weights, "Outcomes and weights must have the same length")

    -- Compute the total weight
    local total_weight = 0
    for _, weight in ipairs(weights) do
        total_weight = total_weight + weight
    end

    -- Generate a random integer in the range [1, total_weight]
    local random_weight = math.random(1, total_weight)

    -- Find which outcome corresponds to the random weight
    local cumulative_weight = 0
    for i, weight in ipairs(weights) do
        cumulative_weight = cumulative_weight + weight
        if random_weight <= cumulative_weight then
            return possible_outcomes[i]
        end
    end
end


--- This function selects and returns one outcome with equals chances of selection from an array of 2 strings.
--- @param possible_outcomes string[] An array of strings containing item names.
--- @return string The randomly selected item.
local function select_one_result_over_n_unweighted(possible_outcomes)
    assert(#possible_outcomes == 2)
    return options[math.random(1, #possible_outcomes)]
end


-- Inventory swapping functions
--------------------------------

--- @param outcomes string[] all the possible outcomes for all items that have spoiled
local function hotswap_stack_in_character_inventory(entity, placeholder_items, outcomes)
    local inventory = entity.get_inventory(defines.inventory.character_main)
    
    for i = 1, #inventory do
        local stack = inventory[i]
        if stack.valid_for_read and is_in_array(placeholder_items, stack.name) then
            local result = func()
            stack.set_stack({ name = result, count = stack.count })
        end
    end
end

local function hotswap_item_in_character_inventory(entity)
    local inventory = event.source_entity.get_inventory(defines.inventory.character_main)
    for _, item_name in ipairs(items) do
        if inventory.get_item_count(item_name) > 0 then
            inventory.remove({ name = item_name, count = inventory.get_item_count(item_name) })
        end
    end
end

local function hotswap_in_belt_inventory(event)
    local transport_lines = {event.source_entity.get_transport_line(1), event.source_entity.get_transport_line(2)}
    --global options = { "iron-plate", "copper-plate", "steel-plate", "plastic-bar" }
    --global result = options[math.random(1, #options)]
    
    for _, line in pairs(transport_lines) do
        if line.get_item_count("mutation-e") == 0 then
            goto continue
        end
        for i = 1, #line do
            local stack = line[i]
            if stack.valid_for_read and stack.name == "mutation-e" then
                stack.set_stack({name = result, count = stack.count})
            end
        end
        ::continue::
    end
end



local function hotswap_in_belt_inventory_v0(event)
    local transport_lines = {
        event.source_entity.get_transport_line(1),
        event.source_entity.get_transport_line(2)
    }

    local contents_a = transport_lines[1].get_detailed_contents()
    local contents_b = transport_lines[2].get_detailed_contents()

    
end

local function register_transport_belt(event)
    if event.source_entity.valid then
        storage.delayed_belts[event.source_entity.unit_number] = event.source_entity
    end
end


local function dood()
    for _, item in pairs(contents_a) do
        if item.stack.name == "mutation-e" then
            item.stack.set_stack({name = result, count = item.stack.count})
        end
    end

    for _, item in pairs(contents_b) do
        if item.stack.name == "mutation-e" then
            item.stack.set_stack({name = result, count = item.stack.count})
        end
    end

end


local function hotswap_in_inserter(event)
    local inserter = event.source_entity
    local options = { "iron-plate", "copper-plate", "steel-plate", "plastic-bar" }
    local result = options[math.random(1, #options)]
    --local result = math.random() < 0.5 and "iron-plate" or "copper-plate"
    local current_stack = inserter.held_stack
    inserter.held_stack.set_stack({name = result, count = current_stack.count})
end

local function hotswap_in_bot(event)
    local bot = event.source_entity
    local options = { "iron-plate", "copper-plate", "steel-plate", "plastic-bar" }
    local result = options[math.random(1, #options)]
    --local result = math.random() < 0.5 and "iron-plate" or "copper-plate"
    local inventory = event.source_entity.get_inventory(defines.inventory.robot_cargo)
    inventory[1].set_stack({name = result, count = inventory[1].count})
end



script.on_event(defines.events.on_script_trigger_effect, function(event)
    if event.effect_id == "mutation_spoil_effect" then
        if event.source_entity.type == "transport-belt" then
            if storage.belt_mutator_counter < 2000 then
                storage.belt_mutator_counter = storage.belt_mutator_counter + 1
                hotswap_in_belt_inventory(event)
            else
                return
            end
        end
        if event.source_entity.name == "character" then
            hotswap_in_character_inventory(event)
        end
        if event.source_entity.type == "inserter" then
            hotswap_in_inserter(event)
        end
        if event.source_entity.type == "logistic-robot" then
            hotswap_in_bot(event)
        end
    end
end)

script.on_event(defines.events.on_tick, function(event)
    if event.tick % 60 == 0 then
        options = { "iron-plate", "copper-plate", "steel-plate", "plastic-bar" }
        result = options[math.random(1, #options)]
    end
    storage.belt_mutator_counter = 0
end)

script.on_init(function()
    storage.delayed_belts = storage.delayed_belts or {}
    storage.belt_mutator_counter = storage.belt_mutator_counter or 0
    storage.event_counter = storage.event_counter or 0
end
)

script.on_configuration_changed(function()
    storage.delayed_belts = storage.delayed_ or {}
    storage.belt_mutator_counter = storage.belt_mutator_counter or 0
    storage.event_counter = storage.event_counter or 0
end)
