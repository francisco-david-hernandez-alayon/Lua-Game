-- core/game/game_controller.lua
--
-- Central controller for the active game session.
-- All game systems (inventory, missions, events, world) are accessed through here.
--
-- FLOW:
--   1. GameController.load(game)            → start session
--   2. GameController.update(state, player) → save position every frame
--   3. GameController.trigger(id, type)     → emit a game event
--   4. GameController.getGame()             → get raw Game instance
--   5. GameController.unload()              → end session

local EventController     = require("core.game.controller.event_controller")
local InventoryController = require("core.game.controller.inventory_controller")
local MissionController   = require("core.game.controller.mission_controller")

local GameController = {}
local currentGame    = nil

-- GAME SESSION
local function requireSession()
    assert(currentGame, "[GameController] no active game session")
end

function GameController.load(game)
    assert(game, "[GameController] load requires a Game instance")
    currentGame = game
    print("[GameController] session started for: " .. game.name)
end

function GameController.getGame()
    return currentGame
end

function GameController.unload()
    if currentGame then
        print("[GameController] session ended for: " .. currentGame.name)
    end
    currentGame = nil
end


-- UPDATE
-- Call every frame from any map state to persist player position
function GameController.update(state, player)
    if not currentGame then return end
    local px, py = player:getPosition()
    currentGame:savePlayerPosition(state, px, py)
end


-- EVENTS
function GameController.trigger(eventId, eventType)
    requireSession()
    EventController.trigger(eventId, eventType, currentGame)
end

function GameController.emit(event)
    requireSession()
    EventController.emit(event, currentGame)
end


-- INVENTORY
function GameController.getInventory()
    requireSession()
    return currentGame.inventory
end

function GameController.earnBytes(amount)
    requireSession()
    return InventoryController.earnBytes(currentGame.inventory, amount)
end

function GameController.spendBytes(amount)
    requireSession()
    return InventoryController.spendBytes(currentGame.inventory, amount)
end

function GameController.addItem(item)
    requireSession()
    return InventoryController.addItem(currentGame.inventory, item)
end

function GameController.removeItem(nameKey, amount)
    requireSession()
    return InventoryController.removeItem(currentGame.inventory, nameKey, amount)
end

function GameController.learnLanguage(languageSlot)
    requireSession()
    return InventoryController.learnLanguage(currentGame.inventory, languageSlot)
end

function GameController.equipLanguageToSlot(languageId, slotIndex)
    requireSession()
    return InventoryController.equipLanguageToSlot(currentGame.inventory, languageId, slotIndex)
end

function GameController.swapLanguageSlots(slotA, slotB)
    requireSession()
    return InventoryController.swapLanguageSlots(currentGame.inventory, slotA, slotB)
end

function GameController.applyReward(reward)
    requireSession()
    InventoryController.applyReward(currentGame.inventory, reward)
end


-- MISSIONS
function GameController.addMission(mission)
    requireSession()
    return MissionController.addMission(currentGame.playerMissions, mission)
end

function GameController.completeTask(missionId, taskId)
    requireSession()
    return MissionController.completeTask(
        currentGame.playerMissions,
        currentGame.inventory,
        missionId,
        taskId
    )
end

function GameController.setCurrentMission(missionId)
    requireSession()
    return MissionController.setCurrentMission(currentGame.playerMissions, missionId)
end

function GameController.getCurrentMission()
    requireSession()
    return MissionController.getCurrentMission(currentGame.playerMissions)
end


-- SPAWN
-- Priority: door target → last saved position → map spawn → fallback (0,0)
function GameController.resolveStartPosition(worldData, spawnPoint)
    if not currentGame then
        return (spawnPoint and spawnPoint.x) or 0,
               (spawnPoint and spawnPoint.y) or 0
    end

    -- Priority 1: door target
    local targetId = currentGame.doorTargetId
    if targetId then
        for _, door in ipairs(worldData.doors or {}) do
            if door.id == targetId and door.x and door.y then
                print("[GameController] start from door:", targetId)
                currentGame.doorTargetId = nil
                return door.x, door.y
            end
        end
        print("[GameController] door target not found:", targetId)
        currentGame.doorTargetId = nil
    end

    -- Priority 2: last saved position
    local pos = currentGame:getPlayerPosition()
    if pos and pos.x and pos.y then
        print("[GameController] start from last position:", pos.x, pos.y)
        return pos.x, pos.y
    end

    -- Priority 3: map spawn
    if spawnPoint and spawnPoint.x and spawnPoint.y then
        print("[GameController] start from spawn:", spawnPoint.x, spawnPoint.y)
        return spawnPoint.x, spawnPoint.y
    end

    -- Priority 4: fallback
    print("[GameController] start from fallback (0, 0)")
    return 0, 0
end


-- DOORS
function GameController.setDoorTarget(doorId)
    if not currentGame then return end
    currentGame.doorTargetId = doorId
    print("[GameController] door target set:", doorId)
end


-- WORLD DATA
-- Returns npcs, objects and doors filtered by map state
function GameController.getWorldDataForState(state)
    requireSession()
    local npcs, objects, doors = {}, {}, {}
    for _, v in ipairs(currentGame.worldData.npcs)    do
        if v.mapState == state then table.insert(npcs,    v) end
    end
    for _, v in ipairs(currentGame.worldData.objects) do
        if v.mapState == state then table.insert(objects, v) end
    end
    for _, v in ipairs(currentGame.worldData.doors)   do
        if v.mapState == state then table.insert(doors,   v) end
    end
    print("[GameController] getWorldDataForState [" .. state .. "]" ..
          " npcs:" .. #npcs .. " objects:" .. #objects .. " doors:" .. #doors)
    return { npcs = npcs, objects = objects, doors = doors }
end

function GameController.getNpc(id)
    requireSession()
    for _, v in ipairs(currentGame.worldData.npcs) do
        if v.npc.id == id then return v end
    end
    print("[WARN] GameController.getNpc: not found: " .. id)
    return nil
end

function GameController.getObject(id)
    requireSession()
    for _, v in ipairs(currentGame.worldData.objects) do
        if v.id == id then return v end
    end
    print("[WARN] GameController.getObject: not found: " .. id)
    return nil
end

function GameController.getDoor(id)
    requireSession()
    for _, v in ipairs(currentGame.worldData.doors) do
        if v.id == id then return v end
    end
    print("[WARN] GameController.getDoor: not found: " .. id)
    return nil
end

return GameController