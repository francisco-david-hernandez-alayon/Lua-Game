-- core/mission/task.lua
--
-- A single objective within a mission.
-- ATTRIBUTES:
--   taskId:                 unique string identifier
--   nameKey:                localization key for task name
--   descKey:                localization key for task description
--   level:                  level number where task takes place
--   mapState:               state key where task takes place
--   missionItemsRequired:   list of item nameKeys required (nil = none)
--   completed:              whether this task is done

local Task = {}
Task.__index = Task

function Task.new(data)
    assert(type(data.taskId)   == "string", "taskId must be a string")
    assert(type(data.nameKey)  == "string", "nameKey must be a string")
    assert(type(data.descKey)  == "string", "descKey must be a string")
    assert(type(data.level)    == "number", "level must be a number")
    assert(type(data.mapState) == "string", "mapState must be a string")
    assert(data.missionItemsRequired == nil or type(data.missionItemsRequired) == "table",
        "missionItemsRequired must be a table or nil")
    return setmetatable({
        taskId                = data.taskId,
        nameKey               = data.nameKey,
        descKey               = data.descKey,
        level                 = data.level,
        mapState              = data.mapState,
        missionItemsRequired  = data.missionItemsRequired or nil,
        completed             = false,
    }, Task)
end

function Task:complete()   self.completed = true  end
function Task:getName(L)   return L.get(self.nameKey) end
function Task:getDesc(L)   return L.get(self.descKey) end

function Task:toTable()
    return {
        taskId               = self.taskId,
        nameKey              = self.nameKey,
        descKey              = self.descKey,
        level                = self.level,
        mapState             = self.mapState,
        missionItemsRequired = self.missionItemsRequired,
        completed            = self.completed,
    }
end

function Task.fromTable(data)
    local t = Task.new(data)
    t.completed = data.completed or false
    return t
end

return Task