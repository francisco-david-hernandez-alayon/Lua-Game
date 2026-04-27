-- core/battle/battle_controller.lua
--
-- Manages a turn-based battle between player and enemy programmer.
--
-- FLOW PER TURN:
--   1. Player picks action (attack or change language)
--   2. If change: swap language first, enemy attacks new language, restart turn
--   3. If attack: player attacks, then enemy attacks
--   4. Check for obsolete languages — force language pick if needed
--   5. Check win/lose condition

local BattleAI = require("core.battle.battle_ai")

local BattleController = {}
BattleController.__index = BattleController

local PHASE = {
    PICK_LANGUAGE  = "pick_language",   -- forced pick when current is obsolete
    PLAYER_ACTION  = "player_action",   -- player chooses attack or swap
    PICK_SWAP      = "pick_swap",       -- player choosing which language to swap to
    RESOLVING      = "resolving",       -- attacks being resolved
    BATTLE_OVER    = "battle_over",
}
BattleController.PHASE = PHASE

function BattleController.new(programmerName, playerLanguages, enemyLanguages)
    assert(type(programmerName) == "string", "programmerName must be a string")
    assert(#playerLanguages >= 1, "player must have at least 1 language")
    assert(#enemyLanguages  >= 1, "enemy must have at least 1 language")

    local self = setmetatable({
        programmerName          = programmerName,
        playerLanguages         = playerLanguages,
        enemyLanguages          = enemyLanguages,
        currentPlayerLanguage   = nil,
        currentEnemyLanguage    = nil,
        phase                   = PHASE.PICK_LANGUAGE,
        pendingPlayerSkill     = nil,
        pendingEnemySkill      = nil,
        winner                  = nil,   -- "player" | "enemy" | nil
        battleLog               = {},    -- list of strings for the info box
        messageQueue = {},
    }, BattleController)

    -- Enemy picks starting language via AI
    self.currentEnemyLanguage = BattleAI.chooseLanguage(enemyLanguages)

    return self
end

-- Add a message to the battle log
function BattleController:log(msg)
    table.insert(self.battleLog, msg)
    print("[Battle] " .. msg)
end

function BattleController:getLastLog()
    return self.battleLog[#self.battleLog]
end

-- Returns list of active player languages
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

-- Check if someone has won
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

-- Called when player picks their starting/replacement language
function BattleController:changeCurrentPlayerLanguage(language)
    assert(language:isActive(), "cannot select an obsolete language")
    self.currentPlayerLanguage = language
    self:log("Player sent out " .. language.language_name)
    self.phase = PHASE.PLAYER_ACTION
end

-- Player chose to swap language mid-battle
function BattleController:playerSwapLanguage(language)
    assert(language:isActive(), "cannot select an obsolete language")
    self.currentPlayerLanguage = language
    self:log("Player swapped to " .. language.language_name)

    -- Enemy attacks the new language immediately
    local enemySkill = BattleAI.chooseAttack(self.currentEnemyLanguage)
    if enemySkill then
        self.currentPlayerLanguage:takeDamage(enemySkill.baseDamage)
        self:log(self.currentEnemyLanguage.language_name ..
            " used " .. enemySkill.nameKey ..
            " → " .. enemySkill.baseDamage .. " damage to " ..
            self.currentPlayerLanguage.language_name)
    end

    if self:checkWinCondition() then return end

    -- If new language is now obsolete, force pick again
    if self.currentPlayerLanguage:isObsolete() then
        self.phase = PHASE.PICK_LANGUAGE
    else
        self.phase = PHASE.PLAYER_ACTION
    end
end

-- Player chose an attack
function BattleController:playerAttack(attack)
    self.pendingPlayerSkill = attack
    self.pendingEnemySkill  = BattleAI.chooseAttack(self.currentEnemyLanguage)
    self.phase = PHASE.RESOLVING
    self:resolveAttacks()
end

-- Resolve both attacks
function BattleController:resolveAttacks()
    -- Player attacks first
    if self.pendingPlayerSkill then
        self.currentEnemyLanguage:takeDamage(self.pendingPlayerSkill.baseDamage)
        self:log(self.currentPlayerLanguage.language_name ..
            " used " .. self.pendingPlayerSkill.nameKey ..
            " → " .. self.pendingPlayerSkill.baseDamage .. " damage to " ..
            self.currentEnemyLanguage.language_name)
    end

    -- Check if enemy language is obsolete, swap if possible
    if self.currentEnemyLanguage:isObsolete() then
        self:log(self.currentEnemyLanguage.language_name .. " is OBSOLETE")
        if self:checkWinCondition() then return end
        self.currentEnemyLanguage = BattleAI.chooseLanguage(self.enemyLanguages)
        if self.currentEnemyLanguage then
            self:log(self.programmerName .. " sent out " .. self.currentEnemyLanguage.language_name)
        end
    end

    -- Enemy attacks
    if self.pendingEnemySkill and self.currentEnemyLanguage then
        self.currentPlayerLanguage:takeDamage(self.pendingEnemySkill.baseDamage)
        self:log(self.currentEnemyLanguage.language_name ..
            " used " .. self.pendingEnemySkill.nameKey ..
            " → " .. self.pendingEnemySkill.baseDamage .. " damage to " ..
            self.currentPlayerLanguage.language_name)
    end

    if self:checkWinCondition() then return end

    -- If player language is obsolete, force pick
    if self.currentPlayerLanguage:isObsolete() then
        self:log(self.currentPlayerLanguage.language_name .. " is OBSOLETE")
        self.phase = PHASE.PICK_LANGUAGE
    else
        self.phase = PHASE.PLAYER_ACTION
    end

    self.pendingPlayerSkill = nil
    self.pendingEnemySkill  = nil
end



function BattleController:pushMessage(msg)
    table.insert(self.messageQueue, msg)
end

function BattleController:popMessage()
    if #self.messageQueue == 0 then return nil end
    return table.remove(self.messageQueue, 1)
end

function BattleController:hasMessages()
    return #self.messageQueue > 0
end

-- Apply a skill attack from attacker to defender, triggering passives
function BattleController:applySkill(attacker, defender, skill)
    -- Trigger attacker before_attack passives
    for _, p in ipairs(attacker:getPassivesByTrigger("before_attack")) do
        p:apply(self, attacker)
    end

    -- Trigger defender before_receive passives
    for _, p in ipairs(defender:getPassivesByTrigger("before_receive")) do
        p:apply(self, defender)
    end

    local damage = attacker:calculateDamage(skill)
    local actual = defender:takeDamage(damage, skill.skillType)

    self:pushMessage(attacker.language_name ..
        " used " .. skill.nameKey ..
        " → " .. actual .. " damage to " .. defender.language_name)

    if defender:isObsolete() then
        self:pushMessage(defender.language_name .. " is OBSOLETE")
    end

    -- Trigger attacker after_attack passives
    for _, p in ipairs(attacker:getPassivesByTrigger("after_attack")) do
        p:apply(self, attacker)
    end

    -- Trigger defender after_receive passives
    if not defender:isObsolete() then
        for _, p in ipairs(defender:getPassivesByTrigger("after_receive")) do
            p:apply(self, defender)
        end
    end
end

return BattleController