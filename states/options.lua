local Options = {}

function Options.enter(sm)
    Options.sm = sm
    Options.languageIndex = 1
    Options.volume = 0.5

    Options.languages = {"ES", "EN", "FR"}
end

function Options.draw()
    love.graphics.print("OPTIONS MENU", 100, 60)

    -- Language
    love.graphics.print(
        "Language: " .. Options.languages[Options.languageIndex],
        100, 120
    )

    -- Volume
    love.graphics.print(
        "Volume: " .. math.floor(Options.volume * 100),
        100, 160
    )

    love.graphics.print("LEFT/RIGHT = Volume", 100, 220)
    love.graphics.print("L = Change language", 100, 250)
    love.graphics.print("ENTER = Save & Back", 100, 280)
end

function Options.keypressed(key)
    if key == "left" then
        Options.volume = math.max(0, Options.volume - 0.1)
    elseif key == "right" then
        Options.volume = math.min(1, Options.volume + 0.1)
    end

    if key == "l" then
        Options.languageIndex = Options.languageIndex % #Options.languages + 1
    end

    if key == "return" then
        require("core.settings").set({
            language = Options.languages[Options.languageIndex],
            volume = Options.volume
        })

        Options.sm.switch(require("states.menu"))
    end
end

return Options