-- states/test/main_test.lua
local SimpleMenuController    = require("ui.simple_menu_controller")
local GameController          = require("core.game.controller.game_controller")
local Game                    = require("core.game.game")
local SaveSystem              = require("core.save_system")
local Item                    = require("core.inventory.item")
local MissionItem             = require("core.inventory.mission_item")


local MainTest = {}

local TEST_SLOT = 3

local function buildTestInventory(inventory)
    local TestLanguage1 = require("core.programming_languages.languages.test_language")
    local TestLanguage2 = require("core.programming_languages.languages.test_language2")
    local LanguageLevelBuilder = require("utils.language_level_builder")
    inventory:addProgrammingLanguageSlot(LanguageLevelBuilder.build(TestLanguage1.new(), 1, "test_esp1"))
    inventory:addProgrammingLanguageSlot(LanguageLevelBuilder.build(TestLanguage2.new(), 2, "test_esp1"))
    inventory:addProgrammingLanguageSlot(LanguageLevelBuilder.build(TestLanguage1.new(), 3, "test_esp2"))
    inventory:addProgrammingLanguageSlot(LanguageLevelBuilder.build(TestLanguage2.new(), 3, "test_esp2"))

    local itemA = Item.new("test_item_a", "test_item_a_desc", 1)
    inventory:addItem(itemA)
    local itemB = Item.new("test_item_b", "test_item_b_desc", 10)
    itemB.count = 10
    inventory:addItem(itemB)
    local itemB2 = Item.new("test_item_b", "test_item_b_desc", 10)
    itemB2.count = 5
    inventory:addItem(itemB2)
    inventory:addMissionItem(MissionItem.new("test_mission_item", "test_mission_item_desc"))
end

local function buildMenuOptions()
    local options = {}
    if SaveSystem.exists(TEST_SLOT) then
        table.insert(options, "LOAD SLOT " .. TEST_SLOT)
    end
    table.insert(options, "NEW TEST GAME")
    table.insert(options, "Return")
    return options
end

function MainTest.enter(sm, L)
    MainTest.sm = sm
    MainTest.L  = L
    MainTest.menu = SimpleMenuController.new(buildMenuOptions())
end

function MainTest.keypressed(key)
    if key == "up"   then SimpleMenuController.moveUp(MainTest.menu)   end
    if key == "down" then SimpleMenuController.moveDown(MainTest.menu) end

    if key == "return" then
        local choice = SimpleMenuController.getSelected(MainTest.menu)

        if choice == "LOAD SLOT " .. TEST_SLOT then
            local game = SaveSystem.load(TEST_SLOT)
            if game then
                GameController.load(game)
                MainTest.sm.switch(game.gameState)
            else
                print("[MainTest] Failed to load slot " .. TEST_SLOT)
            end

        elseif choice == "NEW TEST GAME" then
            local testGame = Game.new({
                name      = "TESTING GAME",
                slot      = TEST_SLOT,
                gameState = "map_test",
            })
            buildTestInventory(testGame.inventory)
            GameController.load(testGame)
            MainTest.sm.switch("map_test")

        elseif choice == "Return" then
            MainTest.sm.switch("main_menu")
        end
    end
end

function MainTest.draw()
    SimpleMenuController.draw(MainTest.menu, 100, 100)
end

return MainTest