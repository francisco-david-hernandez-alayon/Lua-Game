-- utils/build_collision_tile_map.lua
local function buildCollisionTileMap(map, world)
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
                            end
                        end
                    end
                end
            end
        end
    end
end

return buildCollisionTileMap