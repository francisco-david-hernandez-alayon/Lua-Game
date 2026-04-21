-- core/inventory/language_slot.lua
--
-- Represents a programming language slot (used in combat).
-- languageId: string identifier for the language (e.g. "python", "lua")
-- More fields will be added when combat system is implemented.

local ProgrammingLanguageSlot = {}
ProgrammingLanguageSlot.__index = ProgrammingLanguageSlot

function ProgrammingLanguageSlot.new(languageId)
    assert(type(languageId) == "string", "languageId must be a string")
    return setmetatable({
        languageId = languageId,
    }, ProgrammingLanguageSlot)
end

function ProgrammingLanguageSlot:toTable()
    return { languageId = self.languageId }
end

function ProgrammingLanguageSlot.fromTable(data)
    return ProgrammingLanguageSlot.new(data.languageId)
end

return ProgrammingLanguageSlot