-- utils/build_world_tile_map.lua
--
-- TILED MAP STRUCTURE REQUIRED:
-- ─────────────────────────────────────────────────────────────────
-- Object group layers (inside "world" folder in Tiled):
--   "npcs"         Points, name = npc identifier (e.g. "npc_1")
--   "moving_npcs"  Rectangles, name = npc identifier (e.g. "moving_npc_1")
--   "objects"      Points, name = object identifier (e.g. "item_1")
--   "doors"        Rectangles, name = target state (e.g. "door_1")
--
-- COLLISIONS: automatic from tilelayer tiles with objectGroups in tileset.
-- ─────────────────────────────────────────────────────────────────

local PREFIX = "world."

local function findLayer(map, name)
    return map.layers[PREFIX .. name]
end

-- Tile collisions: reads ALL tilelayers and builds static bodies from objectGroups
local function buildTileCollisions(map, world)
    for _, layer in pairs(map.layers) do
        if layer.type == "tilelayer" then
            for y = 1, layer.height do
                for x = 1, layer.width do
                    local tile = layer.data[y] and layer.data[y][x]
                    if tile and tile.objectGroup then
                        for _, obj in pairs(tile.objectGroup.objects) do
                            local wx = (x - 1) * map.tilewidth
                            local wy = (y - 1) * map.tileheight
                            local body = love.physics.newBody(world, wx, wy, "static")
                            local shape

                            if obj.shape == "rectangle" then
                                shape = love.physics.newRectangleShape(
                                    obj.x + obj.width  / 2,
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
                            end
                        end
                    end
                end
            end
        end
    end
end

local function buildNpcs(layer)
    local npcs = {}
    if not layer then return npcs end
    for _, obj in pairs(layer.objects) do
        if obj.name and obj.name ~= "" then
            table.insert(npcs, { id = obj.name, x = obj.x, y = obj.y })
        end
    end
    return npcs
end

local function buildMovingNpcs(layer)
    local npcs = {}
    if not layer then return npcs end
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
    return npcs
end

local function buildObjects(layer)
    local objects = {}
    if not layer then return objects end
    for _, obj in pairs(layer.objects) do
        if obj.name and obj.name ~= "" then
            table.insert(objects, { id = obj.name, x = obj.x, y = obj.y, picked = false })
        end
    end
    return objects
end

local function buildDoors(layer)
    local doors = {}
    if not layer then return doors end
    for _, obj in pairs(layer.objects) do
        if obj.name and obj.name ~= "" then
            table.insert(doors, {
                id   = obj.name,
                x    = obj.x,
                y    = obj.y,
                w    = obj.width,
                h    = obj.height,
                open = false,
            })
        end
    end
    return doors
end

local function buildWorldTileMap(map, world)
    buildTileCollisions(map, world)

    return {
        npcs        = buildNpcs(findLayer(map, "npcs")),
        moving_npcs = buildMovingNpcs(findLayer(map, "moving_npcs")),
        objects     = buildObjects(findLayer(map, "objects")),
        doors       = buildDoors(findLayer(map, "doors")),
    }
end

return buildWorldTileMap