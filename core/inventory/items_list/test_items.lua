-- core/inventory/items_list/test_items.lua

local Item        = require("core.inventory.item")
local MissionItem = require("core.inventory.mission_item")

local test_items = {}

test_items.item_test_a = Item.new("test_item_a", "test_item_a_desc", 1)
test_items.item_test_b = Item.new("test_item_b", "test_item_b_desc", 5)

test_items.mission_item_a = MissionItem.new("mission_item_a", "mission_item_a_desc")

return test_items