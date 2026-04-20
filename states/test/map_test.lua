local MapLoader        = require("core.map_loader")
local PlayerController = require("core.player_controller")
local Camera           = require("core.camera")
local UIController     = require("ui.ui_game_controller")
local Npc              = require("core.npc.npc")
local MovingNpc        = require("core.world_elements.moving_npc")
local Object           = require("core.world_elements.object")
local Door             = require("core.world_elements.door")
local NpcOption        = require("core.npc.npc_option")

local MapTest = {}
local TEST = "assets/sprites/test/"


--DIALOGUE TEST
local SimpleTalkOption  = require("core.npc.options.simple_talk_option")
local DialogueOption    = require("core.npc.options.dialogue_option")
local Dialogue          = require("core.npc.dialogue.dialogue")
local DialogueNode      = require("core.npc.dialogue.dialogue_node")
local PlayerDialogueOption = require("core.npc.dialogue.player_dialogue_option")
-- NPC 1: has dialogue option
local function makeDialogueTestNpc(id, spritePath)
    local dialogue = Dialogue.new({
        DialogueNode.new("node_1", "npc_1",  "dialogueTest1_1", "node_2", {}),
        DialogueNode.new("node_2", "npc_1",  "dialogueTest1_2", nil, {
            PlayerDialogueOption.new("dialoguePlayerTest1_1", "node_3"),
            PlayerDialogueOption.new("dialoguePlayerTest1_2", "node_4"),
        }),
        DialogueNode.new("node_3", "npc_1",  "dialogueTest1_3", nil, {}),
        DialogueNode.new("node_4", "npc_1",  "dialogueTest1_4", nil, {}),
    })
    local dialogueOpt = DialogueOption.new(dialogue)
    return Npc.new(id, spritePath, {
        NpcOption.new("dialogue", "npc_opt_story", dialogueOpt, "dialogueTest1_intro"),
    })
end

-- NPC 2: simple talk
local function makeSimpleTalkTestNpc(id, spritePath)
    local simpleTalk = SimpleTalkOption.new({"SimpleTalkOptionTEST1"}, "ordered")
    return Npc.new(id, spritePath, {
        NpcOption.new("talk", "talk", simpleTalk),
    })
end


function MapTest.enter(sm, L)
    MapTest.sm    = sm
    MapTest.debug = false

    local npcs = {
        makeDialogueTestNpc("npc_1",  TEST .. "PlayerTest.png"),
        makeSimpleTalkTestNpc("npc_2", TEST .. "PlayerTest.png"),
    }
    local moving_npcs = {
        MovingNpc.new("moving_npc_1", TEST .. "PlayerTest.png"),
    }
    local objects = {
        Object.new("item_1", TEST .. "item_test.png"),
        Object.new("item_2", TEST .. "item_test.png"),
        Object.new("item_3", TEST .. "item_test.png"),
        Object.new("item_4", TEST .. "item_test.png"),
    }
    local doors = {
        Door.new("door_1", TEST .. "door_1.png", "map_test2", true),
    }

    MapTest.map, MapTest.world, MapTest.spawn, MapTest.worldData =
    MapLoader.load("assets/maps/TestMap.lua", npcs, moving_npcs, objects, doors)
    MapTest.player = PlayerController.new(MapTest.world, MapTest.spawn)
    MapTest.cam    = Camera.new(5)
end



function MapTest.update(dt)
    MapTest.world:update(dt)
    MapTest.map:update(dt)
    MapTest.player:update(dt, UIController.isMenuOpen())

    local px, py = MapTest.player:getPosition()
    for _, npc in ipairs(MapTest.worldData.npcs) do
        npc:update(dt, px, py)
    end

    if not UIController.isMenuOpen() then
        local px, py = MapTest.player:getPosition()
        for _, door in ipairs(MapTest.worldData.doors) do
            door:update(px, py, MapTest.sm)
        end
    end
end



function MapTest.keypressed(key)
    UIController.keypressed(key, MapTest.sm)

    if key == "e" then
        local px, py = MapTest.player:getPosition()
        for _, npc in ipairs(MapTest.worldData.npcs) do
            local result = npc:interact(px, py)
            if result then
                if result.type == "simple_talk" then
                    npc:triggerSimpleTalk(result.textKey)
                else
                    MapTest.sm.switch("npc_interaction", npc, "map_test", "test")
                end
                break
            end
        end
    end

    if not UIController.isMenuOpen() then
        if key == "escape" then
            MapTest.sm.switch("main_menu")
        elseif key == "f1" then
            MapTest.debug = not MapTest.debug

            -- testing gamecontroller
            local GameController = require("core.game_controller")
            GameController.trigger("test_event_1", "test")

        end
    end
end

function MapTest.draw()
    local px, py = MapTest.player:getPosition()
    Camera.update(MapTest.cam, px, py)

    UIController.draw(
        MapTest.map,
        MapTest.worldData,
        MapTest.player,
        MapTest.cam
    )


    -- Debug
    if MapTest.debug then
        Camera.drawDebug(MapTest.cam, MapTest.world)
    end
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("[F1] Toggle collision debug", 8, 8)
end

return MapTest