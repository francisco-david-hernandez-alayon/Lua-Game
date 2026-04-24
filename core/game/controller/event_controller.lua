-- core/game/controller/event_controller.lua
--
---- Routes events to the correct handler by type.
-- Used internally by GameController — do not call directly.

local Event = require("core.event.event")

local EventController = {}

function EventController.emit(handlers, event, controller)
    -- Get event data
    local eventId = event.eventId
    local eventType = event.eventType

    assert(eventId and eventType, "[EventController] invalid event")

    local event = Event.new(eventId, eventType)

    local handler = handlers[event.eventType]
    if not handler then
        print("[ERROR] EventController: no handler for type: " .. event.eventType)
        return
    end

    local handled = handler(event.eventId, controller)

    if not handled then
        print("[ERROR] EventController: event not found: " ..
              event.eventId .. " in type: " .. event.eventType)
    end
end

return EventController