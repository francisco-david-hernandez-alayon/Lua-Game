-- core/events/handlers/main_events_handler.lua
--
-- Handles all events of type "main".
-- Main events affect the core story progression.

local function handle(eventId, controller)
    if eventId == "main_event_1" then
        print("[MAIN EVENT] main_event_1 triggered")
        -- TODO: do something with game

    else
        return false
    end
    return true
end

return handle