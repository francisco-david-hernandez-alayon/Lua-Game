-- core/programming_languages/languages/test_language.lua
--
-- Test language: Backend type, levels 1-3 with upgrades.

local ProgrammingLanguage = require("core.programming_languages.programming_language")
local LevelTree = require("core.programming_languages.level_tree")
local LevelNode = require("core.programming_languages.level_node")
local Upgrade = require("core.programming_languages.upgrade")
local Skill = require("core.programming_languages.skill")
local PassiveAbility = require("core.programming_languages.passive_ability")
local LanguageTypes = require("core.programming_languages.language_types")

local ID = "test_language"

local upgrade_test_hp = Upgrade.new(
    "upgrade_test_hp", nil, nil, nil,
    { hp = 5 }
)

local upgrade_test_speed = Upgrade.new(
    "upgrade_test_speed", nil, nil, nil,
    { speed = 5 }
)

local upgrade_test_esp1 = Upgrade.new(
    "upgrade_test_esp1", "test_esp1", nil, nil, nil
)

local upgrade_test_esp2 = Upgrade.new(
    "upgrade_test_esp2", "test_esp2", nil, nil, nil
)

local passive_backend_boost = PassiveAbility.new(
    "passive_backend_boost",
    "passive_backend_boost_name",
    "passive_backend_boost_desc",
    ID,
    "before_attack",
    function(battle, owner)
        if not battle.attackBonus then battle.attackBonus = {} end
        battle.attackBonus["Backend"] = (battle.attackBonus["Backend"] or 0) + 5
        battle:pushMessage(owner.language_name .. ": Backend boost +5")
    end
)

local upgrade_test_passive_backend = Upgrade.new(
    "upgrade_test_passive_backend", nil, nil,
    { passive_backend_boost }, nil
)

local passive_system_boost = PassiveAbility.new(
    "passive_system_boost",
    "passive_system_boost_name",
    "passive_system_boost_desc",
    ID,
    "before_attack",
    function(battle, owner)
        if not battle.attackBonus then battle.attackBonus = {} end
        battle.attackBonus["System"] = (battle.attackBonus["System"] or 0) + 5
        battle:pushMessage(owner.language_name .. ": System boost +5")
    end
)

local upgrade_test_passive_system = Upgrade.new(
    "upgrade_test_passive_system", nil, nil,
    { passive_system_boost }, nil
)

local tree = LevelTree.new({
    LevelNode.new(2, "test_level_2_name", "test_level_2_desc", 100,
        { hp = 10, speed = 10, backend_attack = 10, backend_defense = 10 },
        { upgrade_test_hp, upgrade_test_speed }
    ),
    LevelNode.new(3, "test_level_3_name", "test_level_3_desc", 300,
        { hp = 10, speed = 10, backend_attack = 10, backend_defense = 10 },
        { upgrade_test_esp1, upgrade_test_esp2 }
    ),
    LevelNode.new(4, "test_level_4_name", "test_level_4_desc", 600,
        { hp = 15, speed = 15, backend_attack = 15, backend_defense = 15 },
        { upgrade_test_passive_backend, upgrade_test_passive_system }
    ),
})

local skill_compile = Skill.new(
    "skill_test_compile", "skill_test_compile_desc",
    LanguageTypes.BACKEND, 20, "attack"
)

local skill_debug = Skill.new(
    "skill_test_debug", "skill_test_debug_desc",
    LanguageTypes.BACKEND, 15, "attack"
)

local function newTestLanguage()
    local lang = ProgrammingLanguage.new({
        language_name = "TestLang",
        languageType = LanguageTypes.BACKEND,
        hp = 100,
        speed = 10,
        typeAttack = 20,
        typeDefense = 15,
        levelTree = tree,
    })

    lang:addSkill(skill_compile)
    lang:addSkill(skill_debug)
    return lang
end

return { new = newTestLanguage }
