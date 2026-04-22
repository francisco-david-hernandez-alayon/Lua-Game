-- core/game/world_data/objects/test_objects.lua
local WorldObject = require("core.game.world_elements.world_object")
local TEST = "assets/sprites/test/"

return {
    WorldObject.new("item_1", TEST .. "item_test.png", "map_test"),
    WorldObject.new("item_2", TEST .. "item_test.png", "map_test"),
    WorldObject.new("item_3", TEST .. "item_test.png", "map_test"),
    WorldObject.new("item_4", TEST .. "item_test.png", "map_test"),
    WorldObject.new("item_1", TEST .. "item_test.png", "map_test2"),
    WorldObject.new("item_2", TEST .. "item_test.png", "map_test2"),
}