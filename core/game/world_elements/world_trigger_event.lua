-- core/game/world_elements/world_trigger_event.lua
--
-- A world trigger that emits a game event when the player enters its radius.
--
-- ATTRIBUTES:
--   id:           unique trigger identifier
--   event:        Event instance to emit when triggered
--   radius:       activation radius in pixels
--   oneShot:      if true, disables after first activation
--   enabled:      whether this trigger can be activated

local WorldElement   = require("core.game.world_elements.world_element")
local Distance       = require("utils.distance")

local WorldTriggerEvent = {}
WorldTriggerEvent.__index = WorldTriggerEvent
setmetatable(WorldTriggerEvent, { __index = WorldElement })

function WorldTriggerEvent.new(id, mapState, event, radius, oneShot)
    assert(type(id)       == "string",  "id must be a string")
    assert(type(mapState) == "string",  "mapState must be a string")
    assert(event and event.eventId,     "event must be a valid Event instance")
    assert(type(radius)   == "number",  "radius must be a number")
    assert(type(oneShot)  == "boolean", "oneShot must be a boolean")

    local self = WorldElement.new(mapState)
    setmetatable(self, WorldTriggerEvent)

    self.id      = id
    self.event   = event
    self.radius  = radius
    self.oneShot = oneShot
    self.enabled = true

    return self
end

function WorldTriggerEvent:enable()  self.enabled = true  end
function WorldTriggerEvent:disable() self.enabled = false end

-- Call every frame — emits event if player is in radius and trigger is enabled
function WorldTriggerEvent:update(px, py, gameController)
    if not self.x       then return end
    if not self.enabled then return end

    if Distance.inRange(px, py, self.x, self.y, self.radius) then
        print("[WorldTriggerEvent] triggered:", self.id)
        gameController.emit(self.event)
        if self.oneShot then
            self:disable()
            print("[WorldTriggerEvent] oneShot disabled:", self.id)
        end
    end
end

function WorldTriggerEvent:toTable()
    return {
        id       = self.id,
        mapState = self.mapState,
        visible  = self.visible,
        enabled  = self.enabled,
    }
end

return WorldTriggerEvent