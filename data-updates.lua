for _, machine in pairs(data.raw["assembling-machine"]) do
    machine.trash_inventory_size = 5
end

-- Check if Factorio version is >= required_version
local function is_version_or_higher(required_version)
    local game_version = util.split(mods["base"], ".") -- Get game version from "base" mod
    for i = 1, #required_version do
        local v = tonumber(game_version[i]) or 0
        if v > required_version[i] then return true end
        if v < required_version[i] then return false end
    end
    return true  -- Exact match or higher
end


local factorio_version = data.raw["utility-constants"].defaults

-- Apply changes only if Factorio engine version is >= 2.0.38
if is_version_or_higher({2, 0, 38}) then
    for _, lab in pairs(data.raw["lab"]) do
        lab.trash_inventory_size = 5
    end
end