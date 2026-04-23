-- core/event/handlers/test_events_handler.lua
local test_missions = require("core.mission.missions_list.test_missions")

local function handle(eventId, game)
    if eventId == "test_event_1" then
        print("[TEST EVENT] test_event_1 triggered for: " .. game.name)
        local mission = test_missions.mission_test_1
        local mission_id = mission.missionId
        local task_completed = mission.tasks[1].taskId

        local ok, msg, completed = game.playerMissions:completeTask(mission_id, task_completed)

        print("[MISSION] completeTask " .. task_completed, msg)
        if completed then
            -- Apply reward
            if completed.reward.rewardBits then
                game.inventory:addBytes(completed.reward.rewardBits)
            end
            print("[MISSION] mission_test_1 completed! Reward given.")
        end

    elseif eventId == "test_event_2" then
        print("[TEST EVENT] test_event_2 triggered for: " .. game.name)
        local mission = test_missions.mission_test_1
        local mission_id = mission.missionId
        local task_completed = mission.tasks[2].taskId

        local ok, msg, completed = game.playerMissions:completeTask(mission_id, task_completed)
        

        -- THE DISTRIBUTION OF REWARDS SHOULD BE AUTOMATED
        print("[MISSION] completeTask " .. task_completed, msg)
        if completed then
            if completed.reward.rewardBits then
                game.inventory:addBytes(completed.reward.rewardBits)
            end
            if completed.reward.rewardItems then
                for _, item in ipairs(completed.reward.rewardItems) do
                    game.inventory:addItem(item)
                end
            end
            print("[MISSION] " .. mission_id .. " completed! Reward given.")
        end

    else
        return false
    end
    return true
end

return handle