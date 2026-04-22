local MapLoader        = require("core.map_loader")
local PlayerController = require("core.player_controller")
local Camera           = require("core.camera")
local UIController     = require("ui.ui_game_controller")
local Npc              = require("core.npc.npc")
local WorldNpc    = require("core.game.world_elements.world_npc")
local WorldObject = require("core.game.world_elements.world_object")
local WorldDoor   = require("core.game.world_elements.world_door")
local NpcOption        = require("core.npc.npc_option")
local GameController = require("core.game.game_controller")

local MapTest = {}
local STATENAME = "map_test"
local TEST = "assets/sprites/test/"


function MapTest.enter(sm, L)
    MapTest.sm    = sm
    MapTest.debug = false

    local worldData = GameController.getWorldDataForState(STATENAME)

    MapTest.map, MapTest.world, MapTest.spawn, MapTest.worldData =
        MapLoader.load("assets/maps/TestMap.lua",
            worldData.npcs,
            worldData.objects,
            worldData.doors)

    local startX, startY = GameController.resolveStartPosition(MapTest.worldData, MapTest.spawn)
    MapTest.player = PlayerController.new(MapTest.world, { x = startX, y = startY })
    MapTest.cam    = Camera.new(5)

    for _, door in ipairs(MapTest.worldData.doors) do
        door:checkSpawnProximity(startX, startY)
    end
end

function MapTest.update(dt)
    -- Udpate Data
    MapTest.world:update(dt)
    MapTest.map:update(dt)
    MapTest.player:update(dt, UIController.isMenuOpen())
    GameController.update(STATENAME, MapTest.player)

    if not UIController.isMenuOpen() then
        local px, py = MapTest.player:getPosition()

        for _, door in ipairs(MapTest.worldData.doors) do
            door:update(px, py, MapTest.sm, GameController)
        end
        for _, npc in ipairs(MapTest.worldData.npcs) do
            npc:update(dt, px, py)
        end
    end
end


function MapTest.keypressed(key)
    UIController.keypressed(key, MapTest.sm)

    if key == "e" then
        local px, py = MapTest.player:getPosition()
        for _, worldNpc in ipairs(MapTest.worldData.npcs) do
            local result = worldNpc:interact(px, py)
            if result then
                if result.type == "simple_talk" then
                    worldNpc:triggerSimpleTalk(result.textKey)
                else
                    MapTest.sm.switch("npc_interaction", worldNpc.npc, "map_test", "test")
                end
                break
            end
        end
    end

    -- BATTLE TESTING
    if key == "c" then
        local bc = buildTestBattle()
        MapTest.sm.switch("battle", bc, "map_test")
    end

    if not UIController.isMenuOpen() then
        if key == "escape" then
            MapTest.sm.switch("main_menu")
        elseif key == "f1" then
            MapTest.debug = not MapTest.debug

            -- testing gamecontroller
            GameController.trigger("test_event_1", "test")

        end
    end


    -- SAVE TESTING
    if key == "g" then
        local SaveSystem = require("core.save_system")
        local game = GameController.getGame()
        if game then
            SaveSystem.save(game.slot, game)
            print("[MapTest] Game saved to slot " .. game.slot)
        end
    end

    
end

function MapTest.draw()
    local px, py = MapTest.player:getPosition()
    Camera.update(MapTest.cam, px, py)
    UIController.draw(MapTest.map, MapTest.worldData, MapTest.player, MapTest.cam)

    -- Debug
    if MapTest.debug then
        Camera.drawDebug(MapTest.cam, MapTest.world)
    end
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("[F1] Toggle collision debug", 8, 8)
end

return MapTest