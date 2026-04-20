-- core/npc/dialogue/player_dialogue_option.lua
--
-- Represents a choice the player can make during a dialogue.
-- If a dialogue_line has no player_dialogue_options, dialogue advances automatically.
-- If it has one or more, the player must choose — each option jumps to a target line id.

local PlayerDialogueOption = {}
PlayerDialogueOption.__index = PlayerDialogueOption

function PlayerDialogueOption.new(id, textKey, jumpsTo)
    return setmetatable({
        id      = id,       -- unique identifier for this option
        textKey = textKey,  -- localization key for display text
        active  = true,     -- inactive options are hidden
        jumpsTo = jumpsTo,  -- id of the dialogue_line to jump to when chosen
    }, PlayerDialogueOption)
end

function PlayerDialogueOption:activate()   self.active = true  end
function PlayerDialogueOption:deactivate() self.active = false end

function PlayerDialogueOption:getText(L)
    return L.get(self.textKey)
end

return PlayerDialogueOption