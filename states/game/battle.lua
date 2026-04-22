-- states/game/battle.lua
-- Handles input and state logic for the battle screen.

local L                = require("core.localization.localization")
local BattleController = require("core.battle.battle_controller")
local BattleUI         = require("ui.ui_battle")

local Battle = {}

local sm          = nil
local returnState = nil
local bc          = nil
local selected    = 1
local menuMode    = "action"

local PHASE = BattleController.PHASE

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

function Battle.keypressed(key)
    if bc.phase == PHASE.BATTLE_OVER then
        if key == "return" or key == "e" then sm.switch(returnState) end
        return
    end

    -- Force language pick
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

    if bc.phase ~= PHASE.PLAYER_ACTION then return end

    local menuSize = BattleUI.getMenuSize(bc, menuMode)
    if key == "up"   then selected = math.max(1, selected - 1) end
    if key == "down" then selected = math.min(menuSize, selected + 1) end

    if key == "return" or key == "e" then
        if menuMode == "action" then
            if selected == 1 then menuMode = "attack" selected = 1
            elseif selected == 2 then menuMode = "swap" selected = 1
            end

        elseif menuMode == "attack" then
            local attacks = bc.currentPlayerLanguage.currentAttacks
            if selected == #attacks + 1 then
                menuMode = "action" selected = 1
            else
                local atk = attacks[selected]
                if atk then bc:playerAttack(atk) menuMode = "action" selected = 1 end
            end

        elseif menuMode == "swap" then
            local swappable = getSwappable()
            if selected == #swappable + 1 then
                menuMode = "action" selected = 1
            else
                local lang = swappable[selected]
                if lang then bc:playerSwapLanguage(lang) menuMode = "action" selected = 1 end
            end
        end
    end

    if key == "escape" and menuMode ~= "action" then
        menuMode = "action" selected = 1
    end
end

function Battle.update(dt) end

function Battle.draw()
    BattleUI.draw(bc, selected, menuMode)
end

return Battle