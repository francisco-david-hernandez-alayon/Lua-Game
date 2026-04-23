-- core/inventory/player_inventory.lua
local Item                    = require("core.inventory.item")
local MissionItem             = require("core.inventory.mission_item")
local ProgrammingLanguageSlot = require("core.inventory.programming_language_slot")

local MAX_ITEMS          = 20
local MAX_LANGUAGE_SLOTS = 6

local PlayerInventory = {}
PlayerInventory.__index = PlayerInventory

function PlayerInventory.new()
    return setmetatable({
        items                       = {},
        missionItems                = {},
        programmingLanguageSlots    = {},  -- equipped slots (max 6)
        programmingLanguagesLearnt  = {},  -- all captured languages
        bytes                       = 0,   -- currency
    }, PlayerInventory)
end


-- BYTES
function PlayerInventory:getBytes()
    return self.bytes
end

function PlayerInventory:addBytes(amount)
    assert(type(amount) == "number" and amount > 0, "amount must be a positive number")
    self.bytes = self.bytes + amount
    return "inventory_bytes_gained"
end

function PlayerInventory:spendBytes(amount)
    assert(type(amount) == "number" and amount > 0, "amount must be a positive number")
    if self.bytes < amount then
        return nil, "inventory_bytes_insufficient"
    end
    self.bytes = self.bytes - amount
    return true, "inventory_bytes_spent"
end


-- ITEMS
function PlayerInventory:isItemsFull()
    return #self.items >= MAX_ITEMS
end

function PlayerInventory:addItem(item)
    for _, existing in ipairs(self.items) do
        if existing.nameKey == item.nameKey and not existing:isFull() then
            local overflow = existing:add(item.count)
            if overflow == 0 then return nil, "inventory_item_added" end
            item.count = overflow
        end
    end
    if self:isItemsFull() then return nil, "inventory_items_full" end
    table.insert(self.items, item)
    return true, "inventory_item_added"
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
    return true, "inventory_mission_item_added"
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


-- PROGRAMMING LANGUAGE LEARNT
-- Returns true if language is already learnt
function PlayerInventory:hasLearntLanguage(languageId)
    assert(type(languageId) == "string", "languageId must be a string")
    for _, lang in ipairs(self.programmingLanguagesLearnt) do
        if lang.languageId == languageId then return true end
    end
    return false
end

-- Returns true if language is currently in a slot
function PlayerInventory:isLanguageInSlot(languageId)
    assert(type(languageId) == "string", "languageId must be a string")
    for _, slot in ipairs(self.programmingLanguageSlots) do
        if slot.languageId == languageId then return true end
    end
    return false
end

-- Learn a new language — adds to learnt list and equips if slot available
function PlayerInventory:learnLanguage(languageSlot)
    assert(languageSlot and type(languageSlot.languageId) == "string",
        "languageSlot must have a languageId string")

    -- MUST ADD INVENTORY LANGUAGE ID TO BE ABLE TO LEARTN THE SAME LANGUAGE MORE TIMES
    if self:hasLearntLanguage(languageSlot.languageId) then
        return nil, "inventory_language_already_learnt"
    end

    table.insert(self.programmingLanguagesLearnt, languageSlot)

    -- Auto-equip if slot available
    if not self:isProgrammingLanguageSlotsFull() then
        table.insert(self.programmingLanguageSlots, languageSlot)
        return true, "inventory_language_learnt_and_equipped"
    end

    return true, "inventory_language_learnt"
end


-- PROGRAMMING LANGUAGE SLOTS
function PlayerInventory:isProgrammingLanguageSlotsFull()
    return #self.programmingLanguageSlots >= MAX_LANGUAGE_SLOTS
end

-- Equip a learnt language into a specific slot index (replaces existing)
function PlayerInventory:equipLanguageToSlot(languageId, slotIndex)
    assert(type(languageId) == "string",  "languageId must be a string")
    assert(type(slotIndex)  == "number"
        and slotIndex >= 1
        and slotIndex <= MAX_LANGUAGE_SLOTS,  "slotIndex must be between 1 and " .. MAX_LANGUAGE_SLOTS)
    assert(self:hasLearntLanguage(languageId), "language not learnt: " .. languageId)
    assert(not self:isLanguageInSlot(languageId), "language already in a slot: " .. languageId)

    local slot = self:_getLearntLanguage(languageId)
    self.programmingLanguageSlots[slotIndex] = slot
    return true, "inventory_language_equipped"
end

-- Swap two slot positions
function PlayerInventory:swapLanguageSlots(slotA, slotB)
    assert(type(slotA) == "number" and slotA >= 1 and slotA <= MAX_LANGUAGE_SLOTS,
        "slotA must be between 1 and " .. MAX_LANGUAGE_SLOTS)
    assert(type(slotB) == "number" and slotB >= 1 and slotB <= MAX_LANGUAGE_SLOTS,
        "slotB must be between 1 and " .. MAX_LANGUAGE_SLOTS)
    assert(slotA ~= slotB, "slotA and slotB must be different")

    self.programmingLanguageSlots[slotA], self.programmingLanguageSlots[slotB] =
        self.programmingLanguageSlots[slotB], self.programmingLanguageSlots[slotA]
    return true, "inventory_slots_swapped"
end

-- Internal: get learnt language by id
function PlayerInventory:_getLearntLanguage(languageId)
    for _, lang in ipairs(self.programmingLanguagesLearnt) do
        if lang.languageId == languageId then return lang end
    end
    return nil
end

function PlayerInventory:addProgrammingLanguageSlot(languageSlot)
    if self:isProgrammingLanguageSlotsFull() then
        return nil, "inventory_languages_full"
    end
    table.insert(self.programmingLanguageSlots, languageSlot)
    return true, "inventory_language_equipped"
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
    local items, missionItems, slots, learnt = {}, {}, {}, {}
    for _, v in ipairs(self.items)                       do table.insert(items,  v:toTable()) end
    for _, v in ipairs(self.missionItems)                do table.insert(missionItems, v:toTable()) end
    for _, v in ipairs(self.programmingLanguageSlots)    do table.insert(slots,  v:toTable()) end
    for _, v in ipairs(self.programmingLanguagesLearnt)  do table.insert(learnt, v:toTable()) end
    return {
        bytes                      = self.bytes,
        items                      = items,
        missionItems               = missionItems,
        programmingLanguageSlots   = slots,
        programmingLanguagesLearnt = learnt,
    }
end

function PlayerInventory.fromTable(data)
    local inv = PlayerInventory.new()
    inv.bytes = data.bytes or 0
    for _, d in ipairs(data.items                      or {}) do table.insert(inv.items,                      Item.fromTable(d))                    end
    for _, d in ipairs(data.missionItems               or {}) do table.insert(inv.missionItems,               MissionItem.fromTable(d))             end
    for _, d in ipairs(data.programmingLanguageSlots   or {}) do table.insert(inv.programmingLanguageSlots,   ProgrammingLanguageSlot.fromTable(d)) end
    for _, d in ipairs(data.programmingLanguagesLearnt or {}) do table.insert(inv.programmingLanguagesLearnt, ProgrammingLanguageSlot.fromTable(d)) end
    return inv
end

return PlayerInventory