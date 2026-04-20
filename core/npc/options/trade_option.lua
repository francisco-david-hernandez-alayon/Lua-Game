-- core/npc/options/trade_option.lua
--
-- NPC option that opens a shop.
-- items: list of Item {name, price}
-- interest: multiplier applied to each item's price (e.g. 1.2 = 20% markup)
-- promptKey: localization key for the trade prompt text

local TradeOption = {}
TradeOption.__index = TradeOption

-- Item class used inside trade
local Item = {}
Item.__index = Item
function Item.new(name, price)
    return setmetatable({ name = name, price = price }, Item)
end

function TradeOption.new(items, interest, promptKey)
    return setmetatable({
        type      = "trade",
        items     = items or {},
        interest  = interest or 1.0,
        promptKey = promptKey or "trade_prompt",
        active    = true,
    }, TradeOption)
end

-- Returns the final price of an item with interest applied
function TradeOption:getPrice(item)
    return math.floor(item.price * self.interest)
end

-- Returns all items with their final prices
function TradeOption:getShopItems()
    local result = {}
    for _, item in ipairs(self.items) do
        table.insert(result, {
            name  = item.name,
            price = self:getPrice(item),
        })
    end
    return result
end

function TradeOption:getPrompt(L)
    return L.get(self.promptKey)
end

function TradeOption:activate()   self.active = true  end
function TradeOption:deactivate() self.active = false end

TradeOption.Item = Item
return TradeOption