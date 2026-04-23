-- core/event/handlers/test_events_handler.lua
--
-- Handles test events. Uses GameController for all game mutations.

local test_missions  = require("core.mission.missions_list.test_missions")

local function handle(eventId, controller)

    local gameName = controller.getGame().name

    -- test_event_1: complete first task
    if eventId == "test_event_1" then
        print("[TEST EVENT] test_event_1 triggered for: " .. gameName)
        local mission = test_missions.mission_test_1
        controller.completeTask(mission.missionId, mission.tasks[1].taskId)

    -- test_event_2: complete second task 
    elseif eventId == "test_event_2" then
        print("[TEST EVENT] test_event_2 triggered for: " .. gameName)
        local mission = test_missions.mission_test_1
        controller.completeTask(mission.missionId, mission.tasks[2].taskId)

    else
        return false
    end
    return true
end

return handle