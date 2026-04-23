-- core/mission/mission.lua
--
-- A mission with a list of tasks and a reward.
-- ATTRIBUTES:
--   missionId:   unique string identifier
--   nameKey:     localization key for mission name
--   descKey:     localization key for mission description
--   missionType: "main" | "secondary" | "task"
--   reward:      MissionReward instance
--   tasks:       list of Task instances
--   completed:   true when all tasks are done

local MissionReward = require("core.mission.mission_reward")
local Task          = require("core.mission.task")

local VALID_TYPES = { main = true, secondary = true, task = true }

local Mission = {}
Mission.__index = Mission

function Mission.new(data)
    assert(type(data.missionId)   == "string", "missionId must be a string")
    assert(type(data.nameKey)     == "string", "nameKey must be a string")
    assert(type(data.descKey)     == "string", "descKey must be a string")
    assert(VALID_TYPES[data.missionType], "missionType must be: main, secondary or task")
    assert(type(data.tasks)       == "table",  "tasks must be a table")
    assert(#data.tasks > 0,                    "tasks must not be empty")

    return setmetatable({
        missionId   = data.missionId,
        nameKey     = data.nameKey,
        descKey     = data.descKey,
        missionType = data.missionType,
        reward      = data.reward or MissionReward.new({}),
        tasks       = data.tasks,
        completed   = false,
    }, Mission)
end

function Mission:getName(L) return L.get(self.nameKey) end
function Mission:getDesc(L) return L.get(self.descKey) end

-- Returns task by id or nil
function Mission:getTask(taskId)
    for _, task in ipairs(self.tasks) do
        if task.taskId == taskId then return task end
    end
    return nil
end

-- Complete a task by id — returns true if mission is now fully complete
function Mission:completeTask(taskId)
    local task = self:getTask(taskId)
    if not task then
        print("[WARN] Mission:completeTask: task not found: " .. taskId)
        return false
    end
    if task.completed then return false end
    task:complete()
    -- Check if all tasks done
    for _, t in ipairs(self.tasks) do
        if not t.completed then return false end
    end
    self.completed = true
    return true
end

function Mission:allTasksComplete()
    for _, t in ipairs(self.tasks) do
        if not t.completed then return false end
    end
    return true
end

function Mission:toTable()
    local tasks = {}
    for _, t in ipairs(self.tasks) do table.insert(tasks, t:toTable()) end
    return {
        missionId   = self.missionId,
        nameKey     = self.nameKey,
        descKey     = self.descKey,
        missionType = self.missionType,
        reward      = self.reward:toTable(),
        tasks       = tasks,
        completed   = self.completed,
    }
end

function Mission.fromTable(data)
    local tasks = {}
    for _, td in ipairs(data.tasks or {}) do
        table.insert(tasks, Task.fromTable(td))
    end
    local m = Mission.new({
        missionId   = data.missionId,
        nameKey     = data.nameKey,
        descKey     = data.descKey,
        missionType = data.missionType,
        reward      = MissionReward.fromTable(data.reward or {}),
        tasks       = tasks,
    })
    m.completed = data.completed or false
    return m
end

return Mission