-- ui/ui_controller.lua
local UIController = {}

-- SPRITES
local menuSprite = love.graphics.newImage("assets/sprites/test/handle-game-menu-test.png")
local appSprite  = love.graphics.newImage("assets/sprites/test/app-test.png")

-- SCALE
local MENU_SCALE = 3
local APP_SCALE  = MENU_SCALE - 1
local APP_SIZE   = 32 * APP_SCALE
local APP_PAD    = APP_SIZE / 4  
local ROW_PAD    = APP_SIZE / 2   

local COLS = 3
local ROWS = 2

local APPS = {
    { name = "app1" },
    { name = "app2" },
    { name = "app3" },
    { name = "missions" },
    { name = "inventory" },
    { name = "menu" },
}

local menuOpen    = false
local selectedCol = 1
local selectedRow = 1

local function getIndex(col, row)
    return (row - 1) * COLS + col
end

local function getSelected()
    return APPS[getIndex(selectedCol, selectedRow)]
end

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
        local app = getSelected()
        if app and app.name == "menu" then
            menuOpen = false
            sm.switch("main_menu")
        elseif app and app.name == "missions" then
            menuOpen = false
            sm.switch("list_missions")
        elseif app and app.name == "inventory" then
            menuOpen = false
            sm.switch("inventory_state")
        end
    end
end

function UIController.isMenuOpen()
    return menuOpen
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

    -- 2. Draw NPCs (static and moving unified)
    love.graphics.setColor(1, 1, 1)
    for _, npc in ipairs(worldData.npcs or {}) do npc:draw(tx, ty, scale) end

    -- 3. Draw pickable objects
    for _, obj in ipairs(worldData.objects or {}) do obj:draw(tx, ty, scale) end

    -- 4. Draw doors
    for _, door in ipairs(worldData.doors or {}) do door:draw(tx, ty, scale) end

    -- 5. Draw player on top of world
    player:draw(tx, ty, scale)

    -- 6. HUD: tab hint centered at bottom
    love.graphics.setColor(1, 1, 1)
    local hint  = menuOpen and "[Tab] Cerrar menu" or "[Tab] Abrir menu"
    local hintW = font:getWidth(hint)
    love.graphics.print(hint, sw / 2 - hintW / 2, sh - 24)

    -- 7. Tab menu panel (bottom right)
    if menuOpen then
        local spriteW = menuSprite:getWidth()  * MENU_SCALE
        local spriteH = menuSprite:getHeight() * MENU_SCALE
        local mx      = sw - spriteW - 16
        local my      = sh - spriteH

        love.graphics.setColor(1, 1, 1)
        love.graphics.draw(menuSprite, mx, my, 0, MENU_SCALE, MENU_SCALE)

        -- Grid centered horizontally, in bottom half of sprite
        local gridW      = COLS * APP_SIZE + (COLS - 1) * APP_PAD
        local gridStartX = mx + (spriteW - gridW) / 2
        local gridStartY = my + spriteH / 2 + APP_SIZE / 2

        for i, app in ipairs(APPS) do
            local col = ((i - 1) % COLS) + 1
            local row = math.ceil(i / COLS)

            local ax = gridStartX + (col - 1) * (APP_SIZE + APP_PAD)
            local ay = gridStartY + (row - 1) * (APP_SIZE + ROW_PAD)

            -- Highlight selected
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