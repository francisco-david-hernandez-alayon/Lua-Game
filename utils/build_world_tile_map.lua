-- utils/build_world_tile_map.lua
--
-- TILED MAP STRUCTURE REQUIRED:
-- ─────────────────────────────────────────────────────────────────
-- Object group layers (inside "world" folder in Tiled):
--   "npcs"         Points, name = npc identifier (e.g. "npc_1")
--   "moving_npcs"  Rectangles, name = npc identifier (e.g. "moving_npc_1")
--   "objects"      Points, name = object identifier (e.g. "item_1")
--   "doors"        Points, name = target state (e.g. "door_1")
--
-- COLLISIONS: automatic from tilelayer tiles with objectGroups in tileset and for a object group calles "colliders"
-- NOTE: INFINITE TILED MAPS CANNOT BE LOADED
-- ─────────────────────────────────────────────────────────────────

local PREFIX = "world."

local function findLayer(map, name)
    return map.layers[PREFIX .. name]
end

-- COLLISIONS
-- Object colliders: reads "colliders" object layer and builds static bodies from rectangles
local function buildObjectColliders(map, world)
    local layer = map.layers["colliders"]
    local count = 0

    -- Check whether it is a group of objects called colliders
    if not layer then return 0 end
    if layer.type ~= "objectgroup" then return 0 end  -- skip if not object layer
    if not layer.objects then return 0 end

    for _, obj in pairs(layer.objects) do
        local body = love.physics.newBody(world, obj.x + obj.width / 2, obj.y + obj.height / 2, "static")
        local shape

        if obj.shape == "rectangle" then
            shape = love.physics.newRectangleShape(obj.width, obj.height)
        elseif obj.shape == "polygon" then
            local verts = {}
            for _, v in ipairs(obj.polygon) do
                table.insert(verts, v.x)
                table.insert(verts, v.y)
            end
            shape = love.physics.newPolygonShape(verts)
        end

        if shape then
            love.physics.newFixture(body, shape)
            count = count + 1
        end
    end

    print("[OK] object colliders loaded: " .. count)
    return count
end


-- Tile collisions: reads ALL tilelayers and builds static bodies from objectGroups
local function buildTileCollisions(map, world)
    local count = 0
    for _, layer in pairs(map.layers) do
        if layer.type == "tilelayer" then
            for y = 1, layer.height do
                for x = 1, layer.width do
                    local tile = layer.data[y] and layer.data[y][x]
                    if tile and tile.objectGroup then
                        for _, obj in pairs(tile.objectGroup.objects) do
                            local tileset = nil
                            for _, ts in ipairs(map.tilesets) do
                                if tile.gid >= ts.firstgid then tileset = ts end
                            end

                            local tileH = (tileset and tileset.tileheight or map.tileheight)
                            local extraY = tileH - map.tileheight

                            local wx = (x - 1) * map.tilewidth
                            local wy = (y - 1) * map.tileheight - extraY
                            local body = love.physics.newBody(world, wx, wy, "static")
                            local shape

                            if obj.shape == "rectangle" then
                                shape = love.physics.newRectangleShape(
                                    obj.x + obj.width / 2,
                                    obj.y + obj.height / 2,
                                    obj.width,
                                    obj.height
                                )
                            elseif obj.shape == "polygon" then
                                local verts = {}
                                for _, v in ipairs(obj.polygon) do
                                    table.insert(verts, obj.x + v.x)
                                    table.insert(verts, obj.y + v.y)
                                end
                                shape = love.physics.newPolygonShape(verts)
                            end

                            if shape then
                                love.physics.newFixture(body, shape)
                                count = count + 1
                            end
                        end
                    end
                end
            end
        end
    end
    print("[OK] tile colliders loaded: " .. count)
    return count
end

-- WORLD DATA
local function buildNpcs(layer)
    local npcs = {}
    if not layer then
        print("[WARN] build_world_tile_map: layer 'npcs' not found")
        return npcs
    end
    for _, obj in pairs(layer.objects) do
        if obj.name and obj.name ~= "" then
            table.insert(npcs, { id = obj.name, x = obj.x, y = obj.y })
        end
    end
    print("[OK] npcs loaded: " .. #npcs)
    return npcs
end

local function buildMovingNpcs(layer)
    local npcs = {}
    if not layer then
        print("[WARN] build_world_tile_map: layer 'moving_npcs' not found")
        return npcs
    end
    for _, obj in pairs(layer.objects) do
        if obj.name and obj.name ~= "" then
            table.insert(npcs, {
                id     = obj.name,
                x      = obj.x,
                y      = obj.y,
                bounds = { x = obj.x, y = obj.y, w = obj.width, h = obj.height }
            })
        end
    end
    print("[OK] moving_npcs loaded: " .. #npcs)
    return npcs
end

local function buildObjects(layer)
    local objects = {}
    if not layer then
        print("[WARN] build_world_tile_map: layer 'objects' not found")
        return objects
    end
    for _, obj in pairs(layer.objects) do
        if obj.name and obj.name ~= "" then
            table.insert(objects, { id = obj.name, x = obj.x, y = obj.y, picked = false })
        end
    end
    print("[OK] objects loaded: " .. #objects)
    return objects
end

local function buildDoors(layer)
    local doors = {}
    if not layer then
        print("[WARN] build_world_tile_map: layer 'doors' not found")
        return doors
    end
    for _, obj in pairs(layer.objects) do
        if obj.name and obj.name ~= "" then
            table.insert(doors, {
                id   = obj.name,
                x    = obj.x,
                y    = obj.y,
                open = false,
            })
        else
            print("[WARN] build_world_tile_map: door object has no name, skipped")
        end
    end
    print("[OK] doors loaded: " .. #doors)
    return doors
end

-- MAIN FUNCTION
local function buildWorldTileMap(map, world)

    for name, layer in pairs(map.layers) do
    if type(name) == "string" then
        print("LAYER: '" .. name .. "' type: " .. tostring(layer.type))
    end
end

    local tileCount   = buildTileCollisions(map, world)
    local objectCount = buildObjectColliders(map, world)
    print("[INFO] total colliders: " .. tileCount + objectCount)

    local npcsLayer       = findLayer(map, "npcs")
    local movingNpcsLayer = findLayer(map, "moving_npcs")
    local objectsLayer    = findLayer(map, "objects")
    local doorsLayer      = findLayer(map, "doors")

    print("[INFO] build_world_tile_map: building world for map")

    return {
        npcs        = buildNpcs(npcsLayer),
        moving_npcs = buildMovingNpcs(movingNpcsLayer),
        objects     = buildObjects(objectsLayer),
        doors       = buildDoors(doorsLayer),
    }
end

return buildWorldTileMap
