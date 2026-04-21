-- core/npc/dialogue/dialogue_node.lua
--
-- A single node in the dialogue graph.
-- speakerId:     id of the speaker (npc id or "player")
-- textKey:       localization key for the spoken text
-- nextNodeId:    default next node (nil = end of dialogue)
-- playerOptions: if non-empty, player must choose — each option has its own nextNodeId
-- eventOnAdvance: event emitted when this node is advanced past

local DialogueNode = {}
DialogueNode.__index = DialogueNode

function DialogueNode.new(dialogNodeId, speakerId, textKey, nextNodeId, playerOptions, eventOnAdvance)
    assert(eventOnAdvance == nil or type(eventOnAdvance) == "string",
        "eventOnAdvance must be a string or nil")
    return setmetatable({
        dialogNodeId    = dialogNodeId,
        speakerId       = speakerId,
        textKey         = textKey,
        nextNodeId      = nextNodeId or nil,
        playerOptions   = playerOptions or {},
        eventOnAdvance  = eventOnAdvance or nil,  
    }, DialogueNode)
end

function DialogueNode:getActiveOptions()
    local active = {}
    for _, opt in ipairs(self.playerOptions) do
        if opt.active then table.insert(active, opt) end
    end
    return active
end

function DialogueNode:getText(L)    return L.get(self.textKey) end
function DialogueNode:isPlayerTurn() return #self:getActiveOptions() > 0 end

return DialogueNode