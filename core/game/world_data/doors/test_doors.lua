-- core/game/world_data/doors/test_doors.lua
local WorldDoor = require("core.game.world_elements.world_door")
local TEST = "assets/sprites/test/"

return {
    WorldDoor.new("door_1_map_test",  "map_test",  true, TEST .. "door_1.png", "door_1_map_test2", "map_test2"),
    WorldDoor.new("door_1_map_test2", "map_test2", true, TEST .. "door_1.png", "door_1_map_test",  "map_test"),
    WorldDoor.new("door_2_map_test2", "map_test2", true, TEST .. "door_1.png", "door_1_map_test",  "map_test"),
}