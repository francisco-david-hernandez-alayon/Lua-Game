-- core/programming_languages/level_node.lua
--
-- A single level in the language's progression tree.
-- ATTRIBUTES:
--   levelNumber:    which level this node represents
--   nameKey:        localization key
--   descKey:        localization key
--   expRequired:    exp needed to reach this level
--   attributeBonus: automatic stat increases on level up {hp=N, speed=N, ...}
--   upgrades:       list of Upgrade — player picks one (can be empty)

local LevelNode = {}
LevelNode.__index = LevelNode

function LevelNode.new(levelNumber, nameKey, descKey, expRequired, attributeBonus, upgrades)
    assert(type(levelNumber)  == "number", "levelNumber must be a number")
    assert(type(nameKey)      == "string", "nameKey must be a string")
    assert(type(descKey)      == "string", "descKey must be a string")
    assert(type(expRequired)  == "number", "expRequired must be a number")
    assert(attributeBonus == nil or type(attributeBonus) == "table",
        "attributeBonus must be table or nil")
    return setmetatable({
        levelNumber    = levelNumber,
        nameKey        = nameKey,
        descKey        = descKey,
        expRequired    = expRequired,
        attributeBonus = attributeBonus or {},
        upgrades       = upgrades       or {},
    }, LevelNode)
end

function LevelNode:toTable()
    local upgrades = {}
    for _, upgrade in ipairs(self.upgrades) do
        table.insert(upgrades, upgrade:toTable())
    end

    return {
        levelNumber = self.levelNumber,
        nameKey = self.nameKey,
        descKey = self.descKey,
        expRequired = self.expRequired,
        attributeBonus = self.attributeBonus,
        upgrades = upgrades,
    }
end


return LevelNode