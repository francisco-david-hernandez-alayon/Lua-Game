-- core/game/world_data/world_doors_list/test_doors.lua
local WorldDoor = require("core.game.world_elements.world_door")
local S         = require("core.state_system.states_names")
local TEST      = "assets/sprites/test/"

return {
    WorldDoor.new("door_1_map_test",  S.test.map_test,  true, TEST .. "door_1.png", "door_1_map_test2", S.test.map_test2),
    WorldDoor.new("door_1_map_test2", S.test.map_test2, true, TEST .. "door_1.png", "door_1_map_test",  S.test.map_test),
    WorldDoor.new("door_2_map_test2", S.test.map_test2, true, TEST .. "door_1.png", "door_1_map_test",  S.test.map_test),
}