-- core/audio/sound.lua

local Sound = {}
Sound.__index = Sound

function Sound.new(id, path, sourceType, looping)
    return setmetatable({
        id = id,
        path = path,
        sourceType = sourceType or "static",
        looping = looping or false
    }, Sound)
end

return Sound