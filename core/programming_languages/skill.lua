-- core/programming_languages/skill.lua
--
-- A skill used in battle.
-- ATTRIBUTES:
--   nameKey:            localization key for display name
--   descKey:            localization key for description
--   skillType:          one of LanguageTypes
--   skillCategories:    list of categories:
--                       "attack" | "attribute_effect" | "heal"
--   damage:             damage value or nil
--   heal:               heal value or nil
--   modifiedAttributes: attribute bonus table or nil

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
Skill.VALID_CATEGORIES = VALID_CATEGORIES

local function areValidCategories(skillCategories)
    if type(skillCategories) ~= "table" or #skillCategories == 0 then
        return false
    end

    for _, category in ipairs(skillCategories) do
        if not VALID_CATEGORIES[category] then
            return false
        end
    end

    return true
end

local function isValidAccuracy(accuracy)
    return type(accuracy) == "number" and accuracy >= 0 and accuracy <= 100
end

function Skill.new(nameKey, descKey, skillType, skillCategories, damage, heal, modifiedAttributes, accuracy)
    assert(type(nameKey) == "string", "nameKey must be a string")
    assert(type(descKey) == "string", "descKey must be a string")
    assert(VALID_TYPES[skillType], "skillType must be a valid LanguageType")
    assert(areValidCategories(skillCategories), "skillCategories must be a non-empty list of valid categories")
    assert(damage == nil or type(damage) == "number", "damage must be a number or nil")
    assert(heal == nil or type(heal) == "number", "heal must be a number or nil")
    assert(modifiedAttributes == nil or type(modifiedAttributes) == "table", "modifiedAttributes must be a table or nil")
    assert(isValidAccuracy(accuracy), "accuracy must be a number between 0 and 100")

    return setmetatable({
        nameKey = nameKey,
        descKey = descKey,
        skillType = skillType,
        skillCategories = skillCategories,
        damage = damage,
        heal = heal,
        modifiedAttributes = modifiedAttributes,
        accuracy = accuracy,
    }, Skill)
end

function Skill:hasCategory(category)
    for _, currentCategory in ipairs(self.skillCategories) do
        if currentCategory == category then
            return true
        end
    end

    return false
end

function Skill:getName(L)
    return L.get(self.nameKey)
end

function Skill:getDesc(L)
    return L.get(self.descKey)
end

return Skill
