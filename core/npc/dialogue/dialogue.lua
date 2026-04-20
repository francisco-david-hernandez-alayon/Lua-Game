-- core/npc/dialogue/dialogue.lua
--
-- A full dialogue sequence made of DialogueLines indexed by id.
-- Tracks the current line and handles auto-advance and player choices.
-- When the sequence ends (no next line), dialogue is marked as finished.

local Dialogue = {}
Dialogue.__index = Dialogue

function Dialogue.new(lines)
    -- lines: ordered list of DialogueLine; first line is the entry point
    local self = setmetatable({}, Dialogue)
    self.lines    = {}
    self.order    = {}  -- ordered list of ids for auto-advance
    self.current  = nil
    self.finished = false

    for i, line in ipairs(lines) do
        self.lines[line.id] = line
        self.order[i]       = line.id
    end

    if #lines > 0 then
        self.current = lines[1].id
    end

    return self
end

-- Returns the current DialogueLine
function Dialogue:getCurrentLine()
    if not self.current then return nil end
    return self.lines[self.current]
end

-- Advance to next line automatically (call when autoAdvance() is true)
function Dialogue:advance()
    if self.finished then return end

    for i, id in ipairs(self.order) do
        if id == self.current then
            if self.order[i + 1] then
                self.current = self.order[i + 1]
            else
                self.finished = true
                self.current  = nil
            end
            return
        end
    end
end

-- Jump to a specific line by id (call when player picks an option)
function Dialogue:jumpTo(lineId)
    if self.lines[lineId] then
        self.current = lineId
    else
        self.finished = true
        self.current  = nil
    end
end

-- Player picks an option by index from the active options list
function Dialogue:choose(optionIndex)
    local line = self:getCurrentLine()
    if not line then return end
    local active = line:getActiveOptions()
    local opt    = active[optionIndex]
    if opt then
        self:jumpTo(opt.jumpsTo)
    end
end

function Dialogue:isFinished()
    return self.finished
end

-- Reset dialogue to beginning
function Dialogue:reset()
    self.finished = false
    self.current  = self.order[1]
end

return Dialogue