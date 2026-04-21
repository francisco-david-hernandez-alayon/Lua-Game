-- core/inventory/mission_item.lua
-- (item de misión)
--
-- A mission item. Cannot be stacked or dropped.
-- nameKey:  localization key for item name
-- descKey:  localization key for item description

local MissionItem = {}
MissionItem.__index = MissionItem

function MissionItem.new(nameKey, descKey)
    return setmetatable({
        nameKey = nameKey,
        descKey = descKey,
    }, MissionItem)
end

function MissionItem:getName(L) return L.get(self.nameKey) end
function MissionItem:getDesc(L) return L.get(self.descKey) end

function MissionItem:toTable()
    return { nameKey = self.nameKey, descKey = self.descKey }
end

function MissionItem.fromTable(data)
    return MissionItem.new(data.nameKey, data.descKey)
end

return MissionItem