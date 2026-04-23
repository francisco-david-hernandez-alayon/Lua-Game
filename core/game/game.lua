-- core/game/game.lua
local PlayerInventory  = require("core.inventory.player_inventory")
local WorldGameData    = require("core.game.world_data.world_game_data")
local GameSerializer   = require("utils.game_serializer")
local PlayerMissions = require("core.mission.player_missions")
local test_missions  = require("core.mission.missions_list.test_missions")

local Game = {}
Game.__index = Game

function Game.new(data)
    local self = setmetatable({}, Game)
    assert(type(data.name)      == "string", "name must be string")
    assert(type(data.gameState) == "string", "gameState must be string")

    -- Game data
    self.name       = data.name
    self.created_at = data.created_at or os.time()
    self.last_save  = data.last_save  or os.time()
    self.slot       = data.slot       or 1

    -- Player position
    self.gameState    = data.gameState
    self.playerX      = data.playerX      or nil
    self.playerY      = data.playerY      or nil
    self.doorTargetId = data.doorTargetId or nil

    -- Inventory
    if data.inventory then
        self.inventory = PlayerInventory.fromTable(data.inventory)
    else
        self.inventory = PlayerInventory.new()
    end

    -- World data: npcs, objects, doors across all maps
    -- New game: build from world_game_data
    -- Load game: deserialize from saved data
    if data.worldData then
        self.worldData = GameSerializer.deserializeWorldData(data.worldData)
    else
        self.worldData = WorldGameData.buildWorldData()
    end

    -- Missions
    if data.playerMissions then
        self.playerMissions = PlayerMissions.fromTable(data.playerMissions)
    else
        self.playerMissions = PlayerMissions.new()
        -- Add test mission on new game
        self.playerMissions:addMission(test_missions.mission_test_1)
    end

    return self
end

function Game:getPlayerPosition()
    return { state = self.gameState, x = self.playerX, y = self.playerY }
end

function Game:savePlayerPosition(state, x, y)
    self.gameState = state
    self.playerX   = x
    self.playerY   = y
end

function Game:toTable()
    return {
        name          = self.name,
        created_at    = self.created_at,
        last_save     = self.last_save,
        slot          = self.slot,
        gameState     = self.gameState,
        playerX       = self.playerX,
        playerY       = self.playerY,
        doorTargetId  = self.doorTargetId,
        inventory     = self.inventory:toTable(),
        worldData     = GameSerializer.serializeWorldData(self.worldData),
        playerMissions = self.playerMissions:toTable(),
    }
end

return Game