-- core/programming_languages/skill.lua
--
-- A skill used in battle.
-- ATTRIBUTES:
--   nameKey:       localization key for display name
--   descKey:       localization key for description
--   skillType:     "Backend" | "Frontend" | "System"
--   baseDamage:    base damage before stat calculation
--   skillCategory: "attack" | "attribute_effect" | "heal"

local LanguageTypes = require("core.programming_languages.language_types")

local VALID_TYPES = {
    [LanguageTypes.SYSTEM] = true,
    [LanguageTypes.BACKEND] = true,
    [LanguageTypes.FRONTEND] = true,
    [LanguageTypes.MOBILE] = true,
    [LanguageTypes.SCRIPTING] = true,
    [LanguageTypes.AI] = true,
    [LanguageTypes.GAME] = true,
    [LanguageTypes.SCIENTIFIC] = true,
}

local VALID_CATEGORIES = {
    attack = true,
    attribute_effect = true,
    heal = true,
}

local Skill = {}
Skill.__index = Skill

function Skill.new(nameKey, descKey, skillType, baseDamage, skillCategory)
    assert(type(nameKey) == "string", "nameKey must be a string")
    assert(type(descKey) == "string", "descKey must be a string")
    assert(VALID_TYPES[skillType], "skillType must be Backend/Frontend/System")
    assert(type(baseDamage) == "number", "baseDamage must be a number")
    assert(VALID_CATEGORIES[skillCategory], "skillCategory must be attack/attribute_effect/heal")

    return setmetatable({
        nameKey = nameKey,
        descKey = descKey,
        skillType = skillType,
        baseDamage = baseDamage,
        skillCategory = skillCategory,
    }, Skill)
end

function Skill:getName(L)
    return L.get(self.nameKey)
end

function Skill:getDesc(L)
    return L.get(self.descKey)
end

return Skill
