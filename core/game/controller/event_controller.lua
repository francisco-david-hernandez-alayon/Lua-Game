-- core/game/controller/event_controller.lua
--
-- Routes events to the correct handler by type.
-- Used internally by GameController — do not call directly.

local Event = require("core.event.event")

local handlers = {
    main      = require("core.event.handlers.main_events_handler"),
    secondary = require("core.event.handlers.secondary_events_handler"),
    test      = require("core.event.handlers.test_events_handler"),
}

local EventController = {}

-- Emit
function EventController.emit(event, game)
    assert(event and event.eventId and event.eventType, "[EventController] invalid event")

    local handler = handlers[event.eventType]
    if not handler then
        print("[ERROR] EventController: no handler for type: " .. event.eventType)
        return
    end

    local handled = handler(event.eventId, game)
    if not handled then
        print("[ERROR] EventController: event not found: " .. event.eventId ..
              " in type: " .. event.eventType)
    end
end

function EventController.trigger(eventId, eventType, game)
    print("[EventController] trigger:", eventId, eventType)
    EventController.emit(Event.new(eventId, eventType), game)
end

return EventController