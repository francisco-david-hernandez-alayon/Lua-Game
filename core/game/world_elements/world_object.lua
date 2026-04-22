-- core/game/world_elements/world_object.lua
--
-- A pickable object in the world. Extends WorldElement.
-- ATTRIBUTES:
--   id     → unique object identifier
--   sprite → love2d image
--   picked → whether the object has been picked up

local WorldElement = require("core.game.world_elements.world_element")

local WorldObject = {}
WorldObject.__index = WorldObject
setmetatable(WorldObject, { __index = WorldElement })

function WorldObject.new(id, sprite, mapState)
    assert(type(id)       == "string", "id must be a string")
    assert(type(mapState) == "string", "mapState must be a string")

    local self = WorldElement.new(mapState)
    setmetatable(self, WorldObject)

    self.id     = id
    self.sprite = love.graphics.newImage(sprite)
    self.picked = false

    return self
end

function WorldObject:pick() self.picked = true end

function WorldObject:draw(tx, ty, scale)
    if not self.x or self.picked or not self.visible then return end
    local sx   = (self.x - tx) * scale
    local sy   = (self.y - ty) * scale
    local ox   = self.sprite:getWidth()  / 2
    local oy   = self.sprite:getHeight() / 2
    local font = love.graphics.getFont()
    love.graphics.setColor(1, 1, 1)
    love.graphics.draw(self.sprite, sx, sy, 0, scale, scale, ox, oy)
    love.graphics.setColor(1, 0.8, 0)
    local textW = font:getWidth(self.id)
    love.graphics.print(self.id, sx - textW / 2, sy - 12 * scale)
    love.graphics.setColor(1, 1, 1)
end

return WorldObject