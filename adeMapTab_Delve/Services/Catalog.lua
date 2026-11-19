local _, addon = ...
local Catalog = addon.Catalog
local Data = addon.Data

-- 分组、排序、过滤与搜索。
-- 基础顺序由 Services/DelveScanner.lua 的构建顺序给出：地区表倒序，地区内地下堡正序。
-- 最终排序（开发计划 §1.3）：
--   ① 迷宫  ② 丰裕  ③ 其余（普通 + 宿敌）  ④ 仪式站点（固定在分组末尾）

-- 地图显示顺序（用户 2026-10-28 给定，db2 数据 + 实测确认无误）。
-- ⚠ 与 Data/DelveZones.lua 的 DELVE_MAPS 有一处不同：midnight 里这里把
-- 哈籁恩达尔(2413) 排在虚影风暴(2405) 前面，DELVE_MAPS 里两者是反的。
-- 用户已确认本表顺序才是对的；DELVE_MAPS 只作为扫描起点，不影响显示顺序。
local ZONE_ORDER = {
    midnight = { 2393, 2424, 2395, 2437, 2413, 2405, 2512 },
    tww = { 2248, 2214, 2215, 2255, 2346, 2371 },
}

local ZONE_INDEX = {}
for expansionKey, mapIDs in pairs(ZONE_ORDER) do
    local index = {}
    for position, mapID in ipairs(mapIDs) do
        index[mapID] = position
    end
    ZONE_INDEX[expansionKey] = index
end

-- 表里没列出的地图排到最后（返回很大的序号），而不是挤到最前面。
local function ZoneIndex(entry, expansionKey)
    local index = ZONE_INDEX[expansionKey]
    if not index then return math.huge end
    return index[entry.zoneMapID] or index[entry.uiMapID] or math.huge
end

-- 第二阶段 9.4.1：类型过滤收敛为 3 类。丰饶区域与仪式场地各归自身 kind，
-- 其余（普通 / 丰裕 / 宿敌 / 迷宫）一律归 delve。
local function KindFilterKey(entry)
    if entry.kind == "abundance" then return "abundance" end
    if entry.kind == "ritual" then return "ritual" end
    return "delve"
end

-- 第二阶段 9.4.3：二级「按类型排序」的类型序 地下堡 → 丰饶区域 → 仪式场地。
-- 直接复用 KindFilterKey 的分流，保证与 9.4.1 的三类口径一致。
local TYPE_ORDER = { delve = 1, abundance = 2, ritual = 3 }
local function TypeOrder(entry)
    return TYPE_ORDER[KindFilterKey(entry)] or math.huge
end

local function SortRank(entry, eventActiveFirst)
    if entry.kind == "labyrinth" then return 0 end
    -- 第二阶段 9.5.2：事件激活范围扩到 丰裕地下堡 + 丰饶收获区域 + 激活的仪式场地。
    if eventActiveFirst then
        local active = entry.bountiful
            or (entry.kind == "abundance" and entry.abundanceActive)
            or (entry.kind == "ritual" and entry.ritualActive)
        if active then return 1 end
    end
    if entry.kind == "ritual" then return 4 end
    -- 宿敌与普通地下堡同属「其余」，一并按基础顺序排列。
    return 2
end

local function MatchesSearch(entry, needle)
    if not needle or needle == "" then return true end
    local name = entry.name and string.lower(entry.name) or ""
    local zone = entry.zoneName and string.lower(entry.zoneName) or ""
    return string.find(name, needle, 1, true) ~= nil or string.find(zone, needle, 1, true) ~= nil
end

local function IsVisible(entry, db, needle)
    if not db then return true end

    -- 资料片总开关
    if entry.expansion == "tww" and db.showTWW == false then return false end
    if entry.expansion == "midnight" and db.showMidnight == false then return false end
    if entry.kind == "labyrinth" and db.showLabyrinth == false then return false end
    if entry.kind == "ritual" and db.showRitual == false then return false end
    if entry.kind == "nemesis" and db.showNemesis == false then return false end
    -- 第二阶段 9.3.1：未开启「显示丰饶区域」时跳过丰饶条目。
    if entry.kind == "abundance" and db.showAbundance == false then return false end

    -- TopBar 过滤器
    if not addon.Database.GetFilter("expansion", entry.expansion) then return false end
    if not addon.Database.GetFilter("kind", KindFilterKey(entry)) then return false end

    -- 第二阶段 9.4.2：TopBar 临时类型下拉（面板级）优先于上面的类型过滤；
    -- 资料片过滤仍生效（上面的 expansion 分支已处理）。
    local typeFilter = addon.MapPanel and addon.MapPanel.GetTypeFilter and addon.MapPanel:GetTypeFilter()
    if typeFilter and typeFilter ~= "all" and KindFilterKey(entry) ~= typeFilter then return false end

    if db.hideCompleted then
        local achID = addon.Stats:GetEntryAchievement(entry)
        local done, total, complete = addon.Stats:GetAchievementProgress(achID)
        local callState = addon.Stats:GetCallState(entry.callQuestID)
        local achDone = (total == nil) or complete
        local callDone = (callState == nil) or callState == "done"
        if achDone and callDone then return false end
    end

    return MatchesSearch(entry, needle)
end

--- 返回按资料片分组后的列表：{ { expansion = "midnight", entries = {...} }, ... }
function Catalog:Build(searchText)
    local db = addon.db
    local entries = addon.Scanner:GetEntries()
    local needle = searchText and string.lower(searchText) or ""

    local buckets = {}
    for _, expansionKey in ipairs(Data.EXPANSION_ORDER) do
        buckets[expansionKey] = {}
    end

    -- 迷宫与普通地下堡会重复：迷宫是独立扫的一遍（Services/DelveScanner.lua:285-302），
    -- 与普通扫描之间没有互斥，所以同一座地下堡会出现两次——一条带 `[迷宫]`、一条没有
    -- （2026-10-27 截图：金多赞的迷宫）。按名字去重，保留 labyrinth 那条。
    local labyrinthNames = {}
    for _, entry in ipairs(entries) do
        if entry.kind == "labyrinth" and entry.name then
            labyrinthNames[entry.name] = true
        end
    end

    local indexed = {}
    for index, entry in ipairs(entries) do
        local shadowedByLabyrinth = entry.kind ~= "labyrinth" and entry.name and labyrinthNames[entry.name]
        if not shadowedByLabyrinth and IsVisible(entry, db, needle) then
            local bucket = buckets[entry.expansion]
            if bucket then
                indexed[index] = true
                bucket[#bucket + 1] = { entry = entry, index = index }
            end
        end
    end

    local eventActiveFirst = not db or db.eventActiveFirst ~= false
    -- 第二阶段 9.4.3：二级的可切换模式（「默认」= 按类型，「map」= 按地图）。
    local sortMode = db and db.entrySortMode or "default"
    local byMap = sortMode == "map"
    local groups = {}
    for _, expansionKey in ipairs(Data.EXPANSION_ORDER) do
        local bucket = buckets[expansionKey] or {}
        table.sort(bucket, function(a, b)
            local ea, eb = a.entry, b.entry
            -- 固定规则：迷宫 → 事件激活（丰裕 / 丰饶收获 / 激活仪式场地）→ 其余 → 仪式场地垫底
            local rankA, rankB = SortRank(ea, eventActiveFirst), SortRank(eb, eventActiveFirst)
            if rankA ~= rankB then return rankA < rankB end
            -- 二级：由 entrySortMode 决定「先类型后地图」还是「先地图后类型」（第二阶段 9.4.3）
            if byMap then
                -- 按地图排序：先地图后类型，地图序沿用 ZoneIndex
                local zoneA, zoneB = ZoneIndex(ea, expansionKey), ZoneIndex(eb, expansionKey)
                if zoneA ~= zoneB then return zoneA < zoneB end
                local kindA, kindB = TypeOrder(ea), TypeOrder(eb)
                if kindA ~= kindB then return kindA < kindB end
            else
                -- 默认：按类型排序，先类型后地图（类型序 地下堡 → 丰饶区域 → 仪式场地）
                local kindA, kindB = TypeOrder(ea), TypeOrder(eb)
                if kindA ~= kindB then return kindA < kindB end
                local zoneA, zoneB = ZoneIndex(ea, expansionKey), ZoneIndex(eb, expansionKey)
                if zoneA ~= zoneB then return zoneA < zoneB end
            end
            -- 同一地图里宿敌殿后
            local nemesisA, nemesisB = ea.kind == "nemesis" and 1 or 0, eb.kind == "nemesis" and 1 or 0
            if nemesisA ~= nemesisB then return nemesisA < nemesisB end
            -- 三级：剩下的普通地下堡按 poiRegular 降序
            local poiA, poiB = ea.poiRegular or 0, eb.poiRegular or 0
            if poiA ~= poiB then return poiA > poiB end
            return a.index < b.index
        end)

        local list = {}
        for _, item in ipairs(bucket) do
            list[#list + 1] = item.entry
        end
        groups[#groups + 1] = { expansion = expansionKey, entries = list }
    end

    return groups
end

function Catalog:CountVisible(groups)
    local count = 0
    for _, group in ipairs(groups or {}) do
        count = count + #group.entries
    end
    return count
end
