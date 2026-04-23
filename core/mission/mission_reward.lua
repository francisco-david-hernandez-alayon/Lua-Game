-- core/mission/mission_reward.lua
--
-- Reward given to the player upon mission completion.
-- ATTRIBUTES:
--   expReward:      experience points (nil = none)
--   rewardBits:     currency reward (nil = none)
--   rewardItems:    list of item nameKeys (nil = none)
--   rewardLanguage: languageId string (nil = none)

local MissionReward = {}
MissionReward.__index = MissionReward

function MissionReward.new(data)
    data = data or {}
    assert(data.expReward   == nil or type(data.expReward)   == "number", "expReward must be number or nil")
    assert(data.rewardBits  == nil or type(data.rewardBits)  == "number", "rewardBits must be number or nil")
    assert(data.rewardItems == nil or type(data.rewardItems) == "table",  "rewardItems must be table or nil")
    assert(data.rewardLanguage == nil or type(data.rewardLanguage) == "string", "rewardLanguage must be string or nil")
    return setmetatable({
        expReward      = data.expReward      or nil,
        rewardBits     = data.rewardBits     or nil,
        rewardItems    = data.rewardItems    or nil,
        rewardLanguage = data.rewardLanguage or nil,
    }, MissionReward)
end

function MissionReward:hasReward()
    return self.expReward ~= nil
        or self.rewardBits ~= nil
        or self.rewardItems ~= nil
        or self.rewardLanguage ~= nil
end

function MissionReward:toTable()
    return {
        expReward      = self.expReward,
        rewardBits     = self.rewardBits,
        rewardItems    = self.rewardItems,
        rewardLanguage = self.rewardLanguage,
    }
end

function MissionReward.fromTable(data)
    return MissionReward.new(data)
end

return MissionReward