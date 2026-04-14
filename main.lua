function love.load()
    jugador = { x = 400, y = 300 }
end

function love.update(dt)
    if love.keyboard.isDown("right") then
        jugador.x = jugador.x + 200 * dt
    end

    if love.keyboard.isDown("left") then
        jugador.x = jugador.x - 200 * dt
    end
end

function love.draw()
    love.graphics.circle("fill", jugador.x, jugador.y, 20)
    love.graphics.print("Mi primer juego en LÖVE", 10, 10)
end