-- core/events/event.lua
--
-- Represents a game event.
-- eventId:   unique string identifier (e.g. "open_door_1")
-- eventType: "main" | "secondary" | "test"

local Event = {}
Event.__index = Event

local VALID_TYPES = { main = true, secondary = true, test = true }

function Event.new(eventId, eventType)
    assert(type(eventId) == "string", "eventId must be a string")
    assert(VALID_TYPES[eventType], "eventType must be: main, secondary or test")
    return setmetatable({
        eventId   = eventId,
        eventType = eventType,
    }, Event)
end

return Event