local StateManager = require("core.state_manager")

-- Execute when game start
function love.load()
    local menu = require("states.menu")
    StateManager.switch(menu)
end

-- Update game state every frame
function love.update(dt)
    StateManager.update(dt)
end

-- Draw in current screen every frame
function love.draw()
    StateManager.draw()
end

-- Keyboward input
function love.keypressed(key)
    StateManager.keypressed(key)
end