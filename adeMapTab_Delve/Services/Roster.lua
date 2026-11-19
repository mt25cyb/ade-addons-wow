local _, addon = ...
local Roster = addon.Roster
local Data = addon.Data

-- 跨角色快照：账号级 SavedVariables 累积，照 EverythingDelves
-- EverythingDelves.lua:1159-1231（E:CaptureRosterSnapshot）。

local function IsTimerunning()
    if C_ChatInfo and C_ChatInfo.IsTimerunningPlayer then
        local ok, result = pcall(C_ChatInfo.IsTimerunningPlayer, UnitGUID("player"))
        if ok and result then return true end
    end
    if PlayerGetTimerunningSeasonID then
        local ok, season = pcall(PlayerGetTimerunningSeasonID)
        if ok and season and season ~= 0 then return true end
    end
    return false
end

local function GetEquippedItemLevel()
    if not GetAverageItemLevel then return nil end
    local ok, _, equipped = pcall(GetAverageItemLevel)
    if ok and equipped and equipped > 0 then return math.floor(equipped + 0.5) end
    return nil
end

--- 宏伟宝库进度：EverythingDelves.lua:1201-1219。
local function GetVaultProgress()
    local progress, total, slots = 0, 0, 0
    if not (C_WeeklyRewards and C_WeeklyRewards.GetActivities) then return progress, total, slots end
    if not (Enum and Enum.WeeklyRewardChestThresholdType) then return progress, total, slots end

    local ok, activities = pcall(C_WeeklyRewards.GetActivities)
    if not ok or type(activities) ~= "table" then return progress, total, slots end

    for _, activity in ipairs(activities) do
        if activity.type == Enum.WeeklyRewardChestThresholdType.World then
            progress = math.max(progress, activity.progress or 0)
            total = math.max(total, activity.threshold or 0)
            if (activity.threshold or 0) > 0 and (activity.progress or 0) >= activity.threshold then
                slots = slots + 1
            end
        end
    end
    return progress, total, slots
end

local function IsQuestDone(questID)
    if not questID or not (C_QuestLog and C_QuestLog.IsQuestFlaggedCompleted) then return false end
    return C_QuestLog.IsQuestFlaggedCompleted(questID) and true or false
end

--- 采集当前角色快照并写入账号级 SavedVariables。
function Roster:Capture()
    local db = addon.db
    if not db then return end
    -- Remix / Timerunning 角色没有当前资料片数据：EverythingDelves.lua:1163-1167。
    if IsTimerunning() then return end

    db.roster = db.roster or {}
    local key = addon.Database.CharKey()
    local rec = db.roster[key] or {}

    rec.name = UnitName("player") or rec.name
    rec.realm = GetRealmName() or rec.realm
    rec.class = select(2, UnitClass("player")) or rec.class
    rec.faction = UnitFactionGroup("player") or rec.faction
    rec.level = UnitLevel("player") or rec.level

    local ilvl = GetEquippedItemLevel()
    if ilvl then rec.ilvl = ilvl end

    local keys = addon.Stats:GetCurrency(Data.CURRENCIES.keys)
    rec.keys = keys and keys.quantity or 0

    local shards = addon.Stats:GetCurrency(Data.CURRENCIES.shards)
    rec.shards = shards and shards.quantity or 0
    rec.shardsEarnedWeek = shards and shards.earnedThisWeek or 0
    -- maxWeeklyQuantity 在货币加载完成前会读到 0，保留上一次已知上限：EverythingDelves.lua:1188-1191。
    local shardCap = shards and shards.maxWeekly or 0
    if shardCap > 0 then rec.shardsMaxWeek = shardCap end
    rec.shardsMaxWeek = rec.shardsMaxWeek or 0

    rec.bountyMaps = addon.Stats:GetItemCount(Data.ITEMS.bountyMap)
    rec.weeklyQuestDone = IsQuestDone(Data.WEEKLY_QUEST_ID)

    local progress, total, slots = GetVaultProgress()
    rec.vaultProgress = progress
    rec.vaultTotal = total
    rec.vaultSlots = slots

    local gildedCollected, gildedTotal = addon.Stats:GetGildedStash()
    if gildedCollected then rec.gildedCollected = gildedCollected end
    if gildedTotal then rec.gildedTotal = gildedTotal end

    local seconds = C_DateAndTime and C_DateAndTime.GetSecondsUntilWeeklyReset
        and C_DateAndTime.GetSecondsUntilWeeklyReset()
    if seconds and seconds > 0 then rec.weekEnd = time() + seconds end

    rec.updated = time()
    db.roster[key] = rec
    return rec
end

--- 全部角色快照，按更新时间倒序。
function Roster:GetAll()
    local db = addon.db
    if not db or type(db.roster) ~= "table" then return {} end
    local list = {}
    for key, rec in pairs(db.roster) do
        rec.key = key
        list[#list + 1] = rec
    end
    table.sort(list, function(a, b) return (a.updated or 0) > (b.updated or 0) end)
    return list
end

function Roster:GetCurrentKey()
    return addon.Database.CharKey()
end
