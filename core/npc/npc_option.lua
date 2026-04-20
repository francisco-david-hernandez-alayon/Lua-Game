-- core/npc/npc_option.lua
--
-- Wraps any option type (talk, trade, combat) with an id, display label,
-- and active flag. Inactive options are hidden from the player menu.

local NpcOption = {}
NpcOption.__index = NpcOption

-- core/npc/npc_option.lua
function NpcOption.new(id, labelKey, option, initialLineKey)
    -- id:          unique string identifier
    -- labelKey:    localization key shown in the NPC option menu
    -- option:      TalkOption | TradeOption | CombatOption instance
    -- active:      An NPC can say this option
    -- initialLineKey: First dialogue line to shown as intro before get into the option
    return setmetatable({
        id             = id,
        labelKey       = labelKey,
        option         = option,
        active         = true,
        initialLineKey = initialLineKey,  
    }, NpcOption)
end

function NpcOption:getInitialLine(L)
    if not self.initialLineKey then return nil end
    return L.get(self.initialLineKey)
end

function NpcOption:getLabel(L)
    return L.get(self.labelKey)
end

function NpcOption:activate()   self.active = true  end
function NpcOption:deactivate() self.active = false end

return NpcOption