-- core/settings.lua

local Settings = {
    language = "EN",
    masterVolume = 1,
    musicVolume = 1,
    sfxVolume = 1
}

local FILE = "settings.txt"

function Settings.set(data)
    for k, v in pairs(data) do
        if Settings[k] ~= nil then
            Settings[k] = v
        end
    end
end

local function clamp(value)
    return math.max(0, math.min(1, value))
end

function Settings.save()
    local data = table.concat({
        "language=" .. Settings.language,
        "masterVolume=" .. tostring(clamp(Settings.masterVolume)),
        "musicVolume=" .. tostring(clamp(Settings.musicVolume)),
        "sfxVolume=" .. tostring(clamp(Settings.sfxVolume))
    }, "\n")

    love.filesystem.write(FILE, data)
end

function Settings.load()
    if not love.filesystem.getInfo(FILE) then
        return
    end

    local data = love.filesystem.read(FILE)

    local legacyLang, legacyVolume = data:match("([A-Z]+)\n([%d%.]+)")
    if legacyLang and legacyVolume and not data:find("=") then
        Settings.language = legacyLang
        Settings.masterVolume = clamp(tonumber(legacyVolume) or 1)
        Settings.musicVolume = Settings.masterVolume
        Settings.sfxVolume = Settings.masterVolume
        return
    end

    for key, value in data:gmatch("([%a_]+)=([^\n]+)") do
        if key == "language" then
            Settings.language = value
        elseif key == "masterVolume" or key == "musicVolume" or key == "sfxVolume" then
            Settings[key] = clamp(tonumber(value) or 1)
        end
    end
end

return Settings