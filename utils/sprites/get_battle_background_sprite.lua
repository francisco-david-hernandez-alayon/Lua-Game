-- utils/sprites/get_battle_background_sprite.lua
--
-- Renders an animated sprite sheet as a full-screen battle background.
-- The sprite is scaled to COVER the screen (may overflow borders).
-- Sheet format: 512w x 256h, multiple frames in a single row.
--
-- ATTRIBUTES:
--   SHEET_W:       expected sprite sheet width
--   SHEET_H:       expected sprite sheet height
--   FRAME_W:       width of each frame
--   FRAME_H:       height of each frame (= SHEET_H since single row)

local anim8 = require("libs.anim8")

local GetBattleBackgroundSprite = {}

local ZOOM = 1 
local SHEET_W    = 512
local SHEET_H    = 256
local FRAME_W    = 512 
local FRAME_H    = 256

local cache = {}

-- Load
function GetBattleBackgroundSprite.load(path, frameDuration)
    assert(type(path) == "string", "path must be a string")

    if cache[path] then return cache[path] end

    assert(love.filesystem.getInfo(path),
        "[GetBattleBackgroundSprite] file not found: " .. path)

    local image = love.graphics.newImage(path)

    local sheetW = image:getWidth()
    local sheetH = image:getHeight()

    assert(sheetW % FRAME_W == 0,
        "[GetBattleBackgroundSprite] sheet width must be divisible by FRAME_W")

    assert(sheetH == FRAME_H,
        "[GetBattleBackgroundSprite] sheet height must match FRAME_H (single row expected)")

    -- Caclculate frames
    local frameCount = sheetW / FRAME_W

    local grid = anim8.newGrid(FRAME_W, FRAME_H, sheetW, sheetH)
    local anim = anim8.newAnimation(
        grid("1-" .. frameCount, 1),
        frameDuration or 0.15
    )

    local data = { image = image, anim = anim }
    cache[path] = data

    print("[GetBattleBackgroundSprite] loaded:", path, "| frames:", frameCount)

    return data
end

-- Update
function GetBattleBackgroundSprite.update(data, dt)
    if data and data.anim then data.anim:update(dt) end
end


-- Draw
-- Scales the frame to COVER the screen — may overflow borders.
-- Uses love.graphics.setScissor to clip overflow if needed.
function GetBattleBackgroundSprite.draw(data)
    if not data or not data.anim then return end

    local sw    = love.graphics.getWidth()
    local sh    = love.graphics.getHeight()

    -- Scale to cover: use the LARGER of the two scale ratios
    
    local scaleX = (sw / FRAME_W) * ZOOM
    local scaleY = (sh / FRAME_H) * ZOOM
    local scale  = math.max(scaleX, scaleY)

    -- Center the scaled frame on screen
    local scaledW = FRAME_W * scale
    local scaledH = FRAME_H * scale
    local ox      = (scaledW - sw) / 2
    local oy      = (scaledH - sh) / 2

    love.graphics.setColor(1, 1, 1)
    data.anim:draw(
        data.image,
        -ox, -oy,      -- offset to center
        0,             -- rotation
        scale, scale,  -- scale x, scale y
        0, 0           -- origin (top-left of frame)
    )
end

return GetBattleBackgroundSprite