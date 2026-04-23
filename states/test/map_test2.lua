local MapLoader        = require("core.map_loader")
local PlayerController = require("core.player_controller")
local Camera           = require("core.camera")
local UIController     = require("ui.ui_game_controller")
local GameController = require("core.game.controller.game_controller")
local S = require("core.state_system.states_names")

local MapTest2 = {}
local STATENAME = S.test.map_test2


function MapTest2.enter(sm, L)
    MapTest2.sm    = sm
    MapTest2.debug = false

    local worldData = GameController.getWorldDataForState(STATENAME)

    MapTest2.map, MapTest2.world, MapTest2.spawn, MapTest2.worldData =
        MapLoader.load("assets/maps/TestMap2.lua",
            worldData.npcs,
            worldData.objects,
            worldData.doors)

    local startX, startY = GameController.resolveStartPosition(MapTest2.worldData, MapTest2.spawn)
    MapTest2.player = PlayerController.new(MapTest2.world, { x = startX, y = startY })
    MapTest2.cam    = Camera.new(5)

    for _, door in ipairs(MapTest2.worldData.doors) do
        door:checkSpawnProximity(startX, startY)
    end
end


function MapTest2.update(dt)
    -- Update data
    MapTest2.world:update(dt)
    MapTest2.map:update(dt)
    MapTest2.player:update(dt, UIController.isMenuOpen())
    GameController.update(STATENAME, MapTest2.player)

    if not UIController.isMenuOpen() then
        local px, py = MapTest2.player:getPosition()
        for _, door in ipairs(MapTest2.worldData.doors) do
            door:update(px, py, MapTest2.sm, GameController)
        end
        for _, npc in ipairs(MapTest2.worldData.npcs) do
            npc:update(dt, px, py)
        end
    end
end


function MapTest2.keypressed(key)
    UIController.keypressed(key, MapTest2.sm)

    if key == "e" then
        local px, py = MapTest2.player:getPosition()
        for _, worldNpc in ipairs(MapTest2.worldData.npcs) do
            local result = worldNpc:interact(px, py)
            if result then
                if result.type == "simple_talk" then
                    worldNpc:triggerSimpleTalk(result.textKey)
                else
                    MapTest2.sm.switch("npc_interaction", worldNpc.npc, "map_test", "test")
                end
                break
            end
        end
    end

    if not UIController.isMenuOpen() then
        if key == "escape" then
            MapTest2.sm.switch("main_menu")
        elseif key == "f1" then
            MapTest2.debug = not MapTest2.debug
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


function MapTest2.draw()
    local px, py = MapTest2.player:getPosition()
    Camera.update(MapTest2.cam, px, py)
    UIController.draw(MapTest2.map, MapTest2.worldData, MapTest2.player, MapTest2.cam)

    -- Debug
    if MapTest2.debug then
        Camera.drawDebug(MapTest2.cam, MapTest2.world)
    end
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("[F1] Toggle collision debug", 8, 8)
end

return MapTest2