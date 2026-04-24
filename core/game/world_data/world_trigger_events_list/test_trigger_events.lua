-- core/game/world_data/world_trigger_events_list/test_trigger_events.lua

local WorldTriggerEvent = require("core.game.world_elements.world_trigger_event")
local test_events       = require("core.event.events_list.test_events")
local S                 = require("core.state_system.states_names")

return {
    WorldTriggerEvent.new(
        "trigger_test_1",
        S.test.map_test,
        test_events.test_event_1,
        32,    -- radius in pixels
        true   -- oneShot: disables after first activation
    ),
}