-- core/game/world_elements/world_element.lua
--
-- Base class for all world elements.
-- ATTRIBUTES:
--   x        → world x position (set by map loader)
--   y        → world y position (set by map loader)
--   mapState → state key where this element lives (e.g. "map_test")
--   visible  → whether this element should be drawn and updated

local WorldElement = {}
WorldElement.__index = WorldElement

function WorldElement.new(mapState)
    assert(type(mapState) == "string", "mapState must be a string")
    return setmetatable({
        x        = nil,
        y        = nil,
        mapState = mapState,
        visible  = true,
    }, WorldElement)
end

function WorldElement:setPosition(x, y)
    assert(type(x) == "number", "x must be a number")
    assert(type(y) == "number", "y must be a number")
    self.x = x
    self.y = y
end

function WorldElement:show() self.visible = true  end
function WorldElement:hide() self.visible = false end
function WorldElement:isVisible() return self.visible end

return WorldElement