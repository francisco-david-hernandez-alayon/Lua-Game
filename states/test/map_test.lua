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


----- DIALOGUE TESTING -----
local SimpleTalkOption  = require("core.npc.options.simple_talk_option")
local DialogueOption    = require("core.npc.options.dialogue_option")
local Dialogue          = require("core.npc.dialogue.dialogue")
local DialogueNode      = require("core.npc.dialogue.dialogue_node")
local PlayerDialogueOption = require("core.npc.dialogue.player_dialogue_option")
-- NPC 1: has dialogue option
local function makeDialogueTestNpc(id, spritePath)
    local initialDialogue = Dialogue.new({
        DialogueNode.new("intro_1", id, "dialogueTest1_intro_1", "intro_2", {}, nil),
        DialogueNode.new("intro_2", id, "dialogueTest1_intro_2", nil,       {}, "test_event_1"),  -- emits on advance
    })

    local dialogue = Dialogue.new({
        DialogueNode.new("node_1", id, "dialogueTest1_1", "node_2", {}, nil),
        DialogueNode.new("node_2", id, "dialogueTest1_2", nil, {
            PlayerDialogueOption.new("dialoguePlayerTest1_1", "node_3", "test_event_1"),  -- emits on choose
            PlayerDialogueOption.new("dialoguePlayerTest1_2", "node_4", "test_event_2"),  -- emits on choose
        }, nil),
        DialogueNode.new("node_3", id, "dialogueTest1_3", nil, {}, nil),
        DialogueNode.new("node_4", id, "dialogueTest1_4", nil, {}, nil),
    })

    local dialogueOpt = DialogueOption.new(dialogue)
    local npc = Npc.new(id, spritePath, {
        NpcOption.new("dialogue", "npc_opt_story", dialogueOpt, "dialogueTest1_option_intro"),
    }, initialDialogue, true)

    return WorldNpc.new(npc, STATENAME);
end

-- NPC 2: simple talk
local function makeSimpleTalkTestNpc(id, spritePath)
    local simpleTalk = SimpleTalkOption.new({"SimpleTalkOptionTEST1"}, "ordered")
    local npc = Npc.new(id, spritePath, {
        NpcOption.new("talk", "talk", simpleTalk),
    }, nil, false)
    
    return WorldNpc.new(npc, STATENAME);
end



------------------ BATLE TESTING --------------------------------------
local BattleController     = require("core.battle.battle_controller")
local ProgrammingLanguage  = require("core.battle.programming_language")
local Attack               = require("core.battle.attack")

local function buildTestBattle()
    -- Enemy: 2 languages, 1 attack each
    local enemyLua = ProgrammingLanguage.new("Lua", 80, 5)
    enemyLua:addAttack(Attack.new("atk_metatables", 20))

    local enemyC = ProgrammingLanguage.new("C", 100, 3)
    enemyC:addAttack(Attack.new("atk_pointers", 30))

    -- Player: 3 languages, 2 attacks each
    local playerPy = ProgrammingLanguage.new("Python", 90, 6)
    playerPy:addAttack(Attack.new("atk_list_comp",  18))
    playerPy:addAttack(Attack.new("atk_decorators", 25))

    local playerJS = ProgrammingLanguage.new("JavaScript", 70, 7)
    playerJS:addAttack(Attack.new("atk_callback",  15))
    playerJS:addAttack(Attack.new("atk_promise",   22))

    local playerRust = ProgrammingLanguage.new("Rust", 110, 4)
    playerRust:addAttack(Attack.new("atk_ownership", 28))
    playerRust:addAttack(Attack.new("atk_borrow",    20))

    return BattleController.new(
        "EnemyProgrammer",
        { playerPy, playerJS, playerRust },
        { enemyLua, enemyC }
    )
end


function MapTest.enter(sm, L)
    MapTest.sm    = sm
    MapTest.debug = false

    local npcs = {
        makeDialogueTestNpc("npc_1",  TEST .. "PlayerTest.png"),
        makeSimpleTalkTestNpc("npc_2", TEST .. "PlayerTest.png"),
    }
    local objects = {
        WorldObject.new("item_1", TEST .. "item_test.png", STATENAME),
        WorldObject.new("item_2", TEST .. "item_test.png", STATENAME),
        WorldObject.new("item_3", TEST .. "item_test.png", STATENAME),
        WorldObject.new("item_4", TEST .. "item_test.png", STATENAME),
    }
    local doors = {
        WorldDoor.new("door_1", TEST .. "door_1.png", "door_1", "map_test2", STATENAME, true),
    }
    -- LOAD WORLD
    MapTest.map, MapTest.world, MapTest.spawn, MapTest.worldData = MapLoader.load("assets/maps/TestMap.lua", npcs, objects, doors)

    -- Get player spawn
    local startX, startY = GameController.resolveStartPosition(MapTest.worldData, MapTest.spawn)
    MapTest.player = PlayerController.new(MapTest.world, { x = startX, y = startY })
    MapTest.cam    = Camera.new(5)

    -- Check doors proximity To Player
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