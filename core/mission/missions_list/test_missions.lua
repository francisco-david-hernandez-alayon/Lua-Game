-- core/mission/missions_list/test_missions.lua
--
-- Test missions. Use these ids when emitting events.

local Mission       = require("core.mission.mission")
local MissionReward = require("core.mission.mission_reward")
local Task          = require("core.mission.task")
local S             = require("core.state_system.states_names")
local Item          = require("core.inventory.item")
local Items        = require("core.inventory.items_list.test_items")

local test_missions = {}

-- Test mission 1: two tasks, 100 bits + 200 exp reward
test_missions.mission_test_1 = Mission.new({
    missionId   = "mission_test_1",
    nameKey     = "mission_test_1_name",
    descKey     = "mission_test_1_desc",
    missionType = "task",
    reward      = MissionReward.new({
        expReward  = 200,
        rewardBits = 100,
        rewardItems =  { Items.item_test_a }
    }),
    tasks = {
        Task.new({
            taskId   = "test_task_1",
            nameKey  = "test_task_1_name",
            descKey  = "test_task_1_desc",
            level    = -1,
            mapState = S.test.map_test,
        }),
        Task.new({
            taskId   = "test_task_2",
            nameKey  = "test_task_2_name",
            descKey  = "test_task_2_desc",
            level    = -1,
            mapState = S.test.map_test,
        }),
    },
})

return test_missions