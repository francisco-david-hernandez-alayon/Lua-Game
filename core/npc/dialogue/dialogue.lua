-- core/npc/dialogue/dialogue.lua
--
-- Directed graph of DialogueNodes.
-- Nodes are indexed by dialogNodeId.
-- advance() follows nextNodeId of current node.
-- choose(i) follows nextNodeId of the i-th active player option.

local Dialogue = {}
Dialogue.__index = Dialogue

function Dialogue.new(nodes)
    -- nodes: ordered list of DialogueNode — first is entry point
    local self  = setmetatable({}, Dialogue)
    self.nodes   = {}
    self.startId = nil
    self.currentNodeId = nil
    self.finished      = false

    for i, node in ipairs(nodes) do
        self.nodes[node.dialogNodeId] = node
        if i == 1 then
            self.startId       = node.dialogNodeId
            self.currentNodeId = node.dialogNodeId
        end
    end

    return self
end

function Dialogue:getCurrentNode()
    if not self.currentNodeId then return nil end
    return self.nodes[self.currentNodeId]
end

function Dialogue:advance()
    local node = self:getCurrentNode()
    if not node then return end

    if node.nextNodeId and self.nodes[node.nextNodeId] then
        self.currentNodeId = node.nextNodeId
    else
        self.finished      = true
        self.currentNodeId = nil
    end
end

function Dialogue:choose(optionIndex)
    local node = self:getCurrentNode()
    if not node then return end

    local active = node:getActiveOptions()
    local opt    = active[optionIndex]
    if not opt then return end

    if opt.nextNodeId and self.nodes[opt.nextNodeId] then
        self.currentNodeId = opt.nextNodeId
    else
        self.finished      = true
        self.currentNodeId = nil
    end
end

function Dialogue:isFinished()
    return self.finished
end

function Dialogue:reset()
    self.finished      = false
    self.currentNodeId = self.startId
end

return Dialogue