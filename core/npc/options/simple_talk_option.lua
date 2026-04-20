-- core/npc/options/simple_talk_option.lua
--
-- Simple NPC interaction: shows one text line above the NPC's head.
-- No menu, no player choices. Just a message.
-- mode "ordered": cycles through texts in order, loops
-- mode "random":  picks a random text each interaction

local SimpleTalkOption = {}
SimpleTalkOption.__index = SimpleTalkOption

function SimpleTalkOption.new(textKeys, mode)
    -- textKeys: list of localization keys
    -- mode: "ordered" | "random"
    return setmetatable({
        type     = "simple_talk",
        textKeys = textKeys,
        mode     = mode or "ordered",
        index    = 1,
        active   = true,
    }, SimpleTalkOption)
end

-- Returns the next text key to display
function SimpleTalkOption:interact()
    if #self.textKeys == 0 then return nil end

    if self.mode == "random" then
        return self.textKeys[math.random(#self.textKeys)]
    end

    -- ordered: cycle through and loop
    local key = self.textKeys[self.index]
    self.index = self.index + 1
    if self.index > #self.textKeys then self.index = 1 end
    return key
end

function SimpleTalkOption:activate()   self.active = true  end
function SimpleTalkOption:deactivate() self.active = false end

return SimpleTalkOption