-- core/programming_languages/level_tree.lua
--
-- Ordered list of LevelNodes defining a language's progression.
-- ATTRIBUTES:
--   levels: list of LevelNode ordered by levelNumber

local LevelTree = {}
LevelTree.__index = LevelTree

function LevelTree.new(levels)
    assert(type(levels) == "table" and #levels > 0, "levels must be a non-empty table")
    return setmetatable({ levels = levels }, LevelTree)
end

-- Returns LevelNode for a given level number or nil
function LevelTree:getLevel(n)
    for _, node in ipairs(self.levels) do
        if node.levelNumber == n then return node end
    end
    return nil
end

-- Returns the next LevelNode after currentLevel or nil if max level
function LevelTree:getNextLevel(currentLevel)
    return self:getLevel(currentLevel + 1)
end

-- Returns expRequired for next level or nil if max
function LevelTree:getExpRequired(currentLevel)
    local next = self:getNextLevel(currentLevel)
    return next and next.expRequired or nil
end

function LevelTree:toTable()
    local levels = {}
    for _, level in ipairs(self.levels) do
        table.insert(levels, level:toTable())
    end

    return {
        levels = levels,
    }
end


return LevelTree