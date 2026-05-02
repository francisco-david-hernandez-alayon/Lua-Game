-- utils/sprites/get_skill_animation_sprite.lua
--
-- Loads and caches a skill-effect sprite sheet for use with anim8.
-- Sheet format: one row of N frames, each frame FRAME_W × FRAME_H pixels.
--
-- CONFIGURABLE PER-SHEET via metadata OR global defaults below.
--
-- DEFAULT SHEET SPEC:
--   FRAME_W      = 64    px  (width of each animation frame)
--   FRAME_H      = 64    px  (height of each animation frame)
--   FRAME_COUNT  = 4         (frames per row; auto-detected if sheet width is exact multiple)
--   FRAME_DUR    = 0.12  s   (seconds per frame)
--   SCALE        = 1.0       (draw scale applied when drawing via SkillAnimation)
--
-- The cache key is the sprite path string.
-- Returns a table:  { image, anim, originX, originY, scaleX, scaleY }

local anim8 = require("libs.anim8")

local GetSkillAnimationSprite = {}

-- GLOBAL DEFAULTS (change here to affect all skill sprites)
local DEFAULT_FRAME_W     = 128
local DEFAULT_FRAME_H     = 128
local DEFAULT_FRAME_COUNT = 4      -- frames per row; change this to add/remove frames globally
local DEFAULT_FRAME_DUR   = 0.20   -- seconds per frame
local DEFAULT_SCALE       = 1.0

-- CACHE
local cache = {}

-- LOAD
-- @param path       string  — path to sprite sheet PNG
-- @param opts       table   — optional overrides:
--   opts.frameW    number   — frame width  (default DEFAULT_FRAME_W)
--   opts.frameH    number   — frame height (default DEFAULT_FRAME_H)
--   opts.frameDur  number   — seconds per frame (default DEFAULT_FRAME_DUR)
--   opts.scale     number   — draw scale (default DEFAULT_SCALE)
--   opts.frameCount number  — frames per row (default DEFAULT_FRAME_COUNT)
--
-- Returns cached data table { image, anim, originX, originY, scaleX, scaleY }
function GetSkillAnimationSprite.load(path, opts)
    assert(type(path) == "string", "path must be a string")

    -- Build a cache key that includes any opts that affect the animation
    local cacheKey = path
    if opts then
        cacheKey = path .. "|" ..
            tostring(opts.frameW or "")    .. "|" ..
            tostring(opts.frameH or "")    .. "|" ..
            tostring(opts.frameDur or "")  .. "|" ..
            tostring(opts.scale or "")     .. "|" ..
            tostring(opts.frameCount or "")
    end

    if cache[cacheKey] then return cache[cacheKey] end

    assert(love.filesystem.getInfo(path),
        "[GetSkillAnimationSprite] file not found: " .. path)

    local frameW     = (opts and opts.frameW)     or DEFAULT_FRAME_W
    local frameH     = (opts and opts.frameH)     or DEFAULT_FRAME_H
    local frameDur   = (opts and opts.frameDur)   or DEFAULT_FRAME_DUR
    local scale      = (opts and opts.scale)      or DEFAULT_SCALE

    local image      = love.graphics.newImage(path)
    local sheetW     = image:getWidth()
    local sheetH     = image:getHeight()

    -- Validate sheet dimensions
    assert(sheetW % frameW == 0,
        "[GetSkillAnimationSprite] sheet width (" .. sheetW ..
        ") is not divisible by frameW (" .. frameW .. ") for: " .. path)
    assert(sheetH % frameH == 0,
        "[GetSkillAnimationSprite] sheet height (" .. sheetH ..
        ") is not divisible by frameH (" .. frameH .. ") for: " .. path)

    local frameCount = (opts and opts.frameCount) or DEFAULT_FRAME_COUNT

    -- Single-row assumed; rows = sheetH / frameH (usually 1)
    local rows       = sheetH / frameH

    local grid       = anim8.newGrid(frameW, frameH, sheetW, sheetH)

    local frames
    if rows == 1 then
        frames = grid("1-" .. frameCount, 1)
    else
        -- Multi-row: flatten all frames row by row
        frames = {}
        for row = 1, rows do
            for col = 1, frameCount do
                table.insert(frames, grid(col, row))
            end
        end
    end

    local anim = anim8.newAnimation(frames, frameDur)

    local data = {
        image   = image,
        anim    = anim,
        originX = frameW / 2,   -- centre pivot
        originY = frameH / 2,
        scaleX  = scale,
        scaleY  = scale,
        frameW  = frameW,
        frameH  = frameH,
    }

    cache[cacheKey] = data

    print("[GetSkillAnimationSprite] loaded:", path,
          "| frames:", frameCount,
          "| rows:",   rows,
          "| scale:",  scale)

    return data
end

-- UPDATE
-- Convenience — call if you hold a reference to the data outside SkillAnimation.
function GetSkillAnimationSprite.update(data, dt)
    if data and data.anim then data.anim:update(dt) end
end

-- CLEAR CACHE
-- Call on scene unload to free memory if needed.
function GetSkillAnimationSprite.clearCache()
    cache = {}
end

return GetSkillAnimationSprite