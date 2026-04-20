-- core/npc/npc.lua
--
-- Base NPC class. Holds position, sprite, and a list of NpcOptions.
--
-- INTERACTION RULES:
--   1. If the NPC has an active TalkOption → use it directly, skip option menu.
--      (Even if other options exist, talk takes priority when active.)
--   2. If no active TalkOption → show a menu of all active options.
--   3. If only one active option (non-talk) → trigger it directly, skip menu.
--
-- Use Distance.inRange() to check if player is close enough before calling interact().

local Distance = require("utils.distance")

local Npc = {}
Npc.__index = Npc

local INTERACT_RANGE = 32  -- pixels

function Npc.new(id, sprite, options)
    -- options: list of NpcOption
    return setmetatable({
        id      = id,
        sprite  = love.graphics.newImage(sprite),
        options = options or {},
        x       = nil,
        y       = nil,
    }, Npc)
end

-- Returns active TalkOption if present
-- Returns active SimpleTalkOption if present — takes full priority
function Npc:getSimpleTalkOption()
    for _, npcOpt in ipairs(self.options) do
        if npcOpt.active and npcOpt.option.type == "simple_talk" then
            return npcOpt.option
        end
    end
    return nil
end


-- Returns all active non-talk options
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

-- Main interact entry point. Returns interaction result:
--   { type = "talk",   line = DialogueLine }
--   { type = "trade",  shop = TradeOption  }
--   { type = "combat", option = CombatOption }
--   { type = "menu",   options = list of NpcOption }  -- player must pick
--   nil if not in range
function Npc:interact(px, py)
    if not self:playerInRange(px, py) then return nil end

    -- SimpleTalk takes full priority over everything else
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

function Npc:draw(tx, ty, scale)
    if not self.x then return end
    local sx = (self.x - tx) * scale
    local sy = (self.y - ty) * scale
    local ox = self.sprite:getWidth()  / 2
    local oy = self.sprite:getHeight() / 2
    love.graphics.setColor(1, 1, 1)
    love.graphics.draw(self.sprite, sx, sy, 0, scale, scale, ox, oy)
    love.graphics.setColor(1, 1, 0)
    local font  = love.graphics.getFont()
    local textW = font:getWidth(self.id)
    love.graphics.print(self.id, sx - textW / 2, sy - 12 * scale)
    love.graphics.setColor(1, 1, 1)
    love.graphics.setPointSize(6)
    love.graphics.points(sx, sy)
end

return Npc