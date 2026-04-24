-- core/localization/localization.lua
--
-- Loads all localization files for the current language and merges them.
-- Files are loaded once at startup and cached — no runtime performance difference
-- vs a single large file.

local L        = {}
local Settings = require("core.settings")

-- Language file groups
-- Add new files here as the game grows.
local languageFiles = {
    EN = {
        require("core.localization.en.menu_en"),
        require("core.localization.en.testing_en"),
        require("core.localization.en.game_en"),
    },
    ES = {
        require("core.localization.es.menu_es"),
        require("core.localization.es.testing_es"),
        require("core.localization.es.game_es"),
    },
}

-- Merge all files for a language into one flat table
local cache = {}

local function buildCache(lang)
    local merged = {}
    local files  = languageFiles[lang]
    if not files then
        print("[WARN] Localization: no files for language: " .. tostring(lang))
        return merged
    end
    for _, file in ipairs(files) do
        for k, v in pairs(file) do
            if merged[k] then
                print("[WARN] Localization: duplicate key '" .. k .. "' in " .. lang)
            end
            merged[k] = v
        end
    end
    return merged
end

-- Rebuild cache when language changes
local function getCache()
    local lang = Settings.language
    if not cache[lang] then
        cache[lang] = buildCache(lang)
        print("[Localization] built cache for: " .. lang)
    end
    return cache[lang]
end

function L.get(key)
    local t = getCache()
    local v = t[key]
    if not v then
        print("[WARN] Localization: key not found: " .. tostring(key))
        return key
    end
    return v
end

-- Call this after changing language in Settings so cache rebuilds
function L.reload()
    cache = {}
    print("[Localization] cache cleared — will rebuild on next get()")
end

return L