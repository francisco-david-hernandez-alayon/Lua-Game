local sti = require("libs/sti")
local buildCollisionTileMap = require("utils.build_collision_tile_map")

local MapLoader = {}

function MapLoader.load(mapPath)
    love.physics.setMeter(32)
    local world = love.physics.newWorld(0, 0)
    local map = sti(mapPath)

    buildCollisionTileMap(map, world)

    local layerCount = #map.layers
    map:addCustomLayer("Sprites", layerCount + 1)

    local spawn
    for _, object in pairs(map.objects) do
        if object.name == "spawn point" then
            spawn = object
            break
        end
    end

    map:removeLayer("spawn point")

    -- DEBUG
    -- print("SPAWN POINT: " .. spawn.x .. " " .. spawn.y)
    
    return map, world, spawn
end

return MapLoader