-- states/test/main_test.lua
local SimpleMenuController    = require("ui.simple_menu_controller")
local GameController          = require("core.game.game_controller")
local Game                    = require("core.game.game")
local Item                    = require("core.inventory.item")
local MissionItem             = require("core.inventory.mission_item")
local ProgrammingLanguageSlot = require("core.inventory.programming_language_slot")

local MainTest = {}

local function buildTestInventory(inventory)
    inventory:addProgrammingLanguageSlot(ProgrammingLanguageSlot.new("c++"))

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

function MainTest.enter(sm, L)
    MainTest.sm = sm
    MainTest.L  = L

    local testGame = Game.new({
        name      = "TestPlayer",
        slot      = 0,
        gameState = "map_test",  -- default map state for test session
    })
    buildTestInventory(testGame.inventory)
    GameController.load(testGame)

    MainTest.menu = SimpleMenuController.new({
        "MAP TEST",
        "Return"
    })
end

function MainTest.keypressed(key)
    if key == "up"   then SimpleMenuController.moveUp(MainTest.menu)   end
    if key == "down" then SimpleMenuController.moveDown(MainTest.menu) end
    if key == "return" then
        local choice = SimpleMenuController.getSelected(MainTest.menu)
        if choice == "MAP TEST" then
            MainTest.sm.switch("map_test")
        elseif choice == "Return" then
            GameController.unload()
            MainTest.sm.switch("main_menu")
        end
    end
end

function MainTest.draw()
    SimpleMenuController.draw(MainTest.menu, 100, 100)
end

return MainTest