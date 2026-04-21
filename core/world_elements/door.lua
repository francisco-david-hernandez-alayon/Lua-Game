-- core/world_elements/door.lua
local Distance = require("utils.distance")

local Door = {}
Door.__index = Door

local TRIGGER_DIST  = 16   -- pixels to trigger switch
local SAFE_DIST     = 48   -- player must reach this distance before door activates

function Door.new(id, sprite, targetId, targetState, open)
    assert(type(id) == "string",          "id must be a string")
    assert(type(targetId) == "string",          "target id must be a string")
    assert(type(targetState) == "string", "targetState must be a string")
    local self = setmetatable({
        id          = id,
        sprite      = love.graphics.newImage(sprite),
        targetId = targetId,
        targetState = targetState,
        x           = nil,
        y           = nil,
        open        = open or false,
        blocked     = false,  -- true when player spawned too close, blocks trigger
    }, Door)
    return self
end

function Door:openDoor()
    self.open = true
end

-- Call once after positions are resolved — blocks door if player is too close at spawn
function Door:checkSpawnProximity(px, py)
    if not self.x then return end
    if Distance.inRange(px, py, self.x, self.y, SAFE_DIST) then
        self.blocked = true

        --DEBUG
        -- print("-----> Player spawn close to door " .. self.id .. " Blocking door after player reach safe distance")
    end
end

function Door:update(px, py, sm, gameController)
    if not self.x   then return end
    if not self.open then return end

    -- Unblock once player moves far enough away
    if self.blocked then
        if not Distance.inRange(px, py, self.x, self.y, SAFE_DIST) then
            self.blocked = false
            
            --DEBUG
            -- print("-----> Player spawn not close close to door " .. self.id .. " Unblocking door")
        end
        return
    end

    if Distance.inRange(px, py, self.x, self.y, TRIGGER_DIST) then
        gameController.setDoorTarget(self.targetId)
        sm.switch(self.targetState)
    end
end

function Door:draw(tx, ty, scale)
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

return Door