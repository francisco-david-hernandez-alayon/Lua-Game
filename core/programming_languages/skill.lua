-- core/programming_languages/skill.lua
--
-- A skill used in battle (replaces Attack).
-- ATTRIBUTES:
--   nameKey:       localization key for display name
--   descKey:       localization key for description
--   skillType:     "Backend" | "Frontend" | "System" — determines which attack stat is used
--   baseDamage:    base damage before stat calculation
--   skillCategory: "physical" | "special"

local VALID_TYPES      = { Backend = true, Frontend = true, System = true }
local VALID_CATEGORIES = { physical = true, special = true }

local Skill = {}
Skill.__index = Skill

function Skill.new(nameKey, descKey, skillType, baseDamage, skillCategory)
    assert(type(nameKey)       == "string",               "nameKey must be a string")
    assert(type(descKey)       == "string",               "descKey must be a string")
    assert(VALID_TYPES[skillType],                        "skillType must be Backend/Frontend/System")
    assert(type(baseDamage)    == "number",               "baseDamage must be a number")
    assert(VALID_CATEGORIES[skillCategory],               "skillCategory must be physical/special")
    return setmetatable({
        nameKey       = nameKey,
        descKey       = descKey,
        skillType     = skillType,
        baseDamage    = baseDamage,
        skillCategory = skillCategory,
    }, Skill)
end

function Skill:getName(L) return L.get(self.nameKey) end
function Skill:getDesc(L) return L.get(self.descKey) end

return Skill