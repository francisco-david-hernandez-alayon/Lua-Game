-- core/programming_languages/languages_registry.lua
--
-- Register languages to restore them when game is saved

local LanguagesRegistry = {
    test_language = require("core.programming_languages.languages.test_language"),
}

function LanguagesRegistry.create(templateId)
    local template = LanguagesRegistry[templateId]
    assert(template and template.new, "Unknown language template: " .. tostring(templateId))
    return template.new()
end

return LanguagesRegistry
