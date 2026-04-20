-- core/npc/npc.lua
--
-- Base NPC class. Holds position, sprite, and a list of NpcOptions.
--
-- INTERACTION RULES:
--   1. If the NPC has an active SimpleTalkOption → trigger it directly, show bubble above NPC.
--   2. If no SimpleTalkOption → show menu of all active options.
--   3. If only one active option → trigger it directly, skip menu.
--
-- Use Distance.inRange() to check if player is close enough before calling interact().

local L        = require("core.localization.localization")
local Distance = require("utils.distance")

local Npc = {}
Npc.__index = Npc

local INTERACT_RANGE = 32

function Npc.new(id, sprite, options)
    return setmetatable({
        id        = id,
        sprite    = love.graphics.newImage(sprite),
        options   = options or {},
        x         = nil,
        y         = nil,
        talkTimer = 0,
        talkText  = nil,
    }, Npc)
end

-- Returns active SimpleTalkOption if present — takes full priority
function Npc:getSimpleTalkOption()
    for _, npcOpt in ipairs(self.options) do
        if npcOpt.active and npcOpt.option.type == "simple_talk" then
            return npcOpt.option
        end
    end
    return nil
end

-- Returns all active options
function Npc:getActiveOptions()
    local active = {}
    for _, npcOpt in ipairs(self.options) do
        if npcOpt.active then
            table.insert(active, npcOpt)
        end
    end
    return active
end

-- Returns true if player is within interaction range
function Npc:playerInRange(px, py)
    if not self.x then return false end
    return Distance.inRange(px, py, self.x, self.y, INTERACT_RANGE)
end

-- Main interact entry point
function Npc:interact(px, py)
    if not self:playerInRange(px, py) then return nil end

    local simpleTalk = self:getSimpleTalkOption()
    if simpleTalk then
        return { type = "simple_talk", textKey = simpleTalk:interact() }
    end

    local active = self:getActiveOptions()

    if #active == 1 then
        local opt = active[1].option
        if opt.type == "dialogue" then return { type = "dialogue", option = opt } end
        if opt.type == "trade"    then return { type = "trade",    shop   = opt } end
        if opt.type == "combat"   then return { type = "combat",   option = opt } end
    end

    return { type = "menu", options = active }
end

-- Triggers the simple talk bubble above the NPC for 3 seconds
function Npc:triggerSimpleTalk(textKey)
    self.talkText  = L.get(textKey)
    self.talkTimer = 3
end

function Npc:update(dt)
    if self.talkTimer > 0 then
        self.talkTimer = self.talkTimer - dt
        if self.talkTimer <= 0 then
            self.talkText  = nil
            self.talkTimer = 0
        end
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

    -- NPC id label
    love.graphics.setColor(1, 1, 0)
    local textW = font:getWidth(self.id)
    love.graphics.print(self.id, sx - textW / 2, sy - 12 * scale)

    -- Simple talk bubble above NPC
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