local Distance = require("utils.distance")

local Door = {}
Door.__index = Door

local TRIGGER_DIST = 16  -- pixels to trigger door switch

function Door.new(id, sprite, targetState, open)
    assert(type(id) == "string", "id must be a string")
    assert(type(targetState) == "string", "targetState must be a string")
    return setmetatable({
        id          = id,
        sprite      = love.graphics.newImage(sprite),
        targetState = targetState,
        x    = nil,
        y    = nil,
        open = open or false,
    }, Door)
end

function Door:openDoor()
    self.open = true
end

function Door:update(px, py, sm)
    if not self.x   then return end
    if not self.open then return end

    if Distance.inRange(px, py, self.x, self.y, TRIGGER_DIST) then
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