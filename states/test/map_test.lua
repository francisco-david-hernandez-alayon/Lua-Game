local MapLoader        = require("core.map_loader")
local PlayerController = require("core.player_controller")
local Camera           = require("core.camera")
local Npc              = require("core.world_elements.npc")
local MovingNpc        = require("core.world_elements.moving_npc")
local Object           = require("core.world_elements.object")
local Door             = require("core.world_elements.door")

local MapTest = {}

local TEST = "assets/sprites/test/"

function MapTest.enter(sm, L)
    MapTest.sm    = sm
    MapTest.debug = false

    -- World Data
    local npcs = {
        Npc.new("npc_1", TEST .. "PlayerTest.png"),
        Npc.new("npc_2", TEST .. "PlayerTest.png"),
    }

    local moving_npcs = {
        MovingNpc.new("moving_npc_1", TEST .. "PlayerTest.png"),
    }

    local objects = {
        Object.new("item_1", TEST .. "item_test.png"),
        Object.new("item_2", TEST .. "item_test.png"),
        Object.new("item_3", TEST .. "item_test.png"),
        Object.new("item_4", TEST .. "item_test.png"),
    }

    local doors = {
        Door.new("door_1", TEST .. "door_1.png"),
    }

    -- Load map
    local scale = 2;
    MapTest.map, MapTest.world, MapTest.spawn, MapTest.worldData =
    MapLoader.load("assets/maps/TestMap.lua", npcs, moving_npcs, objects, doors)
    MapTest.player = PlayerController.new(MapTest.world, MapTest.spawn)
    MapTest.cam    = Camera.new(scale)

    
    -- DEBUG
    print("=== TEST MAP LOAD SUMMARY ===")
    local function count(t)
    local c = 0
    for _, _ in pairs(t or {}) do c = c + 1 end
        return c
    end
    print("Map:", MapTest.map and "OK" or "nil")
    print("World:", MapTest.world and "OK" or "nil")

    if MapTest.spawn then
        print("Spawn:", "x=" .. MapTest.spawn.x .. ", y=" .. MapTest.spawn.y)
    else
        print("Spawn: nil")
    end

    print("---- Entities ----")
    print("NPCs:", count(MapTest.worldData.npcs))
    print("Moving NPCs:", count(MapTest.worldData.moving_npcs))
    print("Objects:", count(MapTest.worldData.objects))
    print("Doors:", count(MapTest.worldData.doors))

    print("---- Systems ----")
    print("Player:", MapTest.player and "OK" or "nil")
    print("Camera scale:", MapTest.cam and MapTest.cam.scale or "nil")

    print("========================")

end

function MapTest.update(dt)
    MapTest.world:update(dt)
    MapTest.map:update(dt)
    MapTest.player:update(dt)
end

function MapTest.draw()
    local px, py = MapTest.player:getPosition()
    Camera.update(MapTest.cam, px, py)

    local tx    = MapTest.cam.tx
    local ty    = MapTest.cam.ty
    local scale = MapTest.cam.scale

    MapTest.map:draw(-tx, -ty, scale)

    -- Draw world elements
    for _, npc  in ipairs(MapTest.worldData.npcs)        do npc:draw(tx, ty, scale)  end
    for _, npc  in ipairs(MapTest.worldData.moving_npcs) do npc:draw(tx, ty, scale)  end
    for _, obj  in ipairs(MapTest.worldData.objects)     do obj:draw(tx, ty, scale)  end
    for _, door in ipairs(MapTest.worldData.doors)       do door:draw(tx, ty, scale) end

    MapTest.player:draw(tx, ty, scale)

    if MapTest.debug then
        Camera.drawDebug(MapTest.cam, MapTest.world)
    end

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