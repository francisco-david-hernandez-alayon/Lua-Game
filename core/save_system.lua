local Save = {}

function Save.newGame()
    return {
        hp = 100,
        enemy = "slime",
        turn = 1
    }
end

function Save.save(data)
    love.filesystem.write("save.txt", love.data.encode("string", "json", data))
end

function Save.load()
    local file = love.filesystem.read("save.txt")
    if not file then return nil end
    return love.data.decode("string", "json", file)
end

return Save