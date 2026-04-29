-- utils/language_level_builder.lua
--
-- Builds a programming language instance at a target level using its level tree.

local LanguageLevelBuilder = {}

local function getRandomElement(list)
    if #list == 0 then
        return nil
    end

    return list[math.random(#list)]
end

local function getUpgradeIndex(node, specializationId)
    if not node or not node.upgrades or #node.upgrades == 0 then
        return nil
    end

    local preferredIndexes = {}
    local fallbackIndexes = {}

    for i, upgrade in ipairs(node.upgrades) do
        table.insert(fallbackIndexes, i)

        if specializationId and upgrade.specializationId == specializationId then
            table.insert(preferredIndexes, i)
        end
    end

    if specializationId and #preferredIndexes > 0 then
        return getRandomElement(preferredIndexes)
    end

    return getRandomElement(fallbackIndexes)
end

local function clearCurrentSkills(lang)
    for i = #lang.currentSkills, 1, -1 do
        lang:removeCurrentSkill(i)

    end
end

local function hasCurrentSkill(lang, skill)
    for _, currentSkill in ipairs(lang.currentSkills) do
        if currentSkill == skill then
            return true
        end
    end

    return false
end

local function equipCurrentSkill(lang, skill)
    if not skill or hasCurrentSkill(lang, skill) then
        return false
    end

    if #lang.currentSkills >= 4 then
        return false
    end

    table.insert(lang.currentSkills, skill)
    return true
end

local function equipRandomCurrentSkills(lang)
    clearCurrentSkills(lang)

    local usedPoolIndexes = {}

    -- Ensure at least one attack skill if possible.
    for poolIndex, skill in ipairs(lang.skills) do
        if skill:hasCategory("attack") then
            if equipCurrentSkill(lang, skill) then
                usedPoolIndexes[poolIndex] = true
                break
            end
        end
    end

    while #lang.currentSkills < 4 do
        local availableIndexes = {}

        for poolIndex, skill in ipairs(lang.skills) do
            if not usedPoolIndexes[poolIndex] and not hasCurrentSkill(lang, skill) then
                table.insert(availableIndexes, poolIndex)
            end
        end

        if #availableIndexes == 0 then
            break
        end

        local chosenPoolIndex = getRandomElement(availableIndexes)
        local chosenSkill = lang.skills[chosenPoolIndex]

        if equipCurrentSkill(lang, chosenSkill) then
            usedPoolIndexes[chosenPoolIndex] = true
        else
            break
        end
    end
end


function LanguageLevelBuilder.build(baseLanguage, targetLevel, specializationId)
    assert(baseLanguage, "baseLanguage is required")
    assert(type(targetLevel) == "number" and targetLevel >= 1, "targetLevel must be >= 1")

    local lang = baseLanguage
    local tree = lang.levelTree

    if not tree then
        lang.exp = 0
        equipRandomCurrentSkills(lang)
        return lang
    end

    while lang.level < targetLevel do
        local nextNode = tree:getNextLevel(lang.level)
        if not nextNode then
            break
        end

        local leveledUp = lang:addExp(nextNode.expRequired)
        if not leveledUp then
            break
        end

        local upgradeIndex = getUpgradeIndex(nextNode, specializationId)
        if upgradeIndex then
            lang:applyUpgrade(upgradeIndex)
        end
    end

    lang.exp = 0
    equipRandomCurrentSkills(lang)

    lang:heal();  -- Restore hp

    return lang
end

return LanguageLevelBuilder
