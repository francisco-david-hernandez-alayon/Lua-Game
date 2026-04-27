-- ui/ui_battle.lua
-- Handles all drawing for the battle state.

local L                = require("core.localization.localization")
local BattleController = require("core.battle.battle_controller")

local BattleUI = {}

local PHASE = BattleController.PHASE

-- ── Menu builders ─────────────────────────────────────────────────

local function buildActionMenu()
    return { L.get("battle_attack"), L.get("battle_swap") }
end

local function buildAttackMenu(bc)
    local labels = {}
    for _, skill in ipairs(bc.currentPlayerLanguage.currentSkills) do
        table.insert(labels, skill.nameKey .. " (" .. skill.baseDamage .. ")")
    end
    table.insert(labels, L.get("battle_back"))
    return labels
end

local function buildSwapMenu(bc)
    local labels = {}
    local langs  = bc:getActivePlayerLanguages()
    for _, lang in ipairs(langs) do
        if lang ~= bc.currentPlayerLanguage then
            table.insert(labels, lang.language_name ..
                " [" .. lang.attributes.hp .. "/" .. lang.attributes.maxHp .. "]")
        end
    end
    table.insert(labels, L.get("battle_back"))
    return labels
end

local function buildPickMenu(bc)
    local labels = {}
    local langs  = bc:getActivePlayerLanguages()
    for _, lang in ipairs(langs) do
        if lang ~= bc.currentPlayerLanguage then
            table.insert(labels, lang.language_name ..
                " [" .. lang.attributes.hp .. "/" .. lang.attributes.maxHp .. "]")
        end
    end
    return labels
end

local function getMenu(bc, menuMode)
    if bc.phase == PHASE.PICK_LANGUAGE then return buildPickMenu(bc) end
    if menuMode == "action" then return buildActionMenu() end
    if menuMode == "attack" then return buildAttackMenu(bc) end
    if menuMode == "swap" then return buildSwapMenu(bc) end
    return {}
end

-- Returns menu size (used by battle.lua for clamping selection)
function BattleUI.getMenuSize(bc, menuMode)
    return #getMenu(bc, menuMode)
end


function BattleUI.draw(bc, selected, menuMode)
    local sw    = love.graphics.getWidth()
    local sh    = love.graphics.getHeight()
    local ARENA_W = math.floor(sw * 2 / 3)
    local MENU_W  = sw - ARENA_W
    local LOG_H   = 48
    local ARENA_H = sh - LOG_H

    love.graphics.setColor(0.08, 0.08, 0.08)
    love.graphics.rectangle("fill", 0, 0, sw, sh)

    love.graphics.setColor(0.12, 0.12, 0.12)
    love.graphics.rectangle("fill", 0, 0, ARENA_W, ARENA_H)

    if bc.currentEnemyLanguage then
        local el = bc.currentEnemyLanguage
        love.graphics.setColor(0.8, 0.2, 0.2)
        love.graphics.print(
            el.language_name .. "  [" .. el.attributes.hp .. "/" .. el.attributes.maxHp .. "]",
            16, 16)
        love.graphics.setColor(0.4, 0.4, 0.4)
        love.graphics.print(bc.programmerName, 16, 36)
    end

    if bc.currentPlayerLanguage then
        local pl = bc.currentPlayerLanguage
        love.graphics.setColor(0.2, 0.6, 1)
        love.graphics.print(
            pl.language_name .. "  [" .. pl.attributes.hp .. "/" .. pl.attributes.maxHp .. "]",
            16, ARENA_H - 48)
        love.graphics.setColor(0.4, 0.4, 0.4)
        love.graphics.print(L.get("battle_you"), 16, ARENA_H - 28)
    end

    love.graphics.setColor(0.15, 0.15, 0.15)
    love.graphics.rectangle("fill", ARENA_W, 0, MENU_W, ARENA_H)
    love.graphics.setColor(0.3, 0.3, 0.3)
    love.graphics.rectangle("line", ARENA_W, 0, MENU_W, ARENA_H)

    if bc.phase == PHASE.BATTLE_OVER then
        local msg       = bc.winner == "player" and L.get("battle_win") or L.get("battle_lose")
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
        love.graphics.setColor(0.6, 0.6, 0.6)
        if bc.phase == PHASE.PICK_LANGUAGE then
            love.graphics.setColor(1, 0.6, 0)
            love.graphics.print(L.get("battle_pick_language"), ARENA_W + 8, 8)
        else
            local title = menuMode == "action" and L.get("battle_menu_action")
                       or menuMode == "attack" and L.get("battle_menu_attack")
                       or L.get("battle_menu_swap")
            love.graphics.print(title, ARENA_W + 8, 8)
        end

        local menu = getMenu(bc, menuMode)
        for i, item in ipairs(menu) do
            love.graphics.setColor(i == selected and 1 or 1, i == selected and 1 or 1, i == selected and 0 or 1)
            love.graphics.print("> " .. item, ARENA_W + 8, 28 + (i - 1) * 20)
        end
    end

    love.graphics.setColor(0.05, 0.05, 0.05)
    love.graphics.rectangle("fill", 0, ARENA_H, sw, LOG_H)
    love.graphics.setColor(0.3, 0.3, 0.3)
    love.graphics.rectangle("line", 0, ARENA_H, sw, LOG_H)
    love.graphics.setColor(1, 1, 1)
    love.graphics.print(bc:getLastLog() or "", 8, ARENA_H + 8)
end

return BattleUI