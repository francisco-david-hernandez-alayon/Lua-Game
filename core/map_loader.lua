local sti               = require("libs/sti")
local buildWorldTileMap = require("utils.build_world_tile_map")

local MapLoader = {}

-- Match elements list with worldData positions
local function resolvePositions(elements, worldDataList)
    for _, element in ipairs(elements) do
        local id = element.npc and element.npc.id or element.id
        for _, data in ipairs(worldDataList) do
            if data.id == id then
                if element.setPosition then
                    element:setPosition(data.x, data.y)
                else
                    element.x = data.x
                    element.y = data.y
                end
                if data.bounds then element.bounds = data.bounds end
                if data.w      then element.w      = data.w      end
                if data.h      then element.h      = data.h      end
                break
            end
        end
    end
    return elements
end

function MapLoader.load(mapPath, npcs, objects, doors, triggers)
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
        "world.objects",
        "world.doors",
        "world.trigger_events",
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
    if objects     then resolvePositions(objects,     worldData.objects)     end
    if doors       then resolvePositions(doors,       worldData.doors)       end
    if triggers then resolvePositions(triggers, worldData.triggers) end

    return map, world, spawn, {
        npcs        = npcs        or {},
        objects     = objects     or {},
        doors       = doors       or {},
        triggers = triggers or {},
    }
end


return MapLoader