local MapLoader        = require("core.map_loader")
local PlayerController = require("core.player_controller")
local Camera           = require("core.camera")

local MapTest = {}

function MapTest.enter(sm, L)
    MapTest.sm    = sm
    MapTest.debug = false

    -- LOAD: Map, camera and player
    MapTest.map, MapTest.world, MapTest.spawn = MapLoader.load("assets/maps/TestMap.lua")
    MapTest.player = PlayerController.new(MapTest.world, MapTest.spawn)
    MapTest.cam    = Camera.new(3) -- scale
end

function MapTest.update(dt)
    MapTest.world:update(dt)
    MapTest.map:update(dt)
    MapTest.player:update(dt)
end

function MapTest.draw()
    local px, py = MapTest.player:getPosition()
    Camera.update(MapTest.cam, px, py)

    local tx = MapTest.cam.tx
    local ty = MapTest.cam.ty
    local scale = MapTest.cam.scale

    MapTest.map:draw(-tx, -ty, scale)
    MapTest.player:draw(tx, ty, scale)

    if MapTest.debug then
        Camera.drawDebug(MapTest.cam, MapTest.world)
    end

    -- HUD
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("[F1] Toggle collision debug", 8, 8)
end

function MapTest.keypressed(key)
    if key == "escape" then
        MapTest.sm.switch("main_menu")
    elseif key == "f1" then
        MapTest.debug = not MapTest.debug
    end
end

return MapTest