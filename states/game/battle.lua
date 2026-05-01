-- states/game/battle.lua
-- Handles input and state logic for the battle screen.

local L                = require("core.localization.localization")
local BattleController = require("core.battle.battle_controller")
local BattleUI         = require("ui.ui_battle")
local GetBattleBackgroundSprite = require("utils.sprites.get_battle_background_sprite")

local Battle = {}

local sm          = nil
local returnState = nil
local bc          = nil
local selected    = 1
local menuMode    = "action"

local PHASE = BattleController.PHASE


-- BACKGROUND INFO
local bgData = nil
local BG_PATH           = "assets/sprites/test/battle_bg_test.png"
local BG_FRAME_DURATION = 0.2


-- ACTIVE LANGUAGES
local function getPickable()
    local langs    = bc:getActivePlayerLanguages()
    local pickable = {}
    for _, lang in ipairs(langs) do
        if lang ~= bc.currentPlayerLanguage then
            table.insert(pickable, lang)
        end
    end
    return pickable
end

local function getSwappable()
    return getPickable()
end


function Battle.enter(stateManager, localization, battleController, targetReturnState)
    sm          = stateManager
    returnState = targetReturnState
    bc          = battleController
    selected    = 1
    menuMode    = "action"
end


-- INPUT
function Battle.keypressed(key)

    -- BATTLE OVER
    if bc.phase == PHASE.BATTLE_OVER then
        if key == "return" or key == "e" then
            for _, lang in ipairs(bc.playerLanguages) do
                lang:resetLanguageAfterBattle()
            end
            sm.switch(returnState)
        end
        return
    end

    -- MESSAGE QUEUE (blocks everything else)
    -- During RESOLVING_FIRST / RESOLVING_SECOND the player just advances logs.
    -- When the last message is popped we call advanceResolution() so the
    -- controller can fire the second attacker (or close the turn).
    if bc:hasMessages() then
        if key == "return" or key == "e" then
            bc:popMessage()

            -- If queue is now empty and we are mid-resolution, advance
            if not bc:hasMessages() then
                local p = bc.phase
                if p == PHASE.RESOLVING_FIRST or p == PHASE.RESOLVING_SECOND then
                    bc:advanceResolution()
                    -- advanceResolution may push new messages (second attacker)
                    -- or switch phase to PLAYER_ACTION / PICK_LANGUAGE / BATTLE_OVER
                end
            end
        end
        return
    end

    -- FORCE LANGUAGE PICK
    if bc.phase == PHASE.PICK_LANGUAGE then
        local pickable = getPickable()
        if key == "up"   then selected = math.max(1, selected - 1) end
        if key == "down" then selected = math.min(#pickable, selected + 1) end
        if key == "return" or key == "e" then
            local lang = pickable[selected]
            if lang then
                bc:changeCurrentPlayerLanguage(lang)
                selected = 1
            end
        end
        return
    end

    -- PLAYER ACTION (normal menu)
    if bc.phase ~= PHASE.PLAYER_ACTION then return end

    local menuSize = BattleUI.getMenuSize(bc, menuMode)
    if key == "up"   then selected = math.max(1, selected - 1) end
    if key == "down" then selected = math.min(menuSize, selected + 1) end

    if key == "return" or key == "e" then
        if menuMode == "action" then
            if selected == 1 then
                menuMode = "attack"
                selected = 1
            elseif selected == 2 then
                menuMode = "swap"
                selected = 1
            end

        elseif menuMode == "attack" then
            local skills = bc.currentPlayerLanguage.currentSkills
            if selected == #skills + 1 then
                menuMode = "action"
                selected = 1
            else
                local skill = skills[selected]
                if skill then
                    bc:playerAttack(skill)
                    menuMode = "action"
                    selected = 1
                end
            end

        elseif menuMode == "swap" then
            local swappable = getSwappable()
            if selected == #swappable + 1 then
                menuMode = "action"
                selected = 1
            else
                local lang = swappable[selected]
                if lang then
                    bc:playerSwapLanguage(lang)
                    menuMode = "action"
                    selected = 1
                end
            end
        end
    end

    if key == "escape" and menuMode ~= "action" then
        menuMode = "action"
        selected = 1
    end
end


-- UPDATE
function Battle.update(dt)
    -- BACKGROUND
    if not bgData then
        local ok = love.filesystem.getInfo(BG_PATH)
        if ok then
            bgData = GetBattleBackgroundSprite.load(BG_PATH, BG_FRAME_DURATION)
        end
    end
    GetBattleBackgroundSprite.update(bgData, dt)

    -- UI
    BattleUI.update(bc, dt)
end


-- DRAW
function Battle.draw()
    local sw = love.graphics.getWidth()
    local sh = love.graphics.getHeight()

    if bgData then
        GetBattleBackgroundSprite.draw(bgData)
    else
        love.graphics.setColor(0.08, 0.08, 0.08)
        love.graphics.rectangle("fill", 0, 0, sw, sh)
    end

    BattleUI.draw(bc, selected, menuMode)
end

return Battle