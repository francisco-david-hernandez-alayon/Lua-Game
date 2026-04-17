local Camera = {}

function Camera.new(scale)
    return {
        scale = scale or 1,
        tx = 0,
        ty = 0
    }
end

function Camera.update(cam, px, py)
    local screen_width = love.graphics.getWidth()  / cam.scale
    local screen_height = love.graphics.getHeight() / cam.scale
    cam.tx = math.floor(px - screen_width / 2)
    cam.ty = math.floor(py - screen_height / 2)
end

-- DEBUG: DRAW COLLISIONS
function Camera.drawDebug(cam, world)
    love.graphics.setColor(1, 0, 0, 0.5)
    local scale = cam.scale
    local tx, ty = cam.tx, cam.ty
    for _, body in pairs(world:getBodies()) do
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

return Camera