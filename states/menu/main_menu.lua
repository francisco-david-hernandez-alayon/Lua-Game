local MenuController = require("ui.menu_controller")
local MainMenu = {}

function MainMenu.enter(sm, L)
    MainMenu.sm = sm
    MainMenu.L = L

    MainMenu.menu = MenuController.new({
        L.get("play"),
        L.get("options"),
        L.get("exit")
    })
end

function MainMenu.keypressed(key)
    if key == "up" then
        MenuController.moveUp(MainMenu.menu)
        
    elseif key == "down" then
        MenuController.moveDown(MainMenu.menu)

    elseif key == "return" then
        local choice = MenuController.getSelected(MainMenu.menu)

        if choice == MainMenu.L.get("play") then
            MainMenu.sm.switch("play_menu")

        elseif choice == MainMenu.L.get("options") then
            MainMenu.sm.switch("options")

        elseif choice == MainMenu.L.get("exit") then
            love.event.quit()
        end
    end
end

function MainMenu.draw()
    MenuController.draw(MainMenu.menu, 100, 100)
end

return MainMenu