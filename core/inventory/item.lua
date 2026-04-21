-- core/inventory/item.lua
--
-- Represents a stackable inventory item.
-- nameKey:        localization key for item name
-- descKey:        localization key for item description
-- maxStack:       maximum amount that can be stacked in one slot
-- count:          current amount in this stack

local Item = {}
Item.__index = Item

function Item.new(nameKey, descKey, maxStack)
    return setmetatable({
        nameKey  = nameKey,
        descKey  = descKey,
        maxStack = maxStack or 1,
        count    = 1,
    }, Item)
end

-- Returns true if this stack is full
function Item:isFull()
    return self.count >= self.maxStack
end

-- Add amount to stack, returns overflow (amount that didn't fit)
function Item:add(amount)
    local space    = self.maxStack - self.count
    local added    = math.min(amount, space)
    self.count     = self.count + added
    return amount  - added  -- overflow
end

function Item:getName(L)   return L.get(self.nameKey) end
function Item:getDesc(L)   return L.get(self.descKey) end

function Item:toTable()
    return { nameKey = self.nameKey, descKey = self.descKey, maxStack = self.maxStack, count = self.count }
end

function Item.fromTable(data)
    local item = Item.new(data.nameKey, data.descKey, data.maxStack)
    item.count = data.count
    return item
end

return Item