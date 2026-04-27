-- core/programming_languages/programming_language.lua
--
-- A programming language entity used in progression and battle.
--
-- ATTRIBUTES (base — persist between battles):
--   language_name:     display string
--   languageType:      "Backend" | "Frontend" | "System"
--   attributes:        stat table — nil stats are unused by this language type:
--     hp              → current health (persists between battles)
--     maxHp           → maximum health
--     speed           → lower = faster turn order
--     backend_attack  → Backend skill damage multiplier  (Backend only)
--     backend_defense → damage reduction vs Backend      (Backend only)
--     frontend_attack → Frontend skill damage multiplier (Frontend only)
--     frontend_defense→ damage reduction vs Frontend     (Frontend only)
--     system_attack   → System skill damage multiplier   (System only)
--     system_defense  → damage reduction vs System       (System only)
--
-- ATTRIBUTES (battle — reset each battle except hp):
--   currentBattle.status        → "active" | "obsolete"
--   currentBattle.statusEffects → list of active effects (future use)
--
-- PROGRESSION:
--   level, exp, levelTree
--   chosenUpgrades  → list of upgrade ids already applied
--   specialization  → nil or string id
--
-- SKILLS & PASSIVES:
--   skills          → full pool of known skills
--   currentSkills   → up to MAX_CURRENT_SKILLS equipped
--   passiveAbilities→ list of active passives
--
-- ITEMS:
--   equippedItems   → list, max maxEquippedItems (default 2)

local LevelTree = require("core.programming_languages.level_tree")
local LanguageTypes = require("core.programming_languages.language_types")

local MAX_CURRENT_SKILLS = 4
local DEFAULT_MAX_ITEMS  = 2

-- Which attack/defense stats belong to each type.
local TYPE_STATS = {
    [LanguageTypes.BACKEND]  = { attack = "backend_attack",  defense = "backend_defense"  },
    [LanguageTypes.FRONTEND] = { attack = "frontend_attack", defense = "frontend_defense" },
    [LanguageTypes.SYSTEM]   = { attack = "system_attack",   defense = "system_defense"   },
}

local STATUS = { ACTIVE = "active", OBSOLETE = "obsolete" }

local ProgrammingLanguage = {}
ProgrammingLanguage.__index = ProgrammingLanguage
ProgrammingLanguage.STATUS = STATUS
ProgrammingLanguage.TYPE_STATS = TYPE_STATS

-- Build default attributes table for a given language type.
-- Stats not relevant to the type are nil.
local function buildAttributes(languageType, hp, speed, typeAttack, typeDefense)
    local attrs = {
        hp               = hp,
        maxHp            = hp,
        speed            = speed,
        backend_attack   = nil,
        backend_defense  = nil,
        frontend_attack  = nil,
        frontend_defense = nil,
        system_attack    = nil,
        system_defense   = nil,
    }

    local ts = TYPE_STATS[languageType]
    if ts then
        attrs[ts.attack]  = typeAttack
        attrs[ts.defense] = typeDefense
    end

    return attrs
end

function ProgrammingLanguage.new(data)
    assert(type(data.language_name) == "string", "language_name must be a string")
    assert(TYPE_STATS[data.languageType], "languageType must be Backend/Frontend/System")
    assert(type(data.hp) == "number", "hp must be a number")
    assert(type(data.speed) == "number", "speed must be a number")
    assert(type(data.typeAttack) == "number", "typeAttack must be a number")
    assert(type(data.typeDefense) == "number", "typeDefense must be a number")
    assert(data.levelTree == nil or data.levelTree.levels, "levelTree must be a LevelTree or nil")

    local self = setmetatable({
        language_name = data.language_name,
        languageType = data.languageType,

        attributes = buildAttributes(
            data.languageType,
            data.hp,
            data.speed,
            data.typeAttack,
            data.typeDefense
        ),

        currentBattle = {
            status = STATUS.ACTIVE,
            statusEffects = {},
        },

        level = data.level or 1,
        exp = data.exp or 0,
        levelTree = data.levelTree or nil,
        chosenUpgrades = {},
        specialization = nil,

        skills = {},
        currentSkills = {},

        passiveAbilities = {},

        equippedItems = {},
        maxEquippedItems = data.maxEquippedItems or DEFAULT_MAX_ITEMS,
    }, ProgrammingLanguage)

    return self
end

function ProgrammingLanguage:resetBattleState()
    self.currentBattle = { status = STATUS.ACTIVE, statusEffects = {} }
end

function ProgrammingLanguage:isActive() return self.currentBattle.status == STATUS.ACTIVE end
function ProgrammingLanguage:isObsolete() return self.currentBattle.status == STATUS.OBSOLETE end

function ProgrammingLanguage:setObsolete()
    self.currentBattle.status = STATUS.OBSOLETE
    print("[ProgrammingLanguage] " .. self.language_name .. " is OBSOLETE")
end

function ProgrammingLanguage:takeDamage(amount, skillType)
    local totalDef, count = 0, 0
    for key, val in pairs(self.attributes) do
        if key:find("_defense") and val ~= nil then
            totalDef = totalDef + val
            count = count + 1
        end
    end

    local avgDefense = count > 0 and (totalDef / count) or 0
    local actual = math.max(1, math.floor(amount - avgDefense * 0.5))

    self.attributes.hp = math.max(0, self.attributes.hp - actual)
    if self.attributes.hp <= 0 then
        self:setObsolete()
    end

    return actual
end

function ProgrammingLanguage:calculateDamage(skill)
    local ts = TYPE_STATS[skill.skillType]
    local atkStat = ts and self.attributes[ts.attack] or 0
    return math.floor(skill.baseDamage + (atkStat or 0) * 0.5)
end

function ProgrammingLanguage:addSkill(skill)
    table.insert(self.skills, skill)
    if #self.currentSkills < MAX_CURRENT_SKILLS then
        table.insert(self.currentSkills, skill)
    end
end

function ProgrammingLanguage:swapCurrentSkill(slotIndex, poolIndex)
    assert(slotIndex >= 1 and slotIndex <= MAX_CURRENT_SKILLS, "invalid slot")
    assert(poolIndex >= 1 and poolIndex <= #self.skills, "invalid pool index")
    self.currentSkills[slotIndex] = self.skills[poolIndex]
end

function ProgrammingLanguage:removeCurrentSkill(slotIndex)
    assert(slotIndex >= 1 and slotIndex <= #self.currentSkills, "invalid slot")
    table.remove(self.currentSkills, slotIndex)
end

function ProgrammingLanguage:addPassive(passive)
    table.insert(self.passiveAbilities, passive)
end

function ProgrammingLanguage:removePassive(id)
    for i, p in ipairs(self.passiveAbilities) do
        if p.id == id then
            table.remove(self.passiveAbilities, i)
            return true
        end
    end
    return false
end

function ProgrammingLanguage:getPassivesByTrigger(trigger)
    local result = {}
    for _, p in ipairs(self.passiveAbilities) do
        if p.trigger == trigger then
            table.insert(result, p)
        end
    end
    return result
end

function ProgrammingLanguage:addAttributeBonus(bonuses)
    for stat, delta in pairs(bonuses) do
        if self.attributes[stat] ~= nil then
            self.attributes[stat] = self.attributes[stat] + delta
            if stat == "hp" then
                self.attributes.maxHp = self.attributes.maxHp + delta
            end
        end
    end
end

function ProgrammingLanguage:equipItem(item)
    if #self.equippedItems >= self.maxEquippedItems then
        return nil, "language_items_full"
    end
    table.insert(self.equippedItems, item)
    return true, "language_item_equipped"
end

function ProgrammingLanguage:unequipItem(index)
    assert(index >= 1 and index <= #self.equippedItems, "invalid item index")
    table.remove(self.equippedItems, index)
end

function ProgrammingLanguage:addExp(amount)
    assert(type(amount) == "number" and amount > 0, "amount must be positive")
    if not self.levelTree then return false, nil end

    self.exp = self.exp + amount
    local nextNode = self.levelTree:getNextLevel(self.level)

    if nextNode and self.exp >= nextNode.expRequired then
        self.exp = self.exp - nextNode.expRequired
        self.level = self.level + 1

        if nextNode.attributeBonus then
            self:addAttributeBonus(nextNode.attributeBonus)
        end

        print("[ProgrammingLanguage] " .. self.language_name .. " leveled up to " .. self.level)
        return true, nextNode
    end

    return false, nil
end

function ProgrammingLanguage:applyUpgrade(upgradeIndex)
    if not self.levelTree then return nil, "no_level_tree" end

    local node = self.levelTree:getLevel(self.level)
    if not node or not node.upgrades[upgradeIndex] then
        return nil, "invalid_upgrade"
    end

    local upgrade = node.upgrades[upgradeIndex]
    for _, id in ipairs(self.chosenUpgrades) do
        if id == upgrade.id then
            return nil, "upgrade_already_chosen"
        end
    end

    upgrade:apply(self)
    return true, "upgrade_applied"
end

return ProgrammingLanguage
