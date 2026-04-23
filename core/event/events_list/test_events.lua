-- core/event/events_list/test_events.lua

local Event = require("core.event.event")

local test_events = {}

test_events.test_event_1 = Event.new("test_event_1", "test")
test_events.test_event_2 = Event.new("test_event_2", "test")

return test_events