-- core/state_system/states_names.lua
--
-- Central registry of all map state names grouped by level.
-- level -1 = test maps
-- level  1 = first area, etc.
--
-- Usage:
--   local S = require("core.state_system.states_names")
--   WorldObject.new("item_1", sprite, S.test.map_test)

local states_names = {}

-- Level -1: Test 
local level_test = {
    level      = -1,
    level_name = "test",
    map_test   = "map_test",
    map_test2  = "map_test2",
}

-- Level 0: (placeholder)
local level_0 = {
    level      = 0,
    level_name = "level_0",
    -- map_village = "map_village",
}

states_names.test    = level_test
states_names.level_1 = level_0

return states_names