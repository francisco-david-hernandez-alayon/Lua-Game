-- core/world_elements/moving_npc.lua
local MovingNpc = {}
MovingNpc.__index = MovingNpc

function MovingNpc.new(id, sprite)
    return setmetatable({
        id     = id,
        sprite = love.graphics.newImage(sprite),
        x      = nil,
        y      = nil,
        bounds = nil,
    }, MovingNpc)
end

function MovingNpc:draw(tx, ty, scale)
    if not self.x then return end
    local sx = (self.x - tx) * scale
    local sy = (self.y - ty) * scale
    local ox = self.sprite:getWidth() / 2
    local oy = self.sprite:getHeight() / 2
    love.graphics.setColor(1, 1, 1)
    love.graphics.draw(self.sprite, sx, sy, 0, scale, scale, ox, oy)
    love.graphics.setColor(1, 1, 0)
    local font = love.graphics.getFont()
    local textW = font:getWidth(self.id)
    love.graphics.print(self.id, sx - textW / 2, sy - 12 * scale)
    love.graphics.setColor(1, 1, 1)

    -- Debug center point
    love.graphics.setColor(1, 1, 1)
    love.graphics.setPointSize(6)
    love.graphics.points(sx, sy)
end

return MovingNpc