local GameState = {}

local Game 

function GameState.enter(sm, L, game)
    GameState.sm = sm
    GameState.L = L
    GameState.game = game

    -- fallback if the game is not passed 
    if not GameState.game then
        Game = require("core.game.game")
        GameState.game = Game.new({
            name = "DEBUG PLAYER"
        })
    end
end

function GameState.update(dt)
    
end

function GameState.draw()
    local DateFormat = require("utils.date_format")

    love.graphics.print("=== GAME STATE ===", 100, 60)

    if GameState.game then
        love.graphics.print("Name: " .. tostring(GameState.game.name), 100, 120)
        love.graphics.print(
            "Created: " .. DateFormat.format(GameState.game.created_at),
            100, 150
        )

        love.graphics.print(
            "Last Save: " .. DateFormat.format(GameState.game.last_save),
            100, 180
        )
    else
        love.graphics.print("NO GAME LOADED", 100, 120)
    end

    love.graphics.print("ESC / BACKSPACE = back", 100, 260)

    love.graphics.print("Press S to SAVE", 100, 300)

end

function GameState.keypressed(key)
    if key == "escape" or key == "backspace" then
        GameState.sm.switch("main_menu")

    elseif key == "s" then
        local SaveSystem = require("core.save_system")
        SaveSystem.save(GameState.game.slot, GameState.game)
    end
end

function GameState.exit()
    GameState.game = nil
end

return GameState