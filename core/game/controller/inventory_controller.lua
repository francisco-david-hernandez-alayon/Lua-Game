-- core/game/controller/inventory_controller.lua
--
-- Handles all inventory operations for the current game session.
-- Used internally by GameController — do not call directly.

local InventoryController = {}

-- Bytes
function InventoryController.earnBytes(inventory, amount)
    assert(type(amount) == "number" and amount > 0, "amount must be positive")
    local ok, msg = inventory:addBytes(amount)
    print("[InventoryController] earnBytes:", amount, msg)
    return ok, msg
end

function InventoryController.spendBytes(inventory, amount)
    assert(type(amount) == "number" and amount > 0, "amount must be positive")
    local ok, msg = inventory:spendBytes(amount)
    print("[InventoryController] spendBytes:", amount, msg)
    return ok, msg
end

-- Items
function InventoryController.addItem(inventory, item)
    local ok, msg = inventory:addItem(item)
    print("[InventoryController] addItem:", item.nameKey, msg)
    return ok, msg
end

function InventoryController.removeItem(inventory, nameKey, amount)
    local ok = inventory:removeItem(nameKey, amount)
    print("[InventoryController] removeItem:", nameKey, ok)
    return ok
end

-- Languages
function InventoryController.learnLanguage(inventory, languageSlot)
    local ok, msg = inventory:learnLanguage(languageSlot)
    print("[InventoryController] learnLanguage:", languageSlot.languageId, msg)
    return ok, msg
end

function InventoryController.equipLanguageToSlot(inventory, languageId, slotIndex)
    local ok, msg = inventory:equipLanguageToSlot(languageId, slotIndex)
    print("[InventoryController] equipLanguageToSlot:", languageId, slotIndex, msg)
    return ok, msg
end

function InventoryController.swapLanguageSlots(inventory, slotA, slotB)
    local ok, msg = inventory:swapLanguageSlots(slotA, slotB)
    print("[InventoryController] swapLanguageSlots:", slotA, slotB, msg)
    return ok, msg
end

-- Rewards 
-- Automatically apply a MissionReward — called by MissionController via GameController
function InventoryController.applyReward(inventory, reward)
    if not reward or not reward:hasReward() then return end
    if reward.rewardBits then
        inventory:addBytes(reward.rewardBits)
        print("[InventoryController] applyReward bits:", reward.rewardBits)
    end
    if reward.rewardItems then
        for _, item in ipairs(reward.rewardItems) do
            inventory:addItem(item)
            print("[InventoryController] applyReward item:", item.nameKey)
        end
    end
    if reward.rewardLanguage then
        local ProgrammingLanguageSlot = require("core.inventory.programming_language_slot")
        inventory:learnLanguage(ProgrammingLanguageSlot.new(reward.rewardLanguage))
        print("[InventoryController] applyReward language:", reward.rewardLanguage)
    end
end

return InventoryController