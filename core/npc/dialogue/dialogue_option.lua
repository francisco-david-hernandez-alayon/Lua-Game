-- core/npc/options/dialogue_option.lua
--
-- NPC option that opens a full dialogue sequence.
-- Uses Dialogue + DialogueLine + PlayerDialogueOption.

local DialogueOption = {}
DialogueOption.__index = DialogueOption

function DialogueOption.new(dialogue)
    -- dialogue: a Dialogue instance
    return setmetatable({
        type     = "dialogue",
        dialogue = dialogue,
        active   = true,
    }, DialogueOption)
end

function DialogueOption:getCurrentLine()
    return self.dialogue:getCurrentLine()
end

function DialogueOption:advance()
    self.dialogue:advance()
end

function DialogueOption:choose(optionIndex)
    self.dialogue:choose(optionIndex)
end

function DialogueOption:isFinished()
    return self.dialogue:isFinished()
end

function DialogueOption:reset()
    self.dialogue:reset()
end

function DialogueOption:activate()   self.active = true  end
function DialogueOption:deactivate() self.active = false end

return DialogueOption