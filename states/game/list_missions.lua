-- states/game/list_missions.lua
--
-- Shows all active missions grouped by type.
-- Navigate with up/down, select with E to set as current mission.
-- Escape to return.

local L              = require("core.localization.localization")
local GameController = require("core.game.controller.game_controller")

local ListMissions = {}

local sm          = nil
local returnState = nil
local allMissions = {}
local selected    = 1

local function buildList()
    local game = GameController.getGame()
    if not game then return {} end
    local pm   = game.playerMissions
    local list = {}
    for _, m in ipairs(pm.mainMissions)      do table.insert(list, m) end
    for _, m in ipairs(pm.secondaryMissions) do table.insert(list, m) end
    for _, m in ipairs(pm.taskMissions)      do table.insert(list, m) end
    return list
end

function ListMissions.enter(stateManager, localization, targetReturnState)
    sm          = stateManager
    returnState = targetReturnState or "map_test"
    selected    = 1
    allMissions = buildList()
end

function ListMissions.keypressed(key)
    if key == "escape" then
        sm.switch(returnState)
        return
    end
    if key == "up"   then selected = math.max(1, selected - 1) end
    if key == "down" then selected = math.min(#allMissions, selected + 1) end
    if (key == "return" or key == "e") and #allMissions > 0 then
        local m = allMissions[selected]
        if m then GameController.setCurrentMission(m.missionId) end
    end
end

function ListMissions.update(dt) end

function ListMissions.draw()
    local sw   = love.graphics.getWidth()
    local sh   = love.graphics.getHeight()
    local font = love.graphics.getFont()
    local PAD  = 16

    -- Background
    love.graphics.setColor(0.05, 0.05, 0.05)
    love.graphics.rectangle("fill", 0, 0, sw, sh)

    -- Title
    love.graphics.setColor(0.2, 0.8, 0.4)
    love.graphics.print("[ " .. L.get("missions_title") .. " ]", PAD, PAD)

    -- Divider
    love.graphics.setColor(0.3, 0.3, 0.3)
    love.graphics.rectangle("fill", PAD, PAD + 20, sw - PAD * 2, 1)

    if #allMissions == 0 then
        love.graphics.setColor(0.5, 0.5, 0.5)
        love.graphics.print(L.get("missions_empty"), PAD, PAD + 32)
    else
        local current = GameController.getCurrentMission()
        local y = PAD + 32

        for i, m in ipairs(allMissions) do
            local isCurrent = current and current.missionId == m.missionId
            local isSelected = i == selected

            -- Selection highlight
            if isSelected then
                love.graphics.setColor(0.15, 0.15, 0.15)
                love.graphics.rectangle("fill", PAD - 4, y - 2, sw - PAD * 2 + 8, 52)
            end

            -- Mission name
            if isSelected then
                love.graphics.setColor(1, 1, 0)
            elseif isCurrent then
                love.graphics.setColor(0.2, 0.8, 0.4)
            else
                love.graphics.setColor(1, 1, 1)
            end

            local prefix = isCurrent and "► " or "  "
            love.graphics.print(prefix .. m:getName(L) ..
                " [" .. m.missionType:upper() .. "]", PAD, y)

            -- Mission desc
            love.graphics.setColor(0.5, 0.5, 0.5)
            love.graphics.print(m:getDesc(L), PAD + 8, y + 14)

            -- Tasks summary
            local doneCount = 0
            for _, t in ipairs(m.tasks) do if t.completed then doneCount = doneCount + 1 end end
            love.graphics.setColor(0.4, 0.7, 1)
            love.graphics.print(
                L.get("missions_tasks") .. ": " .. doneCount .. "/" .. #m.tasks,
                PAD + 8, y + 28)

            y = y + 60
        end
    end

    -- Footer
    love.graphics.setColor(0.4, 0.4, 0.4)
    love.graphics.print(
        "[↑↓] " .. L.get("missions_navigate") ..
        "  [E] " .. L.get("missions_set_current") ..
        "  [Esc] " .. L.get("inv_back"),
        PAD, sh - 20)
end

return ListMissions