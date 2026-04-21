-- core/game_controller.lua
--
-- FLOW:
--   1. GameController.load(game)           → called when player starts/loads a game
--   2. GameController.update(state, px, py) → call every frame from map state update
--   3. GameController.emit(event)           → routes event to handler by type
--   4. GameController.getGame()             → returns current Game (for save system)
--   5. GameController.unload()              → called when returning to main menu

local Event = require("core.events.event")

local handlers = {
    main      = require("core.events.handlers.main_events_handler"),
    secondary = require("core.events.handlers.secondary_events_handler"),
    test      = require("core.events.handlers.test_events_handler"),
}

local GameController = {}
local currentGame = nil

function GameController.load(game)
    assert(game, "GameController.load requires a Game instance")
    currentGame = game
    print("[GameController] session started for: " .. game.name)
end

-- Call every frame from any map state, passing current state name and player position
function GameController.update(state, player)
    if not currentGame then return end
    local px, py = player:getPosition()
    currentGame:savePlayerPosition(state, px, py)

    --Debug
    --print("---Save player position in " .. state .. ": (" .. px .. ", " .. py .. ")")
end

---------- EVENTS ----------
function GameController.emit(event)
    assert(currentGame, "[GameController] no active game session")
    assert(event and event.eventId and event.eventType, "[GameController] invalid event")
    local handler = handlers[event.eventType]
    if not handler then
        print("[ERROR] GameController: no handler for type: " .. event.eventType)
        return
    end
    local handled = handler(event.eventId, currentGame)
    if not handled then
        print("[ERROR] GameController: event not found: " .. event.eventId .. " in type: " .. event.eventType)
    end
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

function GameController.trigger(eventId, eventType)
    GameController.emit(Event.new(eventId, eventType))
end

---------- SPAWN ----------
-- Resolves the correct player start position in this priority order:
-- 1. Door target spawn (coming from another map through a door)
-- 2. Last saved player position (returning from inventory, dialogue, etc.)
-- 3. Map spawn point
-- 4. Fallback (0, 0)
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
                print("[GameController] Start from door:", targetId)
                currentGame.doorTargetId = nil
                return door.x, door.y
            end
        end
        print("[GameController] Door target not found:", targetId)
        currentGame.doorTargetId = nil
    end

    -- Priority 2: last saved position
    local pos = currentGame:getPlayerPosition()
    if pos and pos.x and pos.y then
        print("[GameController] Start from last position:", pos.x, pos.y)
        return pos.x, pos.y
    end

    -- Priority 3: map spawn
    if spawnPoint and spawnPoint.x and spawnPoint.y then
        print("[GameController] Start from spawn point:", spawnPoint.x, spawnPoint.y)
        return spawnPoint.x, spawnPoint.y
    end

    -- Priority 4: fallback
    print("[GameController] Start from fallback (0, 0)")
    return 0, 0
end

---------- DOORS ----------
function GameController.setDoorTarget(doorId)
    if not currentGame then return end
    currentGame.doorTargetId = doorId

    print("[GameController] Door target set:", doorId)
end

return GameController