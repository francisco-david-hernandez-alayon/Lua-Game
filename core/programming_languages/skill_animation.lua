-- core/programming_languages/skill_animation.lua
--
-- Defines the animation data attached to a Skill.
--
-- ANIMATION TYPES (enum):
--   APPROACH  — attacker moves toward defender, plays sprite, snaps back
--   PROJECTILE — sprite travels from attacker to defender, then disappears
--   STATIC    — sprite plays on top of the attacker, attacker stays still
--
-- A SkillAnimation holds an ORDERED LIST of SkillAnimationEntry objects.
-- Each entry = { animationType, spritePath }.
-- They play one after another; when all finish the battle controller
-- applies damage / heal / effects.
--
-- DEFAULT_ENTRY_DURATION controls how long each entry plays (seconds).
-- The sprite loops during that window.

local GetSkillAnimationSprite = require("utils.sprites.get_skill_animation_sprite")

-- ENUM

local AnimationType = {
    APPROACH   = "approach",
    PROJECTILE = "projectile",
    STATIC     = "static",
}

-- CONSTANTS
local DEFAULT_ENTRY_DURATION = 1.0  -- seconds each animation entry lasts

-- Approach movement: fraction of the attacker→defender distance to travel
local APPROACH_TRAVEL_FRACTION = 0.8
-- How fast the attacker snaps back (pixels per second)
local APPROACH_RETURN_SPEED    = 900

-- ENTRY
local SkillAnimationEntry = {}
SkillAnimationEntry.__index = SkillAnimationEntry


function SkillAnimationEntry.new(animationType, spritePath, duration)
    assert(AnimationType[string.upper(animationType)] or
           animationType == AnimationType.APPROACH or
           animationType == AnimationType.PROJECTILE or
           animationType == AnimationType.STATIC,
        "animationType must be a valid AnimationType")
    assert(type(spritePath) == "string", "spritePath must be a string")

    return setmetatable({
        animationType = animationType,
        spritePath    = spritePath,
        duration      = duration or DEFAULT_ENTRY_DURATION,
    }, SkillAnimationEntry)
end

-- SKILL ANIMATION
local SkillAnimation = {}
SkillAnimation.__index = SkillAnimation
SkillAnimation.AnimationType = AnimationType


function SkillAnimation.new(entries)
    assert(type(entries) == "table" and #entries > 0,
        "entries must be a non-empty list of SkillAnimationEntry")

    return setmetatable({
        entries = entries,

        -- runtime state (reset each play)
        _playing       = false,
        _currentIndex  = 0,
        _entryTimer    = 0,
        _spriteData    = nil,   -- loaded sprite for current entry

        -- positions supplied by play()
        _attackerPos   = nil,   -- { x, y }
        _defenderPos   = nil,   -- { x, y }

        -- approach-specific state
        _approachOffsetX  = 0,
        _approachOffsetY  = 0,
        _approachReturning = false,

        -- projectile-specific state
        _projX = 0,
        _projY = 0,
    }, SkillAnimation)
end


-- Returns true if the animation sequence is still running.
function SkillAnimation:isPlaying()
    return self._playing
end

-- Start the full sequence.
-- attackerPos / defenderPos = { x=number, y=number }
-- scale = draw scale to match the attacker sprite (e.g. ENEMY_SPRITE_SCALE / PLAYER_SPRITE_SCALE)
function SkillAnimation:play(attackerPos, defenderPos, scale)
    self._attackerPos  = attackerPos
    self._defenderPos  = defenderPos
    self._scale        = scale or 1.0
    self._playing      = true
    self._currentIndex = 0
    self:_startNextEntry()
end

-- Call every frame from BattleUI.update / battle.update.
function SkillAnimation:update(dt)
    if not self._playing then return end

    local entry = self.entries[self._currentIndex]
    if not entry then
        self._playing = false
        return
    end

    -- Update sprite animation
    if self._spriteData and self._spriteData.anim then
        self._spriteData.anim:update(dt)
    end

    -- Update movement logic
    if entry.animationType == AnimationType.APPROACH then
        self:_updateApproach(dt, entry)
    elseif entry.animationType == AnimationType.PROJECTILE then
        self:_updateProjectile(dt, entry)
    end
    -- STATIC: nothing to move

    -- Advance timer
    self._entryTimer = self._entryTimer + dt
    if self._entryTimer >= entry.duration then
        self:_startNextEntry()
    end
end

-- Draw the current animation frame.
-- Call this from BattleUI.draw, BEFORE drawing character sprites
-- so the effect appears beneath them.
function SkillAnimation:draw()
    if not self._playing then return end
    if not self._spriteData or not self._spriteData.anim then return end

    local entry = self.entries[self._currentIndex]
    if not entry then return end

    love.graphics.setColor(1, 1, 1, 1)

    local sd     = self._spriteData
    local scaleX = sd.scaleX * self._scale
    local scaleY = sd.scaleY * self._scale

    if entry.animationType == AnimationType.STATIC then
        -- Draw centred on attacker
        local ax = self._attackerPos.x
        local ay = self._attackerPos.y
        sd.anim:draw(
            sd.image,
            ax + self._approachOffsetX,
            ay + self._approachOffsetY,
            0,
            scaleX, scaleY,
            sd.originX, sd.originY
        )

    elseif entry.animationType == AnimationType.APPROACH then
        -- Draw at attacker + current offset
        local ax = self._attackerPos.x + self._approachOffsetX
        local ay = self._attackerPos.y + self._approachOffsetY
        sd.anim:draw(
            sd.image,
            ax, ay,
            0,
            scaleX, scaleY,
            sd.originX, sd.originY
        )

    elseif entry.animationType == AnimationType.PROJECTILE then
        sd.anim:draw(
            sd.image,
            self._projX,
            self._projY,
            0,
            scaleX, scaleY,
            sd.originX, sd.originY
        )
    end
end

-- PRIVATE: entry lifecycle
function SkillAnimation:_startNextEntry()
    self._currentIndex = self._currentIndex + 1

    if self._currentIndex > #self.entries then
        self._playing = false
        return
    end

    local entry = self.entries[self._currentIndex]
    self._entryTimer = 0

    -- Load sprite (cached by GetSkillAnimationSprite)
    self._spriteData = GetSkillAnimationSprite.load(entry.spritePath)

    -- Reset movement state
    self._approachOffsetX  = 0
    self._approachOffsetY  = 0
    self._approachReturning = false

    if entry.animationType == AnimationType.PROJECTILE then
        -- Start projectile at attacker position
        self._projX = self._attackerPos.x
        self._projY = self._attackerPos.y
    end
end

-- PRIVATE: movement updates
function SkillAnimation:_updateApproach(dt, entry)
    local ax = self._attackerPos.x
    local ay = self._attackerPos.y
    local dx = self._defenderPos.x - ax
    local dy = self._defenderPos.y - ay

    -- Target offset = fraction of the full distance
    local targetX = dx * APPROACH_TRAVEL_FRACTION
    local targetY = dy * APPROACH_TRAVEL_FRACTION

    -- Use first half of duration to travel, second half to return
    local halfDur = entry.duration * 0.5

    if self._entryTimer < halfDur then
        -- Lerp toward target
        local t = self._entryTimer / halfDur
        self._approachOffsetX = targetX * t
        self._approachOffsetY = targetY * t
    else
        -- Snap back toward (0, 0) at APPROACH_RETURN_SPEED
        local returnT = (self._entryTimer - halfDur) / halfDur
        self._approachOffsetX = targetX * (1 - returnT)
        self._approachOffsetY = targetY * (1 - returnT)
    end
end

function SkillAnimation:_updateProjectile(dt, entry)
    local dx  = self._defenderPos.x - self._attackerPos.x
    local dy  = self._defenderPos.y - self._attackerPos.y
    local t   = self._entryTimer / entry.duration  -- 0 → 1 over the entry

    -- Disappear in the last 15% of the duration
    if t >= 0.85 then
        self._projX = self._defenderPos.x
        self._projY = self._defenderPos.y
        return
    end

    -- Linear travel from attacker to defender
    local progress = t / 0.85
    self._projX = self._attackerPos.x + dx * progress
    self._projY = self._attackerPos.y + dy * progress
end


-- FACTORY HELPERS
-- Convenience: build a SkillAnimation from a plain list of tables.
-- Each table: { type = AnimationType.X, path = "...", duration = N (optional) }
--
-- Example:
--   SkillAnimation.build({
--       { type = AnimationType.APPROACH,   path = "assets/sprites/skills/slash.png" },
--       { type = AnimationType.PROJECTILE, path = "assets/sprites/skills/spark.png", duration = 0.8 },
--   })
function SkillAnimation.build(list)
    assert(type(list) == "table" and #list > 0, "list must be non-empty")
    local entries = {}
    for _, item in ipairs(list) do
        table.insert(entries, SkillAnimationEntry.new(item.type, item.path, item.duration))
    end
    return SkillAnimation.new(entries)
end

-- EXPORTS

return {
    SkillAnimation      = SkillAnimation,
    SkillAnimationEntry = SkillAnimationEntry,
    AnimationType       = AnimationType,
}