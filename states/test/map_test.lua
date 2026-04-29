-- states/test/map_test.lua

local MapLoader        = require("core.map_loader")
local PlayerController = require("core.player_controller")
local Camera           = require("core.camera")
local UIController     = require("ui.ui_game_controller")
local GameController = require("core.game.controller.game_controller")
local S = require("core.state_system.states_names")
local BattleController = require("core.battle.battle_controller")


local MapTest = {}
local STATENAME = S.test.map_test


function MapTest.enter(sm, L)
    MapTest.sm    = sm
    MapTest.debug = false

    local worldData = GameController.getWorldDataForState(STATENAME)

    MapTest.map, MapTest.world, MapTest.spawn, MapTest.worldData =
        MapLoader.load("assets/maps/TestMap.lua",
            worldData.npcs,
            worldData.objects,
            worldData.doors,
            worldData.triggers)

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

        for _, trigger in ipairs(MapTest.worldData.triggers) do
            trigger:update(px, py, GameController)
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
        local TestLanguage1 = require("core.programming_languages.languages.test_language")
        local TestLanguage2 = require("core.programming_languages.languages.test_language2")
        local LanguageLevelBuilder = require("utils.language_level_builder")

        local enemyLanguages = {
            LanguageLevelBuilder.build(TestLanguage1.new(), 3, "test_esp1"),
            LanguageLevelBuilder.build(TestLanguage2.new(), 3, "test_esp2"),
        }

        GameController.startBattle(
            MapTest.sm,
            "EnemyProgrammer",
            enemyLanguages,
            "map_test"
        )
    end



    if not UIController.isMenuOpen() then
        if key == "escape" then
            MapTest.sm.switch("main_menu")
        elseif key == "f1" then
            MapTest.debug = not MapTest.debug

            -- testing gamecontroller
            local test_events = require("core.event.events_list.test_events")
            GameController.emit(test_events.test_event_1)

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
    love.graphics.print("[F1] Toggle collision debug, [G] to save, [C] to combat", 8, 8)
end

return MapTest