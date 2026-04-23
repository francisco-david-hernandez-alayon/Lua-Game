-- core/state_system/state_manager.lua
local StateManager   = {}
local CurrentState   = nil
local StatesRegistry = require("core.state_system.states_registry")
local L              = require("core.localization.localization")

-- Given a state name it gets states from states_registry
function StateManager.resolveState(stateName)
    if type(stateName) == "string" then
        return StatesRegistry.getState(stateName)
    end

    return stateName
end

-- Switch states
function StateManager.switch(newState, ...)
    -- Get New State
    newState = StateManager.resolveState(newState)
    
    -- Execute Current State Exit Function 
    if CurrentState and CurrentState.exit then
        CurrentState.exit()
    end

    -- Change State and Execute New State Enter Function
    CurrentState = newState
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