-- core/game/world_elements/world_npc.lua
--
-- NPC world element. Extends WorldElement.
-- Handles all world-side logic: position, range detection,
-- interaction, simple talk bubble, hint display and drawing.
--
-- ATTRIBUTES:
--   npc:       Npc instance (data only)
--   bounds:    optional patrol area {x, y, w, h} (nil = static)
--   inRange:   true when player is within INTERACT_RANGE
--   talkTimer: countdown for simple talk bubble
--   talkText:  current simple talk string (nil when not showing)

local WorldElement = require("core.game.world_elements.world_element")
local Distance     = require("utils.distance")
local L            = require("core.localization.localization")

local WorldNpc = {}
WorldNpc.__index = WorldNpc
setmetatable(WorldNpc, { __index = WorldElement })

local INTERACT_RANGE = 32

function WorldNpc.new(npc, mapState, bounds)
    assert(npc,                                      "npc must be a valid Npc instance")
    assert(type(mapState) == "string",               "mapState must be a string")
    assert(bounds == nil or type(bounds) == "table", "bounds must be a table or nil")

    print("-----WORLD NPC, NPC ENABLED: " .. tostring(npc.interactEnabled))

    local self = WorldElement.new(mapState)
    setmetatable(self, WorldNpc)

    self.npc       = npc
    self.bounds    = bounds
    self.inRange   = false
    self.talkTimer = 0
    self.talkText  = nil

    return self
end

function WorldNpc:setPosition(x, y)
    assert(type(x) == "number", "x must be a number")
    assert(type(y) == "number", "y must be a number")
    self.x = x
    self.y = y
end

function WorldNpc:isMoving()
    return self.bounds ~= nil
end

-- Returns true if player is within interaction range
function WorldNpc:playerInRange(px, py)
    if not self.x then return false end
    return Distance.inRange(px, py, self.x, self.y, INTERACT_RANGE)
end

-- Show simple talk bubble above NPC for 3 seconds
function WorldNpc:triggerSimpleTalk(textKey)
    self.talkText  = L.get(textKey)
    self.talkTimer = 3
end

-- Main interact entry point — returns result table or nil
function WorldNpc:interact(px, py)
    if not self.visible              then return nil end
    if not self.npc.interactEnabled  then return nil end
    if not self:playerInRange(px, py) then return nil end

    local simpleTalk = self.npc:getSimpleTalkOption()
    if simpleTalk then
        return { type = "simple_talk", textKey = simpleTalk:interact() }
    end

    local active = self.npc:getActiveOptions()
    if #active == 0 and not self.npc.initialDialogue then return nil end

    return { type = "interaction" }
end

function WorldNpc:update(dt, px, py)
    if not self.visible then return end

    -- Update talk bubble timer
    if self.talkTimer > 0 then
        self.talkTimer = self.talkTimer - dt
        if self.talkTimer <= 0 then
            self.talkText  = nil
            self.talkTimer = 0
        end
    end

    -- Update range detection
    if px and py then
        self.inRange = self:playerInRange(px, py)
    end
end

function WorldNpc:draw(tx, ty, scale)
    if not self.x or not self.visible then return end

    local sx   = (self.x - tx) * scale
    local sy   = (self.y - ty) * scale
    local ox   = self.npc.sprite:getWidth()  / 2
    local oy   = self.npc.sprite:getHeight() / 2
    local font = love.graphics.getFont()

    -- Sprite
    love.graphics.setColor(1, 1, 1)
    love.graphics.draw(self.npc.sprite, sx, sy, 0, scale, scale, ox, oy)

    -- Id label
    love.graphics.setColor(1, 1, 0)
    local textW = font:getWidth(self.npc.id)
    love.graphics.print(self.npc.id, sx - textW / 2, sy - 12 * scale)

    -- Interact hint [E]
    if self.inRange and self.npc.interactEnabled then
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

return WorldNpc