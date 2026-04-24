-- states/menu/main_menu.lua

local AudioManager = require("core.audio.audio_manager")
local MusicList = require("core.audio.music_list")
local SfxList = require("core.audio.sfx_list")
local GameController = require("core.game.controller.game_controller")
local SimpleMenuController = require("ui.simple_menu_controller")
local MainMenu = {}

function MainMenu.enter(sm, L)
    MainMenu.sm = sm
    MainMenu.L = L

    GameController.unload()

    MainMenu.menu = SimpleMenuController.new({
        "TEST",
        L.get("play"),
        L.get("options"),
        L.get("exit")
    })

    AudioManager.playMusic(MusicList.menu)
end

function MainMenu.keypressed(key)
    if key == "up" then
        SimpleMenuController.moveUp(MainMenu.menu)
    elseif key == "down" then
        SimpleMenuController.moveDown(MainMenu.menu)
    elseif key == "return" then
        local choice = SimpleMenuController.getSelected(MainMenu.menu)
        if choice == MainMenu.L.get("play") then
            MainMenu.sm.switch("play_menu")
        elseif choice == MainMenu.L.get("options") then
            MainMenu.sm.switch("options")
        elseif choice == MainMenu.L.get("exit") then
            love.event.quit()
        elseif choice == "TEST" then
            MainMenu.sm.switch("main_test")
        end
    end
end

function MainMenu.draw()
    SimpleMenuController.draw(MainMenu.menu, 100, 100)
end

return MainMenu