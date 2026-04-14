local Menu = {}

function Menu.enter(sm)
    Menu.sm = sm
    Menu.selected = 1

    Menu.items = {
        "PLAY",
        "OPTIONS",
        "EXIT"
    }
end

function Menu.update(dt)
end

function Menu.draw()
    for i, item in ipairs(Menu.items) do
        if i == Menu.selected then
            love.graphics.print("> " .. item, 100, 100 + i * 30)
        else
            love.graphics.print("  " .. item, 100, 100 + i * 30)
        end
    end
end

function Menu.keypressed(key)
    if key == "up" then
        Menu.selected = Menu.selected - 1
        if Menu.selected < 1 then
            Menu.selected = #Menu.items
        end
    end

    if key == "down" then
        Menu.selected = Menu.selected + 1
        if Menu.selected > #Menu.items then
            Menu.selected = 1
        end
    end

    if key == "return" then
        local choice = Menu.items[Menu.selected]

        if choice == "PLAY" then
            Menu.sm.switch(require("states.play_menu"))

        elseif choice == "OPTIONS" then
            Menu.sm.switch(require("states.options"))

        elseif choice == "EXIT" then
            love.event.quit()
        end
    end
end

return Menu