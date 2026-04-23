-- core/mission/player_missions.lua
--
-- Manages all player missions grouped by type.
-- ATTRIBUTES:
--   mainMissions:      list of main Mission instances
--   secondaryMissions: list of secondary Mission instances
--   taskMissions:      list of task Mission instances
--   currentMission:    currently tracked Mission (nil if none)

local Mission = require("core.mission.mission")

local PlayerMissions = {}
PlayerMissions.__index = PlayerMissions

function PlayerMissions.new()
    return setmetatable({
        mainMissions      = {},
        secondaryMissions = {},
        taskMissions      = {},
        currentMission    = nil,
    }, PlayerMissions)
end

-- Returns the list for a given type
function PlayerMissions:_listForType(missionType)
    if missionType == "main"      then return self.mainMissions      end
    if missionType == "secondary" then return self.secondaryMissions end
    if missionType == "task"      then return self.taskMissions      end
    error("Unknown missionType: " .. tostring(missionType))
end

-- Find mission by id across all lists
function PlayerMissions:getMission(missionId)
    for _, list in ipairs({ self.mainMissions, self.secondaryMissions, self.taskMissions }) do
        for _, m in ipairs(list) do
            if m.missionId == missionId then return m end
        end
    end
    return nil
end

-- Add a mission to the correct list
function PlayerMissions:addMission(mission)
    assert(mission and mission.missionId, "mission must be a valid Mission instance")
    if self:getMission(mission.missionId) then
        print("[WARN] PlayerMissions:addMission: already exists: " .. mission.missionId)
        return nil, "mission_already_active"
    end
    local list = self:_listForType(mission.missionType)
    table.insert(list, mission)
    return true, "mission_added"
end

-- Complete a task — if mission fully complete, remove it and clear currentMission
-- Returns: ok, messageKey, completedMission (if finished)
function PlayerMissions:completeTask(missionId, taskId)
    local mission = self:getMission(missionId)
    if not mission then
        print("[WARN] PlayerMissions:completeTask: mission not found: " .. missionId)
        return nil, "mission_not_found"
    end

    local missionComplete = mission:completeTask(taskId)

    if missionComplete then
        -- Remove from list
        local list = self:_listForType(mission.missionType)
        for i, m in ipairs(list) do
            if m.missionId == missionId then
                table.remove(list, i)
                break
            end
        end
        -- Clear currentMission if it was this one
        if self.currentMission and self.currentMission.missionId == missionId then
            self.currentMission = nil
        end
        return true, "mission_completed", mission
    end

    return true, "task_completed"
end

-- Set current mission by id
function PlayerMissions:setCurrentMission(missionId)
    local mission = self:getMission(missionId)
    if not mission then
        return nil, "mission_not_found"
    end
    self.currentMission = mission
    return true, "mission_current_set"
end

function PlayerMissions:clearCurrentMission()
    self.currentMission = nil
end

-- Serialization
function PlayerMissions:toTable()
    local function serializeList(list)
        local t = {}
        for _, m in ipairs(list) do table.insert(t, m:toTable()) end
        return t
    end
    return {
        mainMissions      = serializeList(self.mainMissions),
        secondaryMissions = serializeList(self.secondaryMissions),
        taskMissions      = serializeList(self.taskMissions),
        currentMissionId  = self.currentMission and self.currentMission.missionId or nil,
    }
end

function PlayerMissions.fromTable(data)
    local pm = PlayerMissions.new()
    for _, d in ipairs(data.mainMissions      or {}) do table.insert(pm.mainMissions,      Mission.fromTable(d)) end
    for _, d in ipairs(data.secondaryMissions or {}) do table.insert(pm.secondaryMissions, Mission.fromTable(d)) end
    for _, d in ipairs(data.taskMissions      or {}) do table.insert(pm.taskMissions,      Mission.fromTable(d)) end
    if data.currentMissionId then
        pm.currentMission = pm:getMission(data.currentMissionId)
    end
    return pm
end

return PlayerMissions