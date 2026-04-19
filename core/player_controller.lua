local anim8 = require("libs/anim8")

local PlayerController = {}
PlayerController.__index = PlayerController

-- Directions
local DIR = { UP = "up", DOWN = "down", LEFT = "left", RIGHT = "right" }

function PlayerController.new(world, spawn)
    local self = setmetatable({}, PlayerController)

    -- Body
    local x = spawn and spawn.x or 64
    local y = spawn and spawn.y or 64
    self.body = love.physics.newBody(world, x, y, "dynamic")
    local shape = love.physics.newCircleShape(8)
    love.physics.newFixture(self.body, shape)
    self.body:setFixedRotation(true)

    -- Sprite & animation
    self.spritesheet = love.graphics.newImage("assets/sprites/test/Sprite-player-test.png")
    local grid = anim8.newGrid(32, 32, self.spritesheet:getWidth(), self.spritesheet:getHeight())
    self.anims = {
        walk = anim8.newAnimation(grid("1-3", 1), 0.10)
    }
    self.anim = self.anims.walk

    -- State
    self.moving   = false
    self.dir      = DIR.UP
    self.ox       = 16
    self.oy       = 16
    self.rotation = 0

    -- movement
    self.speed    = 100
    self.velx = 0
    self.vely = 0
    self.accel = 500        
    self.friction = 700     
    self.sprintMultiplier = 1.4
    self.trails = {}
    self.trailTimer = 0

    return self
end

function PlayerController:update(dt, menuOpen)
    local inputX, inputY = 0, 0

    if not menuOpen then
        if love.keyboard.isDown("w", "up") then
            inputY = -1
            self.dir = DIR.UP
        end
        if love.keyboard.isDown("s", "down") then
            inputY = 1
            self.dir = DIR.DOWN
        end
        if love.keyboard.isDown("a", "left") then
            inputX = -1
            self.dir = DIR.LEFT
        end
        if love.keyboard.isDown("d", "right") then
            inputX = 1
            self.dir = DIR.RIGHT
        end
    end

    -- Sprint
    local speed = self.speed
    if love.keyboard.isDown("lshift", "rshift") then
        speed = speed * self.sprintMultiplier
    end

    -- Normalize input (Avoid fasted diagonal)
    local len = math.sqrt(inputX * inputX + inputY * inputY)
    if len > 0 then
        inputX = inputX / len
        inputY = inputY / len
    end

    -- Target velocity
    local targetVx = inputX * speed
    local targetVy = inputY * speed

    -- Interpolate (aceleration)
    local function approach(current, target, rate)
        if current < target then
            return math.min(current + rate * dt, target)
        elseif current > target then
            return math.max(current - rate * dt, target)
        end
        return current
    end

    if inputX ~= 0 or inputY ~= 0 then
        self.velx = approach(self.velx, targetVx, self.accel)
        self.vely = approach(self.vely, targetVy, self.accel)
        self.moving = true
    else
        self.velx = approach(self.velx, 0, self.friction)
        self.vely = approach(self.vely, 0, self.friction)
        self.moving = false
    end

    self.body:setLinearVelocity(self.velx, self.vely)

    if self.moving then
        self.anim:update(dt)
    else
        self.anim:gotoFrame(1)
    end

    -- Update speed lines
    self:updateSpeedLines(dt)
end


-- Execute when player sprints
function PlayerController:updateSpeedLines(dt)
    
    local sprinting = love.keyboard.isDown("lshift", "rshift")

    local speed = math.sqrt(self.velx^2 + self.vely^2)

    if sprinting and speed > 20 then
        self.trailTimer = self.trailTimer - dt
        if self.trailTimer <= 0 then
            self.trailTimer = 0.05 

            local px, py = self.body:getPosition()

            -- perpendicular vector to separate lines
            local len = math.sqrt(self.velx^2 + self.vely^2)
            local nx, ny = 0, 0
            if len > 0 then
                nx = -self.vely / len
                ny = self.velx / len
            end

            local separation = 6 -- distance between lines

            for i = -1, 1 do
                local len = math.sqrt(self.velx^2 + self.vely^2)

                    local dirx, diry = 0, 0
                    if len > 0 then
                        dirx = self.velx / len
                        diry = self.vely / len
                    end

                table.insert(self.trails, {
                    x = px + nx * separation * i,
                    y = py + ny * separation * i,
                    life = 0.15,
                    dx = -dirx,
                    dy = -diry
                })
            end
        end
    end

    -- Update trails
    for i = #self.trails, 1, -1 do
        local t = self.trails[i]
        t.life = t.life - dt
        t.x = t.x + t.dx
        t.y = t.y + t.dy

        if t.life <= 0 then
            table.remove(self.trails, i)
        end
    end
end


function PlayerController:draw(tx, ty, scale)

    -- Draw Speed trails
    local oldWidth = love.graphics.getLineWidth()
    love.graphics.setLineWidth(2 * scale)

    for _, t in ipairs(self.trails) do
        local alpha = t.life / 0.4
        love.graphics.setColor(1, 1, 1, alpha)

        local x = (t.x - tx) * scale
        local y = (t.y - ty) * scale

        local length = 25

        love.graphics.line(
            x, y,
            x - t.dx * length,
            y - t.dy * length
        )

    end

    love.graphics.setLineWidth(oldWidth)
    love.graphics.setColor(1, 1, 1)



    local px, py = self.body:getPosition()

    local x = (px - tx) * scale
    local y = (py - ty) * scale

    local sx, sy = scale, scale

    -- Movement direction
    local len = math.sqrt(self.velx^2 + self.vely^2)

    if len > 1 then
        self.rotation = math.atan2(self.vely, self.velx) + math.pi/2
    end

    local r = self.rotation
    local sx, sy = scale, scale

    self.anim:draw(self.spritesheet, x, y, r, sx, sy, self.ox, self.oy)
end

function PlayerController:getPosition()
    return self.body:getPosition()
end

return PlayerController