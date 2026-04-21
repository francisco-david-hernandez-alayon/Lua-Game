-- core/inventory/player_inventory.lua
--
-- Player inventory. Holds items, mission items and language slots.
-- items:                    list of Item                    — max MAX_ITEMS slots
-- missionItems:             list of MissionItem             — no limit
-- programmingLanguageSlots: list of ProgrammingLanguageSlot — max MAX_LANGUAGE_SLOTS

local Item                    = require("core.inventory.item")
local MissionItem             = require("core.inventory.mission_item")
local ProgrammingLanguageSlot = require("core.inventory.programming_language_slot")

local MAX_ITEMS          = 20
local MAX_LANGUAGE_SLOTS = 6

local PlayerInventory = {}
PlayerInventory.__index = PlayerInventory

function PlayerInventory.new()
    return setmetatable({
        items                    = {},
        missionItems             = {},
        programmingLanguageSlots = {},
    }, PlayerInventory)
end

-- ITEMS
function PlayerInventory:isItemsFull()
    return #self.items >= MAX_ITEMS
end

function PlayerInventory:addItem(item)
    for _, existing in ipairs(self.items) do
        if existing.nameKey == item.nameKey and not existing:isFull() then
            local overflow = existing:add(item.count)
            if overflow == 0 then return nil end
            item.count = overflow
        end
    end
    if self:isItemsFull() then return "inventory_items_full" end
    table.insert(self.items, item)
    return nil
end

function PlayerInventory:removeItem(nameKey, amount)
    amount = amount or 1
    for i, item in ipairs(self.items) do
        if item.nameKey == nameKey then
            item.count = item.count - amount
            if item.count <= 0 then table.remove(self.items, i) end
            return true
        end
    end
    return false
end


-- MISSION ITEMS
function PlayerInventory:addMissionItem(missionItem)
    table.insert(self.missionItems, missionItem)
    return nil
end

function PlayerInventory:removeMissionItem(nameKey)
    for i, item in ipairs(self.missionItems) do
        if item.nameKey == nameKey then
            table.remove(self.missionItems, i)
            return true
        end
    end
    return false
end


-- PROGRAMMING LANGUAGE SLOTS
function PlayerInventory:isProgrammingLanguageSlotsFull()
    return #self.programmingLanguageSlots >= MAX_LANGUAGE_SLOTS
end

function PlayerInventory:addProgrammingLanguageSlot(languageSlot)
    if self:isProgrammingLanguageSlotsFull() then
        return "inventory_languages_full"
    end
    table.insert(self.programmingLanguageSlots, languageSlot)
    return nil
end

function PlayerInventory:removeProgrammingLanguageSlot(languageId)
    for i, slot in ipairs(self.programmingLanguageSlots) do
        if slot.languageId == languageId then
            table.remove(self.programmingLanguageSlots, i)
            return true
        end
    end
    return false
end


-- SERIALIZATION
function PlayerInventory:toTable()
    local items, missionItems, programmingLanguageSlots = {}, {}, {}
    for _, v in ipairs(self.items)                    do table.insert(items,                    v:toTable()) end
    for _, v in ipairs(self.missionItems)             do table.insert(missionItems,             v:toTable()) end
    for _, v in ipairs(self.programmingLanguageSlots) do table.insert(programmingLanguageSlots, v:toTable()) end
    return {
        items                    = items,
        missionItems             = missionItems,
        programmingLanguageSlots = programmingLanguageSlots,
    }
end

function PlayerInventory.fromTable(data)
    local inv = PlayerInventory.new()
    for _, d in ipairs(data.items                    or {}) do table.insert(inv.items,                    Item.fromTable(d))                    end
    for _, d in ipairs(data.missionItems             or {}) do table.insert(inv.missionItems,             MissionItem.fromTable(d))             end
    for _, d in ipairs(data.programmingLanguageSlots or {}) do table.insert(inv.programmingLanguageSlots, ProgrammingLanguageSlot.fromTable(d)) end
    return inv
end

return PlayerInventory