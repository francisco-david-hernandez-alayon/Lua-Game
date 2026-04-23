-- core/game/controller/mission_controller.lua
--
-- Handles all mission operations for the current game session.
-- Reward distribution is automated via InventoryController.applyReward.
-- Used internally by GameController — do not call directly.

local MissionController = {}

-- Add
function MissionController.addMission(playerMissions, mission)
    local ok, msg = playerMissions:addMission(mission)
    print("[MissionController] addMission:", mission.missionId, msg)
    return ok, msg
end

-- Complete task 
function MissionController.completeTask(playerMissions, inventory, inventoryController, missionId, taskId)
    local ok, msg, completed = playerMissions:completeTask(missionId, taskId)
    print("[MissionController] completeTask:", taskId, msg)
    if completed then
        print("[MissionController] mission completed:", missionId)
        inventoryController.applyReward(inventory, completed.reward)
    end
    return ok, msg, completed
end

-- Current mission
function MissionController.setCurrentMission(playerMissions, missionId)
    local ok, msg = playerMissions:setCurrentMission(missionId)
    print("[MissionController] setCurrentMission:", missionId, msg)
    return ok, msg
end

function MissionController.getCurrentMission(playerMissions)
    return playerMissions.currentMission
end

return MissionController