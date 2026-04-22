-- core/npc/npc.lua
--
-- Pure data class for an NPC.
-- ATTRIBUTES:
--   id:              unique string identifier
--   sprite:          love2d image
--   options:         list of NpcOption
--   initialDialogue: Dialogue played on first interaction (nil if none)
--   interactEnabled: if false, no interaction or hint shown

local Npc = {}
Npc.__index = Npc

function Npc.new(id, sprite, options, initialDialogue, interactEnabled)
    assert(type(id)     == "string", "id must be a string")
    assert(type(sprite) == "string", "sprite must be a path string")

    return setmetatable({
        id              = id,
        sprite          = love.graphics.newImage(sprite),
        options         = options or {},
        initialDialogue = initialDialogue or nil,
        interactEnabled = interactEnabled,
    }, Npc)
end

function Npc:setInitialDialogue(dialogue)  self.initialDialogue = dialogue  end
function Npc:clearInitialDialogue()        self.initialDialogue = nil       end
function Npc:enableInteract()              self.interactEnabled = true      end
function Npc:disableInteract()             self.interactEnabled = false     end

function Npc:activateOption(optionId)
    for _, npcOpt in ipairs(self.options) do
        if npcOpt.id == optionId then npcOpt:activate() return end
    end
    print("[WARN] Npc:activateOption: not found: " .. optionId)
end

function Npc:deactivateOption(optionId)
    for _, npcOpt in ipairs(self.options) do
        if npcOpt.id == optionId then npcOpt:deactivate() return end
    end
    print("[WARN] Npc:deactivateOption: not found: " .. optionId)
end

function Npc:getSimpleTalkOption()
    for _, npcOpt in ipairs(self.options) do
        if npcOpt.active and npcOpt.option.type == "simple_talk" then
            return npcOpt.option
        end
    end
    return nil
end

function Npc:getActiveOptions()
    local active = {}
    for _, npcOpt in ipairs(self.options) do
        if npcOpt.active then table.insert(active, npcOpt) end
    end
    return active
end

return Npc