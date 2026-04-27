-- core/programming_languages/passive_ability.lua
--
-- A passive ability that triggers at specific moments in battle.
-- ATTRIBUTES:
--   id:         unique string identifier
--   nameKey:    localization key for name
--   descKey:    localization key for description
--   languageId: id of the language that owns this passive
--   trigger:    when it activates:
--               "before_attack"  → before this language attacks
--               "after_attack"   → after this language attacks
--               "before_receive" → before this language receives damage
--               "after_receive"  → after this language receives damage
--   applyFn:    function(battle, owner) → modifies battle state, adds messages

local VALID_TRIGGERS = {
    before_attack  = true,
    after_attack   = true,
    before_receive = true,
    after_receive  = true,
}

local PassiveAbility = {}
PassiveAbility.__index = PassiveAbility

function PassiveAbility.new(id, nameKey, descKey, languageId, trigger, applyFn)
    assert(type(id)         == "string",  "id must be a string")
    assert(type(nameKey)    == "string",  "nameKey must be a string")
    assert(type(descKey)    == "string",  "descKey must be a string")
    assert(type(languageId) == "string",  "languageId must be a string")
    assert(VALID_TRIGGERS[trigger],       "invalid trigger: " .. tostring(trigger))
    assert(type(applyFn)    == "function","applyFn must be a function")
    return setmetatable({
        id         = id,
        nameKey    = nameKey,
        descKey    = descKey,
        languageId = languageId,
        trigger    = trigger,
        applyFn    = applyFn,
    }, PassiveAbility)
end

-- Call this at the correct battle moment
function PassiveAbility:apply(battle, owner)
    self.applyFn(battle, owner)
end

function PassiveAbility:getName(L) return L.get(self.nameKey) end
function PassiveAbility:getDesc(L) return L.get(self.descKey) end

return PassiveAbility