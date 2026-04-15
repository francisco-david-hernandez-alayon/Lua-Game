local Game = {}
Game.__index = Game

function Game.new(data)
    local self = setmetatable({}, Game)

    -- TYPE CHECK
    assert(type(data.name) == "string", "name must be string")

    -- GAME DATA
    self.name = data.name
    self.created_at = data.created_at or os.time()
    self.last_save = data.last_save or os.time()
    self.slot = data.slot or 1

    return self
end

-- to encoding
function Game:toTable()
    return {
        name = self.name,
        created_at = self.created_at,
        last_save = self.last_save,
        slot = self.slot
    }
end

return Game