-- core/game_controller.lua
--
-- Central game controller. Loaded when a game session starts.
-- Receives a Game instance and routes emitted events to the correct handler.
--
-- FLOW:
--   1. GameController.load(game)  → called when player starts/loads a game
--   2. GameController.emit(event) → routes event to handler by type
--   3. GameController.getGame()   → returns current Game (for save system)
--   4. GameController.unload()    → called when returning to main menu

local Event = require("core.events.event")

local handlers = {
    main      = require("core.events.handlers.main_events_handler"),
    secondary = require("core.events.handlers.secondary_events_handler"),
    test      = require("core.events.handlers.test_events_handler"),
}

local GameController = {}

local currentGame = nil

-- Load a game session
function GameController.load(game)
    assert(game, "GameController.load requires a Game instance")
    currentGame = game
    print("[GameController] session started for: " .. game.name)
end

-- Emit an event — routes to the correct handler by eventType
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

-- Returns current Game instance (used by SaveSystem)
function GameController.getGame()
    return currentGame
end

-- Unload session (call when returning to main menu)
function GameController.unload()
    if currentGame then
        print("[GameController] session ended for: " .. currentGame.name)
    end
    currentGame = nil
end

-- Shortcut to create and emit an event in one call
function GameController.trigger(eventId, eventType)
    local event = Event.new(eventId, eventType)
    GameController.emit(event)
end

return GameController