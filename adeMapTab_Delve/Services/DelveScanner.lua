local _, addon = ...
local Scanner = addon.Scanner
local Data = addon.Data
local L = addon.L

-- 丰裕判定：DFCN_DelveHelper:4049 与 HandyNotes RetailDelves.lua:726 使用同一 atlas。
local BOUNTIFUL_ATLAS = "delves-bountiful"
-- 故事变种：DFCN_DelveHelper Locales:30 的两种语言模式。
local STORY_VARIANT_PATTERNS = { "故事变种：%s*(.+)", "Story Variant:%s*(.+)" }
local CACHE_TTL = 1

Scanner.entries = nil
Scanner.entriesAt = 0
Scanner.zoneCache = {}

local function MapInfo(mapID)
    if not mapID or not (C_Map and C_Map.GetMapInfo) then return nil end
    return C_Map.GetMapInfo(mapID)
end

function Scanner:GetMapName(mapID)
    local info = MapInfo(mapID)
    return info and info.name or nil
end

function Scanner:GetParentMapID(mapID)
    local info = MapInfo(mapID)
    return info and info.parentMapID or nil
end

-- DELVE_MAPS 全集，用来判断「这张图是不是一条地下堡归属区」。
local DELVE_MAP_SET = {}
for _, list in pairs(Data.DELVE_MAPS or {}) do
    for _, mapID in ipairs(list) do
        DELVE_MAP_SET[mapID] = true
    end
end

--- 归属地图：从地下堡自己的地图沿父地图链向上，取第一个出现在 DELVE_MAPS 里的。
-- 子区域本身也在表里，所以黑暗回廊(2525) → 银月城(2393)；不在表里的继续上溯，
-- 千丝之城(2213) → 艾基-卡赫特(2255)。这样子区域的地下堡不会被错挂到它的父区域上
-- （用户 2026-10-28）。整条链都不在表里时返回 nil，交给后面的 POI 兜底处理。
local function ResolveZoneMapID(mapID)
    local seen = {}
    local current = mapID
    while current and not seen[current] do
        seen[current] = true
        if DELVE_MAP_SET[current] then return current end
        current = Scanner:GetParentMapID(current)
    end
    return nil
end

--- 区域地图列表：种子表（Data/DelveZones.lua）在前，从大陆自发现的追加在后。
function Scanner:GetZoneMapIDs(expansionKey)
    if Scanner.zoneCache[expansionKey] then return Scanner.zoneCache[expansionKey] end

    local list, seen = {}, {}
    for _, id in ipairs(Data.DELVE_MAPS[expansionKey] or {}) do
        if not seen[id] then
            seen[id] = true
            list[#list + 1] = id
        end
    end

    local continent = Data.CONTINENTS[expansionKey]
    if continent and C_Map and C_Map.GetMapChildrenInfo then
        local ok, children = pcall(C_Map.GetMapChildrenInfo, continent, nil, true)
        if ok and type(children) == "table" then
            for _, info in ipairs(children) do
                local id = info and info.mapID
                if id and not seen[id] then
                    local ok2, delves = pcall(C_AreaPoiInfo.GetDelvesForMap, id)
                    if ok2 and type(delves) == "table" and #delves > 0 then
                        seen[id] = true
                        list[#list + 1] = id
                    end
                end
            end
        end
    end

    Scanner.zoneCache[expansionKey] = list
    return list
end

--- 区域遍历顺序：种子表倒序，自发现的新区域追加在末尾（正序）。
function Scanner:GetZoneMapIDsOrdered(expansionKey)
    local all = Scanner:GetZoneMapIDs(expansionKey)
    local seedCount = #(Data.DELVE_MAPS[expansionKey] or {})
    local ordered = {}
    for i = seedCount, 1, -1 do
        ordered[#ordered + 1] = all[i]
    end
    for i = seedCount + 1, #all do
        ordered[#ordered + 1] = all[i]
    end
    return ordered
end

local function ParseStoryVariant(poiInfo)
    local setID = poiInfo and poiInfo.tooltipWidgetSet
    if not setID or not (C_UIWidgetManager and C_UIWidgetManager.GetAllWidgetsBySetID) then return nil end

    local ok, widgets = pcall(C_UIWidgetManager.GetAllWidgetsBySetID, setID)
    if not ok or type(widgets) ~= "table" then return nil end

    for _, widget in ipairs(widgets) do
        if widget.widgetType == 8 then
            local ok2, info = pcall(C_UIWidgetManager.GetTextWithStateWidgetVisualizationInfo, widget.widgetID)
            local text = ok2 and info and info.text
            if text then
                for _, pattern in ipairs(STORY_VARIANT_PATTERNS) do
                    local matched = string.match(text, pattern)
                    if matched then return matched end
                end
            end
        end
    end
    return nil
end

--- 收集某区域地图上的全部地下堡 POI，按 linkedUiMapID / areaPoiID 双索引。
local function CollectZonePOIs(zoneMapID)
    local byDelveMap, byPoiID, extras = {}, {}, {}
    if not (C_AreaPoiInfo and C_AreaPoiInfo.GetDelvesForMap) then return byDelveMap, byPoiID, extras end

    local ok, poiIDs = pcall(C_AreaPoiInfo.GetDelvesForMap, zoneMapID)
    if not ok or type(poiIDs) ~= "table" then return byDelveMap, byPoiID, extras end

    for _, poiID in ipairs(poiIDs) do
        local ok2, info = pcall(C_AreaPoiInfo.GetAreaPOIInfo, zoneMapID, poiID)
        if ok2 and info then
            local record = {
                poiID = poiID,
                zoneMapID = zoneMapID,
                bountiful = info.atlasName == BOUNTIFUL_ATLAS,
                name = info.name,
                storyVariant = ParseStoryVariant(info),
                x = nil,
                y = nil,
            }
            if info.position and info.position.GetXY then
                record.x, record.y = info.position:GetXY()
            end
            if info.linkedUiMapID then byDelveMap[info.linkedUiMapID] = record end
            byPoiID[poiID] = record
            extras[#extras + 1] = record
        end
    end
    return byDelveMap, byPoiID, extras
end

local function FindPOI(static, byDelveMap, byPoiID)
    if not static then return nil end
    local byMap = static.uiMapID and byDelveMap[static.uiMapID]
    if byMap then return byMap end
    if static.poiRegular and byPoiID[static.poiRegular] then return byPoiID[static.poiRegular] end
    if static.poiBountiful and byPoiID[static.poiBountiful] then return byPoiID[static.poiBountiful] end
    return nil
end

--- 直查宿敌 POI：宿敌常不在 GetDelvesForMap 的返回里（MN 标注原生地图不显示），
--- 因此在其所在区域与兜底地图上直接按 areaPoiID 查询。
local function FindNemesisPOI(static)
    if not static or not static.poiRegular then return nil end
    if not (C_AreaPoiInfo and C_AreaPoiInfo.GetAreaPOIInfo) then return nil end

    local candidates = {}
    local parent = Scanner:GetParentMapID(static.uiMapID)
    if parent then candidates[#candidates + 1] = parent end
    if static.wpMapID then candidates[#candidates + 1] = static.wpMapID end

    for _, mapID in ipairs(candidates) do
        local ok, info = pcall(C_AreaPoiInfo.GetAreaPOIInfo, mapID, static.poiRegular)
        if ok and info then
            local record = {
                poiID = static.poiRegular,
                zoneMapID = mapID,
                bountiful = info.atlasName == BOUNTIFUL_ATLAS,
                name = info.name,
                storyVariant = ParseStoryVariant(info),
            }
            if info.position and info.position.GetXY then
                record.x, record.y = info.position:GetXY()
            end
            return record
        end
    end
    return nil
end

local function MakeEntry(expansionKey, static, poi, zoneMapID)
    local parent = Scanner:GetParentMapID(static.uiMapID)
    local zone = zoneMapID or parent
    local x, y, waypointMapID

    -- ⚠ 宿敌的 wpMapID 是「入口地图」，只决定点击后切到哪张图（见下面 waypointMapID）。
    -- 归属地图不能跟着它走：2026-10-27 曾把 zone 也改成 wpMapID，于是泽克维尔的巢穴
    -- 归属成了千丝之城(2213)，而它应该属于艾基-卡赫特(2255)（用户 2026-10-28 实测）。
    -- 归属改由调用方按父地图链解析后传进来（ResolveZoneMapID）；没有 POI 的宿敌走到
    -- 兜底分支时，zoneMapID 为 nil，回落到 parent——2348 的父正是 2255，同样是对的。
    local nemesisEntry = (static.kind == "nemesis") and static.wpMapID

    if poi and poi.x and poi.y then
        x, y = poi.x, poi.y
        waypointMapID = poi.zoneMapID or zone
    elseif static.wpX and static.wpY then
        x, y = static.wpX / 100, static.wpY / 100
        waypointMapID = static.wpMapID or zone
    end

    if nemesisEntry then
        waypointMapID = static.wpMapID
    end

    return {
        expansion = expansionKey,
        kind = static.kind or "normal",
        uiMapID = static.uiMapID,
        -- 排序要用：同一地图内的普通地下堡按 poiRegular 降序（用户 2026-10-28）。
        poiRegular = static.poiRegular,
        name = Scanner:GetMapName(static.uiMapID) or (poi and poi.name) or tostring(static.uiMapID),
        zoneMapID = zone,
        zoneName = Scanner:GetMapName(zone),
        bountiful = poi and poi.bountiful or false,
        storyVariant = poi and poi.storyVariant or nil,
        waypointMapID = waypointMapID,
        x = x,
        y = y,
        achChest = static.achChest,
        achStory = static.achStory,
        achNemesis = static.achNemesis,
        season = static.season,
        bossKey = static.bossKey,
        -- DELVERS_CALL_QUESTS 按资料片分组（与 DELVES 同款），先取该资料片的表再查 uiMapID。
        callQuestID = Data.DELVERS_CALL_QUESTS
            and Data.DELVERS_CALL_QUESTS[expansionKey]
            and Data.DELVERS_CALL_QUESTS[expansionKey][static.uiMapID],
    }
end

--- 构建全部地下堡条目。顺序：地区倒序遍历，地区内按静态声明序（正序）。
function Scanner:BuildEntries()
    local entries = {}
    local emitted = {}

    for _, expansionKey in ipairs(Data.EXPANSION_ORDER) do
        local statics = Data.DELVES[expansionKey] or {}
        local zones = Scanner:GetZoneMapIDsOrdered(expansionKey)
        local zonePOIs = {}
        for _, zoneMapID in ipairs(zones) do
            zonePOIs[zoneMapID] = { CollectZonePOIs(zoneMapID) }
        end

        -- 0) 归属地图匹配：必须单独跑完一遍，再进下面的循环。
        --    ⚠ 区域是倒序遍历的（GetZoneMapIDsOrdered 对种子表倒序），银月城(2393)
        --    排在永歌森林(2395) 后面，而银月城又是永歌森林的子图——黑暗回廊与学府骚动
        --    的 POI 在两张图上都能看到。这一步若和下面的 POI 兜底处在同一层循环，
        --    它们会在遍历到永歌森林时就被抢走，归属成永歌森林（用户 2026-10-28 实测）。
        for _, zoneMapID in ipairs(zones) do
            local byDelveMap, byPoiID = zonePOIs[zoneMapID][1], zonePOIs[zoneMapID][2]
            for _, static in ipairs(statics) do
                if not emitted[static.uiMapID] and ResolveZoneMapID(static.uiMapID) == zoneMapID then
                    local poi = FindPOI(static, byDelveMap, byPoiID) or FindNemesisPOI(static)
                    emitted[static.uiMapID] = true
                    entries[#entries + 1] = MakeEntry(expansionKey, static, poi, zoneMapID)
                end
            end
        end

        for _, zoneMapID in ipairs(zones) do
            local byDelveMap, byPoiID, extras = zonePOIs[zoneMapID][1], zonePOIs[zoneMapID][2], zonePOIs[zoneMapID][3]

            -- 1) 静态条目：所在地区等于当前区域的，按声明序（正序）加入。
            for _, static in ipairs(statics) do
                if not emitted[static.uiMapID] and Scanner:GetParentMapID(static.uiMapID) == zoneMapID then
                    local poi = FindPOI(static, byDelveMap, byPoiID) or FindNemesisPOI(static)
                    emitted[static.uiMapID] = true
                    entries[#entries + 1] = MakeEntry(expansionKey, static, poi, zoneMapID)
                end
            end

            -- 2) 静态条目：POI 出现在当前区域但所在地区不同的（子区域等）。
            for _, static in ipairs(statics) do
                if not emitted[static.uiMapID] then
                    local poi = FindPOI(static, byDelveMap, byPoiID)
                    if poi then
                        emitted[static.uiMapID] = true
                        entries[#entries + 1] = MakeEntry(expansionKey, static, poi, zoneMapID)
                    end
                end
            end

            -- 3) 静态表里没有的新地下堡（未来新增），按 POI 信息加入。
            for _, poi in ipairs(extras) do
                local known = false
                for _, static in ipairs(statics) do
                    if static.uiMapID == poi.linkedUiMapID
                        or static.poiRegular == poi.poiID
                        or static.poiBountiful == poi.poiID then
                        known = true
                        break
                    end
                end
                if not known then
                    local pseudo = { uiMapID = poi.linkedUiMapID, kind = "normal", poiRegular = poi.poiID }
                    local key = poi.linkedUiMapID or poi.poiID
                    if not emitted[key] then
                        emitted[key] = true
                        entries[#entries + 1] = MakeEntry(expansionKey, pseudo, poi, zoneMapID)
                    end
                end
            end
        end

        -- 4) 完全没被任何区域命中的静态条目（宿敌等）：用兜底坐标补在末尾。
        for _, static in ipairs(statics) do
            if not emitted[static.uiMapID] then
                emitted[static.uiMapID] = true
                entries[#entries + 1] = MakeEntry(expansionKey, static, nil, nil)
            end
        end
    end

    return entries
end

--- 迷宫与仪式站点：两者都不在 DELVES_CONFIG 里，单独扫描。
function Scanner:BuildSpecialEntries()
    local entries = {}

    -- 迷宫：按资料片遍历 Data.LABYRINTHS（表结构与 DELVES / ABUNDANCE 一致，
    -- 资料片由表的 key 决定，不再单设 LABYRINTH_EXPANSION）。
    for expansionKey, zoneMap in pairs(Data.LABYRINTHS or {}) do
        for _, zoneMapID in ipairs(Scanner:GetZoneMapIDsOrdered(expansionKey)) do
            local poiIDs = zoneMap[zoneMapID]
            if poiIDs then
                -- 同一区域内的两个 POI 可能指向同一座迷宫（9035/9036 同名），按名字去重。
                local seen = {}
                for _, poiID in ipairs(poiIDs) do
                    local ok, info = pcall(C_AreaPoiInfo.GetAreaPOIInfo, zoneMapID, poiID)
                    local name = ok and info and info.name
                    if name and name ~= "" and not seen[name] then
                        seen[name] = true
                        local entry = {
                            expansion = expansionKey,
                            kind = "labyrinth",
                            uiMapID = info.linkedUiMapID,
                            name = name,
                            zoneMapID = zoneMapID,
                            zoneName = Scanner:GetMapName(zoneMapID),
                            bountiful = false,
                            storyVariant = nil,
                            waypointMapID = zoneMapID,
                        }
                        if info.position and info.position.GetXY then
                            entry.x, entry.y = info.position:GetXY()
                        end
                        entries[#entries + 1] = entry
                    end
                end
            end
        end
    end

    -- 第二阶段 9.2：仪式场地两个都显示。激活的用 API 数据；未激活的 GetAreaPOIInfo
    -- 取不到，用静态兜底名称与坐标（Data.RITUAL_STATIC）。判定照 DFCN_DelveHelper：
    -- 只有 poiInfo 与 poiInfo.name 都有才算激活（分组标题本身就叫 ACTIVE_RITUAL_SITE）。
    -- 固定显示顺序走 Data.RITUAL_SITE_ORDER（永歌森林 → 祖阿曼）。
    for expansionKey, zoneMap in pairs(Data.RITUAL_SITES or {}) do
        local statics = Data.RITUAL_STATIC and Data.RITUAL_STATIC[expansionKey]
        for _, zoneMapID in ipairs((Data.RITUAL_SITE_ORDER and Data.RITUAL_SITE_ORDER[expansionKey]) or {}) do
            local poiIDs = zoneMap[zoneMapID]
            if poiIDs then
                for _, poiID in ipairs(poiIDs) do
                    local ok, info = pcall(C_AreaPoiInfo.GetAreaPOIInfo, zoneMapID, poiID)
                    local active = ok and info and info.name and info.name ~= ""
                    local static = statics and statics[poiID]
                    local name, x, y
                    if active then
                        name = info.name
                        if info.position and info.position.GetXY then
                            x, y = info.position:GetXY()
                        end
                    elseif static then
                        -- 未激活：静态兜底名称（locale）+ 坐标，功能不降级。
                        name = (L and L[static.nameKey]) or tostring(zoneMapID)
                        x, y = static.x, static.y
                    end
                    if name then
                        entries[#entries + 1] = {
                            expansion = expansionKey,
                            kind = "ritual",
                            uiMapID = nil,
                            name = name,
                            zoneMapID = zoneMapID,
                            zoneName = Scanner:GetMapName(zoneMapID),
                            bountiful = false,
                            storyVariant = nil,
                            waypointMapID = zoneMapID,
                            ritualActive = active,
                            x = x, y = y,
                        }
                    end
                end
            end
        end
    end

    -- 第二阶段 9.3：丰饶收获区域。按资料片遍历 Data.ABUNDANCE（组 A POI 8525-8528）。
    -- 名称走 locale、专业走专业 ID；坐标优先 API，取不到用静态兜底 wpX/wpY——
    -- 非「丰饶收获」状态时地图不渲染该 POI，拿不到坐标会让右键设路径点失败。
    for expansionKey, zones in pairs(Data.ABUNDANCE or {}) do
        for _, zone in ipairs(zones) do
            local ok, info = pcall(C_AreaPoiInfo.GetAreaPOIInfo, zone.mapID, zone.poi)
            local active, x, y = false, nil, nil
            if ok and info and info.name then
                active = (info.atlasName == "UI-EventPoi-abundancebountiful") or (info.isCurrentEvent == true)
                if info.position and info.position.GetXY then
                    x, y = info.position:GetXY()
                end
            end
            -- 静态兜底：POI 取不到时也要有坐标，保证路径点可用。
            if (not x or not y) and zone.wpX and zone.wpY then
                x, y = zone.wpX / 100, zone.wpY / 100
            end
            local entry = {
                expansion = expansionKey,
                kind = "abundance",
                uiMapID = zone.mapID,
                poiID = zone.poi,
                name = (L and L[zone.nameKey]) or tostring(zone.mapID),
                zoneMapID = zone.mapID,
                zoneName = Scanner:GetMapName(zone.mapID),
                bountiful = false,
                storyVariant = nil,
                waypointMapID = zone.mapID,
                abundanceActive = active,
                professions = zone.professions,
                x = x, y = y,
            }
            -- 剩余时间：优先 API（9.3.5），失败留 nil。
            if ok and info then
                local ok2, secs = pcall(C_AreaPoiInfo.GetAreaPOISecondsLeft, zone.poi)
                entry.timeLeft = (ok2 and secs and secs > 0) and secs or nil
            end
            entries[#entries + 1] = entry
        end
    end

    return entries
end

function Scanner:Invalidate()
    Scanner.entries = nil
    Scanner.entriesAt = 0
    Scanner.zoneCache = {}
end

function Scanner:GetEntries()
    local now = GetTime and GetTime() or 0
    if Scanner.entries and Scanner.entriesAt > 0 and (now - Scanner.entriesAt) <= CACHE_TTL then
        return Scanner.entries
    end

    local entries = Scanner:BuildEntries()
    for _, entry in ipairs(Scanner:BuildSpecialEntries()) do
        entries[#entries + 1] = entry
    end

    Scanner.entries = entries
    Scanner.entriesAt = now
    return entries
end
