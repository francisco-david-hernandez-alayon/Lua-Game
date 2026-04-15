local StateManager = require("core.state_manager")

-- Execute when game start
function love.load()
    require("core.settings").load()
    StateManager.switch("main_menu")
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