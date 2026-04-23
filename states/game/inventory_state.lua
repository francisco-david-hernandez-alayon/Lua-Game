-- states/game/inventory_state.lua
--
-- Shows the player inventory: items, mission items and programming language slots.
-- Returns to the saved game state on exit.

local L              = require("core.localization.localization")
local GameController = require("core.game.controller.game_controller")

local InventoryState = {}

local sm          = nil
local returnState = nil

local TABS = { "items", "mission", "languages" }
local tab         = "items" 
local tabIndex = 1

function InventoryState.enter(stateManager, localization)
    sm = stateManager
    local game = GameController.getGame()
    returnState = game and game.gameState or "main_menu"
    tab      = "items"
    tabIndex = 1
end

local function currentInventory()
    local game = GameController.getGame()
    return game and game.inventory or nil
end

function InventoryState.keypressed(key)
    if key == "escape" then
        sm.switch(returnState)
        return
    end

    if key == "left" then
        tabIndex = math.max(1, tabIndex - 1)
        tab = TABS[tabIndex]
    elseif key == "right" then
        tabIndex = math.min(#TABS, tabIndex + 1)
        tab = TABS[tabIndex]
    end
end

function InventoryState.update(dt) end

function InventoryState.draw()
    local sw   = love.graphics.getWidth()
    local sh   = love.graphics.getHeight()
    local font = love.graphics.getFont()
    local inv  = currentInventory()

    -- Background
    love.graphics.setColor(0.05, 0.05, 0.05)
    love.graphics.rectangle("fill", 0, 0, sw, sh)

    -- Title
    love.graphics.setColor(0.2, 0.6, 1)
    love.graphics.print("[ INVENTORY ]", 24, 16)

    -- Tabs
    local tabLabels = {
        items     = L.get("inv_tab_items"),
        mission   = L.get("inv_tab_mission"),
        languages = L.get("inv_tab_languages"),
    }
    local tx = 24
    for i, t in ipairs(TABS) do
        if t == tab then
            love.graphics.setColor(1, 1, 0)
        else
            love.graphics.setColor(0.5, 0.5, 0.5)
        end
        local label = "[ " .. tabLabels[t] .. " ]"
        love.graphics.print(label, tx, 44)
        tx = tx + font:getWidth(label) + 16
    end

    -- Divider
    love.graphics.setColor(0.3, 0.3, 0.3)
    love.graphics.rectangle("fill", 24, 64, sw - 48, 1)

    if not inv then
        love.graphics.setColor(0.8, 0.2, 0.2)
        love.graphics.print("No active game session.", 24, 80)
        return
    end

    local y = 80
    local PAD = 20

    -- Items tab
    if tab == "items" then
        if #inv.items == 0 then
            love.graphics.setColor(0.5, 0.5, 0.5)
            love.graphics.print(L.get("inv_empty"), 24, y)
        else
            for _, item in ipairs(inv.items) do
                love.graphics.setColor(1, 1, 1)
                local name  = item:getName(L)
                local stack = item.count .. "/" .. item.maxStack
                love.graphics.print(name, 24, y)
                love.graphics.setColor(0.6, 0.6, 0.6)
                love.graphics.print(stack, 200, y)
                love.graphics.setColor(0.4, 0.4, 0.4)
                love.graphics.print(item:getDesc(L), 260, y)
                y = y + PAD
            end
        end

    -- Mission items tab
    elseif tab == "mission" then
        if #inv.missionItems == 0 then
            love.graphics.setColor(0.5, 0.5, 0.5)
            love.graphics.print(L.get("inv_empty"), 24, y)
        else
            for _, item in ipairs(inv.missionItems) do
                love.graphics.setColor(1, 0.8, 0.2)
                love.graphics.print(item:getName(L), 24, y)
                love.graphics.setColor(0.4, 0.4, 0.4)
                love.graphics.print(item:getDesc(L), 200, y)
                y = y + PAD
            end
        end

    -- Language slots tab
    elseif tab == "languages" then
        local count = #inv.programmingLanguageSlots
        love.graphics.setColor(0.5, 0.5, 0.5)
        love.graphics.print(count .. " / 6", 24, y)
        y = y + PAD
        if count == 0 then
            love.graphics.setColor(0.5, 0.5, 0.5)
            love.graphics.print(L.get("inv_empty"), 24, y)
        else
            for _, slot in ipairs(inv.programmingLanguageSlots) do
                love.graphics.setColor(0.2, 1, 0.4)
                love.graphics.print("[ " .. slot.languageId .. " ]", 24, y)
                y = y + PAD
            end
        end
    end

    -- Footer
    love.graphics.setColor(0.4, 0.4, 0.4)
    love.graphics.print("[←→] " .. L.get("inv_switch_tab") .. "   [Esc] " .. L.get("inv_back"), 24, sh - 24)
end

return InventoryState