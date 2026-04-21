-- core/battle/attack.lua
--
-- A single attack move.
-- nameKey: localization key for display name
-- damage:  base damage value

local Attack = {}
Attack.__index = Attack

function Attack.new(nameKey, damage)
    assert(type(nameKey) == "string", "nameKey must be a string")
    assert(type(damage)  == "number", "damage must be a number")
    return setmetatable({
        nameKey = nameKey,
        damage  = damage,
    }, Attack)
end

function Attack:getName(L) return L.get(self.nameKey) end

return Attack