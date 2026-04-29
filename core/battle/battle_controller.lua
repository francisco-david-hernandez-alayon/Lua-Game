-- core/battle/battle_controller.lua
--
-- Manages a turn-based battle between player and enemy programmer.
--
-- FLOW PER TURN:
--   1. Player picks action (attack or change language)
--   2. If change: swap language first, enemy attacks new language, restart turn
--   3. If attack: resolve turn order by speed
--   4. Check for obsolete languages — force language pick if needed
--   5. Check win/lose condition

local BattleAI = require("core.battle.battle_ai")
local LanguageEffectiveness = require("utils.language_effectiveness")

local BattleController = {}
BattleController.__index = BattleController

local PHASE = {
    PICK_LANGUAGE  = "pick_language",
    PLAYER_ACTION  = "player_action",
    PICK_SWAP      = "pick_swap",
    RESOLVING      = "resolving",
    BATTLE_OVER    = "battle_over",
}
BattleController.PHASE = PHASE

function BattleController.new(battle)
    assert(battle, "battle is required")
    assert(type(battle.programmerName) == "string", "battle.programmerName must be a string")
    assert(#battle.playerLanguages >= 1, "player must have at least 1 language")
    assert(#battle.enemyLanguages >= 1, "enemy must have at least 1 language")

    local self = setmetatable({
        battle = battle,
        programmerName = battle.programmerName,
        playerLanguages = battle.playerLanguages,
        enemyLanguages = battle.enemyLanguages,
        currentPlayerLanguage = nil,
        currentEnemyLanguage = nil,
        phase = PHASE.PICK_LANGUAGE,
        pendingPlayerSkill = nil,
        pendingEnemySkill = nil,
        winner = nil,
        battleLog = {},
        messageQueue = {},
    }, BattleController)

    self.currentEnemyLanguage = BattleAI.chooseLanguage(self.enemyLanguages)

    return self
end


function BattleController:finish(sm)
    assert(sm, "state manager is required to finish battle in BattleController")
    sm.switch(self.battle.returnState)
end



-- BATTLE LOG
function BattleController:log(msg)
    table.insert(self.battleLog, msg)
    print("[Battle] " .. msg)
end

function BattleController:getLastLog()
    return self.battleLog[#self.battleLog]
end

function BattleController:pushMessage(msg)
    table.insert(self.messageQueue, msg)
    self:log(msg)
end

function BattleController:popMessage()
    if #self.messageQueue == 0 then return nil end
    return table.remove(self.messageQueue, 1)
end

function BattleController:hasMessages()
    return #self.messageQueue > 0
end

-- GET ACTIVE LANGUAGES
function BattleController:getActivePlayerLanguages()
    local active = {}
    for _, lang in ipairs(self.playerLanguages) do
        if lang:isActive() then
            table.insert(active, lang)
        end
    end
    return active
end

function BattleController:getActiveEnemyLanguages()
    local active = {}
    for _, lang in ipairs(self.enemyLanguages) do
        if lang:isActive() then
            table.insert(active, lang)
        end
    end
    return active
end

-- WIN CONDITION
function BattleController:checkWinCondition()
    if #self:getActivePlayerLanguages() == 0 then
        self.winner = "enemy"
        self.phase = PHASE.BATTLE_OVER
        self:log(self.programmerName .. " wins! All player languages are obsolete.")
        return true
    end

    if #self:getActiveEnemyLanguages() == 0 then
        self.winner = "player"
        self.phase = PHASE.BATTLE_OVER
        self:log("Player wins! All enemy languages are obsolete.")
        return true
    end

    return false
end

function BattleController:changeCurrentPlayerLanguage(language)
    assert(language:isActive(), "cannot select an obsolete language")
    self.currentPlayerLanguage = language
    self:log("Player sent out " .. language.language_name)
    self.phase = PHASE.PLAYER_ACTION
end

function BattleController:playerSwapLanguage(language)
    assert(language:isActive(), "cannot select an obsolete language")
    self.currentPlayerLanguage = language
    self:log("Player swapped to " .. language.language_name)

    local enemySkill = BattleAI.chooseAttack(self.currentEnemyLanguage)
    if enemySkill then
        self:applySkill(self.currentEnemyLanguage, self.currentPlayerLanguage, enemySkill)
    end

    if self:checkWinCondition() then return end

    if self.currentPlayerLanguage:isObsolete() then
        self.phase = PHASE.PICK_LANGUAGE
    else
        self.phase = PHASE.PLAYER_ACTION
    end
end

function BattleController:playerAttack(skill)
    self.pendingPlayerSkill = skill
    self.pendingEnemySkill = BattleAI.chooseAttack(self.currentEnemyLanguage)
    self.phase = PHASE.RESOLVING
    self:resolveAttacks()
end

function BattleController:resolveAttacks()
    local playerFirst = true

    if self.currentEnemyLanguage and self.currentPlayerLanguage then
        local playerSpeed = self.currentPlayerLanguage.currentBattle.currentSpeed
        local enemySpeed = self.currentEnemyLanguage.currentBattle.currentSpeed

        if enemySpeed > playerSpeed then
            playerFirst = false
        end
    end

    local function afterEnemyHit()
        if self.currentEnemyLanguage and self.currentEnemyLanguage:isObsolete() then
            self:log(self.currentEnemyLanguage.language_name .. " is OBSOLETE")
            if self:checkWinCondition() then return true end

            self.currentEnemyLanguage = BattleAI.chooseLanguage(self.enemyLanguages)
            if self.currentEnemyLanguage then
                self:log(self.programmerName .. " sent out " .. self.currentEnemyLanguage.language_name)
            end
        end
        return false
    end

    local function resolvePlayerSkill()
        if not self.pendingPlayerSkill or not self.currentEnemyLanguage then
            return false
        end

        self:applySkill(self.currentPlayerLanguage, self.currentEnemyLanguage, self.pendingPlayerSkill)
        return afterEnemyHit()
    end

    local function resolveEnemySkill()
        if not self.pendingEnemySkill or not self.currentEnemyLanguage then
            return false
        end

        self:applySkill(self.currentEnemyLanguage, self.currentPlayerLanguage, self.pendingEnemySkill)
        if self:checkWinCondition() then
            return true
        end

        return false
    end

    if playerFirst then
        if resolvePlayerSkill() then return end
        if resolveEnemySkill() then return end
    else
        if resolveEnemySkill() then return end
        if resolvePlayerSkill() then return end
    end

    if self:checkWinCondition() then return end

    if self.currentPlayerLanguage:isObsolete() then
        self:log(self.currentPlayerLanguage.language_name .. " is OBSOLETE")
        self.phase = PHASE.PICK_LANGUAGE
    else
        self.phase = PHASE.PLAYER_ACTION
    end

    self.pendingPlayerSkill = nil
    self.pendingEnemySkill = nil
end


-- SKILL
-- Applies a skill from attacker to defender, triggering passives.
function BattleController:applySkill(attacker, defender, skill)
    for _, p in ipairs(attacker:getPassivesByTrigger("before_attack")) do
        p:apply(self, attacker)
    end

    for _, p in ipairs(defender:getPassivesByTrigger("before_receive")) do
        p:apply(self, defender)
    end

    -- Accuracy check.
    if skill.accuracy and math.random(100) > skill.accuracy then
        self:pushMessage(
            attacker.language_name ..
            " used " .. skill.nameKey ..
            " but it missed " ..
            defender.language_name
        )
        return
    end

    local didSomething = false

    -- Attack effect.
    if skill:hasCategory("attack") and skill.damage then
        local damage = attacker:calculateDamage(skill)
        local multiplier, effectId = LanguageEffectiveness.getMultiplierAndEffectId(defender, skill)
        local finalDamage = math.max(1, math.floor(damage * multiplier)) -- 1 is to avoid 0 damage for rounding
        local actual = defender:takeDamage(finalDamage)

        self:pushMessage(
            attacker.language_name ..
            " used " .. skill.nameKey ..
            " with " .. actual .. " damage to " ..
            defender.language_name
        )

        if effectId ~= "neutral" then
            self:pushMessage(effectId)
        end

        if defender:isObsolete() then
            self:pushMessage(defender.language_name .. " is OBSOLETE")
        end

        didSomething = true
    end


    -- Heal effect.
    if skill:hasCategory("heal") and skill.heal then
        local oldHp = attacker.currentBattle.currentHp
        local maxHp = attacker.attributes.hp

        attacker.currentBattle.currentHp = math.min(
            maxHp,
            attacker.currentBattle.currentHp + skill.heal
        )

        local healed = attacker.currentBattle.currentHp - oldHp

        self:pushMessage(
            attacker.language_name ..
            " used " .. skill.nameKey ..
            " and healed " .. healed .. " HP"
        )

        didSomething = true
    end

    -- Attribute effect.
    if skill:hasCategory("attribute_effect") and skill.modifiedAttributes then
        for attributeName, delta in pairs(skill.modifiedAttributes) do
            if attacker.currentBattle.currentAttributes[attributeName] ~= nil then
                attacker.currentBattle.currentAttributes[attributeName] =
                    attacker.currentBattle.currentAttributes[attributeName] + delta
            end
        end

        self:pushMessage(
            attacker.language_name ..
            " used " .. skill.nameKey ..
            " and modified current attributes"
        )

        didSomething = true
    end

    if not didSomething then
        self:pushMessage(
            attacker.language_name ..
            " used " .. skill.nameKey ..
            " but nothing happened"
        )
    end

    for _, p in ipairs(attacker:getPassivesByTrigger("after_attack")) do
        p:apply(self, attacker)
    end

    if not defender:isObsolete() then
        for _, p in ipairs(defender:getPassivesByTrigger("after_receive")) do
            p:apply(self, defender)
        end
    end
end


return BattleController
