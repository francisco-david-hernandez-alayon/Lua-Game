-- core/game/world_elements/world_door.lua
--
-- A door world element. Extends WorldElement.
-- ATTRIBUTES:
--   id          → unique door identifier string
--   sprite      → love2d image
--   targetId    → id of the door to spawn at in the target state
--   targetState → state key to switch to when triggered
--   open        → whether the door is passable
--   blocked     → true when player spawned too close (prevents instant retrigger)

local WorldElement = require("core.game.world_elements.world_element")
local Distance     = require("utils.distance")

local WorldDoor = {}
WorldDoor.__index = WorldDoor
setmetatable(WorldDoor, { __index = WorldElement })

local TRIGGER_DIST = 16
local SAFE_DIST    = 48

function WorldDoor.new(id, sprite, targetId, targetState, mapState, open)
    assert(type(id)          == "string", "id must be a string")
    assert(type(targetId)    == "string", "targetId must be a string")
    assert(type(targetState) == "string", "targetState must be a string")
    assert(type(mapState)    == "string", "mapState must be a string")

    local self = WorldElement.new(mapState)
    setmetatable(self, WorldDoor)

    self.id          = id
    self.sprite      = love.graphics.newImage(sprite)
    self.targetId    = targetId
    self.targetState = targetState
    self.open        = open or false
    self.blocked     = false

    return self
end

function WorldDoor:openDoor()  self.open = true  end
function WorldDoor:closeDoor() self.open = false end

function WorldDoor:checkSpawnProximity(px, py)
    if not self.x then return end
    if Distance.inRange(px, py, self.x, self.y, SAFE_DIST) then
        self.blocked = true
    end
end

function WorldDoor:update(px, py, sm, gameController)
    if not self.x    then return end
    if not self.open then return end

    if self.blocked then
        if not Distance.inRange(px, py, self.x, self.y, SAFE_DIST) then
            self.blocked = false
        end
        return
    end

    if Distance.inRange(px, py, self.x, self.y, TRIGGER_DIST) then
        gameController.setDoorTarget(self.targetId)
        sm.switch(self.targetState)
    end
end

function WorldDoor:draw(tx, ty, scale)
    if not self.x or not self.visible then return end
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
    love.graphics.setColor(1, 1, 1)
    love.graphics.setPointSize(6)
    love.graphics.points(sx, sy)
end

return WorldDoor