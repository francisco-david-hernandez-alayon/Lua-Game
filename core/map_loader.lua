local sti               = require("libs/sti")
local buildWorldTileMap = require("utils.build_world_tile_map")

local MapLoader = {}

-- Match elements list with worldData positions
local function resolvePositions(elements, worldDataList)
    for _, element in ipairs(elements) do
        
        for _, data in ipairs(worldDataList) do

            -- print("SEARCH: " .. data.id .. " " .. element.id )  -- DEBUG

            if data.id == element.id then
                element.x      = data.x
                element.y      = data.y
                element.bounds = data.bounds  -- only moving npcs
                element.w      = data.w       -- only doors
                element.h      = data.h       -- only doors

                -- print("found " .. data.id) -- DEBUG
                break
            end
        end
    end
    return elements
end

function MapLoader.load(mapPath, npcs, moving_npcs, objects, doors)
    love.physics.setMeter(32)
    local world = love.physics.newWorld(0, 0)
    local map   = sti(mapPath)

    local worldData = buildWorldTileMap(map, world)

    local layerCount = #map.layers
    map:addCustomLayer("Sprites", layerCount + 1)

    -- Get spawn
    local spawn
    for _, object in pairs(map.objects) do
        if object.name == "spawn_point" then
            spawn = object
            break
        end
    end

    -- Remove STI object layers
    local toRemove = {
        "spawn_point",
        "world.npcs",
        "world.moving_npcs",
        "world.objects",
        "world.doors",
    }

    -- colliders if is objectgroup
    if map.layers["colliders"] and map.layers["colliders"].type == "objectgroup" then
        table.insert(toRemove, "colliders")
    end
    
    for _, name in ipairs(toRemove) do
        if map.layers[name] then
            map:removeLayer(name)
        end
    end

    -- Resolve positions from worldData
    if npcs        then resolvePositions(npcs,        worldData.npcs)        end
    if moving_npcs then resolvePositions(moving_npcs, worldData.moving_npcs) end
    if objects     then resolvePositions(objects,     worldData.objects)     end
    if doors       then resolvePositions(doors,       worldData.doors)       end

    return map, world, spawn, {
        npcs        = npcs        or {},
        moving_npcs = moving_npcs or {},
        objects     = objects     or {},
        doors       = doors       or {},
    }
end

-- Worl data example:
-- {
--     npcs        = { { id="guard_1", x=100, y=200 }, ... },
--     moving_npcs = { { id="patrol_1", x=50, y=80, bounds={x,y,w,h} }, ... },
--     objects     = { { id="sword_1", x=300, y=150, picked=false }, ... },
--     doors       = { { id="dungeon", x=400, y=300, w=32, h=32, open=false }, ... },
-- }

return MapLoader