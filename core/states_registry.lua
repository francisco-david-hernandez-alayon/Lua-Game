local StatesRegistry = {}

-- GET STATES
local StatesMenuPath = "states.menu"
local StatesTestPath = "states.test"
local StatesGamePath = "states.game"
StatesRegistry.states = {
    -- MENU
    main_menu = StatesMenuPath .. ".main_menu",
    play_menu = StatesMenuPath .. ".play_menu",
    options = StatesMenuPath .. ".options",

    -- TESTING
    main_test = StatesTestPath .. ".main_test",
    map_test = StatesTestPath .. ".map_test",
    map_test2 = StatesTestPath .. ".map_test2",

    -- GAME
    game = StatesGamePath .. ".game",
    npc_interaction = StatesGamePath .. ".npc_interaction",
    inventory_state = StatesGamePath .. ".inventory_state",
    
}

function StatesRegistry.getState(name)
    local path = StatesRegistry.states[name]
    if not path then
        error("State not found: " .. tostring(name))
    end

    print("[OK] switch to " .. path)
    print("\n\n")
    return require(path)
end

return StatesRegistry