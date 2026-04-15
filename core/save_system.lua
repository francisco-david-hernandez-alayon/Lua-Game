local json = require("libs.json") -- ligthweight json library
local Game = require("core.game")

local SaveSystem = {}

SaveSystem.slots = 3

local function getPath(slot)
    return "save_slot_" .. slot .. ".json"
end

function SaveSystem.exists(slot)
    return love.filesystem.getInfo(getPath(slot)) ~= nil
end

function SaveSystem.save(slot, game)
    game.last_save = os.time()

    local data = json.encode(game:toTable())
    love.filesystem.write(getPath(slot), data)
end

function SaveSystem.load(slot)
    if not SaveSystem.exists(slot) then return nil end

    local data = love.filesystem.read(getPath(slot))

    local ok, decoded = pcall(json.decode, data)
    if not ok or type(decoded) ~= "table" then
        return nil
    end

    return Game.new(decoded)
end

function SaveSystem.delete(slot)
    if SaveSystem.exists(slot) then
        love.filesystem.remove(getPath(slot))
    end
end

return SaveSystem