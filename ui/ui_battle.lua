-- ui/ui_battle.lua
-- Handles all drawing for the battle state.
local anim8               = require("libs.anim8")
local GetLanguageBattleSprite = require("utils.sprites.get_language_battle_sprite")

local L                   = require("core.localization.localization")
local BattleController    = require("core.battle.battle_controller")
local LanguageEffectiveness = require("utils.language_effectiveness")

local BattleUI            = {}

-- GENERAL VARIABLES
local PHASE               = BattleController.PHASE
local INFO_PANEL_H        = 420
local MAX_LINES_INFO_PANEL = 100


----------------------------------- SPRITE -----------------------------------
local battleSpriteCache = {}

local function getBattleSprite(language)
    if not language or not language.language_id or not language.spritePath then
        return nil
    end

    if not battleSpriteCache[language.language_id] then
        battleSpriteCache[language.language_id] = GetLanguageBattleSprite.create(language)
    end

    return battleSpriteCache[language.language_id]
end


----------------------------------- MENU -----------------------------------
-- Menu builders
local function buildActionMenu()
    return { L.get("battle_attack"), L.get("battle_swap") }
end

local function getSkillLabel(skill)
    if skill.damage then
        return skill.nameKey
    end

    if skill.heal then
        return skill.nameKey
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
        "Level: " .. lang.level,
    }

    if lang.specialization ~= nil then
        table.insert(lines, "Specialization: " .. lang.specialization)
    end

    table.insert(lines, "Types: " .. table.concat(lang.languageTypes, ", "))
    table.insert(lines, "HP: " .. lang.currentBattle.currentHp .. "/" .. lang.attributes.hp)
    table.insert(lines, "Speed: " .. lang.currentBattle.currentSpeed .. "/" .. lang.attributes.speed)


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
        local effectLabel = nil

        if bc.currentEnemyLanguage and skill:hasCategory("attack") then
            local multiplier, effectId = LanguageEffectiveness.getMultiplierAndEffectId(
                bc.currentEnemyLanguage,
                skill
            )
            effectLabel = "Effect: " .. effectId .. " (x" .. multiplier .. ")"
        end

        local lines = {
            "Skill: " .. skill:getName(L),
            "Type: " .. skill.skillType,
            "Categories: " .. categories,
            "Accuracy: " .. tostring(skill.accuracy or 100) .. "%",
        }

        if skill.damage then
            table.insert(lines, "Damage: " .. skill.damage)
        end

        if skill.heal then
            table.insert(lines, "Heal: " .. skill.heal)
        end

        if effectLabel then
            table.insert(lines, effectLabel)
        end

        table.insert(lines, "Description: " .. skill:getDesc(L))


        drawWrappedLines(lines, contentX, contentY, contentW, lineH, MAX_LINES_INFO_PANEL)
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

        drawWrappedLines(lines, contentX, contentY, contentW, lineH, MAX_LINES_INFO_PANEL)
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

        drawWrappedLines(langLines, contentX, contentY, contentW, lineH, MAX_LINES_INFO_PANEL)
    end
end


function BattleUI.getMenuSize(bc, menuMode)
    if bc:hasMessages() then
        return 0
    end

    return #getMenu(bc, menuMode)
end


----------------------------------- SPRITE BAR -----------------------------------
local HP_BAR_OFFSET_Y = -100   
local HP_BAR_WIDTH    = 120
local HP_BAR_HEIGHT   = 12

local HP_COLOR_HIGH   = {0.2, 0.8, 0.2}  -- green
local HP_COLOR_MED    = {1.0, 0.6, 0.0}  -- orange
local HP_COLOR_LOW    = {0.9, 0.2, 0.2}  -- red

local HP_BG_COLOR     = {0.2, 0.2, 0.2}
local HP_BORDER_COLOR = {0.4, 0.4, 0.4}

local HEADER_OFFSET_Y = -150
local HEADER_LINE_SPACING = 14

local TYPE_MAX_WIDTH = HP_BAR_WIDTH
local TYPE_BG_PADDING_X = 6
local TYPE_BG_PADDING_Y = 2

local function drawHeader(x, y, programming_language)

    -- LINE 1: name + specialization
    local line1 = programming_language.language_name
    if programming_language.specialization then
        line1 = line1 .. " [" .. programming_language.specialization .. "]"
    end
    love.graphics.setColor(1, 1, 1)
    love.graphics.print(line1, x, y)

    -- LINE 2: level
    local lvlText = "nvl " .. tostring(programming_language.level)
    love.graphics.print(
        lvlText,
        x,
        y + HEADER_LINE_SPACING
    )

    -- LINE 3: types badge
    local typesText = table.concat(programming_language.languageTypes or {}, ", ")
    local font = love.graphics.getFont()
    local _, wrappedLines = font:getWrap(typesText, TYPE_MAX_WIDTH)
    local ty = y + HEADER_LINE_SPACING * 2
    local lineH = font:getHeight()
    local boxH = #wrappedLines * lineH
    local padX = TYPE_BG_PADDING_X
    local padY = TYPE_BG_PADDING_Y

    -- badge background
    love.graphics.setColor(0, 0, 0, 0.5)
    love.graphics.rectangle(
        "fill",
        x,
        ty - padY,
        TYPE_MAX_WIDTH,
        boxH + padY * 2
    )

    -- badge text
    love.graphics.setColor(1, 1, 1)
    for i, line in ipairs(wrappedLines) do
        love.graphics.print(line, x, ty + (i - 1) * lineH)
    end
end

local function drawHPBar(x, y, w, h, current, max)
    if not current or not max or max == 0 then return end

    local ratio = current / max
    local fillW = w * ratio

    local color
    if ratio > 0.5 then
        color = HP_COLOR_HIGH
    elseif ratio > 0.25 then
        color = HP_COLOR_MED
    else
        color = HP_COLOR_LOW
    end

    -- Background
    love.graphics.setColor(HP_BG_COLOR)
    love.graphics.rectangle("fill", x, y, w, h)

    -- Fill
    love.graphics.setColor(color)
    love.graphics.rectangle("fill", x, y, fillW, h)

    -- Border
    love.graphics.setColor(HP_BORDER_COLOR)
    love.graphics.rectangle("line", x, y, w, h)

    -- TEXT CENTERED VERTICALLY (FIX IMPORTANTE)
    love.graphics.setColor(1, 1, 1)

    local text = current .. "/" .. max
    local font = love.graphics.getFont()

    local textY = y + (h / 2) - (font:getHeight() / 2)

    love.graphics.print(text, x + w + 8, textY)
end



-- MAIN UPDATE
function BattleUI.update(bc, dt)
    if bc.currentEnemyLanguage then
        local enemySprite = getBattleSprite(bc.currentEnemyLanguage)
        if enemySprite then
            enemySprite.frontAnim:update(dt)
        end
    end

    if bc.currentPlayerLanguage then
        local playerSprite = getBattleSprite(bc.currentPlayerLanguage)
        if playerSprite then
            playerSprite.backAnim:update(dt)
        end
    end
end



-- MAIN DRAW
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

    --Sprites
    local BATTLE_FRAME_WIDTH = 128
    local BATTLE_FRAME_HEIGHT = 128
    local BATTLE_FRAME_OX = BATTLE_FRAME_WIDTH / 2
    local BATTLE_FRAME_OY = BATTLE_FRAME_HEIGHT / 2

    local ArenaHCenter= (2 * ARENA_H) / 3  -- The ARENA takes up the bottom two-thirds of the height; the centre is halfway between those two-thirds
    local ArenaWCenter= ARENA_W / 2
    local SpriteHMargin = 100
    local SpriteWMargin = 140
    local enemySpriteX        = ArenaWCenter + SpriteWMargin
    local enemySpriteY        = ArenaHCenter - SpriteHMargin
    local playerSpriteX       = ArenaWCenter - SpriteWMargin
    local playerSpriteY       = ArenaHCenter + SpriteHMargin


    -- ENEMY
    if bc.currentEnemyLanguage then
        local el = bc.currentEnemyLanguage
        local enemyTypes = table.concat(el.languageTypes, ", ")

        love.graphics.setColor(0.7, 0.7, 0.7)
        love.graphics.print(enemyTypes, 16, 32)
        love.graphics.setColor(0.4, 0.4, 0.4)
        love.graphics.print(bc.programmerName, 16, 48)

        -- Header
        local baseX = enemySpriteX - HP_BAR_WIDTH / 2
        local headY = enemySpriteY + HEADER_OFFSET_Y
        drawHeader(baseX, headY, bc.currentEnemyLanguage)

        -- HP
        local hpX = enemySpriteX - HP_BAR_WIDTH / 2
        local hpY = enemySpriteY + HP_BAR_OFFSET_Y
        drawHPBar(
            hpX,
            hpY,
            HP_BAR_WIDTH,
            HP_BAR_HEIGHT,
            el.currentBattle.currentHp,
            el.attributes.hp
        )

        local spriteData = getBattleSprite(el)
        if spriteData then
            love.graphics.setColor(1, 1, 1)
            spriteData.frontAnim:draw(
                spriteData.image,
                enemySpriteX,
                enemySpriteY,
                0,
                ENEMY_SPRITE_SCALE,
                ENEMY_SPRITE_SCALE,
                BATTLE_FRAME_OX,
                BATTLE_FRAME_OY
            )
        end

    end

    -- PLAYER
    if bc.currentPlayerLanguage then
        local pl = bc.currentPlayerLanguage
        local playerTypes = table.concat(pl.languageTypes, ", ")

        love.graphics.setColor(0.7, 0.7, 0.7)
        love.graphics.print(playerTypes, 16, ARENA_H - 48)
        love.graphics.setColor(0.4, 0.4, 0.4)
        love.graphics.print(L.get("battle_you"), 16, ARENA_H - 28)

        -- Header
        local baseX = playerSpriteX - HP_BAR_WIDTH / 2
        local headY = playerSpriteY - (HEADER_OFFSET_Y + 20)  -- TODO CHANGE THIS OFFSET: NEED TO ENCOMPASS THE ENTIRE OFFSET SO THAT IT CAN BE USED BOTH ABOVE THE ENEMY AND BELOW THE PLAYER
        drawHeader(baseX, headY, bc.currentPlayerLanguage )

        -- HP
        local hpX = playerSpriteX - HP_BAR_WIDTH / 2
        local hpY = playerSpriteY - HP_BAR_OFFSET_Y
        drawHPBar(
            hpX,
            hpY,
            HP_BAR_WIDTH,
            HP_BAR_HEIGHT,
            pl.currentBattle.currentHp,
            pl.attributes.hp
        )

        local spriteData = getBattleSprite(pl)
        if spriteData then
            love.graphics.setColor(1, 1, 1)
            spriteData.backAnim:draw(
                spriteData.image,
                playerSpriteX,
                playerSpriteY,
                0,
                PLAYER_SPRITE_SCALE,
                PLAYER_SPRITE_SCALE,
                BATTLE_FRAME_OX,
                BATTLE_FRAME_OY
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
