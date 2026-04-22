-- utils/game_serializer.lua
--
-- Serializes and deserializes world data for SaveSystem.
-- serialize: extracts only mutable state (visible, picked, open, etc.)
-- deserialize: rebuilds full objects from WorldGameData + applies saved state

local WorldGameData = require("core.game.world_data.world_game_data")

local GameSerializer = {}

-- SERIALIZE
local function serializeNpc(worldNpc)
    local optionStates = {}
    for _, opt in ipairs(worldNpc.npc.options) do
        optionStates[opt.id] = opt.active
    end
    return {
        id              = worldNpc.npc.id,
        mapState        = worldNpc.mapState,
        visible         = worldNpc.visible,
        interactEnabled = worldNpc.npc.interactEnabled,
        optionStates    = optionStates,
    }
end

local function serializeObject(worldObject)
    return {
        id       = worldObject.id,
        mapState = worldObject.mapState,
        visible  = worldObject.visible,
        picked   = worldObject.picked,
    }
end

local function serializeDoor(worldDoor)
    return {
        id       = worldDoor.id,
        mapState = worldDoor.mapState,
        visible  = worldDoor.visible,
        open     = worldDoor.open,
    }
end

function GameSerializer.serializeWorldData(worldData)
    local npcs, objects, doors = {}, {}, {}
    for _, v in ipairs(worldData.npcs)    do table.insert(npcs,    serializeNpc(v))    end
    for _, v in ipairs(worldData.objects) do table.insert(objects, serializeObject(v)) end
    for _, v in ipairs(worldData.doors)   do table.insert(doors,   serializeDoor(v))   end
    return { npcs = npcs, objects = objects, doors = doors }
end


-- DESERIALIZE
local function deserializeNpc(data)
    local worldNpc = WorldGameData.getNpcById(data.id)
    if not worldNpc then return nil end
    worldNpc.visible             = data.visible
    worldNpc.npc.interactEnabled = data.interactEnabled
    for id, active in pairs(data.optionStates or {}) do
        if active then worldNpc.npc:activateOption(id)
        else           worldNpc.npc:deactivateOption(id)
        end
    end
    return worldNpc
end

local function deserializeObject(data)
    local worldObject = WorldGameData.getObjectById(data.id)
    if not worldObject then return nil end
    worldObject.visible = data.visible
    worldObject.picked  = data.picked
    return worldObject
end

local function deserializeDoor(data)
    local worldDoor = WorldGameData.getDoorById(data.id)
    if not worldDoor then return nil end
    worldDoor.visible = data.visible
    worldDoor.open    = data.open
    return worldDoor
end

function GameSerializer.deserializeWorldData(data)
    local npcs, objects, doors = {}, {}, {}
    for _, d in ipairs(data.npcs    or {}) do local v = deserializeNpc(d)    if v then table.insert(npcs,    v) end end
    for _, d in ipairs(data.objects or {}) do local v = deserializeObject(d) if v then table.insert(objects, v) end end
    for _, d in ipairs(data.doors   or {}) do local v = deserializeDoor(d)  if v then table.insert(doors,   v) end end
    return { npcs = npcs, objects = objects, doors = doors }
end

return GameSerializer