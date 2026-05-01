-- core/battle/battle_controller.lua
--
-- Manages a turn-based battle between player and enemy programmer.
--
-- FLOW PER TURN:
--   1. Player picks action (attack or change language)
--   2. If change: swap language first, enemy attacks new language, restart turn
--   3. If attack: resolve turn order by speed
--   4. Each attacker resolves independently — player confirms messages before next attacker goes
--   5. Check for obsolete languages — force language pick if needed
--   6. Check win/lose condition
--
-- RESOLVING PHASES (step-by-step for future animation hooks):
--   RESOLVING_FIRST  — first attacker's skill is being shown (messages pending)
--   RESOLVING_SECOND — second attacker's skill queued, waiting for first messages to clear
--   After RESOLVING_SECOND messages clear → back to PLAYER_ACTION or PICK_LANGUAGE

local BattleAI = require("core.battle.battle_ai")
local LanguageEffectiveness = require("utils.language_effectiveness")

local BattleController = {}
BattleController.__index = BattleController

local PHASE = {
    PICK_LANGUAGE    = "pick_language",
    PLAYER_ACTION    = "player_action",
    PICK_SWAP        = "pick_swap",
    RESOLVING_FIRST  = "resolving_first",   -- first attacker hit, messages pending
    RESOLVING_SECOND = "resolving_second",  -- second attacker queued, messages pending
    BATTLE_OVER      = "battle_over",
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

        -- Pending skills for the two-step resolution
        pendingPlayerSkill = nil,
        pendingEnemySkill  = nil,
        -- Whether player goes first this turn
        _playerFirst = true,
        -- Whether the second attacker is still alive to act
        _secondPending = false,

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


-- ACTIVE LANGUAGES
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


-- LANGUAGE SWAP
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


-- ATTACK RESOLUTION (step-by-step)
--
-- Step 1  playerAttack()         — store skills, determine order, fire first attacker
-- Step 2  advanceResolution()    — called by battle.lua when last message is popped
--           • if RESOLVING_FIRST and second is pending → fire second attacker
--           • if RESOLVING_SECOND (or first was last) → close turn

function BattleController:playerAttack(skill)
    self.pendingPlayerSkill = skill
    self.pendingEnemySkill  = BattleAI.chooseAttack(self.currentEnemyLanguage)

    -- Determine speed order
    local playerSpeed = self.currentPlayerLanguage.currentBattle.currentSpeed
    local enemySpeed  = self.currentEnemyLanguage and
                        self.currentEnemyLanguage.currentBattle.currentSpeed or 0
    self._playerFirst = (playerSpeed >= enemySpeed)

    -- Fire first attacker
    if self._playerFirst then
        self:_resolveFirstStep(
            self.currentPlayerLanguage,
            self.currentEnemyLanguage,
            self.pendingPlayerSkill
        )
    else
        self:_resolveFirstStep(
            self.currentEnemyLanguage,
            self.currentPlayerLanguage,
            self.pendingEnemySkill
        )
    end
end

-- Internal: apply first attacker, set phase to RESOLVING_FIRST, mark if second is possible.
function BattleController:_resolveFirstStep(attacker, defender, skill)
    self:applySkill(attacker, defender, skill)

    -- Did the defender die? Second attacker may still be alive.
    -- We always check second step in advanceResolution; just store whether it can act.
    self._secondPending = true
    self.phase = PHASE.RESOLVING_FIRST
end

-- Called by battle.lua after the player pops the last message.
function BattleController:advanceResolution()
    if self.phase == PHASE.RESOLVING_FIRST then
        -- Check win before second attacker goes
        if self:checkWinCondition() then
            -- Messages about battle_over are now in queue; phase is BATTLE_OVER
            return
        end

        if self._secondPending then
            self._secondPending = false

            local secondAttacker, secondDefender, secondSkill

            if self._playerFirst then
                -- Enemy is second; skip if enemy is dead
                if not self.currentEnemyLanguage or self.currentEnemyLanguage:isObsolete() then
                    self:_closeTurn()
                    return
                end
                secondAttacker = self.currentEnemyLanguage
                secondDefender = self.currentPlayerLanguage
                secondSkill    = self.pendingEnemySkill
            else
                -- Player is second; skip if player is dead
                if self.currentPlayerLanguage:isObsolete() then
                    self:_closeTurn()
                    return
                end
                secondAttacker = self.currentPlayerLanguage
                secondDefender = self.currentEnemyLanguage
                secondSkill    = self.pendingPlayerSkill
            end

            self:applySkill(secondAttacker, secondDefender, secondSkill)
            self.phase = PHASE.RESOLVING_SECOND
            -- battle.lua will call advanceResolution again when these messages clear
        else
            self:_closeTurn()
        end

    elseif self.phase == PHASE.RESOLVING_SECOND then
        self:_closeTurn()
    end
end

-- Internal: wrap up the turn after all attacks are done.
function BattleController:_closeTurn()
    if self:checkWinCondition() then return end

    -- Handle enemy replacement if it went obsolete during player's attack
    if self.currentEnemyLanguage and self.currentEnemyLanguage:isObsolete() then
        self:log(self.currentEnemyLanguage.language_name .. " is OBSOLETE")
        if self:checkWinCondition() then return end

        self.currentEnemyLanguage = BattleAI.chooseLanguage(self.enemyLanguages)
        if self.currentEnemyLanguage then
            self:pushMessage(self.programmerName .. " sent out " .. self.currentEnemyLanguage.language_name)
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


-- SKILL APPLICATION
function BattleController:applySkill(attacker, defender, skill)
    for _, p in ipairs(attacker:getPassivesByTrigger("before_attack")) do
        p:apply(self, attacker)
    end

    for _, p in ipairs(defender:getPassivesByTrigger("before_receive")) do
        p:apply(self, defender)
    end

    -- Accuracy check
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

    -- Attack effect
    if skill:hasCategory("attack") and skill.damage then
        local damage = attacker:calculateDamage(skill)
        local multiplier, effectId = LanguageEffectiveness.getMultiplierAndEffectId(defender, skill)
        local finalDamage = math.max(1, math.floor(damage * multiplier))
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

    -- Heal effect
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

    -- Attribute effect
    if skill:hasCategory("attribute_effect") and skill.modifiedAttributes then
        for attributeName, delta in pairs(skill.modifiedAttributes) do
            if attacker.currentBattle.currentAttributes[attributeName] ~= nil then
                attacker.currentBattle.currentAttributes[attributeName] =
                    attacker.currentBattle.currentAttributes[attributeName] + delta
            end
        end

        local modifiedAttributes = ""
        for atributeName, atributeValue in pairs(skill.modifiedAttributes) do
            modifiedAttributes = modifiedAttributes .. atributeName .. " in " .. tostring(atributeValue) .. " "
        end

        self:pushMessage(
            attacker.language_name ..
            " used " .. skill.nameKey ..
            " and modified " .. modifiedAttributes
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