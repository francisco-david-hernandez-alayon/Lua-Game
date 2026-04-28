-- core/programming_languages/programming_language.lua
--
-- A programming language entity used in progression and battle.
--
-- BASE ATTRIBUTES (persist between battles):
--   language_name:    display string
--   languageTypes:    list of LanguageTypes
--   attributes:       permanent stat table:
--     hp
--     speed
--     atk_backend     / def_backend
--     atk_frontend    / def_frontend
--     atk_system      / def_system
--     atk_mobile      / def_mobile
--     atk_scripting   / def_scripting
--     atk_ai          / def_ai
--     atk_game        / def_game
--     atk_scientific  / def_scientific
--
-- BATTLE ATTRIBUTES (reset every battle):
--   currentBattle.currentHp
--   currentBattle.currentSpeed
--   currentBattle.currentAttributes
--
-- PROGRESSION:
--   level, exp, levelTree
--   chosenUpgrades
--   specialization
--
-- SKILLS & PASSIVES:
--   skills
--   currentSkills
--   passiveAbilities
--
-- ITEMS:
--   equippedItems
--   maxEquippedItems

local LevelTree = require("core.programming_languages.level_tree")
local LanguageTypes = require("core.programming_languages.language_types")
local IdGenerator = require("utils.id_generator")

local MAX_CURRENT_SKILLS = 4
local DEFAULT_MAX_ITEMS = 2

-- Which attack/defense stats belong to each type.
local TYPE_STATS = {
    [LanguageTypes.BACKEND] = { attack = "atk_backend", defense = "def_backend" },
    [LanguageTypes.FRONTEND] = { attack = "atk_frontend", defense = "def_frontend" },
    [LanguageTypes.SYSTEM] = { attack = "atk_system", defense = "def_system" },
    [LanguageTypes.MOBILE] = { attack = "atk_mobile", defense = "def_mobile" },
    [LanguageTypes.SCRIPTING] = { attack = "atk_scripting", defense = "def_scripting" },
    [LanguageTypes.AI] = { attack = "atk_ai", defense = "def_ai" },
    [LanguageTypes.GAME] = { attack = "atk_game", defense = "def_game" },
    [LanguageTypes.SCIENTIFIC] = { attack = "atk_scientific", defense = "def_scientific" },
}

local ProgrammingLanguage = {}
ProgrammingLanguage.__index = ProgrammingLanguage
ProgrammingLanguage.TYPE_STATS = TYPE_STATS

-- Returns a full stat table with all supported type stats.
local function createEmptyAttributes(hp, speed)
    return {
        hp = hp,
        speed = speed,

        atk_backend = nil,
        def_backend = nil,

        atk_frontend = nil,
        def_frontend = nil,

        atk_system = nil,
        def_system = nil,

        atk_mobile = nil,
        def_mobile = nil,

        atk_scripting = nil,
        def_scripting = nil,

        atk_ai = nil,
        def_ai = nil,

        atk_game = nil,
        def_game = nil,

        atk_scientific = nil,
        def_scientific = nil,
    }
end

-- Builds the permanent attribute table for a language with one or more types.
local function buildAttributes(languageTypes, hp, speed, typeAttributes)
    local attrs = createEmptyAttributes(hp, speed)

    for _, languageType in ipairs(languageTypes) do
        local ts = TYPE_STATS[languageType]
        local typeData = typeAttributes and typeAttributes[languageType]

        if ts and typeData then
            attrs[ts.attack] = typeData.attack
            attrs[ts.defense] = typeData.defense
        end
    end

    return attrs
end

-- Creates the battle snapshot from the permanent attributes.
local function buildCurrentBattle(attributes)
    local currentAttributes = {}

    for key, value in pairs(attributes) do
        currentAttributes[key] = value
    end

    return {
        currentHp = attributes.hp,
        currentSpeed = attributes.speed,
        currentAttributes = currentAttributes,
    }
end

local function isValidLanguageTypes(languageTypes)
    if type(languageTypes) ~= "table" or #languageTypes == 0 then
        return false
    end

    for _, languageType in ipairs(languageTypes) do
        if not TYPE_STATS[languageType] then
            return false
        end
    end

    return true
end


function ProgrammingLanguage.new(data)
    assert(type(data.language_name) == "string", "language_name must be a string")
    assert(isValidLanguageTypes(data.languageTypes), "languageTypes must be a non-empty list of valid LanguageTypes")
    assert(type(data.hp) == "number", "hp must be a number")
    assert(type(data.speed) == "number", "speed must be a number")
    assert(type(data.typeAttributes) == "table", "typeAttributes must be a table")
    assert(data.levelTree == nil or data.levelTree.levels, "levelTree must be a LevelTree or nil")

    local baseAttributes = buildAttributes(
        data.languageTypes,
        data.hp,
        data.speed,
        data.typeAttributes
    )


    local self = setmetatable({
        -- Identity
        language_id = IdGenerator.uuid(),
        language_name = data.language_name,
        languageTypes = data.languageTypes,

        -- Permanent stats
        attributes = baseAttributes,

        -- Battle-only stats
        currentBattle = buildCurrentBattle(baseAttributes),

        -- Progression
        level = data.level or 1,
        exp = data.exp or 0,
        levelTree = data.levelTree or nil,
        chosenUpgrades = {},
        specialization = nil,

        -- Skills
        skills = {},
        currentSkills = {},

        -- Passives
        passiveAbilities = {},

        -- Items
        equippedItems = {},
        maxEquippedItems = data.maxEquippedItems or DEFAULT_MAX_ITEMS,
    }, ProgrammingLanguage)

    -- Initial current skills
    if data.skills then
        for _, skill in ipairs(data.skills) do
            self:addSkill(skill)
        end
    end

    return self
end

function ProgrammingLanguage:resetBattleState()
    self.currentBattle = buildCurrentBattle(self.attributes)
end

function ProgrammingLanguage:isActive()
    return self.currentBattle.currentHp > 0
end

function ProgrammingLanguage:isObsolete()
    return self.currentBattle.currentHp <= 0
end

function ProgrammingLanguage:setObsolete()
    self.currentBattle.currentHp = 0
    print("[ProgrammingLanguage] " .. self.language_name .. " is OBSOLETE")
end

-- Returns the current battle attack stat for a given type.
function ProgrammingLanguage:getCurrentTypeAttack(languageType)
    local ts = TYPE_STATS[languageType]
    if not ts then
        return 0
    end
    return self.currentBattle.currentAttributes[ts.attack] or 0
end

-- Returns the average current battle defense across all available defense stats.
function ProgrammingLanguage:getCurrentAverageDefense()
    local totalDefense = 0
    local defenseCount = 0

    for _, typeStats in pairs(TYPE_STATS) do
        local defenseValue = self.currentBattle.currentAttributes[typeStats.defense]
        if defenseValue ~= nil then
            totalDefense = totalDefense + defenseValue
            defenseCount = defenseCount + 1
        end
    end

    if defenseCount == 0 then
        return 0
    end

    return totalDefense / defenseCount
end


-- Takes damage using the average current battle defense.
-- Returns actual damage dealt.
function ProgrammingLanguage:takeDamage(amount)
    print("DEBUG TAKE DAMAGE: " .. amount)
    local averageDefense = self:getCurrentAverageDefense()
    local actual = math.max(1, math.floor(amount - averageDefense * 0.5))

    self.currentBattle.currentHp = math.max(0, self.currentBattle.currentHp - actual)
    return actual
end


-- Calculates damage using current battle attack values.
function ProgrammingLanguage:calculateDamage(skill)
    local atkStat = self:getCurrentTypeAttack(skill.skillType)
    return math.floor(skill.damage + atkStat * 0.5)
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

-- Applies permanent attribute bonuses.
function ProgrammingLanguage:addAttributeBonus(bonuses)
    for stat, delta in pairs(bonuses) do
        if self.attributes[stat] ~= nil then
            self.attributes[stat] = self.attributes[stat] + delta
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
    if not self.levelTree then
        return false, nil
    end

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
    if not self.levelTree then
        return nil, "no_level_tree"
    end

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
