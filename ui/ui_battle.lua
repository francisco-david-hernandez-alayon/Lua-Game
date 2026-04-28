-- ui/ui_battle.lua
-- Handles all drawing for the battle state.
local anim8               = require("libs.anim8")
local L                   = require("core.localization.localization")
local BattleController    = require("core.battle.battle_controller")

local BattleUI            = {}

-- GENERAL VARIABLES
local PHASE               = BattleController.PHASE

local INFO_PANEL_H        = 220


-- SPRITES
local spriteCache = {}

local function getLanguageSpriteData(path)
    if not path then
        return nil
    end

    if not spriteCache[path] then
        local image = love.graphics.newImage(path)
        local width = image:getWidth()
        local height = image:getHeight()

        if width < 128 or height < 64 then
            print("[BattleUI] Invalid language sprite size for: " .. path ..
                " | got " .. width .. "x" .. height .. " | expected at least 128x64")
            return nil
        end

        if width % 64 ~= 0 or height % 64 ~= 0 then
            print("[BattleUI] Warning: language sprite is not aligned to 64px grid: " .. path ..
                " | got " .. width .. "x" .. height)
        end

        local grid = anim8.newGrid(64, 64, width, height)
        local frontFrames = grid(1, 1)
        local backFrames = grid(2, 1)

        if not frontFrames[1] or not backFrames[1] then
            print("[BattleUI] Missing front/back frames in language sprite: " .. path)
            return nil
        end

        print("[BattleUI] Loaded language sprite: " .. path .. " | " .. width .. "x" .. height)

        spriteCache[path] = {
            image = image,
            frontQuad = frontFrames[1],
            backQuad = backFrames[1],
        }
    end

    return spriteCache[path]
end




-- Menu builders
local function buildActionMenu()
    return { L.get("battle_attack"), L.get("battle_swap") }
end

local function getSkillLabel(skill)
    if skill.damage then
        return skill.nameKey .. " (" .. skill.damage .. ")"
    end

    if skill.heal then
        return skill.nameKey .. " (+ " .. skill.heal .. ")"
    end

    return skill.nameKey
end

local function buildAttackMenu(bc)
    local labels = {}
    for _, skill in ipairs(bc.currentPlayerLanguage.currentSkills) do
        table.insert(labels, getSkillLabel(skill))
    end
    table.insert(labels, L.get("battle_back"))
    return labels
end

local function buildSwapMenu(bc)
    local labels = {}
    local langs  = bc:getActivePlayerLanguages()
    for _, lang in ipairs(langs) do
        if lang ~= bc.currentPlayerLanguage then
            table.insert(labels, lang.language_name ..
                " [" .. lang.currentBattle.currentHp .. "/" .. lang.attributes.hp .. "]")
        end
    end
    table.insert(labels, L.get("battle_back"))
    return labels
end

local function buildPickMenu(bc)
    local labels = {}
    local langs  = bc:getActivePlayerLanguages()
    for _, lang in ipairs(langs) do
        if lang ~= bc.currentPlayerLanguage then
            table.insert(labels, lang.language_name ..
                " [" .. lang.currentBattle.currentHp .. "/" .. lang.attributes.hp .. "]")
        end
    end
    return labels
end

local function getMenu(bc, menuMode)
    if bc.phase == PHASE.PICK_LANGUAGE then return buildPickMenu(bc) end
    if menuMode == "action" then return buildActionMenu() end
    if menuMode == "attack" then return buildAttackMenu(bc) end
    if menuMode == "swap" then return buildSwapMenu(bc) end
    return {}
end

local function getSelectableLanguages(bc)
    local langs = {}
    for _, lang in ipairs(bc:getActivePlayerLanguages()) do
        if lang ~= bc.currentPlayerLanguage then
            table.insert(langs, lang)
        end
    end
    return langs
end

local function getSelectedSkill(bc, selected, menuMode)
    if menuMode ~= "attack" or not bc.currentPlayerLanguage then
        return nil
    end

    local skills = bc.currentPlayerLanguage.currentSkills
    if selected < 1 or selected > #skills then
        return nil
    end

    return skills[selected]
end

local function getSelectedLanguage(bc, selected, menuMode)
    if bc.phase ~= PHASE.PICK_LANGUAGE and menuMode ~= "swap" then
        return nil
    end

    local langs = getSelectableLanguages(bc)
    if selected < 1 or selected > #langs then
        return nil
    end

    return langs[selected]
end

local function getCurrentStatsLines(lang)
    local current = lang.currentBattle.currentAttributes
    local lines = {
        "Types: " .. table.concat(lang.languageTypes, ", "),
        "HP: " .. lang.currentBattle.currentHp .. "/" .. lang.attributes.hp,
        "Speed: " .. lang.currentBattle.currentSpeed .. "/" .. lang.attributes.speed,
    }

    local orderedStats = {
        { "atk_backend",    "ATK Backend" },
        { "def_backend",    "DEF Backend" },
        { "atk_frontend",   "ATK Frontend" },
        { "def_frontend",   "DEF Frontend" },
        { "atk_system",     "ATK System" },
        { "def_system",     "DEF System" },
        { "atk_mobile",     "ATK Mobile" },
        { "def_mobile",     "DEF Mobile" },
        { "atk_scripting",  "ATK Scripting" },
        { "def_scripting",  "DEF Scripting" },
        { "atk_ai",         "ATK AI" },
        { "def_ai",         "DEF AI" },
        { "atk_game",       "ATK Game" },
        { "def_game",       "DEF Game" },
        { "atk_scientific", "ATK Scientific" },
        { "def_scientific", "DEF Scientific" },
    }

    for _, statData in ipairs(orderedStats) do
        local key = statData[1]
        local label = statData[2]
        local value = current[key]

        if value ~= nil then
            table.insert(lines, label .. ": " .. value)
        end
    end

    return lines
end

local function drawWrappedLines(lines, x, y, width, lineHeight, maxLines)
    local lineY = y
    local drawn = 0

    for _, line in ipairs(lines) do
        local _, wrapped = love.graphics.getFont():getWrap(line, width)
        for _, wrappedLine in ipairs(wrapped) do
            if drawn >= maxLines then
                return
            end

            love.graphics.print(wrappedLine, x, lineY)
            lineY = lineY + lineHeight
            drawn = drawn + 1
        end
    end
end

local function drawInfoPanel(bc, selected, menuMode, x, y, w, h)
    love.graphics.setColor(0.1, 0.1, 0.1)
    love.graphics.rectangle("fill", x, y, w, h)
    love.graphics.setColor(0.3, 0.3, 0.3)
    love.graphics.rectangle("line", x, y, w, h)

    local contentX = x + 8
    local contentY = y + 8
    local contentW = w - 16
    local lineH = 16

    love.graphics.setColor(1, 1, 1)

    local skill = getSelectedSkill(bc, selected, menuMode)
    if skill then
        local categories = table.concat(skill.skillCategories, ", ")
        local lines = {
            "Skill: " .. skill:getName(L),
            "Type: " .. skill.skillType,
            "Categories: " .. categories,
            "Accuracy: " .. tostring(skill.accuracy or 100) .. "%",
            skill.damage and ("Damage: " .. skill.damage) or nil,
            skill.heal and ("Heal: " .. skill.heal) or nil,
            "Description: " .. skill:getDesc(L),
        }

        local filtered = {}
        for _, line in ipairs(lines) do
            if line then
                table.insert(filtered, line)
            end
        end

        drawWrappedLines(filtered, contentX, contentY, contentW, lineH, 12)
        return
    end

    local lang = getSelectedLanguage(bc, selected, menuMode)
    if lang then
        local lines = {
            "Language: " .. lang.language_name,
            "ID: " .. tostring(lang.language_id),
        }

        for _, statLine in ipairs(getCurrentStatsLines(lang)) do
            table.insert(lines, statLine)
        end

        drawWrappedLines(lines, contentX, contentY, contentW, lineH, 12)
        return
    end

    if bc.currentPlayerLanguage then
        local langLines = {
            "Language: " .. bc.currentPlayerLanguage.language_name,
            "ID: " .. tostring(bc.currentPlayerLanguage.language_id),
        }

        for _, statLine in ipairs(getCurrentStatsLines(bc.currentPlayerLanguage)) do
            table.insert(langLines, statLine)
        end

        drawWrappedLines(langLines, contentX, contentY, contentW, lineH, 12)
    end
end

function BattleUI.getMenuSize(bc, menuMode)
    if bc:hasMessages() then
        return 0
    end

    return #getMenu(bc, menuMode)
end

function BattleUI.draw(bc, selected, menuMode)
    local sw = love.graphics.getWidth()
    local sh = love.graphics.getHeight()

    -- DRAW VARIABLES
    local ARENA_W = math.floor(sw * 2 / 3)
    local MENU_W = sw - ARENA_W
    local LOG_H = 64
    local ARENA_H = sh - LOG_H
    local MENU_CONTENT_H = ARENA_H - INFO_PANEL_H
    
    local ENEMY_SPRITE_SCALE  = 2.5
    local PLAYER_SPRITE_SCALE = 2.5

    local enemySpriteX        = ARENA_W - 220
    local enemySpriteY        = 80

    local playerSpriteX       = 120
    local playerSpriteY       = ARENA_H - 240



    love.graphics.setColor(0.08, 0.08, 0.08)
    love.graphics.rectangle("fill", 0, 0, sw, sh)

    love.graphics.setColor(0.12, 0.12, 0.12)
    love.graphics.rectangle("fill", 0, 0, ARENA_W, ARENA_H)

    if bc.currentEnemyLanguage then
        local el = bc.currentEnemyLanguage
        local spriteData = getLanguageSpriteData(el.spritePath)

        love.graphics.setColor(0.8, 0.2, 0.2)
        love.graphics.print(
            el.language_name .. "  [" .. el.currentBattle.currentHp .. "/" .. el.attributes.hp .. "]",
            16, 16)
        love.graphics.setColor(0.4, 0.4, 0.4)
        love.graphics.print(bc.programmerName, 16, 36)

        if spriteData then
            love.graphics.setColor(1, 1, 1)
            love.graphics.draw(
                spriteData.image,
                spriteData.frontQuad,
                enemySpriteX,
                enemySpriteY,
                0,
                ENEMY_SPRITE_SCALE,
                ENEMY_SPRITE_SCALE
            )
        end
    end


    if bc.currentPlayerLanguage then
        local pl = bc.currentPlayerLanguage
        local spriteData = getLanguageSpriteData(pl.spritePath)

        love.graphics.setColor(0.2, 0.6, 1)
        love.graphics.print(
            pl.language_name .. "  [" .. pl.currentBattle.currentHp .. "/" .. pl.attributes.hp .. "]",
            16, ARENA_H - 48)
        love.graphics.setColor(0.4, 0.4, 0.4)
        love.graphics.print(L.get("battle_you"), 16, ARENA_H - 28)

        if spriteData then
            love.graphics.setColor(1, 1, 1)
            love.graphics.draw(
                spriteData.image,
                spriteData.backQuad,
                playerSpriteX,
                playerSpriteY,
                0,
                PLAYER_SPRITE_SCALE,
                PLAYER_SPRITE_SCALE
            )
        end
    end


    love.graphics.setColor(0.15, 0.15, 0.15)
    love.graphics.rectangle("fill", ARENA_W, 0, MENU_W, ARENA_H)
    love.graphics.setColor(0.3, 0.3, 0.3)
    love.graphics.rectangle("line", ARENA_W, 0, MENU_W, ARENA_H)

    if bc.phase == PHASE.BATTLE_OVER then
        local msg = bc.winner == "player" and L.get("battle_win") or L.get("battle_lose")
        local remaining = bc.winner == "player"
            and #bc:getActivePlayerLanguages()
            or #bc:getActiveEnemyLanguages()

        love.graphics.setColor(1, 1, 0)
        love.graphics.print(msg, ARENA_W + 8, 16)
        love.graphics.setColor(1, 1, 1)
        love.graphics.print(L.get("battle_remaining") .. ": " .. remaining, ARENA_W + 8, 36)
        love.graphics.setColor(0.5, 0.5, 0.5)
        love.graphics.print("[E] " .. L.get("battle_exit"), ARENA_W + 8, 56)
    else
        if not bc:hasMessages() then
            love.graphics.setColor(0.6, 0.6, 0.6)
            if bc.phase == PHASE.PICK_LANGUAGE then
                love.graphics.setColor(1, 0.6, 0)
                love.graphics.print(L.get("battle_pick_language"), ARENA_W + 8, 8)
            else
                local title = menuMode == "action" and L.get("battle_menu_action")
                    or menuMode == "attack" and L.get("battle_menu_attack")
                    or L.get("battle_menu_swap")
                love.graphics.print(title, ARENA_W + 8, 8)
            end

            local menu = getMenu(bc, menuMode)
            for i, item in ipairs(menu) do
                love.graphics.setColor(i == selected and 1 or 1, i == selected and 1 or 1, i == selected and 0 or 1)
                love.graphics.print("> " .. item, ARENA_W + 8, 28 + (i - 1) * 20)
            end

            drawInfoPanel(
                bc,
                selected,
                menuMode,
                ARENA_W + 4,
                MENU_CONTENT_H,
                MENU_W - 8,
                INFO_PANEL_H - 4
            )
        end
    end

    love.graphics.setColor(0.05, 0.05, 0.05)
    love.graphics.rectangle("fill", 0, ARENA_H, sw, LOG_H)
    love.graphics.setColor(0.3, 0.3, 0.3)
    love.graphics.rectangle("line", 0, ARENA_H, sw, LOG_H)
    love.graphics.setColor(1, 1, 1)

    if bc:hasMessages() then
        local message = bc.messageQueue[1] or ""
        drawWrappedLines({ message }, 8, ARENA_H + 6, sw - 120, 16, 2)

        love.graphics.setColor(1, 1, 0)
        love.graphics.print("[ENTER] Continue", sw - 110, ARENA_H + 22)
    else
        love.graphics.print(bc.messageQueue[1] or "", 8, ARENA_H + 8)
    end
end

return BattleUI
