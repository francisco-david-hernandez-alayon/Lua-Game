-- core/programming_languages/upgrade.lua
--
-- An optional upgrade the player can choose when leveling up.
-- ATTRIBUTES:
--   id:               unique string identifier
--   specializationId: nil or string — tags this upgrade as part of a specialization path
--   skills:           nil or list of Skill to add to the language's skill pool
--   passives:         nil or list of PassiveAbility to add to the language's passives
--   attributeBonus:   nil or table of stat deltas e.g. { hp=5, speed=2 }

local Upgrade = {}
Upgrade.__index = Upgrade

function Upgrade.new(id, specializationId, skills, passives, attributeBonus)
    assert(type(id) == "string", "id must be a string")
    assert(specializationId == nil or type(specializationId) == "string",
        "specializationId must be string or nil")
    return setmetatable({
        id               = id,
        specializationId = specializationId,
        skills           = skills        or nil,
        passives         = passives      or nil,
        attributeBonus   = attributeBonus or nil,
    }, Upgrade)
end

-- Apply this upgrade to a ProgrammingLanguage instance
function Upgrade:apply(lang)
    -- Add skills to pool
    if self.skills then
        for _, skill in ipairs(self.skills) do
            lang:addSkill(skill)
        end
    end

    -- Add passive abilities
    if self.passives then
        for _, passive in ipairs(self.passives) do
            lang:addPassive(passive)
        end
    end

    -- Apply attribute bonuses
    if self.attributeBonus then
        for stat, delta in pairs(self.attributeBonus) do
            if lang.attributes[stat] ~= nil then
                lang.attributes[stat] = lang.attributes[stat] + delta
                -- Sync maxLinesOfCode if hp changed
                if stat == "hp" then
                    lang.attributes.maxHp = lang.attributes.maxHp + delta
                end
            end
        end
    end

    -- Set specialization
    if self.specializationId then
        lang.specialization = self.specializationId
    end

    -- Track chosen upgrade
    table.insert(lang.chosenUpgrades, self.id)
    print("[Upgrade] applied: " .. self.id .. " to " .. lang.language_name)
end

return Upgrade