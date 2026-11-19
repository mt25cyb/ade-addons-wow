local _, addon = ...
addon.RosterWindow = addon.RosterWindow or {}
local Window = addon.RosterWindow
local L = addon.L

-- 角色统计窗口：EverythingDelves UI/TabRoster.lua 的简化版，数据为账号级累积快照。

-- 原先只有一列「角色」（名字-服务器）；现已拆成「名字 / 服务器 / 阵营」三列
-- （用户 2026-10-29），末尾再加一列可选的「上次登录时间」。
-- optional 列的显示由 addon.db.rosterShowLastLogin 控制，默认关闭。
local COLUMNS = {
    { key = "name", label = "ROSTER_COL_NAME", width = 130 },
    { key = "realm", label = "ROSTER_COL_REALM", width = 110 },
    { key = "faction", label = "ROSTER_COL_FACTION", width = 80 },
    { key = "ilvl", label = "ROSTER_COL_ILVL", width = 45 },
    { key = "keys", label = "ROSTER_COL_KEYS", width = 45 },
    { key = "shards", label = "ROSTER_COL_SHARDS", width = 45 },
    { key = "wkshards", label = "ROSTER_COL_WKSHARDS", width = 70 },
    { key = "bounty", label = "ROSTER_COL_BOUNTY", width = 45 },
    { key = "vault", label = "ROSTER_COL_VAULT", width = 55 },
    { key = "gilded", label = "ROSTER_COL_GILDED", width = 55 },
    { key = "weekly", label = "ROSTER_COL_WEEKLY", width = 50 },
    { key = "lastSeen", label = "ROSTER_COL_LAST_SEEN", width = 130, optional = true },
}

local ROW_HEIGHT = 22
local GROUP_HEIGHT = 24
local WINDOW_WIDTH = 960
local WINDOW_HEIGHT = 560
local CONTENT_LEFT = 14
-- 行尾删除按钮：图集 SCRAP-deactivated 原始 32x32、悬停 SCRAP-activated 原始 42x42，
-- 这里按行高缩到 18/24。右侧多留一段给它，列区只占剩下的宽度。
local DELETE_SIZE = 18
local DELETE_HIGHLIGHT_SIZE = 24
local CONTENT_RIGHT = 28 + DELETE_SIZE + 8

local function ShowLastLogin()
    return addon.db and addon.db.rosterShowLastLogin == true
end

-- 分组方式（用户 2026-10-29）：none 不分组 / realm 按服务器 / faction 按阵营。
-- 放在 ActiveColumns 之前：列的可见性也由它决定。
local function GroupMode()
    local mode = addon.db and addon.db.rosterGrouping
    if mode ~= "none" and mode ~= "faction" then mode = "realm" end
    return mode
end

--- 当前生效的列。两种情况会改变列集合，行/表头都要按它重排：
--- ①「上次登录时间」开关；②分组方式——按服务器分组时服务器已写在分组标题上，
--- 按阵营分组时阵营已写在分组标题上，对应的列就不再重复显示（用户 2026-10-29）。
--- 每项额外带上它在 COLUMNS 里的下标，供行/表头取对应的 cell（中间列可能被跳过）。
local function ActiveColumns()
    local list = {}
    local showLogin = ShowLastLogin()
    local mode = GroupMode()
    for index, column in ipairs(COLUMNS) do
        column.index = index
        local skip = false
        if column.optional and not showLogin then
            skip = true -- 「上次登录时间」关闭
        elseif mode == "realm" and column.key == "realm" then
            skip = true -- 服务器已作为分组标题
        elseif mode == "faction" and column.key == "faction" then
            skip = true -- 阵营已作为分组标题
        end
        if not skip then list[#list + 1] = column end
    end
    return list
end

---「名字」列吃掉其它列之外的剩余宽度，用来容纳职业图标 + 长角色名。
local function NameColumnWidth(columns)
    columns = columns or ActiveColumns()
    local fixed = 0
    for _, column in ipairs(columns) do
        if column.key ~= "name" then fixed = fixed + column.width end
    end
    return math.max(180, WINDOW_WIDTH - CONTENT_LEFT - CONTENT_RIGHT - fixed)
end

local function ColumnWidth(column, columns)
    if column.key == "name" then return NameColumnWidth(columns) end
    return column.width
end

local frame, rows, emptyText, headers, groupRows

local function CellText(row, index)
    local cell = row:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    cell:SetJustifyH("LEFT")
    row.cells[index] = cell
    return cell
end

local function Build()
    if frame then return frame end

    frame = CreateFrame("Frame", "ADEDelveTabRosterWindow", UIParent, "BasicFrameTemplate")
    frame:SetSize(WINDOW_WIDTH, WINDOW_HEIGHT)
    frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    -- 提到世界地图界面之上：BasicFrameTemplate 默认 MEDIUM，世界地图是 FULLSCREEN 层，
    -- 导致窗口被地图盖住、要关地图才能看（用户 2026-10-28）。DIALOG 高于 FULLSCREEN。
    frame:SetFrameStrata("DIALOG")
    frame:SetMovable(true)
    frame:SetClampedToScreen(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", function(self) self:StartMoving() end)
    frame:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)
    frame.TitleText:SetText(L["ROSTER_TITLE"])
    frame:Hide()

    local scroll = CreateFrame("ScrollFrame", nil, frame, "ScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", frame, "TOPLEFT", 12, -58)
    scroll:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -28, 12)
    local content = CreateFrame("Frame", nil, scroll)
    content:SetSize(1, 1)
    scroll:SetScrollChild(content)
    frame.Content = content

    -- 表头按最大列数一次建好，位置/文本由 RefreshHeaders 重排，
    -- 这样切换「上次登录时间」开关时不必重建 frame。
    headers = {}
    for index = 1, #COLUMNS do
        local header = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        header:SetJustifyH("LEFT")
        header:SetTextColor(1, 0.82, 0)
        headers[index] = header
    end
    groupRows = {}

    rows = {}
    emptyText = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    emptyText:SetPoint("CENTER", frame, "CENTER", 0, 0)
    emptyText:SetText(L["ROSTER_NO_DATA"])
    emptyText:SetTextColor(0.7, 0.7, 0.7)
    emptyText:Hide()

    frame:HookScript("OnShow", function() Window:Refresh() end)
    return frame
end

--- 按当前生效的列重排表头（列数随「上次登录时间」开关变化）。
local function RefreshHeaders(columns)
    local offsetX = 0
    for index, column in ipairs(columns) do
        local width = ColumnWidth(column, columns)
        local header = headers[index]
        header:ClearAllPoints()
        header:SetPoint("TOPLEFT", frame, "TOPLEFT", CONTENT_LEFT + offsetX, -38)
        header:SetWidth(width)
        header:SetText(L[column.label] or column.key)
        -- 对齐（用户 2026-10-29）：名字列左对齐、上次登录时间右对齐，其余居中。
        header:SetJustifyH(column.key == "name" and "LEFT"
            or column.key == "lastSeen" and "RIGHT" or "CENTER")
        header:Show()
        offsetX = offsetX + width
    end
    for index = #columns + 1, #headers do
        headers[index]:Hide()
    end
end

-------------------------------------------------------------------------------
-- 图标与格式化
-------------------------------------------------------------------------------

-- 职业图标照 Altoholic（z-ref_addons_retail/Altoholic/Templates/ClassIcon.lua:180-181）：
-- 用 CharacterCreate 那张职业大图 + CLASS_ICON_TCOORDS[class] 取坐标。
local function ApplyClassIcon(texture, class)
    if not texture then return end
    local coords = class and CLASS_ICON_TCOORDS and CLASS_ICON_TCOORDS[class]
    if not coords then
        texture:Hide()
        return
    end
    texture:SetTexture("Interface\\Glues\\CharacterCreate\\UI-CharacterCreate-Classes")
    texture:SetTexCoord(coords[1], coords[2], coords[3], coords[4])
    texture:Show()
end

-- 阵营徽记 atlas 取自 Blizzard 原生用法：Battle for Azeroth 任务选择里就是这两个
-- （Blizzard_AdventureMap/AM_QuestChoiceDataProvider.lua:86,93 实证 QuestPortraitIcon-*）。
local FACTION_ATLAS = {
    Alliance = "QuestPortraitIcon-Alliance-small",
    Horde = "QuestPortraitIcon-Horde-small",
}

-- 阵营列 = {阵营图标}{联盟|部落}。文字用 Blizzard 全局量 FACTION_ALLIANCE / FACTION_HORDE，
-- 跟着客户端语言走（Blizzard_CharacterCreate.lua 同款用法）。
local function FactionLabel(rec)
    if not rec then return "-" end
    if rec.faction == "Alliance" then
        return "|A:" .. FACTION_ATLAS.Alliance .. ":14:14:0:0|a " .. (FACTION_ALLIANCE or "Alliance")
    end
    if rec.faction == "Horde" then
        return "|A:" .. FACTION_ATLAS.Horde .. ":14:14:0:0|a " .. (FACTION_HORDE or "Horde")
    end
    return "-"
end

--- 上次登录时间（= 该角色快照的采集时间）。
--- 格式：{YYYY-MM-DD} / {YYYY-MM-DD HH:MM} / {YYYY-MM-DD HH:MM:SS}，另有 MM/DD/YYYY（美式）
--- 与 DD/MM/YYYY（欧式）两种习惯写法；12 小时制时追加 AM/PM。
local function FormatLastLogin(rec)
    local stamp = rec and rec.updated
    if not stamp then return "-" end
    local info = date("*t", stamp)
    if not info then return "-" end
    local style = (addon.db and addon.db.rosterTimeFormat) or "ymd"
    local hour, suffix = info.hour, ""
    if addon.db and addon.db.rosterTime24 == false then
        hour = info.hour % 12
        if hour == 0 then hour = 12 end
        suffix = (info.hour < 12) and (L["TIME_AM"] or "AM") or (L["TIME_PM"] or "PM")
    end
    local ymd = string.format("%04d-%02d-%02d", info.year, info.month, info.day)
    local hm = string.format("%02d:%02d%s", hour, info.min, suffix)
    local hms = string.format("%02d:%02d:%02d%s", hour, info.min, info.sec, suffix)
    if style == "ymd_hm" then return ymd .. " " .. hm end
    if style == "ymd_hms" then return ymd .. " " .. hms end
    if style == "mdy" then return string.format("%02d/%02d/%04d", info.month, info.day, info.year) end
    if style == "mdy_hm" then return string.format("%02d/%02d/%04d %s", info.month, info.day, info.year, hm) end
    if style == "dmy" then return string.format("%02d/%02d/%04d", info.day, info.month, info.year) end
    if style == "dmy_hm" then return string.format("%02d/%02d/%04d %s", info.day, info.month, info.year, hm) end
    return ymd -- "ymd" 默认：{YYYY-MM-DD}
end

-------------------------------------------------------------------------------
-- 排序与分组
-------------------------------------------------------------------------------

--- 三级排序（用户 2026-10-29）：
--- ①服务器──当前角色所在服务器排在最前；②阵营──当前角色所属阵营优先；
--- ③上次登录时间从新到旧。当前角色的 updated 本来就是最新的，自然落在队首。
local function SortRecords(list, currentRealm, currentFaction)
    table.sort(list, function(a, b)
        local rankA = (a.realm == currentRealm) and 0 or 1
        local rankB = (b.realm == currentRealm) and 0 or 1
        if rankA ~= rankB then return rankA < rankB end
        local factionA = (a.faction == currentFaction) and 0 or 1
        local factionB = (b.faction == currentFaction) and 0 or 1
        if factionA ~= factionB then return factionA < factionB end
        return (a.updated or 0) > (b.updated or 0)
    end)
end

-- 折叠状态只在本会话保留，不落盘。
local collapsed = {}

local function GroupKeyOf(rec)
    local mode = GroupMode()
    if mode == "realm" then return rec.realm or "" end
    if mode == "faction" then return rec.faction or "" end
    return nil
end

--- 分组标题的文字。第二阶段 9.1.3：不再本地化阵营名，直接返回 token（"Alliance"/"Horde"），
--- 阵营区分交给前面的阵营图标（QuestPortraitIcon-*-small），避免多语言包缺译。
local function GroupTitle(key)
    if key == nil or key == "" then return "-" end
    return key
end

--- 相对时间：EverythingDelves 的 FormatAgo 简化版（只到天）。
local function FormatAgo(seconds)
    if not seconds or seconds < 0 then seconds = 0 end
    if seconds < 60 then return string.format(L["TIME_SECONDS"], seconds) end
    if seconds < 3600 then return string.format(L["TIME_MINUTES"], math.floor(seconds / 60)) end
    if seconds < 86400 then return string.format(L["TIME_HOURS"], math.floor(seconds / 3600)) end
    return string.format(L["TIME_DAYS"], math.floor(seconds / 86400))
end

--- 行 tooltip：照 EverythingDelves UI/TabRoster.lua:79-101 的 TipLines 字段顺序。
local function RowTooltip(row)
    local rec = row.rec
    if not rec then return end
    GameTooltip:SetOwner(row, "ANCHOR_RIGHT")
    local name = rec.name or rec.key or "?"
    local realm = (rec.realm and rec.realm ~= "") and (" - " .. rec.realm) or ""
    GameTooltip:SetText(name .. realm, 1, 0.82, 0)
    GameTooltip:AddLine(string.format(L["ROSTER_TIP_ILVL"], tostring(rec.ilvl or "?")), 1, 1, 1)
    GameTooltip:AddLine(string.format(L["ROSTER_TIP_KEYS_SHARDS"], rec.keys or 0, rec.shards or 0), 1, 1, 1)
    GameTooltip:AddLine(string.format(L["ROSTER_TIP_BOUNTY"], rec.bountyMaps or 0), 1, 1, 1)
    if (rec.shardsMaxWeek or 0) > 0 then
        GameTooltip:AddLine(string.format(L["ROSTER_TIP_WEEK_SHARDS"],
            rec.shardsEarnedWeek or 0, rec.shardsMaxWeek or 0), 1, 1, 1)
    end
    GameTooltip:AddLine(string.format(L["ROSTER_TIP_VAULT"],
        rec.vaultProgress or 0, rec.vaultTotal or 0, rec.vaultSlots or 0), 1, 1, 1)
    if rec.gildedTotal then
        GameTooltip:AddLine(string.format(L["ROSTER_TIP_GILDED"],
            rec.gildedCollected or 0, rec.gildedTotal), 1, 1, 1)
    end
    GameTooltip:AddLine(string.format(L["ROSTER_TIP_WEEKLY"],
        rec.weeklyQuestDone and L["PROGRESS_DONE"] or L["PROGRESS_PENDING"]), 1, 1, 1)
    if rec.updated then
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine(string.format(L["ROSTER_TIP_UPDATED"],
            FormatAgo(time() - rec.updated)), 0.7, 0.7, 0.7)
    end
    GameTooltip:Show()
end

local function EnsureRow(index)
    local row = rows[index]
    if row then return row end
    row = CreateFrame("Frame", nil, frame.Content)
    row:SetHeight(ROW_HEIGHT)

    -- 错行异色背景（斑马纹），颜色在 Refresh 里按行序设置。
    local background = row:CreateTexture(nil, "BACKGROUND")
    background:SetAllPoints(row)
    row.Background = background

    row.cells = {}
    -- cell 的下标始终对应 COLUMNS 的下标（可选列在末尾），位置/宽度在 Refresh 里按当前
    -- 生效的列重排，这样切换「上次登录时间」开关不必重建行。
    for cellIndex, column in ipairs(COLUMNS) do
        if column.key == "name" then
            -- 名字列不是纯文本：职业图标 + 角色名（职业色）+ 当前角色绿点。
            local holder = CreateFrame("Frame", nil, row)
            holder:SetHeight(ROW_HEIGHT)
            local icon = holder:CreateTexture(nil, "ARTWORK")
            icon:SetPoint("LEFT", holder, "LEFT", 0, 0)
            icon:SetSize(16, 16)
            icon:Hide()
            local text = holder:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
            text:SetPoint("LEFT", icon, "RIGHT", 3, 0)
            text:SetJustifyH("LEFT")
            -- 「(当前角色)」的文字改成绿点，同样依附在角色名之后。
            -- 用户建议的 "PlayerFriend" 在本机全库检索中查无此名（0 命中），改用 Blizzard
            -- 真实的在线绿点 Interface\FriendsFrame\StatusIcon-Online
            -- （Blizzard_RecentAlliesTemplates.lua 实证返回的就是它）。
            local dot = holder:CreateTexture(nil, "ARTWORK")
            dot:SetPoint("LEFT", text, "RIGHT", 3, 0)
            dot:SetSize(10, 10)
            dot:SetTexture("Interface\\FriendsFrame\\StatusIcon-Online")
            dot:Hide()
            holder.Icon, holder.Text, holder.Dot = icon, text, dot
            row.cells[cellIndex] = holder
        else
            row.cells[cellIndex] = CellText(row, cellIndex)
        end
    end

    -- 行尾删除按钮（用户 2026-10-29）：删掉这一条角色快照。
    -- 两个 atlas 由用户确认存在：常规 SCRAP-deactivated（32x32）、悬停 SCRAP-activated（42x42）。
    local delete = CreateFrame("Button", nil, row)
    delete:SetSize(DELETE_SIZE, DELETE_SIZE)
    delete:SetPoint("LEFT", row, "RIGHT", 4, 0)
    local deleteIcon = delete:CreateTexture(nil, "ARTWORK")
    deleteIcon:SetAtlas("SCRAP-deactivated", false)
    deleteIcon:SetAllPoints(delete)
    local deleteHighlight = delete:CreateTexture(nil, "HIGHLIGHT")
    deleteHighlight:SetAtlas("SCRAP-activated", false)
    deleteHighlight:SetSize(DELETE_HIGHLIGHT_SIZE, DELETE_HIGHLIGHT_SIZE)
    deleteHighlight:SetPoint("CENTER", 0, 0)
    delete:SetScript("OnClick", function(self)
        local data = self:GetParent().rec
        if not (data and data.key) then return end
        if addon.db and type(addon.db.roster) == "table" then
            addon.db.roster[data.key] = nil
        end
        Window:Refresh()
    end)
    delete:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(L["ROSTER_DELETE"] or "Remove character", 1, 1, 1)
        GameTooltip:Show()
    end)
    delete:SetScript("OnLeave", function() GameTooltip:Hide() end)
    row.Delete = delete

    row:EnableMouse(true)
    row:SetScript("OnEnter", RowTooltip)
    row:SetScript("OnLeave", function() GameTooltip:Hide() end)
    rows[index] = row
    return row
end

--- 分组头：照清单行的可折叠标题（展开/收起图集沿用 DelveEntry 已在用的
--- ui-questtrackerbutton-secondary-collapse / -expand，本文件无需另找资源）。
--- 折叠状态存窗口本地表，不落盘。
local function EnsureGroupRow(index)
    local row = groupRows[index]
    if row then return row end
    row = CreateFrame("Button", nil, frame.Content)
    row:SetHeight(GROUP_HEIGHT)

    -- 分组行不画背景（用户 2026-10-29）。

    -- 折叠按钮放在分组左侧，标题紧跟在它后面（用户 2026-10-29）。
    local expand = row:CreateTexture(nil, "ARTWORK")
    expand:SetSize(12, 12)
    expand:SetPoint("LEFT", row, "LEFT", 4, 0)
    row.Expand = expand

    -- 第二阶段 9.1.3：阵营图标（联盟/部落），非阵营分组时隐藏、标题贴回折叠键。
    local icon = row:CreateTexture(nil, "ARTWORK")
    icon:SetSize(16, 16)
    icon:SetPoint("LEFT", expand, "RIGHT", 4, 0)
    icon:Hide()
    row.Icon = icon

    local title = row:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    title:SetPoint("LEFT", icon, "RIGHT", 4, 0)
    title:SetJustifyH("LEFT")
    title:SetTextColor(1, 0.82, 0)
    row.Title = title

    local count = row:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    count:SetPoint("LEFT", title, "RIGHT", 6, 0)
    row.Count = count

    row:SetScript("OnClick", function(self)
        collapsed[self.groupKey] = not collapsed[self.groupKey]
        Window:Refresh()
    end)
    groupRows[index] = row
    return row
end

local function FormatWeekly(rec)
    if rec.weeklyQuestDone then return "|cff00ff00" .. L["PROGRESS_DONE"] .. "|r" end
    return "|cff999999-|r"
end

local function FormatVault(rec)
    if not rec.vaultTotal or rec.vaultTotal == 0 then return "-" end
    return string.format("%d/%d", rec.vaultProgress or 0, rec.vaultTotal)
end

local function FormatShardsWeek(rec)
    local earned = rec.shardsEarnedWeek or 0
    local max = rec.shardsMaxWeek or 0
    if max > 0 then return string.format("%d/%d", earned, max) end
    return tostring(earned)
end

local function FormatGilded(rec)
    if rec.gildedCollected and rec.gildedTotal then
        return string.format("%d/%d", rec.gildedCollected, rec.gildedTotal)
    end
    return "-"
end

function Window:Refresh()
    Build()
    local data = addon.Roster:GetAll()
    local currentKey = addon.Roster:GetCurrentKey()

    -- 列会随「上次登录时间」开关增减，每次刷新都按当前生效的列重排表头与行。
    local columns = ActiveColumns()
    RefreshHeaders(columns)

    for _, row in ipairs(rows) do row:Hide() end
    for _, row in ipairs(groupRows) do row:Hide() end

    if #data == 0 then
        emptyText:Show()
        frame.Content:SetSize(1, 1)
        return
    end
    emptyText:Hide()

    -- 「服务器优先 / 阵营优先」都以当前角色为基准，先把它找出来。
    local currentRec
    for _, rec in ipairs(data) do
        if rec.key == currentKey then currentRec = rec break end
    end
    local currentRealm = currentRec and currentRec.realm or (GetRealmName and GetRealmName())
    local currentFaction = currentRec and currentRec.faction or (UnitFactionGroup and UnitFactionGroup("player"))

    SortRecords(data, currentRealm, currentFaction)

    local mode = GroupMode()
    -- 分组人数：先数一遍，便于在分组头右侧显示。
    local groupCounts = {}
    if mode ~= "none" then
        for _, rec in ipairs(data) do
            local key = GroupKeyOf(rec)
            groupCounts[key] = (groupCounts[key] or 0) + 1
        end
    end

    local offset = 0
    local rowIndex, groupIndex, visibleRow = 0, 0, 0
    local lastGroupKey, groupOpen = nil, true

    for _, rec in ipairs(data) do
        local groupKey = GroupKeyOf(rec)
        if mode ~= "none" and groupKey ~= lastGroupKey then
            groupIndex = groupIndex + 1
            local grow = EnsureGroupRow(groupIndex)
            grow.groupKey = groupKey
            grow.Title:SetText(GroupTitle(groupKey))
            grow.Count:SetText(string.format("(%d)", groupCounts[groupKey] or 0))
            local isCollapsed = collapsed[groupKey] == true
            grow.Expand:SetAtlas(isCollapsed and "ui-questtrackerbutton-secondary-expand"
                or "ui-questtrackerbutton-secondary-collapse", true)
            -- 第二阶段 9.1.3：阵营分组加阵营图标，标题随之右移；其他分组隐藏图标、标题贴回折叠键。
            if mode == "faction" and groupKey == "Alliance" then
                grow.Icon:SetAtlas("QuestPortraitIcon-Alliance-small", false)
                grow.Icon:Show()
                grow.Title:ClearAllPoints()
                grow.Title:SetPoint("LEFT", grow.Icon, "RIGHT", 4, 0)
            elseif mode == "faction" and groupKey == "Horde" then
                grow.Icon:SetAtlas("QuestPortraitIcon-Horde-small", false)
                grow.Icon:Show()
                grow.Title:ClearAllPoints()
                grow.Title:SetPoint("LEFT", grow.Icon, "RIGHT", 4, 0)
            else
                grow.Icon:Hide()
                grow.Title:ClearAllPoints()
                grow.Title:SetPoint("LEFT", grow.Expand, "RIGHT", 4, 0)
            end
            grow:SetPoint("TOPLEFT", frame.Content, "TOPLEFT", 0, -offset)
            grow:SetPoint("RIGHT", frame.Content, "RIGHT", 0, 0)
            grow:Show()
            offset = offset + GROUP_HEIGHT
            lastGroupKey = groupKey
            groupOpen = not isCollapsed
        end

        -- 折叠的分组整组跳过，只保留分组头。
        if groupOpen then
            visibleRow = visibleRow + 1
            rowIndex = rowIndex + 1
            local row = EnsureRow(rowIndex)
            row.rec = rec
            row:SetPoint("TOPLEFT", frame.Content, "TOPLEFT", 0, -offset)
            row:SetPoint("RIGHT", frame.Content, "RIGHT", 0, 0)
            row.Background:SetColorTexture(1, 1, 1, (visibleRow % 2 == 0) and 0.03 or 0.07)

            local nameText = rec.name or rec.key or "?"
            if rec.class and RAID_CLASS_COLORS and RAID_CLASS_COLORS[rec.class] then
                local color = RAID_CLASS_COLORS[rec.class]
                nameText = string.format("|cff%02x%02x%02x%s|r", color.r * 255, color.g * 255, color.b * 255, nameText)
            end

            local values = {
                realm = rec.realm or "-",
                faction = FactionLabel(rec),
                ilvl = tostring(rec.ilvl or "-"),
                keys = tostring(rec.keys or 0),
                shards = tostring(rec.shards or 0),
                wkshards = FormatShardsWeek(rec),
                bounty = tostring(rec.bountyMaps or 0),
                vault = FormatVault(rec),
                gilded = FormatGilded(rec),
                weekly = FormatWeekly(rec),
                lastSeen = FormatLastLogin(rec),
            }

            local cellOffset = 0
            local used = {}
            for _, column in ipairs(columns) do
                -- 用列在 COLUMNS 里的原始下标取 cell：中间的列可能被分组隐藏掉。
                local cellIndex = column.index
                used[cellIndex] = true
                local width = ColumnWidth(column, columns)
                local cell = row.cells[cellIndex]
                cell:ClearAllPoints()
                cell:SetPoint("LEFT", row, "LEFT", cellOffset, 0)
                cell:SetWidth(width)
                if column.key == "name" then
                    ApplyClassIcon(cell.Icon, rec.class)
                    cell.Text:SetText(nameText)
                    -- 当前角色：名字后面跟一个绿点，不再写「(当前角色)」。
                    cell.Dot:SetShown(rec.key == currentKey)
                else
                    cell:SetText(values[column.key] or "-")
                    -- 对齐（用户 2026-10-29）：上次登录时间右对齐，其余居中。
                    cell:SetJustifyH(column.key == "lastSeen" and "RIGHT" or "CENTER")
                end
                cell:Show()
                cellOffset = cellOffset + width
            end
            for cellIndex = 1, #row.cells do
                if not used[cellIndex] then row.cells[cellIndex]:Hide() end
            end

            row:Show()
            offset = offset + ROW_HEIGHT
        end
    end

    frame.Content:SetSize(WINDOW_WIDTH - CONTENT_LEFT - CONTENT_RIGHT, offset)
end

function Window:Toggle()
    Build()
    if frame:IsShown() then
        frame:Hide()
    else
        addon.Roster:Capture()
        Window:Refresh()
        frame:Show()
    end
end
