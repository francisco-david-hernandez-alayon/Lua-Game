-- core/programming_languages/language_types.lua
--
-- Enum-like table for all valid programming language types.

local LanguageTypes = {
    BACKEND  = "Backend",
    FRONTEND = "Frontend",
    SYSTEM   = "System",
    MOBILE = "Mobile",
    SCRIPTING = "Scripting",
    AI = "AI",
    GAME = "Game",
    SCIENTIFIC = "Scientific"
}

LanguageTypes.RELATIONS = {
    [LanguageTypes.BACKEND] = {
        strongAgainst = {
            LanguageTypes.FRONTEND,
            LanguageTypes.MOBILE,
        },
        weakAgainst = {
            LanguageTypes.SYSTEM,
            LanguageTypes.SCIENTIFIC,
        },
    },

    [LanguageTypes.FRONTEND] = {
        strongAgainst = {
            LanguageTypes.MOBILE,
            LanguageTypes.SCRIPTING,
        },
        weakAgainst = {
            LanguageTypes.BACKEND,
            LanguageTypes.AI,
        },
    },

    [LanguageTypes.SYSTEM] = {
        strongAgainst = {
            LanguageTypes.BACKEND,
            LanguageTypes.AI,
        },
        weakAgainst = {
            LanguageTypes.SCRIPTING,
            LanguageTypes.GAME,
        },
    },

    [LanguageTypes.SCRIPTING] = {
        strongAgainst = {
            LanguageTypes.SYSTEM,
            LanguageTypes.AI,
        },
        weakAgainst = {
            LanguageTypes.FRONTEND,
            LanguageTypes.SCIENTIFIC,
        },
    },

    [LanguageTypes.AI] = {
        strongAgainst = {
            LanguageTypes.FRONTEND,
            LanguageTypes.SCIENTIFIC,
        },
        weakAgainst = {
            LanguageTypes.SYSTEM,
            LanguageTypes.SCRIPTING,
        },
    },

    [LanguageTypes.SCIENTIFIC] = {
        strongAgainst = {
            LanguageTypes.BACKEND,
            LanguageTypes.SCRIPTING,
        },
        weakAgainst = {
            LanguageTypes.GAME,
            LanguageTypes.AI,
        },
    },

    [LanguageTypes.GAME] = {
        strongAgainst = {
            LanguageTypes.SYSTEM,
            LanguageTypes.SCIENTIFIC,
        },
        weakAgainst = {
            LanguageTypes.MOBILE,
            LanguageTypes.SCRIPTING,
        },
    },

    [LanguageTypes.MOBILE] = {
        strongAgainst = {
            LanguageTypes.GAME,
            LanguageTypes.SYSTEM,
        },
        weakAgainst = {
            LanguageTypes.BACKEND,
            LanguageTypes.FRONTEND,
        },
    },
}

return LanguageTypes
