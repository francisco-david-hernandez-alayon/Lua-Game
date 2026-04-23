-- core/state_system/states_registry.lua
local S = require("core.state_system.states_names")

local StatesRegistry = {}

local MenuPath = "states.menu"
local TestPath = "states.test"
local GamePath = "states.game"

StatesRegistry.states = {
    -- MENU (no level system)
    main_menu = MenuPath .. ".main_menu",
    play_menu = MenuPath .. ".play_menu",
    options   = MenuPath .. ".options",

    -- TESTING (level -1)
    main_test = TestPath .. ".main_test",
    [S.test.map_test]  = TestPath .. "." .. S.test.map_test,
    [S.test.map_test2] = TestPath .. "." .. S.test.map_test2,

    -- GAME STATES (no level prefix — shared across levels)
    game_summary          = GamePath .. ".game_summary",
    battle          = GamePath .. ".battle",
    npc_interaction = GamePath .. ".npc_interaction",
    inventory_state = GamePath .. ".inventory_state",
    list_missions = GamePath .. ".list_missions",

    -- GAME STATES (Game levels)
    --level1          = GamePath .. "." .. S.level_name .. ".--",
}   

function StatesRegistry.getState(name)
    local path = StatesRegistry.states[name]
    if not path then
        error("State not found: " .. tostring(name))
    end
    print("[OK] switch to " .. path)
    return require(path)
end

return StatesRegistry