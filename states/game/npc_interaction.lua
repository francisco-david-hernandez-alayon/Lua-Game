-- states/game/npc_interaction.lua
-- Receives an NPC and shows its active options as a menu at the bottom.
-- Player navigates with up/down, confirms with E or Return, exits with Escape.

local L = require("core.localization.localization")

local NpcInteraction = {}

local npc       = nil
local sm        = nil
local options   = {}
local selected  = 1

local BOX_H     = 120
local BOX_PAD   = 16

function NpcInteraction.enter(stateManager, localization, targetNpc)
    sm       = stateManager
    npc      = targetNpc
    selected = 1
    options  = npc:getActiveOptions()
end

function NpcInteraction.keypressed(key)
    if key == "up" then
        selected = math.max(1, selected - 1)
    elseif key == "down" then
        selected = math.min(#options + 1, selected + 1)  -- +1 for leave option
    elseif key == "return" or key == "e" then
        if selected == #options + 1 then
            sm.switch("map_test")  -- TODO: return to previous map state
        else
            local opt = options[selected].option
            if opt.type == "dialogue" then
                -- TODO: switch to dialogue state
            elseif opt.type == "trade" then
                -- TODO: switch to trade state
            elseif opt.type == "combat" then
                -- TODO: switch to combat state
            end
        end
    elseif key == "escape" then
        sm.switch("map_test")  -- TODO: return to previous map state
    end
end

function NpcInteraction.draw()
    local sw   = love.graphics.getWidth()
    local sh   = love.graphics.getHeight()
    local font = love.graphics.getFont()

    local boxW = sw - BOX_PAD * 2
    local boxX = BOX_PAD
    local boxY = sh - BOX_H - BOX_PAD

    -- Background box
    love.graphics.setColor(1, 1, 1, 0.95)
    love.graphics.rectangle("fill", boxX, boxY, boxW, BOX_H)
    love.graphics.setColor(0, 0, 0)
    love.graphics.rectangle("line", boxX, boxY, boxW, BOX_H)

    -- NPC name header
    love.graphics.setColor(0, 0, 0)
    love.graphics.print(npc.id, boxX + BOX_PAD, boxY + BOX_PAD)

    -- Options
    for i, npcOpt in ipairs(options) do
        local oy = boxY + BOX_PAD + 24 + (i - 1) * 22
        if i == selected then
            love.graphics.setColor(0.1, 0.4, 0.8)
        else
            love.graphics.setColor(0, 0, 0)
        end
        love.graphics.print("> " .. npcOpt:getLabel(L), boxX + BOX_PAD + 16, oy)
    end

    -- Leave option
    local leaveY = boxY + BOX_PAD + 24 + #options * 22
    if selected == #options + 1 then
        love.graphics.setColor(0.8, 0.1, 0.1)
    else
        love.graphics.setColor(0.4, 0.4, 0.4)
    end
    love.graphics.print("> " .. L.get("leave_chat"), boxX + BOX_PAD + 16, leaveY)

    love.graphics.setColor(1, 1, 1)
end

function NpcInteraction.update(dt) end

return NpcInteraction