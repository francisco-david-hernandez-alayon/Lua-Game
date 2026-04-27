-- core/battle/battle_ai.lua
--
-- Simple AI for enemy programmer.
-- Returns random attack and random active language.

local BattleAI = {}

function BattleAI.chooseAttack(language)
    if not language then return nil end

    local skills = language.currentSkills
    if #skills == 0 then return nil end
    return skills[math.random(#skills)]
end

function BattleAI.chooseLanguage(languages)
    local active = {}
    for _, lang in ipairs(languages) do
        if lang and lang.isActive and lang:isActive() then
            table.insert(active, lang)
        end
    end
    if #active == 0 then return nil end
    return active[math.random(#active)]
end

return BattleAI
