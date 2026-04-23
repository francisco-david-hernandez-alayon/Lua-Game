local GameSummary = {}

local Game 

function GameSummary.enter(sm, L, game)
    GameSummary.sm = sm
    GameSummary.L = L
    GameSummary.game = game

    -- fallback if the game is not passed 
    if not GameSummary.game then
        Game = require("core.game.game")
        GameSummary.game = Game.new({
            name = "DEBUG PLAYER"
        })
    end
end

function GameSummary.update(dt)
    
end

function GameSummary.draw()
    local DateFormat = require("utils.date_format")

    love.graphics.print("=== GAME STATE ===", 100, 60)

    if GameSummary.game then
        love.graphics.print("Name: " .. tostring(GameSummary.game.name), 100, 120)
        love.graphics.print(
            "Created: " .. DateFormat.format(GameSummary.game.created_at),
            100, 150
        )

        love.graphics.print(
            "Last Save: " .. DateFormat.format(GameSummary.game.last_save),
            100, 180
        )
    else
        love.graphics.print("NO GAME LOADED", 100, 120)
    end

    love.graphics.print("ESC / BACKSPACE = back", 100, 260)

    love.graphics.print("Press S to SAVE", 100, 300)

end

function GameSummary.keypressed(key)
    if key == "escape" or key == "backspace" then
        GameSummary.sm.switch("main_menu")

    elseif key == "s" then
        local SaveSystem = require("core.save_system")
        SaveSystem.save(GameSummary.game.slot, GameSummary.game)
    end
end

function GameSummary.exit()
    GameSummary.game = nil
end

return GameSummary