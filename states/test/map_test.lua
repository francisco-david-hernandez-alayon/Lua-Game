local sti = require("libs/sti")
local MapTest = {}

function MapTest.enter(sm, L)
    MapTest.sm = sm
    MapTest.L = L
    MapTest.debug = false

    -- MAP
    love.physics.setMeter(32)
    MapTest.world = love.physics.newWorld(0, 0)
    MapTest.map = sti("assets/maps/TestMap.lua")

    -- Build collisions
    local buildCollisionTileMap = require("utils.build_collision_tile_map")
    buildCollisionTileMap(MapTest.map, MapTest.world)


    local layer = MapTest.map:addCustomLayer("Sprites", 8)

    -- PLAYER
    local spawn
    for _, object in pairs(MapTest.map.objects) do
        if object.name == "spawn point" then
            spawn = object
            break
        end
    end

    local sprite = love.graphics.newImage("assets/sprites/test/PlayerTest.png")
    local body = love.physics.newBody(MapTest.world, spawn and spawn.x or 64, spawn and spawn.y or 64, "dynamic")
    local shape = love.physics.newCircleShape(8)
    love.physics.newFixture(body, shape)
    body:setFixedRotation(true)

    layer.player = {
        sprite = sprite,
        body = body,
        ox = sprite:getWidth() / 2,
        oy = sprite:getHeight() / 1.35,
        speed = 100
    }

    MapTest.map:removeLayer("spawn point")
end


function MapTest.update(dt)
    MapTest.world:update(dt)
    MapTest.map:update(dt)

    local p = MapTest.map.layers["Sprites"].player
    local vx, vy = 0, 0

    if love.keyboard.isDown("w", "up")    then vy = -p.speed end
    if love.keyboard.isDown("s", "down")  then vy =  p.speed end
    if love.keyboard.isDown("a", "left")  then vx = -p.speed end
    if love.keyboard.isDown("d", "right") then vx =  p.speed end

    p.body:setLinearVelocity(vx, vy)
end


function MapTest.draw()
    local p = MapTest.map.layers["Sprites"].player
    local px, py = p.body:getPosition()

    local scale = 1 -- MUST RESOLVE SCALE PROBLEM WITH ANY NUMBER != 1

    local tx = px - love.graphics.getWidth() / 2
    local ty = py - love.graphics.getHeight() / 2

    love.graphics.setColor(1, 1, 1)

    -- STI handles camera properly
    MapTest.map:draw(-tx, -ty, scale)

    -- Player drawn manually with scale applied
    love.graphics.draw(
        p.sprite,
        (px - tx) * scale,
        (py - ty) * scale,
        0,
        scale,
        scale,
        p.ox,
        p.oy
    )

    -- Debug fixtures
    if MapTest.debug then
        love.graphics.setColor(1, 0, 0, 0.5)
        for _, body in pairs(MapTest.world:getBodies()) do
            for _, fixture in pairs(body:getFixtures()) do
                local shape = fixture:getShape()
                local stype = shape:getType()
                if stype == "circle" then
                    local cx, cy = body:getWorldPoint(shape:getPoint())
                    love.graphics.circle("line", (cx - tx) * scale, (cy - ty) * scale, shape:getRadius() * scale)
                elseif stype == "polygon" then
                    local verts = {body:getWorldPoints(shape:getPoints())}
                    for i = 1, #verts, 2 do
                        verts[i]     = (verts[i]     - tx) * scale
                        verts[i + 1] = (verts[i + 1] - ty) * scale
                    end
                    love.graphics.polygon("line", verts)
                end
            end
        end
        love.graphics.setColor(1, 1, 1)
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