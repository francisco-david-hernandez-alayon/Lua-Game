-- states/menu/options.lua

local AudioManager = require("core.audio.audio_manager")
local Settings = require("core.settings")

local Options = {
    selected = 1
}

local STEP = 0.1

local function clamp(value)
    return math.max(0, math.min(1, value))
end

local function updateSelectedVolume(delta)
    if Options.selected == 1 then
        Settings.masterVolume = clamp(Settings.masterVolume + delta)
    elseif Options.selected == 2 then
        Settings.musicVolume = clamp(Settings.musicVolume + delta)
    elseif Options.selected == 3 then
        Settings.sfxVolume = clamp(Settings.sfxVolume + delta)
    end

    AudioManager.refreshVolumes()
end

local function drawOption(label, value, y, isSelected)
    local prefix = isSelected and "> " or "  "
    love.graphics.print(prefix .. label .. ": " .. math.floor(value * 100), 100, y)
end

function Options.enter(sm, L)
    Options.sm = sm
    Options.L = L
    Options.selected = 1
end

function Options.draw()
    love.graphics.print(Options.L.get("options_title"), 100, 60)

    drawOption("Master", Settings.masterVolume, 120, Options.selected == 1)
    drawOption("Music", Settings.musicVolume, 160, Options.selected == 2)
    drawOption("SFX", Settings.sfxVolume, 200, Options.selected == 3)

    local languagePrefix = Options.selected == 4 and "> " or "  "
    love.graphics.print(
        languagePrefix .. Options.L.get("language") .. ": " .. Settings.language,
        100,
        240
    )

    love.graphics.print("UP/DOWN: select option", 100, 300)
    love.graphics.print("LEFT/RIGHT: change volume", 100, 330)
    love.graphics.print("L: change language", 100, 360)
    love.graphics.print("ENTER: save and back", 100, 390)
end

function Options.keypressed(key)
    if key == "up" then
        Options.selected = math.max(1, Options.selected - 1)

    elseif key == "down" then
        Options.selected = math.min(4, Options.selected + 1)

    elseif key == "left" and Options.selected <= 3 then
        updateSelectedVolume(-STEP)

    elseif key == "right" and Options.selected <= 3 then
        updateSelectedVolume(STEP)

    elseif key == "l" and Options.selected == 4 then
        if Settings.language == "ES" then
            Settings.language = "EN"
        else
            Settings.language = "ES"
        end

    elseif key == "return" then
        Settings.save()
        AudioManager.refreshVolumes()

        Options.sm.switch("main_menu")
    end
end

return Options