-- utils/id_generator.lua
--
-- Utility helpers for generating unique ids.

local IdGenerator = {}

local function randomHex(length)
    local result = {}
    for i = 1, length do
        result[i] = string.format("%x", math.random(0, 15))
    end
    return table.concat(result)
end

-- Generates a UUID-like v4 string.
function IdGenerator.uuid()
    local template = "xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx"

    return (template:gsub("[xy]", function(c)
        local v = (c == "x") and math.random(0, 15) or math.random(8, 11)
        return string.format("%x", v)
    end))
end

-- Generates a long unique id without UUID format.
function IdGenerator.longId(prefix)
    prefix = prefix or "id"
    return string.format(
        "%s_%d_%s_%s",
        prefix,
        os.time(),
        randomHex(8),
        randomHex(8)
    )
end

return IdGenerator
