-- core/game/world_data/world_npcs_list/test_npcs.lua
local WorldNpc             = require("core.game.world_elements.world_npc")
local Npc                  = require("core.npc.npc")
local NpcOption            = require("core.npc.npc_option")
local SimpleTalkOption     = require("core.npc.options.simple_talk_option")
local DialogueOption       = require("core.npc.options.dialogue_option")
local Dialogue             = require("core.npc.dialogue.dialogue")
local DialogueNode         = require("core.npc.dialogue.dialogue_node")
local PlayerDialogueOption = require("core.npc.dialogue.player_dialogue_option")
local S                    = require("core.state_system.states_names")
local TEST                 = "assets/sprites/test/"

local function makeDialogueTestNpc(id, id2, mapState)
    local test_events = require("core.event.events_list.test_events")

    local initialDialogue = Dialogue.new({
        DialogueNode.new("intro_1", id,  "dialogueTest1_intro_1", "intro_2", {}, nil),
        DialogueNode.new("intro_2", id2, "dialogueTest1_intro_2", nil,       {}, test_events.test_event_1),
    })
    local dialogue = Dialogue.new({
        DialogueNode.new("node_1", id,  "dialogueTest1_1", "node_2", {}, nil),
        DialogueNode.new("node_2", id2, "dialogueTest1_2", nil, {
            PlayerDialogueOption.new("dialoguePlayerTest1_1", "node_3", test_events.test_event_1),
            PlayerDialogueOption.new("dialoguePlayerTest1_2", "node_4", test_events.test_event_2),
        }, nil),
        DialogueNode.new("node_3", id2, "dialogueTest1_3", nil, {}, nil),
        DialogueNode.new("node_4", id,  "dialogueTest1_4", nil, {}, nil),
    })
    local npc = Npc.new(id, TEST .. "PlayerTest.png", {
        NpcOption.new("dialogue", "npc_opt_story", DialogueOption.new(dialogue), "dialogueTest1_option_intro"),
    }, initialDialogue)
    npc.interactEnabled = true
    return WorldNpc.new(npc, mapState)
end

local function makeSimpleTalkTestNpc(id, mapState)
    local npc = Npc.new(id, TEST .. "PlayerTest.png", {
        NpcOption.new("talk", "talk", SimpleTalkOption.new({"SimpleTalkOptionTEST1"}, "ordered")),
    })
    npc.interactEnabled = true
    return WorldNpc.new(npc, mapState)
end

return {
    makeDialogueTestNpc("npc_1_map_test",  "npc_5_map_test", S.test.map_test),
    makeSimpleTalkTestNpc("npc_2_map_test",  S.test.map_test),
    makeSimpleTalkTestNpc("npc_1_map_test2", S.test.map_test2),
    makeSimpleTalkTestNpc("npc_2_map_test2", S.test.map_test2),
}