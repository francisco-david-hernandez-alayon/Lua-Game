local MapLoader        = require("core.map_loader")
local PlayerController = require("core.player_controller")
local Camera           = require("core.camera")
local UIController     = require("ui.ui_controller")
local Npc              = require("core.world_elements.npc")
local MovingNpc        = require("core.world_elements.moving_npc")
local Object           = require("core.world_elements.object")
local Door             = require("core.world_elements.door")

local MapTest2 = {}
local TEST = "assets/sprites/test/"

function MapTest2.enter(sm, L)
    MapTest2.sm    = sm
    MapTest2.debug = false

    local npcs = {
        Npc.new("npc_1",  TEST .. "PlayerTest.png"),
        Npc.new("npc_2",  TEST .. "PlayerTest.png"),
    }
    local moving_npcs = {
        -- empty
    }
    local objects = {
        Object.new("item_1", TEST .. "item_test.png"),
        Object.new("item_2", TEST .. "item_test.png"),
    }
    local doors = {
        Door.new("door_1", TEST .. "door_1.png", "map_test", true),
        Door.new("door_2", TEST .. "door_1.png", "map_test", true),
    }

    MapTest2.map, MapTest2.world, MapTest2.spawn, MapTest2.worldData =
    MapLoader.load("assets/maps/TestMap2.lua", npcs, moving_npcs, objects, doors)
    MapTest2.player = PlayerController.new(MapTest2.world, MapTest2.spawn)
    MapTest2.cam    = Camera.new(5)
end



function MapTest2.update(dt)
    MapTest2.world:update(dt)
    MapTest2.map:update(dt)
    MapTest2.player:update(dt, UIController.isMenuOpen())

    if not UIController.isMenuOpen() then
        local px, py = MapTest2.player:getPosition()
        for _, door in ipairs(MapTest2.worldData.doors) do
            door:update(px, py, MapTest2.sm)
        end
    end
end



function MapTest2.keypressed(key)
    UIController.keypressed(key, MapTest2.sm)

    if not UIController.isMenuOpen() then
        if key == "escape" then
            MapTest2.sm.switch("main_menu")
        elseif key == "f1" then
            MapTest2.debug = not MapTest2.debug
        end
    end
end

function MapTest2.draw()
    local px, py = MapTest2.player:getPosition()
    Camera.update(MapTest2.cam, px, py)

    UIController.draw(
        MapTest2.map,
        MapTest2.worldData,
        MapTest2.player,
        MapTest2.cam
    )


    -- Debug
    if MapTest2.debug then
        Camera.drawDebug(MapTest2.cam, MapTest2.world)
    end
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("[F1] Toggle collision debug", 8, 8)
end

return MapTest2