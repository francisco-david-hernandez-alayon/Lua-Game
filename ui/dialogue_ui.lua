-- ui/dialogue_ui.lua
-- Handles rendering and input for NPC interactions.
-- SimpleTalk: shows text above player for 3 seconds, no input needed.
-- Menu/Dialogue: shows options, player navigates with up/down, confirms with E.

local L = require("core.localization.localization")

local DialogueUI = {}

local SIMPLE_TALK_DURATION = 3  -- seconds

local state = {
    active      = false,
    mode        = nil,   -- "simple_talk" | "dialogue" | "menu"
    text        = nil,   -- simple_talk text string
    timer       = 0,
    options     = {},    -- list of {label, action}
    selected    = 1,
    npcOption   = nil,   -- current DialogueOption being played
}

function DialogueUI.isActive()
    return state.active
end

-- Trigger simple talk: shows text above player for N seconds
function DialogueUI.showSimpleTalk(textKey)
    state.active   = true
    state.mode     = "simple_talk"
    state.text     = L.get(textKey)
    state.timer    = SIMPLE_TALK_DURATION
    state.options  = {}
    state.selected = 1
end

-- Trigger full dialogue option
function DialogueUI.showDialogue(dialogueOption)
    state.active     = true
    state.mode       = "dialogue"
    state.npcOption  = dialogueOption
    state.selected   = 1
    state.timer      = 0
end

-- Trigger menu of NpcOptions
function DialogueUI.showMenu(npcOptions)
    state.active   = true
    state.mode     = "menu"
    state.options  = npcOptions
    state.selected = 1
    state.timer    = 0
end

function DialogueUI.close()
    state.active    = false
    state.mode      = nil
    state.text      = nil
    state.npcOption = nil
    state.options   = {}
    state.selected  = 1
end

function DialogueUI.update(dt)
    if not state.active then return end

    if state.mode == "simple_talk" then
        state.timer = state.timer - dt
        if state.timer <= 0 then
            DialogueUI.close()
        end
    end
end

function DialogueUI.keypressed(key)
    if not state.active then return end

    if state.mode == "simple_talk" then
        return  -- no input, auto-closes
    end

    if state.mode == "dialogue" then
        local line = state.npcOption:getCurrentLine()
        if not line then
            DialogueUI.close()
            return
        end

        local active = line:getActiveOptions()

        if key == "e" or key == "return" then
            if #active == 0 then
                -- auto-advance
                state.npcOption:advance()
                if state.npcOption:isFinished() then
                    state.npcOption:reset()
                    DialogueUI.close()
                end
            else
                state.npcOption:choose(state.selected)
                if state.npcOption:isFinished() then
                    state.npcOption:reset()
                    DialogueUI.close()
                end
            end
        elseif key == "up" then
            if #active > 0 then
                state.selected = math.max(1, state.selected - 1)
            end
        elseif key == "down" then
            if #active > 0 then
                state.selected = math.min(#active, state.selected + 1)
            end
        elseif key == "escape" then
            DialogueUI.close()
        end
        return
    end

    if state.mode == "menu" then
        if key == "up" then
            state.selected = math.max(1, state.selected - 1)
        elseif key == "down" then
            state.selected = math.min(#state.options + 1, state.selected + 1)
        elseif key == "e" or key == "return" then
            -- last option is always "leave"
            if state.selected == #state.options + 1 then
                DialogueUI.close()
            else
                local chosen = state.options[state.selected]
                if chosen.option.type == "dialogue" then
                    DialogueUI.showDialogue(chosen.option)
                elseif chosen.option.type == "trade" then
                    DialogueUI.close()  -- trade UI handled separately
                elseif chosen.option.type == "combat" then
                    DialogueUI.close()  -- combat handled separately
                end
            end
        elseif key == "escape" then
            DialogueUI.close()
        end
    end
end

function DialogueUI.draw(px, py, tx, ty, scale)
    if not state.active then return end

    local font  = love.graphics.getFont()
    local sx    = (px - tx) * scale
    local sy    = (py - ty) * scale

    if state.mode == "simple_talk" then
        -- Text bubble above player
        local text  = state.text
        local textW = font:getWidth(text)
        local bx    = sx - textW / 2 - 8
        local by    = sy - 48
        love.graphics.setColor(0, 0, 0, 0.8)
        love.graphics.rectangle("fill", bx, by, textW + 16, 24)
        love.graphics.setColor(1, 1, 1)
        love.graphics.print(text, bx + 8, by + 4)
        return
    end

    if state.mode == "dialogue" then
        local line = state.npcOption:getCurrentLine()
        if not line then return end

        local npcText   = line:getNpcText(L)
        local active    = line:getActiveOptions()
        local boxW      = 400
        local boxX      = sx - boxW / 2
        local boxY      = sy - 120

        -- NPC text box
        love.graphics.setColor(0, 0, 0, 0.85)
        love.graphics.rectangle("fill", boxX, boxY, boxW, 36)
        love.graphics.setColor(1, 1, 1)
        love.graphics.print(npcText, boxX + 8, boxY + 8)

        if #active == 0 then
            -- auto-advance hint
            love.graphics.setColor(0.7, 0.7, 0.7)
            love.graphics.print("[E] Continue", boxX + boxW - 90, boxY + 10)
        else
            -- player options
            for i, opt in ipairs(active) do
                local oy = boxY + 40 + (i - 1) * 24
                if i == state.selected then
                    love.graphics.setColor(1, 1, 0)
                else
                    love.graphics.setColor(1, 1, 1)
                end
                love.graphics.print("> " .. opt:getText(L), boxX + 8, oy)
            end
        end

        -- leave hint
        love.graphics.setColor(0.5, 0.5, 0.5)
        love.graphics.print("[Esc] Leave", boxX + boxW - 80, boxY + 8)
        return
    end

    if state.mode == "menu" then
        local boxW = 200
        local boxX = sx - boxW / 2
        local boxY = sy - 120

        love.graphics.setColor(0, 0, 0, 0.85)
        love.graphics.rectangle("fill", boxX, boxY, boxW, (#state.options + 2) * 24 + 8)

        for i, npcOpt in ipairs(state.options) do
            local oy = boxY + 8 + (i - 1) * 24
            if i == state.selected then
                love.graphics.setColor(1, 1, 0)
            else
                love.graphics.setColor(1, 1, 1)
            end
            love.graphics.print("> " .. npcOpt:getLabel(L), boxX + 8, oy)
        end

        -- Leave option always last
        local leaveY = boxY + 8 + #state.options * 24
        if state.selected == #state.options + 1 then
            love.graphics.setColor(1, 1, 0)
        else
            love.graphics.setColor(0.7, 0.7, 0.7)
        end
        love.graphics.print("> " .. L.get("leave_chat"), boxX + 8, leaveY)

        love.graphics.setColor(1, 1, 1)
    end
end

return DialogueUI