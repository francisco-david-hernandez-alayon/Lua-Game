-- ui/ui_controller.lua
local L          = require("core.localization.localization")
local DialogueUI = require("ui.dialogue_ui")  -- included as submodule

local UIController = {}

-- Expose DialogueUI through UIController
UIController.isDialogueActive = DialogueUI.isActive
UIController.showSimpleTalk   = DialogueUI.showSimpleTalk
UIController.showDialogue     = DialogueUI.showDialogue
UIController.showNpcMenu      = DialogueUI.showMenu
UIController.updateDialogue   = DialogueUI.update
UIController.keypressedDialogue = DialogueUI.keypressed

-- ... resto del código igual que antes ...

function UIController.keypressed(key, sm)
    if key == "tab" then
        menuOpen = not menuOpen
        selectedCol = 1
        selectedRow = 1
        return
    end

    if not menuOpen then return end

    if key == "up"    then selectedRow = math.max(1,    selectedRow - 1) end
    if key == "down"  then selectedRow = math.min(ROWS, selectedRow + 1) end
    if key == "left"  then selectedCol = math.max(1,    selectedCol - 1) end
    if key == "right" then selectedCol = math.min(COLS, selectedCol + 1) end

    if key == "return" then
        local app = menuGetSelected()
        if app and app.name == "menu" then
            menuOpen = false
            sm.switch("main_menu")
        end
    end
end

function UIController.isMenuOpen()
    return menuOpen
end

function UIController.update(dt)
    DialogueUI.update(dt)
end

function UIController.draw(map, worldData, player, cam)
    local tx    = cam.tx
    local ty    = cam.ty
    local scale = cam.scale
    local sw    = love.graphics.getWidth()
    local sh    = love.graphics.getHeight()
    local font  = love.graphics.getFont()

    -- 1. Draw world map
    map:draw(-tx, -ty, scale)

    -- 2. Draw static NPCs
    love.graphics.setColor(1, 1, 1)
    for _, npc in ipairs(worldData.npcs) do npc:draw(tx, ty, scale) end

    -- 3. Draw moving NPCs
    for _, npc in ipairs(worldData.moving_npcs) do npc:draw(tx, ty, scale) end

    -- 4. Draw pickable objects
    for _, obj in ipairs(worldData.objects) do obj:draw(tx, ty, scale) end

    -- 5. Draw doors
    for _, door in ipairs(worldData.doors) do door:draw(tx, ty, scale) end

    -- 6. Draw player on top of world
    player:draw(tx, ty, scale)

    -- 7. Draw dialogue UI on top of world, below HUD
    local px, py = player:getPosition()
    DialogueUI.draw(px, py, tx, ty, scale)

    -- 8. HUD: tab hint centered at bottom
    love.graphics.setColor(1, 1, 1)
    local hint  = menuOpen and "[Tab] Cerrar menu" or "[Tab] Abrir menu"
    local hintW = font:getWidth(hint)
    love.graphics.print(hint, sw / 2 - hintW / 2, sh - 24)

    -- 9. Tab menu panel (bottom right)
    if menuOpen then
        local spriteW = menuSprite:getWidth()  * MENU_SCALE
        local spriteH = menuSprite:getHeight() * MENU_SCALE
        local mx      = sw - spriteW - 16
        local my      = sh - spriteH

        love.graphics.setColor(1, 1, 1)
        love.graphics.draw(menuSprite, mx, my, 0, MENU_SCALE, MENU_SCALE)

        local gridW      = COLS * APP_SIZE + (COLS - 1) * APP_PAD
        local gridStartX = mx + (spriteW - gridW) / 2
        local gridStartY = my + spriteH / 2 + APP_SIZE / 2

        for i, app in ipairs(APPS) do
            local col = ((i - 1) % COLS) + 1
            local row = math.ceil(i / COLS)

            local ax = gridStartX + (col - 1) * (APP_SIZE + APP_PAD)
            local ay = gridStartY + (row - 1) * (APP_SIZE + ROW_PAD)

            if col == selectedCol and row == selectedRow then
                love.graphics.setColor(1, 1, 0, 0.3)
                love.graphics.rectangle("fill", ax - 2, ay - 2, APP_SIZE + 4, APP_SIZE + 4)
            end

            love.graphics.setColor(1, 1, 1)
            love.graphics.draw(appSprite, ax, ay, 0, APP_SCALE, APP_SCALE)

            local nameW = font:getWidth(app.name)
            love.graphics.print(app.name, ax + APP_SIZE / 2 - nameW / 2, ay + APP_SIZE + 2)
        end

        love.graphics.setColor(1, 1, 1)
    end
end

return UIController