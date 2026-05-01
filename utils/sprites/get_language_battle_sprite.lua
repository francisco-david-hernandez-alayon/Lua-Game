-- utils/get_language_battle_sprite.lua
--
-- Builds battle animations for a programming language sprite sheet.

local anim8 = require("libs.anim8")

local GetLanguageBattleSprite = {}

local FRAME_WIDTH = 128
local FRAME_HEIGHT = 128
local FRAMES_PER_DIRECTION = 8
local FRAMES_PER_VARIANT = 16
local BASE_VARIANT_INDEX = 0
local DEFAULT_FRAME_DURATION = 0.20

local sheetCache = {}

local function getSheetData(path)
    assert(type(path) == "string" and path ~= "", "spritePath must be a non-empty string")

    if not love.filesystem.getInfo(path) then
        error("[GetLanguageBattleSprite] sprite file not found: " .. path)
    end

    if not sheetCache[path] then
        local image = love.graphics.newImage(path)
        local width = image:getWidth()
        local height = image:getHeight()

        assert(width >= FRAME_WIDTH * 2, "[GetLanguageBattleSprite] spritesheet width is too small: " .. path)
        assert(height >= FRAME_HEIGHT, "[GetLanguageBattleSprite] spritesheet height is too small: " .. path)
        assert(width % FRAME_WIDTH == 0, "[GetLanguageBattleSprite] spritesheet width must be multiple of frame width: " .. path)
        assert(height % FRAME_HEIGHT == 0, "[GetLanguageBattleSprite] spritesheet height must be multiple of frame height: " .. path)

        local grid = anim8.newGrid(FRAME_WIDTH, FRAME_HEIGHT, width, height)
        local columns = width / FRAME_WIDTH
        local rows = height / FRAME_HEIGHT

        sheetCache[path] = {
            image = image,
            grid = grid,
            width = width,
            height = height,
            columns = columns,
            rows = rows,
            totalFrames = columns * rows,
        }

        print("[GetLanguageBattleSprite] Loaded spritesheet: " .. path ..
            " | size " .. width .. "x" .. height ..
            " | frames " .. sheetCache[path].totalFrames)
    end

    return sheetCache[path]
end

local function getVariantIndex(language)
    if not language.specialization then
        return BASE_VARIANT_INDEX
    end

    local spritePos = language.spritePos or {}
    for i, specializationId in ipairs(spritePos) do
        if specializationId == language.specialization then
            return i
        end
    end

    print("[GetLanguageBattleSprite] Specialization not found in spritePos, using base variant: " ..
        tostring(language.specialization))
    return BASE_VARIANT_INDEX
end

local function getFrameQuad(grid, columns, frameIndex)
    local x = ((frameIndex - 1) % columns) + 1
    local y = math.floor((frameIndex - 1) / columns) + 1
    return grid(x, y)[1]
end

local function buildFrameRange(sheetData, firstFrameIndex, frameCount)
    local frames = {}

    for i = 0, frameCount - 1 do
        local frameIndex = firstFrameIndex + i
        assert(frameIndex <= sheetData.totalFrames,
            "[GetLanguageBattleSprite] spritesheet does not have enough frames. Missing frame " .. frameIndex)

        table.insert(frames, getFrameQuad(sheetData.grid, sheetData.columns, frameIndex))
    end

    return frames
end

function GetLanguageBattleSprite.create(language, frameDuration)
    assert(language, "language is required")
    assert(language.spritePath, "language.spritePath is required")

    local variantIndex = getVariantIndex(language)
    local sheetData = getSheetData(language.spritePath)
    local variantStart = 1 + (variantIndex * FRAMES_PER_VARIANT)

    local frontStart = variantStart
    local backStart = variantStart + FRAMES_PER_DIRECTION

    local frontFrames = buildFrameRange(sheetData, frontStart, FRAMES_PER_DIRECTION)
    local backFrames = buildFrameRange(sheetData, backStart, FRAMES_PER_DIRECTION)

    return {
        image = sheetData.image,
        frontAnim = anim8.newAnimation(frontFrames, frameDuration or DEFAULT_FRAME_DURATION),
        backAnim = anim8.newAnimation(backFrames, frameDuration or DEFAULT_FRAME_DURATION),
    }
end

return GetLanguageBattleSprite
