local Settings = {
    language = "EN",
    volume = 1
}

local FILE = "settings.txt"

function Settings.set(data)
    for k, v in pairs(data) do
        Settings[k] = v
    end
end

function Settings.save()
    local data = Settings.language .. "\n" .. tostring(Settings.volume)
    love.filesystem.write(FILE, data)
end

function Settings.load()
    if not love.filesystem.getInfo(FILE) then
        return
    end

    local data = love.filesystem.read(FILE)
    local lang, volume = data:match("([A-Z]+)\n([%d%.]+)")

    if lang then
        Settings.language = lang
    end

    if volume then
        Settings.volume = tonumber(volume)
    end
end

return Settings