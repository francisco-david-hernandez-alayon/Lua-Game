local MenuController = require("ui.menu_controller")
local PlayMenu = {}

function PlayMenu.enter(sm, L)
    PlayMenu.sm = sm
    PlayMenu.L = L

    PlayMenu.menu = MenuController.new({
        PlayMenu.L.get("new"),
        PlayMenu.L.get("load"),
        PlayMenu.L.get("back")
    })
end

function PlayMenu.keypressed(key)
    if key == "up" then
        MenuController.moveUp(PlayMenu.menu)

    elseif key == "down" then
        MenuController.moveDown(PlayMenu.menu)

    elseif key == "return" then
        local c = MenuController.getSelected(PlayMenu.menu)

        if c == PlayMenu.L.get("new") then
            PlayMenu.sm.switch("new_game")

        elseif c == PlayMenu.L.get("load") then
            PlayMenu.sm.switch("load_game")

        elseif c == PlayMenu.L.get("back") then
            PlayMenu.sm.switch("main_menu")
        end
    end
end

function PlayMenu.draw()
    love.graphics.print("PLAY MENU", 100, 60)
    MenuController.draw(PlayMenu.menu, 100, 100)
end

return PlayMenu