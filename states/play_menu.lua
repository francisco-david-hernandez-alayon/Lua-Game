local PlayMenu = {}

function PlayMenu.enter(sm)
    PlayMenu.sm = sm
    PlayMenu.selected = 1
    PlayMenu.items = {"NEW", "LOAD", "BACK"}
end

function PlayMenu.keypressed(key)
    if key == "return" then
        local c = PlayMenu.items[PlayMenu.selected]

        if c == "NEW" then
            PlayMenu.sm.switch(require("states.new_game"))
        elseif c == "LOAD" then
            PlayMenu.sm.switch(require("states.load_game"))
        elseif c == "BACK" then
            PlayMenu.sm.switch(require("states.menu"))
        end
    end
end

return PlayMenu