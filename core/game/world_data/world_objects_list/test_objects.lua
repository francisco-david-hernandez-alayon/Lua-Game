-- core/game/world_data/world_objects_list/test_objects.lua

local WorldObject = require("core.game.world_elements.world_object")
local S           = require("core.state_system.states_names")
local Items       = require("core.inventory.items_list.test_items")

local TEST = "assets/sprites/test/"

return {
    WorldObject.new("item_1_map_test",  TEST .. "item_test.png", Items.item_test_a, S.test.map_test),
    WorldObject.new("item_2_map_test",  TEST .. "item_test.png", Items.item_test_b, S.test.map_test),
    WorldObject.new("item_3_map_test",  TEST .. "item_test.png", Items.mission_item_a, S.test.map_test),
    WorldObject.new("item_4_map_test",  TEST .. "item_test.png", Items.item_test_a, S.test.map_test),

    WorldObject.new("item_1_map_test2", TEST .. "item_test.png", Items.item_test_b, S.test.map_test2),
    WorldObject.new("item_2_map_test2", TEST .. "item_test.png", Items.mission_item_a, S.test.map_test2),
}