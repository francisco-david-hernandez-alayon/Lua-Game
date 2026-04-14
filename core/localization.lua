local L = {}

local texts = {
    EN = { play="Play", options="Options", exit="Exit" },
    ES = { play="Jugar", options="Opciones", exit="Salir" }
}

function L.get(key)
    local lang = require("core.settings").language
    return texts[lang][key] or key
end

return L