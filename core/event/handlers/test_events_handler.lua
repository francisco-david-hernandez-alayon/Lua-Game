-- core/event/handlers/test_events_handler.lua
--
-- Handles test events. Uses GameController for all game mutations.

local GameController = require("core.game.game_controller")
local test_missions  = require("core.mission.missions_list.test_missions")

local function handle(eventId, game)

    -- ── test_event_1: complete first task ─────────────────────────
    if eventId == "test_event_1" then
        print("[TEST EVENT] test_event_1 triggered for: " .. game.name)
        local mission = test_missions.mission_test_1
        GameController.completeTask(mission.missionId, mission.tasks[1].taskId)

    -- ── test_event_2: complete second task ────────────────────────
    elseif eventId == "test_event_2" then
        print("[TEST EVENT] test_event_2 triggered for: " .. game.name)
        local mission = test_missions.mission_test_1
        GameController.completeTask(mission.missionId, mission.tasks[2].taskId)

    else
        return false
    end
    return true
end

return handle