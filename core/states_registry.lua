local StatesRegistry = {}

-- GET STATES
local StatesMenuPath = "states.menu"
local StatesGamePath = "states.game"
StatesRegistry.states = {
    main_menu = StatesMenuPath .. ".main_menu",
    play_menu = StatesMenuPath .. ".play_menu",
    options = StatesMenuPath .. ".options",
    game = StatesGamePath .. ".game",
}

function StatesRegistry.getState(name)
    local path = StatesRegistry.states[name]
    if not path then
        error("State not found: " .. tostring(name))
    end
    return require(path)
end

return StatesRegistry