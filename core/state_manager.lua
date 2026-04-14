-- Export modules
local StateManager = {}

local CurrentState = nil

function StateManager.switch(state, ...)
    if CurrentState and CurrentState.exit then CurrentState.exit() end

    CurrentState = state

    if CurrentState.enter then
        CurrentState.enter(StateManager, ...)
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