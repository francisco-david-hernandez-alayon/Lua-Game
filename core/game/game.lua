-- core/game.lua
local PlayerInventory = require("core.inventory.player_inventory")

local Game = {}
Game.__index = Game

function Game.new(data)
    local self = setmetatable({}, Game)
    assert(type(data.name) == "string", "name must be string")
    assert(type(data.gameState) == "string", "gameState must be string")
    assert(data.doorTargetId == nil or type(data.doorTargetId) == "string", "doorTargetId must be string or nil")

    -- Game Data
    self.name       = data.name
    self.created_at = data.created_at or os.time()
    self.last_save  = data.last_save  or os.time()
    self.slot       = data.slot       or 1

    --Player position
    self.gameState  = data.gameState  or nil  -- current map state
    self.playerX    = data.playerX    or nil  -- saved player x (nil = use spawn)
    self.playerY    = data.playerY    or nil  -- saved player y (nil = use spawn)
    self.doorTargetId = nil

    -- Inventory
    if data.inventory then
        self.inventory = PlayerInventory.fromTable(data.inventory)
    else
        self.inventory = PlayerInventory.new()
    end

    return self
end

-- Returns current state and position for player restoration
-- x/y nil means use spawn point
function Game:getPlayerPosition()
    return {
        state = self.gameState,
        x     = self.playerX,
        y     = self.playerY,
    }
end

-- Save current player position and state
function Game:savePlayerPosition(state, x, y)
    self.gameState = state
    self.playerX   = x
    self.playerY   = y
end

function Game:toTable()
    return {
        name       = self.name,
        created_at = self.created_at,
        last_save  = self.last_save,
        slot       = self.slot,
        gameState  = self.gameState,
        playerX    = self.playerX,
        playerY    = self.playerY,
        inventory  = self.inventory:toTable(),
    }
end

return Game