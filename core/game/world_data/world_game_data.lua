-- core/game/world_data/world_game_data.lua
--
-- Builds world data for a new game and provides lookup functions.
-- Used by: Game.new (new game) and game_serializer (load game).

local WorldNpc    = require("core.game.world_elements.world_npc")
local WorldObject = require("core.game.world_elements.world_object")
local WorldDoor   = require("core.game.world_elements.world_door")

-- Load all category files
local sources = {
    npcs = {
        require("core.game.world_data.world_npcs_lists.main_npcs"),
        require("core.game.world_data.world_npcs_lists.secondary_npcs"),
        require("core.game.world_data.world_npcs_lists.other_npcs"),
        require("core.game.world_data.world_npcs_lists.test_npcs"),
    },
    objects = {
        require("core.game.world_data.world_objects_list.main_objects"),
        require("core.game.world_data.world_objects_list.secondary_objects"),
        require("core.game.world_data.world_objects_list.test_objects"),
    },
    doors = {
        require("core.game.world_data.world_doors_list.main_doors"),
        require("core.game.world_data.world_doors_list.secondary_doors"),
        require("core.game.world_data.world_doors_list.test_doors"),
    },
}

local WorldGameData = {}

-- Merge all source lists into flat lists
function WorldGameData.buildWorldData()
    local npcs, objects, doors = {}, {}, {}
    for _, src in ipairs(sources.npcs)    do for _, v in ipairs(src) do table.insert(npcs,    v) end end
    for _, src in ipairs(sources.objects) do for _, v in ipairs(src) do table.insert(objects, v) end end
    for _, src in ipairs(sources.doors)   do for _, v in ipairs(src) do table.insert(doors,   v) end end
    return { npcs = npcs, objects = objects, doors = doors }
end

-- Lookup functions (used by deserializer to restore state)
function WorldGameData.getNpcById(id)
    for _, src in ipairs(sources.npcs) do
        for _, v in ipairs(src) do
            if v.npc.id == id then return v end
        end
    end
    print("[WARN] WorldGameData.getNpcById: not found: " .. id)
    return nil
end

function WorldGameData.getObjectById(id)
    for _, src in ipairs(sources.objects) do
        for _, v in ipairs(src) do
            if v.id == id then return v end
        end
    end
    print("[WARN] WorldGameData.getObjectById: not found: " .. id)
    return nil
end

function WorldGameData.getDoorById(id)
    for _, src in ipairs(sources.doors) do
        for _, v in ipairs(src) do
            if v.id == id then return v end
        end
    end
    print("[WARN] WorldGameData.getDoorById: not found: " .. id)
    return nil
end

return WorldGameData