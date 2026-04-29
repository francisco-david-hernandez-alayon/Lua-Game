-- utils/language_effectiveness.lua
--
-- Computes type effectiveness for a skill against a programming language.

local LanguageTypes = require("core.programming_languages.language_types")

local LanguageEffectiveness = {}

local function contains(list, value)
    for _, item in ipairs(list or {}) do
        if item == value then
            return true
        end
    end

    return false
end

function LanguageEffectiveness.getMultiplierAndEffectId(defenderLanguage, skill)
    assert(defenderLanguage, "defenderLanguage is required")
    assert(skill, "skill is required")
    assert(type(defenderLanguage.languageTypes) == "table", "defenderLanguage.languageTypes must be a table")
    assert(type(skill.skillType) == "string", "skill.skillType must be a string")

    local multiplier = 1
    local attackType = skill.skillType

    for _, defenderType in ipairs(defenderLanguage.languageTypes) do
        local relations = LanguageTypes.RELATIONS[defenderType]

        if relations then
            if contains(relations.weakAgainst, attackType) then
                multiplier = multiplier * 2
            end

            if contains(relations.strongAgainst, attackType) then
                multiplier = multiplier * 0.5
            end
        end
    end

    local effectId = "neutral"

    if multiplier >= 4 then
        effectId = "very_effective"
    elseif multiplier >= 2 then
        effectId = "effective"
    elseif multiplier <= 0.25 then
        effectId = "very_little_effective"
    elseif multiplier < 1 then
        effectId = "little_effective"
    end

    return multiplier, effectId
end

return LanguageEffectiveness
