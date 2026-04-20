-- core/npc/npc_option.lua
--
-- Wraps any option type (talk, trade, combat) with an id, display label,
-- and active flag. Inactive options are hidden from the player menu.

local NpcOption = {}
NpcOption.__index = NpcOption

function NpcOption.new(id, labelKey, option)
    -- id:       unique string identifier
    -- labelKey: localization key shown in the NPC option menu
    -- option:   TalkOption | TradeOption | CombatOption instance
    return setmetatable({
        id       = id,
        labelKey = labelKey,
        option   = option,
        active   = true,
    }, NpcOption)
end

function NpcOption:getLabel(L)
    return L.get(self.labelKey)
end

function NpcOption:activate()   self.active = true  end
function NpcOption:deactivate() self.active = false end

return NpcOption