-- states/game/battle.lua
--
-- Battle state. Receives a BattleController as parameter.
-- Layout:
--   Left 2/3:  enemy language name (top) + player language name (bottom)
--   Right 1/3: action menu
--   Bottom bar: battle log info box

local L                = require("core.localization.localization")
local BattleController = require("core.battle.battle_controller")

local Battle = {}

local sm         = nil
local returnState = nil
local bc         = nil   -- BattleController instance
local selected   = 1
local menuMode   = "action"   -- "action" | "attack" | "swap"

local PHASE = BattleController.PHASE

local function buildActionMenu()
    return {
        L.get("battle_attack"),
        L.get("battle_swap"),
    }
end

function Battle.enter(stateManager, localization, battleController, targetReturnState)
    sm          = stateManager
    returnState = targetReturnState
    bc          = battleController
    selected    = 1
    menuMode    = "action"
end

local function currentMenu()
    if menuMode == "action" then
        return buildActionMenu()
    elseif menuMode == "attack" then
        local attacks = bc.currentPlayerLanguage.currentAttacks
        local labels  = {}
        for _, atk in ipairs(attacks) do
            table.insert(labels, atk.nameKey .. " (" .. atk.damage .. ")")
        end
        table.insert(labels, L.get("battle_back"))
        return labels
    elseif menuMode == "swap" or bc.phase == PHASE.PICK_LANGUAGE then
        local langs   = bc:getActivePlayerLanguages()
        local labels  = {}
        for _, lang in ipairs(langs) do
            if lang ~= bc.currentPlayerLanguage then
                table.insert(labels, lang.language_name ..
                    " [" .. lang.linesOfCode .. "/" .. lang.maxLinesOfCode .. "]")
            end
        end
        if bc.phase ~= PHASE.PICK_LANGUAGE then
            table.insert(labels, L.get("battle_back"))
        end
        return labels
    end
    return {}
end

function Battle.keypressed(key)
    if bc.phase == PHASE.BATTLE_OVER then
        if key == "return" or key == "e" then
            sm.switch(returnState)
        end
        return
    end

    -- Force language pick
    if bc.phase == PHASE.PICK_LANGUAGE then
        local langs = bc:getActivePlayerLanguages()
        local menu  = currentMenu()
        if key == "up"   then selected = math.max(1, selected - 1) end
        if key == "down" then selected = math.min(#menu, selected + 1) end
        if key == "return" or key == "e" then
            local lang = langs[selected]
            if lang then bc:changeCurrentPlayerLanguage(lang) end
            selected = 1
        end
        return
    end

    if bc.phase ~= PHASE.PLAYER_ACTION then return end

    local menu = currentMenu()
    if key == "up"   then selected = math.max(1, selected - 1) end
    if key == "down" then selected = math.min(#menu, selected + 1) end

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
            local attacks = bc.currentPlayerLanguage.currentAttacks
            if selected == #attacks + 1 then
                menuMode = "action"
                selected = 1
            else
                local atk = attacks[selected]
                if atk then
                    bc:playerAttack(atk)
                    menuMode = "action"
                    selected = 1
                end
            end

        elseif menuMode == "swap" then
            local langs = bc:getActivePlayerLanguages()
            local swappable = {}
            for _, lang in ipairs(langs) do
                if lang ~= bc.currentPlayerLanguage then
                    table.insert(swappable, lang)
                end
            end
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

function Battle.update(dt) end

function Battle.draw()
    local sw   = love.graphics.getWidth()
    local sh   = love.graphics.getHeight()
    local font = love.graphics.getFont()

    local ARENA_W   = math.floor(sw * 2 / 3)
    local MENU_W    = sw - ARENA_W
    local LOG_H     = 48
    local ARENA_H   = sh - LOG_H

    -- ── Background ────────────────────────────────────────────────
    love.graphics.setColor(0.08, 0.08, 0.08)
    love.graphics.rectangle("fill", 0, 0, sw, sh)

    -- ── Arena (left 2/3) ──────────────────────────────────────────
    love.graphics.setColor(0.12, 0.12, 0.12)
    love.graphics.rectangle("fill", 0, 0, ARENA_W, ARENA_H)

    -- Enemy language
    if bc.currentEnemyLanguage then
        local eLang = bc.currentEnemyLanguage
        love.graphics.setColor(0.8, 0.2, 0.2)
        love.graphics.print(
            eLang.language_name .. "  [" .. eLang.linesOfCode .. "/" .. eLang.maxLinesOfCode .. "]",
            16, 16
        )
        love.graphics.setColor(0.4, 0.4, 0.4)
        love.graphics.print(bc.programmerName, 16, 36)
    end

    -- Player language
    if bc.currentPlayerLanguage then
        local pLang = bc.currentPlayerLanguage
        love.graphics.setColor(0.2, 0.6, 1)
        love.graphics.print(
            pLang.language_name .. "  [" .. pLang.linesOfCode .. "/" .. pLang.maxLinesOfCode .. "]",
            16, ARENA_H - 48
        )
        love.graphics.setColor(0.4, 0.4, 0.4)
        love.graphics.print(L.get("battle_you"), 16, ARENA_H - 28)
    end

    -- ── Menu panel ────────────────────────────────────────────────
    love.graphics.setColor(0.15, 0.15, 0.15)
    love.graphics.rectangle("fill", ARENA_W, 0, MENU_W, ARENA_H)
    love.graphics.setColor(0.3, 0.3, 0.3)
    love.graphics.rectangle("line", ARENA_W, 0, MENU_W, ARENA_H)

    -- 
    if bc.phase == PHASE.BATTLE_OVER then
        -- Battle over
        local msg = bc.winner == "player" and L.get("battle_win") or L.get("battle_lose")
        local remaining = bc.winner == "player"
            and #bc:getActivePlayerLanguages()
            or  #bc:getActiveEnemyLanguages()

        love.graphics.setColor(1, 1, 0)
        love.graphics.print(msg, ARENA_W + 8, 16)

        love.graphics.setColor(1, 1, 1)
        love.graphics.print(L.get("battle_remaining") .. ": " .. remaining, ARENA_W + 8, 36)

        love.graphics.setColor(0.5, 0.5, 0.5)
        love.graphics.print("[E] " .. L.get("battle_exit"), ARENA_W + 8, 56)

    else
        -- Title
        if bc.phase == PHASE.PICK_LANGUAGE then
            love.graphics.setColor(1, 0.6, 0)
            love.graphics.print(L.get("battle_pick_language"), ARENA_W + 8, 8)
        else
            love.graphics.setColor(0.6, 0.6, 0.6)
            local title = menuMode == "action" and L.get("battle_menu_action")
                       or menuMode == "attack" and L.get("battle_menu_attack")
                       or L.get("battle_menu_swap")
            love.graphics.print(title, ARENA_W + 8, 8)
        end

        -- Items
        local menu = currentMenu()
        for i, item in ipairs(menu) do
            local my = 28 + (i - 1) * 20

            if i == selected then
                love.graphics.setColor(1, 1, 0)
            else
                love.graphics.setColor(1, 1, 1)
            end

            love.graphics.print("> " .. item, ARENA_W + 8, my)
        end
    end

    -- ── Log box
    love.graphics.setColor(0.05, 0.05, 0.05)
    love.graphics.rectangle("fill", 0, ARENA_H, sw, LOG_H)

    love.graphics.setColor(0.3, 0.3, 0.3)
    love.graphics.rectangle("line", 0, ARENA_H, sw, LOG_H)

    love.graphics.setColor(1, 1, 1)
    local logText = bc:getLastLog() or ""
    love.graphics.print(logText, 8, ARENA_H + 8)
end

return Battle