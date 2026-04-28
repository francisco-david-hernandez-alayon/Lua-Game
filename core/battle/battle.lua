-- core/battle/battle.lua
--
-- Runtime battle data container.

local Battle = {}
Battle.__index = Battle

function Battle.new(programmerName, playerLanguages, enemyLanguages, returnState)
    assert(type(programmerName) == "string", "programmerName must be a string")
    assert(type(playerLanguages) == "table" and #playerLanguages > 0, "playerLanguages must be a non-empty table")
    assert(type(enemyLanguages) == "table" and #enemyLanguages > 0, "enemyLanguages must be a non-empty table")

    return setmetatable({
        programmerName = programmerName,
        playerLanguages = playerLanguages,
        enemyLanguages = enemyLanguages,
        returnState = returnState or nil,
    }, Battle)
end

return Battle
