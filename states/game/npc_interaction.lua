-- states/game/npc_interaction.lua
local L = require("core.localization.localization")

local NpcInteraction = {}

-- Background sprites map: key → image path
local BACKGROUNDS = {
    -- forest  = "assets/sprites/backgrounds/forest.png",
    -- dungeon = "assets/sprites/backgrounds/dungeon.png",
    -- town    = "assets/sprites/backgrounds/town.png",
    test    = "assets/sprites/test/npc-interaction-bg-test.png",
}

local sm             = nil
local returnState    = nil
local npc            = nil
local options        = {}
local selected       = 1
local inDialogue     = false
local activeDialogue = nil
local bgSprite       = nil

local BOX_PAD = 16
local BOX_H   = 160

local function startDialogue(dialogueOption)
    inDialogue     = true
    activeDialogue = dialogueOption
    activeDialogue:reset()
    selected       = 1
end

local function exitToReturn()
    sm.switch(returnState)
end

function NpcInteraction.enter(stateManager, L, targetNpc, targetReturnState, background)
    sm          = stateManager       -- state manager for switching states
    returnState = targetReturnState  -- state to return to on exit
    npc         = targetNpc          -- npc being interacted with
    selected    = 1                  -- reset selection index
    inDialogue  = false              -- not in dialogue mode on enter
    activeDialogue = nil             -- no active dialogue on enter
    options     = npc:getActiveOptions()  -- fetch npc active options

    -- Load background sprite from key, fallback to nil if not found
    local bgPath = background and BACKGROUNDS[background]
    bgSprite = bgPath and love.graphics.newImage(bgPath) or nil
end

function NpcInteraction.keypressed(key)
    if inDialogue then
        local node = activeDialogue:getCurrentNode()
        if not node then inDialogue = false return end

        local activeOpts = node:getActiveOptions()

        if key == "up" and #activeOpts > 0 then
            selected = math.max(1, selected - 1)
        elseif key == "down" and #activeOpts > 0 then
            selected = math.min(#activeOpts, selected + 1)
        elseif key == "return" or key == "e" then
            if not node:isPlayerTurn() then
                activeDialogue:advance()
                if activeDialogue:isFinished() then
                    activeDialogue:reset()
                    inDialogue = false
                    selected   = 1
                end
            else
                activeDialogue:choose(selected)
                selected = 1
                if activeDialogue:isFinished() then
                    activeDialogue:reset()
                    inDialogue = false
                    selected   = 1
                end
            end
        elseif key == "escape" then
            activeDialogue:reset()
            inDialogue = false
            selected   = 1
        end
        return
    end

    if key == "up" then
        selected = math.max(1, selected - 1)
    elseif key == "down" then
        selected = math.min(#options + 1, selected + 1)
    elseif key == "return" or key == "e" then
        if selected == #options + 1 then
            exitToReturn()
        else
            local opt = options[selected].option
            if opt.type == "dialogue" then
                startDialogue(opt)
                selected = 1
            elseif opt.type == "trade" then
                print("[TODO] Trade with " .. npc.id)
            elseif opt.type == "combat" then
                print("[TODO] Combat with " .. npc.id)
            end
        end
    elseif key == "escape" then
        exitToReturn()
    end
end

function NpcInteraction.update(dt) end

function NpcInteraction.draw()
    local sw   = love.graphics.getWidth()
    local sh   = love.graphics.getHeight()
    local font = love.graphics.getFont()
    local boxW = sw - BOX_PAD * 2
    local boxX = BOX_PAD
    local boxY = sh - BOX_H - BOX_PAD

    -- BACKGROUND: sprite covers area above the dialogue box
    if bgSprite then
        local bgH = boxY
        love.graphics.setColor(1, 1, 1)
        love.graphics.draw(bgSprite, 0, 0, 0,
            sw / bgSprite:getWidth(),
            bgH / bgSprite:getHeight()
        )
    else
        love.graphics.setColor(0.1, 0.1, 0.1)
        love.graphics.rectangle("fill", 0, 0, sw, boxY)
    end

    -- DIALOGUE MODE
    if inDialogue then
        local node = activeDialogue:getCurrentNode()
        if not node then return end

        local activeOpts = node:getActiveOptions()

        love.graphics.setColor(1, 1, 1, 0.95)
        love.graphics.rectangle("fill", boxX, boxY, boxW, BOX_H)
        love.graphics.setColor(0, 0, 0)
        love.graphics.rectangle("line", boxX, boxY, boxW, BOX_H)

        -- Speaker label
        if node:isPlayerTurn() then
            love.graphics.setColor(0.1, 0.5, 0.1)
            love.graphics.print(L.get("player_speaker"), boxX + BOX_PAD, boxY + BOX_PAD)
        else
            love.graphics.setColor(0.1, 0.1, 0.6)
            love.graphics.print(node.speakerId, boxX + BOX_PAD, boxY + BOX_PAD)
        end

        if not node:isPlayerTurn() then
            -- NPC text
            love.graphics.setColor(0, 0, 0)
            love.graphics.print(node:getText(L), boxX + BOX_PAD, boxY + BOX_PAD + 20)
            love.graphics.setColor(0.5, 0.5, 0.5)
            love.graphics.print("[E] " .. L.get("continue"), boxX + boxW - 80, boxY + BOX_H - 24)
        else
            -- Player options
            for i, opt in ipairs(activeOpts) do
                local oy = boxY + BOX_PAD + 20 + (i - 1) * 22
                if i == selected then
                    love.graphics.setColor(0.1, 0.4, 0.8)
                else
                    love.graphics.setColor(0, 0, 0)
                end
                love.graphics.print("> " .. opt:getText(L), boxX + BOX_PAD + 16, oy)
            end
        end

        love.graphics.setColor(1, 1, 1)
        return
    end


    -- OPTION MENU MODE
    love.graphics.setColor(1, 1, 1, 0.95)
    love.graphics.rectangle("fill", boxX, boxY, boxW, BOX_H)
    love.graphics.setColor(0, 0, 0)
    love.graphics.rectangle("line", boxX, boxY, boxW, BOX_H)

    -- NPC name as title
    love.graphics.setColor(0.1, 0.1, 0.6)
    love.graphics.print(npc.id, boxX + BOX_PAD, boxY + BOX_PAD)

    -- Options with intro text inline: [TYPE] intro_text
    for i, npcOpt in ipairs(options) do
        local oy    = boxY + BOX_PAD + 24 + (i - 1) * 28
        local tag   = "[" .. npcOpt.option.type:upper() .. "] "
        local intro = npcOpt:getInitialLine(L) or npcOpt:getLabel(L)
        local lbl   = tag .. intro

        if i == selected then
            love.graphics.setColor(0.1, 0.4, 0.8)
        else
            love.graphics.setColor(0, 0, 0)
        end
        love.graphics.print("> " .. lbl, boxX + BOX_PAD + 16, oy)
    end


    -- Exit
    local leaveY = boxY + BOX_PAD + 60 + #options * 22
    love.graphics.setColor(selected == #options + 1 and {0.8, 0.1, 0.1} or {0.4, 0.4, 0.4})
    love.graphics.print("> " .. L.get("leave_chat"), boxX + BOX_PAD + 16, leaveY)

    love.graphics.setColor(1, 1, 1)
end

return NpcInteraction