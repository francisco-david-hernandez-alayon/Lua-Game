-- core/npc/options/combat_option.lua
--
-- NPC option that triggers a combat encounter.
-- preCombatDialogue:  Dialogue shown before battle starts
-- postCombatDialogue: Dialogue shown after battle ends
-- rewardBits: amount of bits (currency) given to player on victory

local CombatOption = {}
CombatOption.__index = CombatOption

function CombatOption.new(preCombatDialogue, postCombatDialogue, rewardBits)
    return setmetatable({
        type               = "combat",
        preCombatDialogue  = preCombatDialogue,
        postCombatDialogue = postCombatDialogue,
        rewardBits         = rewardBits or 0,
        active             = true,
    }, CombatOption)
end

function CombatOption:getPreCombatLine(L)
    if not self.preCombatDialogue then return nil end
    return self.preCombatDialogue:getCurrentLine()
end

function CombatOption:getPostCombatLine(L)
    if not self.postCombatDialogue then return nil end
    return self.postCombatDialogue:getCurrentLine()
end

function CombatOption:activate()   self.active = true  end
function CombatOption:deactivate() self.active = false end

return CombatOption