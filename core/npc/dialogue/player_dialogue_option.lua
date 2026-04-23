-- core/npc/dialogue/player_dialogue_option.lua
--
-- A choice the player can make at a dialogue node.
-- Selecting it moves the dialogue to nextNodeId.
-- If no options exist on a node, dialogue auto-advances to nextNodeId.
-- eventOnAdvance: event emitted when this option is chosen

local PlayerDialogueOption = {}
PlayerDialogueOption.__index = PlayerDialogueOption

function PlayerDialogueOption.new(textKey, nextNodeId, eventOnAdvance)
    return setmetatable({
        textKey        = textKey,
        nextNodeId     = nextNodeId,
        active         = true,
        eventOnAdvance = eventOnAdvance or nil, 
    }, PlayerDialogueOption)
end

function PlayerDialogueOption:activate()   self.active = true  end
function PlayerDialogueOption:deactivate() self.active = false end
function PlayerDialogueOption:getText(L)   return L.get(self.textKey) end

return PlayerDialogueOption