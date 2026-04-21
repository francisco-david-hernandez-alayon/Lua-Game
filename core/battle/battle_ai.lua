-- core/battle/battle_ai.lua
--
-- Simple AI for enemy programmer.
-- Returns random attack and random active language.

local BattleAI = {}

-- Returns a random attack from the given language's currentAttacks
function BattleAI.chooseAttack(language)
    local attacks = language.currentAttacks
    if #attacks == 0 then return nil end
    return attacks[math.random(#attacks)]
end

-- Returns a random active language from a list
function BattleAI.chooseLanguage(languages)
    local active = {}
    for _, lang in ipairs(languages) do
        if lang:isActive() then table.insert(active, lang) end
    end
    if #active == 0 then return nil end
    return active[math.random(#active)]
end

return BattleAI