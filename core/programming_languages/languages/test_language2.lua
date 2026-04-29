-- core/programming_languages/languages/test_language_2.lua
--
-- Test language 2: System type, levels 1-3 with upgrades.

local ProgrammingLanguage = require("core.programming_languages.programming_language")
local LevelTree = require("core.programming_languages.level_tree")
local LevelNode = require("core.programming_languages.level_node")
local Upgrade = require("core.programming_languages.upgrade")
local Skill = require("core.programming_languages.skill")
local PassiveAbility = require("core.programming_languages.passive_ability")
local LanguageTypes = require("core.programming_languages.language_types")

local ID = "test_language_2"

local upgrade_test2_hp = Upgrade.new(
    "upgrade_test2_hp", nil, nil, nil,
    { hp = 5 }
)

local upgrade_test2_speed = Upgrade.new(
    "upgrade_test2_speed", nil, nil, nil,
    { speed = 5 }
)

local upgrade_test2_esp1 = Upgrade.new(
    "upgrade_test2_esp1", "test2_esp1", nil, nil, nil
)

local upgrade_test2_esp2 = Upgrade.new(
    "upgrade_test2_esp2", "test2_esp2", nil, nil, nil
)

local passive_system_boost = PassiveAbility.new(
    "passive_test2_system_boost",
    "passive_test2_system_boost_name",
    "passive_test2_system_boost_desc",
    ID,
    "before_attack",
    function(battle, owner)
        if not battle.attackBonus then battle.attackBonus = {} end
        battle.attackBonus["System"] = (battle.attackBonus["System"] or 0) + 5
        battle:pushMessage(owner.language_name .. ": System boost +5")
    end
)

local upgrade_test2_passive_system = Upgrade.new(
    "upgrade_test2_passive_system", nil, nil,
    { passive_system_boost }, nil
)

local passive_backend_resist = PassiveAbility.new(
    "passive_test2_backend_resist",
    "passive_test2_backend_resist_name",
    "passive_test2_backend_resist_desc",
    ID,
    "before_receive",
    function(battle, owner)
        battle:pushMessage(owner.language_name .. ": Backend resistance active")
    end
)

local upgrade_test2_passive_resist = Upgrade.new(
    "upgrade_test2_passive_resist", nil, nil,
    { passive_backend_resist }, nil
)

local tree = LevelTree.new({
    LevelNode.new(2, "test2_level_2_name", "test2_level_2_desc", 100,
        { hp = 10, speed = 10, atk_system = 10, def_system = 10 },
        { upgrade_test2_hp, upgrade_test2_speed }
    ),
    LevelNode.new(3, "test2_level_3_name", "test2_level_3_desc", 300,
        { hp = 10, speed = 10, atk_system = 10, def_system = 10 },
        { upgrade_test2_esp1, upgrade_test2_esp2 }
    ),
    LevelNode.new(4, "test2_level_4_name", "test2_level_4_desc", 600,
        { hp = 15, speed = 15, atk_system = 15, def_system = 15 },
        { upgrade_test2_passive_system, upgrade_test2_passive_resist }
    ),
})

local skill_kernel = Skill.new(
    "skill_test2_1_id",
    "skill_test2_kernel",
    "skill_test2_kernel_desc",
    LanguageTypes.SYSTEM,
    { "attack" },
    22,
    nil,
    nil,
    90
)

local skill_optimize = Skill.new(
    "skill_test2_2_id",
    "skill_test2_optimize",
    "skill_test2_optimize_desc",
    LanguageTypes.SYSTEM,
    { "attribute_effect" },
    nil,
    nil,
    { def_system = 5 },
    100
)

local function newTestLanguage2()
    local lang = ProgrammingLanguage.new({
        templateId = ID,
        spritePath = "assets/sprites/test/test-lang1.png"",
        spritePos = { "test2_esp1", "test2_esp2" },
        language_name = "SysLang",
        languageTypes = {
            LanguageTypes.SYSTEM
        },
        hp = 100,
        speed = 12,
        typeAttributes = {
            [LanguageTypes.SYSTEM] = {
                attack = 22,
                defense = 18
            }
        },
        skills = {
            skill_kernel,
            skill_optimize
        },
        levelTree = tree,
    })

    return lang
end

return { new = newTestLanguage2 }
