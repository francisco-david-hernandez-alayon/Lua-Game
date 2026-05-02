-- core/programming_languages/skill.lua
--
-- A skill used in battle.
-- ATTRIBUTES:
--   id:                 unique string identifier
--   nameKey:            localization key for display name
--   descKey:            localization key for description
--   skillType:          one of LanguageTypes
--   skillCategories:    list of categories:
--                       "attack" | "attribute_effect" | "heal"
--   damage:             damage value or nil
--   heal:               heal value or nil
--   modifiedAttributes: attribute bonus table or nil
--   accuracy:           0–100 integer
--   animation:          SkillAnimation or nil
--                       If present, the battle will play the animation before
--                       applying damage / heal / effects.
--                       If nil, the effect is applied immediately (no visual).

local LanguageTypes = require("core.programming_languages.language_types")

local VALID_TYPES = {
    [LanguageTypes.SYSTEM]     = true,
    [LanguageTypes.BACKEND]    = true,
    [LanguageTypes.FRONTEND]   = true,
    [LanguageTypes.MOBILE]     = true,
    [LanguageTypes.SCRIPTING]  = true,
    [LanguageTypes.AI]         = true,
    [LanguageTypes.GAME]       = true,
    [LanguageTypes.SCIENTIFIC] = true,
}

local VALID_CATEGORIES = {
    attack          = true,
    attribute_effect = true,
    heal            = true,
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

function Skill.new(id, nameKey, descKey, skillType, skillCategories,
                   damage, heal, modifiedAttributes, accuracy, animation)

    assert(type(id) == "string",            "id must be a string")
    assert(type(nameKey) == "string",       "nameKey must be a string")
    assert(type(descKey) == "string",       "descKey must be a string")
    assert(VALID_TYPES[skillType],          "skillType must be a valid LanguageType")
    assert(areValidCategories(skillCategories),
        "skillCategories must be a non-empty list of valid categories")
    assert(damage == nil or type(damage) == "number",
        "damage must be a number or nil")
    assert(heal == nil or type(heal) == "number",
        "heal must be a number or nil")
    assert(modifiedAttributes == nil or type(modifiedAttributes) == "table",
        "modifiedAttributes must be a table or nil")
    assert(isValidAccuracy(accuracy),
        "accuracy must be a number between 0 and 100")
    -- animation is duck-typed: must have :play(), :update(), :draw(), :isPlaying()
    -- or be nil.  We don't hard-require the class to avoid circular deps.
    assert(animation == nil or
           (type(animation) == "table" and
            type(animation.play)      == "function" and
            type(animation.update)    == "function" and
            type(animation.draw)      == "function" and
            type(animation.isPlaying) == "function"),
        "animation must be a SkillAnimation instance or nil")

    return setmetatable({
        id                 = id,
        nameKey            = nameKey,
        descKey            = descKey,
        skillType          = skillType,
        skillCategories    = skillCategories,
        damage             = damage,
        heal               = heal,
        modifiedAttributes = modifiedAttributes,
        accuracy           = accuracy,
        animation          = animation,   -- SkillAnimation or nil
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

function Skill:hasAnimation()
    return self.animation ~= nil
end

function Skill:getName(L)
    return L.get(self.nameKey)
end

function Skill:getDesc(L)
    return L.get(self.descKey)
end

function Skill:toTable()
    -- animation is runtime-only; not serialised
    return {
        id                 = self.id,
        nameKey            = self.nameKey,
        descKey            = self.descKey,
        skillType          = self.skillType,
        skillCategories    = self.skillCategories,
        damage             = self.damage,
        heal               = self.heal,
        modifiedAttributes = self.modifiedAttributes,
        accuracy           = self.accuracy,
    }
end

return Skill