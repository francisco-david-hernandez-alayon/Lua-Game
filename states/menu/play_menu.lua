local Game = require("core.game.game")
local GameController = require("core.game.game_controller")
local SaveSystem = require("core.save_system")
local PlayMenu = {}


function PlayMenu.enter(sm, L)
    PlayMenu.sm = sm
    PlayMenu.L = L

    PlayMenu.slots = {}

    for i = 1, 3 do
        local save = SaveSystem.load(i)

        table.insert(PlayMenu.slots, {
            slot = i,
            data = save
        })
    end

    PlayMenu.selected = 1
end

function PlayMenu.keypressed(key)
    if key == "up" then
        PlayMenu.selected = PlayMenu.selected - 1
        if PlayMenu.selected < 1 then PlayMenu.selected = 3 end
    elseif key == "down" then
        PlayMenu.selected = PlayMenu.selected + 1
        if PlayMenu.selected > 3 then PlayMenu.selected = 1 end
    elseif key == "return" then
        local slot = PlayMenu.slots[PlayMenu.selected]

        if slot.data then
            -- LOAD
            GameController.load(slot.data)
            PlayMenu.sm.switch("game", slot.data)
        else
            -- NEW GAME
            local newGame = Game.new({
                name = "Player",
                slot = PlayMenu.selected,
            })

            SaveSystem.save(slot.slot, newGame)
            GameController.load(newGame)
            PlayMenu.sm.switch("game", newGame)
        end
    elseif key == "d" then
        local slot = PlayMenu.slots[PlayMenu.selected]

        SaveSystem.delete(slot.slot)
        slot.data = nil
    end
end

function PlayMenu.draw()
    love.graphics.print("PLAY MENU", 100, 60)

    local DateFormat = require("utils.date_format")

    for i, slot in ipairs(PlayMenu.slots) do
        local text

        if slot.data then
            text = slot.data.name .. " | " .. DateFormat.format(slot.data.last_save) 
        else
            text = PlayMenu.L.get("empty_slot")
        end

        local prefix = (i == PlayMenu.selected) and "> " or "  "
        love.graphics.print(prefix .. text, 100, 100 + i * 30)
    end

    love.graphics.print(
        PlayMenu.L.get("controls_select") .. " | " .. PlayMenu.L.get("controls_delete"),
        100, 250
    )
end

return PlayMenu
