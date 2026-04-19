local StateManager = require("core.state_manager")

-- DEV SCREEN MODE
local DEV = true -- true = windowed half screen, false = fullscreen

if DEV then
    local sw = love.window.getDesktopDimensions()
    love.window.setMode(sw / 2, love.window.getDesktopDimensions() / 2)
else
    love.window.setMode(0, 0, {fullscreen = true})
end


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