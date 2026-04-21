-- core/battle/programming_language.lua
--
-- Represents a programming language used in battle.
-- language_name:   display name string
-- linesOfCode:     health points
-- executionTime:   speed (lower = faster)
-- currentAttacks:  list of up to 4 equipped attacks
-- attacks:         full list of known attacks

local ProgrammingLanguage = {}
ProgrammingLanguage.__index = ProgrammingLanguage

local MAX_CURRENT_ATTACKS = 4

local STATUS = { ACTIVE = "active", OBSOLETE = "obsolete" }
ProgrammingLanguage.STATUS = STATUS

function ProgrammingLanguage.new(language_name, linesOfCode, executionTime)
    assert(type(language_name)  == "string", "language_name must be a string")
    assert(type(linesOfCode)    == "number", "linesOfCode must be a number")
    assert(type(executionTime)  == "number", "executionTime must be a number")
    return setmetatable({
        language_name   = language_name,
        linesOfCode     = linesOfCode,
        maxLinesOfCode  = linesOfCode,
        executionTime   = executionTime,
        status          = STATUS.ACTIVE,
        currentAttacks  = {},  -- up to 4 equipped attacks
        attacks         = {},  -- full attack pool
    }, ProgrammingLanguage)
end

function ProgrammingLanguage:isActive()   return self.status == STATUS.ACTIVE   end
function ProgrammingLanguage:isObsolete() return self.status == STATUS.OBSOLETE end

function ProgrammingLanguage:setObsolete()
    self.status = STATUS.OBSOLETE
    print("[Battle] " .. self.language_name .. " is now OBSOLETE")
end

-- Add attack to full pool
function ProgrammingLanguage:addAttack(attack)
    table.insert(self.attacks, attack)
    -- Auto-equip if slots available
    if #self.currentAttacks < MAX_CURRENT_ATTACKS then
        table.insert(self.currentAttacks, attack)
    end
end

-- Replace a current attack slot (1-4) with an attack from the pool by index
function ProgrammingLanguage:swapCurrentAttack(slotIndex, poolIndex)
    assert(slotIndex  >= 1 and slotIndex  <= MAX_CURRENT_ATTACKS, "invalid slot index")
    assert(poolIndex  >= 1 and poolIndex  <= #self.attacks,        "invalid pool index")
    self.currentAttacks[slotIndex] = self.attacks[poolIndex]
end

-- Take damage, sets obsolete if linesOfCode reaches 0
function ProgrammingLanguage:takeDamage(amount)
    self.linesOfCode = math.max(0, self.linesOfCode - amount)
    if self.linesOfCode <= 0 then
        self:setObsolete()
    end
end

return ProgrammingLanguage