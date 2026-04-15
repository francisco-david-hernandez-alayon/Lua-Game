local StateManager = {}
local CurrentState = nil
local StatesRegistry = require("core.states_registry")
local L = require("core.localization.localization")  -- Lang


-- Resolve require from ONLY game states
function StateManager.resolveState(state)
    if type(state) == "string" then
        return StatesRegistry.getState(state)
    end

    return state
end


-- SWITCH STATES
function StateManager.switch(state, ...)
    state = StateManager.resolveState(state)
    
    if CurrentState and CurrentState.exit then
        CurrentState.exit()
    end

    CurrentState = state

    if CurrentState.enter then
        CurrentState.enter(StateManager, L, ...)
    end
end


function StateManager.update(dt)
    if CurrentState and CurrentState.update then CurrentState.update(dt) end
end

function StateManager.draw()
    if CurrentState and CurrentState.draw then CurrentState.draw() end
end

function StateManager.keypressed(key)
    if CurrentState and CurrentState.keypressed then CurrentState.keypressed(key) end
end

return StateManager
