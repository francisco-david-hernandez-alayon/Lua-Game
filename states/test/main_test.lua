local SimpleMenuController = require("ui.simple_menu_controller")
local MainTest = {}


function MainTest.enter(sm, L)
    MainTest.sm = sm
    MainTest.L = L

    MainTest.menu = SimpleMenuController.new({
        "MAP TEST",
        "Return"
    })
end


function MainTest.keypressed(key)
    if key == "up" then
        SimpleMenuController.moveUp(MainTest.menu)
        
    elseif key == "down" then
        SimpleMenuController.moveDown(MainTest.menu)

    elseif key == "return" then
        local choice = SimpleMenuController.getSelected(MainTest.menu)

        if choice == "MAP TEST" then
            MainTest.sm.switch("map_test")

        elseif choice == "Return" then
            MainTest.sm.switch("main_menu")
        end
    
    end
end

function MainTest.draw()
    SimpleMenuController.draw(MainTest.menu, 100, 100)

end

return MainTest