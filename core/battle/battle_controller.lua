-- core/battle/battle_controller.lua
--
-- Manages a turn-based battle between player and enemy programmer.
--
-- TURN FLOW:
--   1. Player picks action (attack or swap)
--   2. If swap: enemy counter-attacks immediately, restart turn
--   3. If attack: determine speed order
--   4. First attacker fires:
--        a. If skill has animation → phase = ANIMATING (battle.lua drives update/draw)
--        b. Once animation finishes (or no animation) → applySkillEffect() (damage etc.)
--        c. Push result messages → phase = RESOLVING_FIRST
--   5. Player clears messages → advanceResolution()
--        a. Second attacker fires (same animation gate as above)
--        b. Messages pushed → phase = RESOLVING_SECOND
--   6. Player clears messages → advanceResolution() → _closeTurn()
--
-- PHASES:
--   PICK_LANGUAGE    — player must pick a live language
--   PLAYER_ACTION    — player chooses attack / swap
--   RESOLVING_FIRST  — first attacker's messages pending
--   ANIMATING        — an animation is playing; input fully blocked
--   RESOLVING_SECOND — second attacker's messages pending
--   BATTLE_OVER      — battle finished

local BattleAI              = require("core.battle.battle_ai")
local LanguageEffectiveness = require("utils.language_effectiveness")

local BattleController = {}
BattleController.__index = BattleController

local PHASE = {
    PICK_LANGUAGE    = "pick_language",
    PLAYER_ACTION    = "player_action",
    RESOLVING_FIRST  = "resolving_first",
    ANIMATING        = "animating",
    RESOLVING_SECOND = "resolving_second",
    BATTLE_OVER      = "battle_over",
}
BattleController.PHASE = PHASE

function BattleController.new(battle)
    assert(battle,                                   "battle is required")
    assert(type(battle.programmerName) == "string",  "battle.programmerName must be a string")
    assert(#battle.playerLanguages >= 1,             "player must have at least 1 language")
    assert(#battle.enemyLanguages   >= 1,            "enemy must have at least 1 language")

    local self = setmetatable({
        battle          = battle,
        programmerName  = battle.programmerName,
        playerLanguages = battle.playerLanguages,
        enemyLanguages  = battle.enemyLanguages,
        currentPlayerLanguage = nil,
        currentEnemyLanguage  = nil,
        phase = PHASE.PICK_LANGUAGE,

        pendingPlayerSkill = nil,
        pendingEnemySkill  = nil,
        _playerFirst       = true,
        _secondPending     = false,

        -- Animation gate
        -- When a skill with animation fires, we park everything here.
        -- battle.lua polls bc.phase == ANIMATING, drives update/draw,
        -- then calls bc:animationFinished() when the animation ends.
        _animatingSkill    = nil,   -- Skill currently animating
        _animatingAttacker = nil,
        _animatingDefender = nil,
        _animatingStep     = nil,   -- "first" | "second" | "swap"

        winner       = nil,
        battleLog    = {},
        messageQueue = {},
    }, BattleController)

    self.currentEnemyLanguage = BattleAI.chooseLanguage(self.enemyLanguages)
    return self
end


function BattleController:finish(sm)
    assert(sm, "state manager is required")
    sm.switch(self.battle.returnState)
end


-- LOG AND MESSAGES
function BattleController:log(msg)
    table.insert(self.battleLog, msg)
    print("[Battle] " .. msg)
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


-- ACTIVE LANGUAGES
function BattleController:getActivePlayerLanguages()
    local active = {}
    for _, lang in ipairs(self.playerLanguages) do
        if lang:isActive() then table.insert(active, lang) end
    end
    return active
end

function BattleController:getActiveEnemyLanguages()
    local active = {}
    for _, lang in ipairs(self.enemyLanguages) do
        if lang:isActive() then table.insert(active, lang) end
    end
    return active
end


-- WIN CONDITION
function BattleController:checkWinCondition()
    if #self:getActivePlayerLanguages() == 0 then
        self.winner = "enemy"
        self.phase  = PHASE.BATTLE_OVER
        self:log(self.programmerName .. " wins! All player languages are obsolete.")
        return true
    end
    if #self:getActiveEnemyLanguages() == 0 then
        self.winner = "player"
        self.phase  = PHASE.BATTLE_OVER
        self:log("Player wins! All enemy languages are obsolete.")
        return true
    end
    return false
end


-- PROGRAMMING LANGUAGE MANAGEMENT
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
        -- Swap counter-attack: fire with step="swap" so _afterSkillMessages
        -- does NOT touch the resolution phase (playerSwapLanguage handles it).
        self:_fireSkill(
            self.currentEnemyLanguage,
            self.currentPlayerLanguage,
            enemySkill,
            "swap"
        )
    end

    -- If an animation was queued the phase is now ANIMATING.
    -- playerSwapLanguage returns; battle.lua will call animationFinished()
    -- which will call _afterSkillMessages("swap") — no-op for phase —
    -- then the swap messages appear.  The caller (battle.lua keypressed) must
    -- NOT set phase itself when ANIMATING; we handle it in animationFinished.
    if self.phase == PHASE.ANIMATING then
        -- Tell _afterSwap what to do once animation ends
        self._postSwapObsolete = self.currentPlayerLanguage
        return
    end

    self:_resolveSwapResult()
end

-- Finish the swap turn after any animation/messages are done.
function BattleController:_resolveSwapResult()
    if self:checkWinCondition() then return end
    if self.currentPlayerLanguage:isObsolete() then
        self.phase = PHASE.PICK_LANGUAGE
    else
        self.phase = PHASE.PLAYER_ACTION
    end
end


-- ATTACK RESOLUTION
function BattleController:playerAttack(skill)
    self.pendingPlayerSkill = skill
    self.pendingEnemySkill  = BattleAI.chooseAttack(self.currentEnemyLanguage)

    local playerSpeed = self.currentPlayerLanguage.currentBattle.currentSpeed
    local enemySpeed  = self.currentEnemyLanguage
                        and self.currentEnemyLanguage.currentBattle.currentSpeed or 0
    self._playerFirst = (playerSpeed >= enemySpeed)

    if self._playerFirst then
        self:_fireSkill(
            self.currentPlayerLanguage,
            self.currentEnemyLanguage,
            self.pendingPlayerSkill,
            "first"
        )
    else
        self:_fireSkill(
            self.currentEnemyLanguage,
            self.currentPlayerLanguage,
            self.pendingEnemySkill,
            "first"
        )
    end
end

-- Called by battle.lua when the message queue empties mid-resolution.
function BattleController:advanceResolution()
    if self.phase == PHASE.RESOLVING_FIRST then
        if self:checkWinCondition() then return end

        local secondAttacker, secondDefender, secondSkill

        if self._playerFirst then
            if not self.currentEnemyLanguage or self.currentEnemyLanguage:isObsolete() then
                self:_closeTurn(); return
            end
            secondAttacker = self.currentEnemyLanguage
            secondDefender = self.currentPlayerLanguage
            secondSkill    = self.pendingEnemySkill
        else
            if self.currentPlayerLanguage:isObsolete() then
                self:_closeTurn(); return
            end
            secondAttacker = self.currentPlayerLanguage
            secondDefender = self.currentEnemyLanguage
            secondSkill    = self.pendingPlayerSkill
        end

        self:_fireSkill(secondAttacker, secondDefender, secondSkill, "second")

    elseif self.phase == PHASE.RESOLVING_SECOND then
        self:_closeTurn()
    end
end

function BattleController:_closeTurn()
    if self:checkWinCondition() then return end

    if self.currentEnemyLanguage and self.currentEnemyLanguage:isObsolete() then
        self:log(self.currentEnemyLanguage.language_name .. " is OBSOLETE")
        if self:checkWinCondition() then return end

        self.currentEnemyLanguage = BattleAI.chooseLanguage(self.enemyLanguages)
        if self.currentEnemyLanguage then
            self:pushMessage(self.programmerName .. " sent out " ..
                             self.currentEnemyLanguage.language_name)
        end
    end

    if self.currentPlayerLanguage:isObsolete() then
        self:log(self.currentPlayerLanguage.language_name .. " is OBSOLETE")
        self.phase = PHASE.PICK_LANGUAGE
    else
        self.phase = PHASE.PLAYER_ACTION
    end

    self.pendingPlayerSkill = nil
    self.pendingEnemySkill  = nil
end


-- ANIMATION GATE

-- Decide whether to animate or apply immediately.
-- step = "first" | "second" | "swap"
function BattleController:_fireSkill(attacker, defender, skill, step)
    -- Passives before
    for _, p in ipairs(attacker:getPassivesByTrigger("before_attack")) do
        p:apply(self, attacker)
    end
    for _, p in ipairs(defender:getPassivesByTrigger("before_receive")) do
        p:apply(self, defender)
    end

    -- Accuracy check (evaluated before animation so we don't play on a miss)
    if skill.accuracy and math.random(100) > skill.accuracy then
        self:pushMessage(
            attacker.language_name .. " used " .. skill.nameKey ..
            " but it missed " .. defender.language_name
        )
        self:_afterSkillMessages(step)
        return
    end

    if skill:hasAnimation() then
        -- Park state; battle.lua will call animationFinished() when done.
        -- battle.lua is also responsible for calling
        --   skill.animation:play(attackerPos, defenderPos)
        -- because only the UI knows screen coordinates.
        self._animatingSkill    = skill
        self._animatingAttacker = attacker
        self._animatingDefender = defender
        self._animatingStep     = step
        self.phase              = PHASE.ANIMATING
    else
        self:applySkillEffect(attacker, defender, skill)
        self:_afterSkillMessages(step)
    end
end

-- Called by battle.lua once the currently playing animation has finished.
function BattleController:animationFinished()
    local skill    = self._animatingSkill
    local attacker = self._animatingAttacker
    local defender = self._animatingDefender
    local step     = self._animatingStep

    self._animatingSkill    = nil
    self._animatingAttacker = nil
    self._animatingDefender = nil
    self._animatingStep     = nil

    self:applySkillEffect(attacker, defender, skill)
    self:_afterSkillMessages(step)

    -- Special case: swap counter-attack finished
    if step == "swap" then
        self:_resolveSwapResult()
    end
end

-- Set resolution phase after messages are queued for a skill.
function BattleController:_afterSkillMessages(step)
    if step == "first" then
        self._secondPending = true
        self.phase = PHASE.RESOLVING_FIRST
    elseif step == "second" then
        self.phase = PHASE.RESOLVING_SECOND
    end
    -- "swap": phase managed by playerSwapLanguage / animationFinished
end


-- SKILL EFFECT APPLICATION
-- Pure stat changes + message pushes. No phase logic here.
function BattleController:applySkillEffect(attacker, defender, skill)
    local didSomething = false

    -- Attack
    if skill:hasCategory("attack") and skill.damage then
        local damage    = attacker:calculateDamage(skill)
        local mult, eid = LanguageEffectiveness.getMultiplierAndEffectId(defender, skill)
        local final     = math.max(1, math.floor(damage * mult))
        local actual    = defender:takeDamage(final)

        self:pushMessage(
            attacker.language_name .. " used " .. skill.nameKey ..
            " with " .. actual .. " damage to " .. defender.language_name
        )
        if eid ~= "neutral" then self:pushMessage(eid) end
        if defender:isObsolete() then
            self:pushMessage(defender.language_name .. " is OBSOLETE")
        end
        didSomething = true
    end

    -- Heal
    if skill:hasCategory("heal") and skill.heal then
        local oldHp = attacker.currentBattle.currentHp
        attacker.currentBattle.currentHp = math.min(
            attacker.attributes.hp,
            oldHp + skill.heal
        )
        local healed = attacker.currentBattle.currentHp - oldHp
        self:pushMessage(
            attacker.language_name .. " used " .. skill.nameKey ..
            " and healed " .. healed .. " HP"
        )
        didSomething = true
    end

    -- Attribute effect
    if skill:hasCategory("attribute_effect") and skill.modifiedAttributes then
        for attr, delta in pairs(skill.modifiedAttributes) do
            if attacker.currentBattle.currentAttributes[attr] ~= nil then
                attacker.currentBattle.currentAttributes[attr] =
                    attacker.currentBattle.currentAttributes[attr] + delta
            end
        end
        self:pushMessage(
            attacker.language_name .. " used " .. skill.nameKey ..
            " and modified current attributes"
        )
        didSomething = true
    end

    if not didSomething then
        self:pushMessage(
            attacker.language_name .. " used " .. skill.nameKey ..
            " but nothing happened"
        )
    end

    -- Passives after
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