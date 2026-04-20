-- core/events/handlers/test_events_handler.lua
--
-- Handles all events of type "test".
-- Add new test events here by id.

local function handle(eventId, game)
    if eventId == "test_event_1" then
        print("[TEST EVENT] test_event_1 triggered for: " .. game.name)
        -- TODO: do something with game

    elseif eventId == "test_event_2" then
        print("[TEST EVENT] test_event_2 triggered for: " .. game.name)
        -- TODO: do something with game

    else
        return false  -- event not found in this handler
    end
    return true
end

return handle