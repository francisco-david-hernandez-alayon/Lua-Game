local L = {}

local Settings = require("core.settings")

local languages = {
    EN = require("core.localization.en"),
    ES = require("core.localization.es")
}

function L.get(key)
    local lang = Settings.language
    return languages[lang][key] or key
end

return L