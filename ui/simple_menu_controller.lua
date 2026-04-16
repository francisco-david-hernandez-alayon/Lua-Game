local SimpleMenuController = {}

function SimpleMenuController.new(items)
    return {
        items = items,
        selected = 1
    }
end

function SimpleMenuController.moveUp(menu)
    menu.selected = menu.selected - 1
    if menu.selected < 1 then
        menu.selected = #menu.items
    end
end

function SimpleMenuController.moveDown(menu)
    menu.selected = menu.selected + 1
    if menu.selected > #menu.items then
        menu.selected = 1
    end
end

function SimpleMenuController.getSelected(menu)
    return menu.items[menu.selected]
end

function SimpleMenuController.draw(menu, x, y)
    for i, item in ipairs(menu.items) do
        local prefix = (i == menu.selected) and "> " or "  "
        love.graphics.print(prefix .. item, x, y + i * 30)
    end
end

return SimpleMenuController