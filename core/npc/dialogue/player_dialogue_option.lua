-- core/npc/dialogue/player_dialogue_option.lua
--
-- A choice the player can make at a dialogue node.
-- Selecting it moves the dialogue to nextNodeId.
-- If no options exist on a node, dialogue auto-advances to nextNodeId.

local PlayerDialogueOption = {}
PlayerDialogueOption.__index = PlayerDialogueOption

function PlayerDialogueOption.new(textKey, nextNodeId)
    return setmetatable({
        textKey    = textKey,    -- localization key for display text
        nextNodeId = nextNodeId, -- node to jump to when chosen
        active     = true,
    }, PlayerDialogueOption)
end

function PlayerDialogueOption:activate()   self.active = true  end
function PlayerDialogueOption:deactivate() self.active = false end

function PlayerDialogueOption:getText(L)
    return L.get(self.textKey)
end

return PlayerDialogueOption