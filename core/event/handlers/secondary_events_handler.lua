-- core/events/handlers/secondary_events_handler.lua
--
-- Handles all events of type "secondary".
-- Secondary events affect side content (side quests, optional npcs, etc).

local function handle(eventId, controller)
    if eventId == "secondary_event_1" then
        print("[SECONDARY EVENT] secondary_event_1 triggered")

    else
        return false
    end
    return true
end

return handle