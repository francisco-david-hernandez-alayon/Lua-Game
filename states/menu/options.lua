local Options = {}

local Settings = require("core.settings")

function Options.enter(sm, L)
    Options.sm = sm
    Options.L = L
end

function Options.draw()
    love.graphics.print(Options.L.get("options_title"), 100, 60)

    love.graphics.print(
        Options.L.get("language") .. ": " .. Settings.language,
        100, 120
    )

    love.graphics.print(
        Options.L.get("volume") .. ": " .. math.floor(Settings.volume * 100),
        100, 160
    )

    love.graphics.print(Options.L.get("controls_volume"), 100, 220)
    love.graphics.print(Options.L.get("controls_language"), 100, 250)
    love.graphics.print(Options.L.get("controls_back"), 100, 280)
end

function Options.keypressed(key)
    if key == "left" then
        Settings.volume = math.max(0, Settings.volume - 0.1)

    elseif key == "right" then
        Settings.volume = math.min(1, Settings.volume + 0.1)
    end

    if key == "l" then
        if Settings.language == "ES" then
            Settings.language = "EN"
        else
            Settings.language = "ES"
        end
    end

    if key == "return" then
        Settings.save()
        Options.sm.switch("main_menu")
    end
end

return Options