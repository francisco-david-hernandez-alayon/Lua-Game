-- utils/distance.lua

-- Returns the distance between two points
local function distance(x1, y1, x2, y2)
    return math.sqrt((x1 - x2)^2 + (y1 - y2)^2)
end

-- Returns true if a point is within range of the player
local function inRange(px, py, x, y, range)
    return distance(px, py, x, y) < range
end

return {
    distance = distance,
    inRange  = inRange,
}