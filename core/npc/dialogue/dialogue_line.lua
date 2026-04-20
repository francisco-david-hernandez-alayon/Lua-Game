-- core/npc/dialogue/dialogue_line.lua
--
-- A single line in a dialogue sequence.
-- npcTextKey: localization key for the NPC's speech.
-- playerOptions: list of PlayerDialogueOption.
--   - If empty → dialogue advances automatically to the next line.
--   - If one or more → player must pick one, which jumps to that line's id.

local DialogueLine = {}
DialogueLine.__index = DialogueLine

function DialogueLine.new(id, npcTextKey, playerOptions)
    return setmetatable({
        id            = id,
        npcTextKey    = npcTextKey,
        playerOptions = playerOptions or {},  -- list of PlayerDialogueOption
    }, DialogueLine)
end

-- Returns only active player options
function DialogueLine:getActiveOptions()
    local active = {}
    for _, opt in ipairs(self.playerOptions) do
        if opt.active then
            table.insert(active, opt)
        end
    end
    return active
end

-- Returns true if dialogue should auto-advance (no active player options)
function DialogueLine:autoAdvance()
    return #self:getActiveOptions() == 0
end

function DialogueLine:getNpcText(L)
    return L.get(self.npcTextKey)
end

return DialogueLine