-- core/npc/npc.lua
--
-- Base NPC class. Holds position, sprite, and a list of NpcOptions.

-- core/npc/npc.lua
local L        = require("core.localization.localization")
local Distance = require("utils.distance")

local Npc = {}
Npc.__index = Npc

local INTERACT_RANGE = 32

function Npc.new(id, sprite, options, initialDialogue)
    return setmetatable({
        id              = id,
        sprite          = love.graphics.newImage(sprite),
        options         = options or {},
        initialDialogue = initialDialogue or nil,  -- played before option menu
        x               = nil,
        y               = nil,
        talkTimer       = 0,
        talkText        = nil,
        inRange         = false,
    }, Npc)
end

-- Set or replace the initial dialogue
function Npc:setInitialDialogue(dialogue)
    self.initialDialogue = dialogue
end

-- Clear initial dialogue
function Npc:clearInitialDialogue()
    self.initialDialogue = nil
end

-- Activate an option by id
function Npc:activateOption(optionId)
    for _, npcOpt in ipairs(self.options) do
        if npcOpt.id == optionId then
            npcOpt:activate()
            return
        end
    end
    print("[WARN] Npc:activateOption: option not found: " .. optionId)
end

-- Deactivate an option by id
function Npc:deactivateOption(optionId)
    for _, npcOpt in ipairs(self.options) do
        if npcOpt.id == optionId then
            npcOpt:deactivate()
            return
        end
    end
    print("[WARN] Npc:deactivateOption: option not found: " .. optionId)
end

-- Activate a player dialogue option inside a specific dialogue option by id
function Npc:activatePlayerOption(optionId, nodeId, playerOptIndex)
    for _, npcOpt in ipairs(self.options) do
        if npcOpt.id == optionId and npcOpt.option.dialogue then
            local node = npcOpt.option.dialogue.nodes[nodeId]
            if node and node.playerOptions[playerOptIndex] then
                node.playerOptions[playerOptIndex]:activate()
                return
            end
        end
    end
    print("[WARN] Npc:activatePlayerOption: not found")
end

-- Deactivate a player dialogue option
function Npc:deactivatePlayerOption(optionId, nodeId, playerOptIndex)
    for _, npcOpt in ipairs(self.options) do
        if npcOpt.id == optionId and npcOpt.option.dialogue then
            local node = npcOpt.option.dialogue.nodes[nodeId]
            if node and node.playerOptions[playerOptIndex] then
                node.playerOptions[playerOptIndex]:deactivate()
                return
            end
        end
    end
    print("[WARN] Npc:deactivatePlayerOption: not found")
end

function Npc:getSimpleTalkOption()
    for _, npcOpt in ipairs(self.options) do
        if npcOpt.active and npcOpt.option.type == "simple_talk" then
            return npcOpt.option
        end
    end
    return nil
end

function Npc:getActiveOptions()
    local active = {}
    for _, npcOpt in ipairs(self.options) do
        if npcOpt.active then table.insert(active, npcOpt) end
    end
    return active
end

function Npc:playerInRange(px, py)
    if not self.x then return false end
    return Distance.inRange(px, py, self.x, self.y, INTERACT_RANGE)
end

function Npc:interact(px, py)
    if not self:playerInRange(px, py) then return nil end

    local simpleTalk = self:getSimpleTalkOption()
    if simpleTalk then
        return { type = "simple_talk", textKey = simpleTalk:interact() }
    end

    local active = self:getActiveOptions()

    if #active == 0 and not self.initialDialogue then
        return nil
    end

    -- Has initial dialogue or options → go to npc_interaction
    return { type = "interaction" }
end

function Npc:triggerSimpleTalk(textKey)
    self.talkText  = L.get(textKey)
    self.talkTimer = 3
end

function Npc:update(dt, px, py)
    if self.talkTimer > 0 then
        self.talkTimer = self.talkTimer - dt
        if self.talkTimer <= 0 then
            self.talkText  = nil
            self.talkTimer = 0
        end
    end
    if px and py then
        self.inRange = self:playerInRange(px, py)
    end
end

function Npc:draw(tx, ty, scale)
    if not self.x then return end
    local sx   = (self.x - tx) * scale
    local sy   = (self.y - ty) * scale
    local ox   = self.sprite:getWidth()  / 2
    local oy   = self.sprite:getHeight() / 2
    local font = love.graphics.getFont()

    love.graphics.setColor(1, 1, 1)
    love.graphics.draw(self.sprite, sx, sy, 0, scale, scale, ox, oy)

    love.graphics.setColor(1, 1, 0)
    local textW = font:getWidth(self.id)
    love.graphics.print(self.id, sx - textW / 2, sy - 12 * scale)

    -- Interact hint
    if self.inRange then
        local hint  = "[E]"
        local hintW = font:getWidth(hint)
        love.graphics.setColor(1, 1, 1)
        love.graphics.rectangle("fill", sx - hintW/2 - 4, sy - 28 * scale, hintW + 8, 18)
        love.graphics.setColor(0, 0, 0)
        love.graphics.print(hint, sx - hintW/2, sy - 26 * scale)
    end

    -- Simple talk bubble
    if self.talkText then
        local bw = font:getWidth(self.talkText) + 16
        local bx = sx - bw / 2
        local by = sy - 48 * scale
        love.graphics.setColor(0, 0, 0, 0.85)
        love.graphics.rectangle("fill", bx, by, bw, 24)
        love.graphics.setColor(1, 1, 1)
        love.graphics.print(self.talkText, bx + 8, by + 4)
    end

    love.graphics.setColor(1, 1, 1)
end

return Npc