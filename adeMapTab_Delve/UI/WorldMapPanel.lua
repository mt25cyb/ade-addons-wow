local _, addon = ...
local L = addon.L
-- 地基（Tab / 内容框架 / 设置页骨架 / 刷新队列 / 生命周期）统一走主插件公共函数库。
local MapTab = LibStub("AdeMapTab-1.0")

-- 世界地图「地下堡」标签页。
-- 阅读顺序：刷新队列 -> 面板构建 -> TopBar -> 列表 -> 交互 -> 事件。
-- 布局参照 WorldQuestTab（TopBar / 设置按钮 / ScrollBox 条目），
-- 面板挂载方式参照 adePortalTab（LibWorldMapTabs + QuestMapFrame.ContentsAnchor）。

local f = CreateFrame("Frame")
local ICON_DELVE = "Interface\\icons\\ui_delves" -- 聊天行内图标用（|T 只认贴图路径，DFCN_DelveHelper.lua:4221 实证）
local TAB_ICON_ATLAS = "delves-bountiful" -- Tab 图集（用户指定：丰饶地下堡） 备用 majorfactions_icons_delve512

local panel, tabButton, topBar, scrollBox, scrollBar, view, searchBar

local settingsFrame, emptyText
local searchText = ""
local currentMode = "list" -- "list" | "settings"
-- 第二阶段 9.4.2：TopBar 临时类型下拉（面板级），默认「全部」。优先于过滤菜单的类型过滤，
-- 但资料片过滤仍生效。仅作会话/面板级状态，不落盘。
local panelTypeFilter = "all"

-- 默认标签页：WorldQuestTab 也提供同名功能，检测到就让位（同 adePortalTab）。
-- 判定逻辑已抽到主插件公共函数库，两个子插件共用同一份实现。
local function IsDefaultTabClaimedByOthers()
    return MapTab.IsDefaultTabClaimed()
end

function addon.MapPanel.IsDefaultTabClaimed()
    return IsDefaultTabClaimedByOthers()
end

-- 第二阶段 9.4.2：供 Catalog:IsVisible 读取 TopBar 临时类型下拉的当前选择。
function addon.MapPanel:GetTypeFilter()
    return panelTypeFilter
end

-- 刷新队列：合并短时间内的请求（同 adePortalTab UI/WorldMapPanel.lua:106-140）。
-- 一次性去抖交给主插件公共函数 MapTab.NewRefreshQueue，业务逻辑仍在本文件。
local QueueRefresh = MapTab.NewRefreshQueue(function() addon.MapPanel.Refresh() end)

local function IsPanelVisible()
    return panel and panel:IsShown()
end

-------------------------------------------------------------------------------
-- 交互：左键切图；右键设置路点（r003 重设计：统一委托 /way 命令的当前占用者）
-------------------------------------------------------------------------------

local function GetWaypointTarget(entry)
    if not entry then return nil, nil, nil end
    local mapID = entry.waypointMapID or entry.zoneMapID
    return mapID, entry.x, entry.y
end

-- ⚠ 这三个交互函数必须是**冒号**定义：DelveEntry.lua:445/447/451 是冒号调用。
-- 之前写成点号定义，冒号调用时 entry 形参收到的是 MapPanel 表本身，真正的 entry 被丢掉，
-- 于是左键静默无反应、右键与 Shift+右键都落到「不支持路点」分支（用户 2026-10-28 实测）。
function addon.MapPanel:ShowOnMap(entry)
    local mapID = GetWaypointTarget(entry)
    if not mapID then return end
    -- 12.x 打开世界地图用的是 OpenWorldMap(uiMapID)（MapDocumentation.lua:577-587，
    -- 参数 uiMapID 可空）。之前写的 ToggleMap 在 12.x 根本不存在（参考源里搜不到），
    -- 于是走到 ShowUIPanel 那条，左键点了没反应（用户 2026-10-28）。
    -- OpenWorldMap 带 HasRestrictions，受限时退回「先开地图再切图」。
    if OpenWorldMap then
        OpenWorldMap(mapID)
        return
    end
    if WorldMapFrame and WorldMapFrame.SetMapID then
        if not WorldMapFrame:IsShown() and ToggleWorldMap then
            ToggleWorldMap()
        end
        WorldMapFrame:SetMapID(mapID)
    end
end

--- 右键设置路点（r003 重设计）：不再硬编码「右键=原生 / Shift+右键=TomTom」，
--- 统一委托 /way 命令的当前占用者（Core.lua PLAYER_LOGIN 时确定 addon.MapPanel.WayRunner）：
--- MPE/TomTom 等占用 → 调对方 handler，等价执行 `/way #<mapID> x y <名称>`（支持名称）；
--- 未被占用 → 本插件实现（原生路点 + TomTom 同步 + 聊天反馈）。
--- 坐标折成百分数字符串与 HandleWayCommand 解析口径一致（>1 自动 /100）。
function addon.MapPanel:SetWaypointAt(entry)
    local mapID, x, y = GetWaypointTarget(entry)
    if not (mapID and x and y) or not addon.MapPanel.WayRunner then
        print("|T" .. ICON_DELVE .. ":14:14|t " .. (L["WAYPOINT_UNAVAILABLE"] or ""))
        return
    end
    local name = (entry.name or ""):gsub("[%c|]", "")  -- 名称进聊天/对方插件，去掉控制符与管道符防注入
    addon.MapPanel.WayRunner(string.format("#%d %.2f %.2f %s", mapID, x * 100, y * 100, name))
end

-------------------------------------------------------------------------------
-- TopBar：机器人按钮 / 战团按钮 / 过滤器 / 搜索框 / 搜索开关
-------------------------------------------------------------------------------

local function BuildFilterMenu(_, root)
    root:SetTag("MENU_ADE_DELVETAB_FILTERS")

    local expansion = root:CreateButton(L["FILTER_EXPANSION"])
    for _, key in ipairs({ "midnight", "tww" }) do
        local label = key == "midnight" and L["EXPANSION_MIDNIGHT"] or L["EXPANSION_TWW"]
        expansion:CreateCheckbox(label, function()
            return addon.Database.GetFilter("expansion", key)
        end, function()
            addon.Database.SetFilter("expansion", key, not addon.Database.GetFilter("expansion", key))
            QueueRefresh(0)
        end)
    end

    -- 第二阶段 9.4.1：类型过滤收敛为三类（地下堡 / 丰饶区域 / 仪式场地）。
    local kind = root:CreateButton(L["FILTER_TYPE"])
    local kinds = {
        { key = "delve", label = L["FILTER_TYPE_DELVE"] },
        { key = "abundance", label = L["FILTER_TYPE_ABUNDANCE"] },
        { key = "ritual", label = L["FILTER_TYPE_RITUAL"] },
    }
    for _, item in ipairs(kinds) do
        kind:CreateCheckbox(item.label, function()
            return addon.Database.GetFilter("kind", item.key)
        end, function()
            addon.Database.SetFilter("kind", item.key, not addon.Database.GetFilter("kind", item.key))
            QueueRefresh(0)
        end)
    end
end

local function EnsureTopBar(host)
    if topBar then return topBar end

    -- WQT 26px 顶栏容器（TOPLEFT 2,30 / TOPRIGHT -2,30）由主插件公共函数创建。
    -- 本面板边框是 +2，故顶栏层级取 +3（Portal 是 +4），与 v4 逐像素一致。
    -- 顶栏是面板内顶部 0~26 那一行，不是 Mapster 标题栏行，也不是内容区第一行。
    local bar = MapTab.CreateTopBar(host, { levelOffset = 3 })

    -- r003：机器人按钮（地下堡机器人 7001 型）从统计面板迁到顶栏最左（原战团按钮位置），
    -- 战团按钮及后续控件整体右移。外观走暴雪原生 UIPanelIconDropdownButtonTemplate
    -- （底板 + Icon parentKey + HIGHLIGHT 悬停，与右侧 roster 同款），
    -- SecureActionButton 走宏使用玩具（原 StatsPanel.lua:167-215 的实现精简迁移）。
    -- 模板顺序照 LibActionButton-1.0 的 "ActionButtonTemplate, SecureActionButtonTemplate"
    -- （z-ref_retail_Interface_AddOns/CooldownManagerCentered/libs/.../LibActionButton-1.0.lua:240）
    -- ：外观在前、Secure 在后，Secure 的宏 OnClick 最后 apply 必胜（同时覆盖 IconDropdown
    -- 模板可能自带的下拉 OnClick）；Background/Icon/HIGHLIGHT 纹理层保留。
    local toy = CreateFrame("Button", nil, bar, "UIPanelIconDropdownButtonTemplate, SecureActionButtonTemplate")
    toy:SetSize(22, 22)
    toy:SetPoint("LEFT", bar, "LEFT", 0, 0)
    toy:SetAttribute("type1", "macro")
    toy:SetAttribute("macrotext1", "/use item:" .. tostring(addon.Data.TOY.itemID))
    -- 12.x 实证（SecureTemplates.xml:4-10）：模板不自带 RegisterForClicks，必须显式注册。
    toy:RegisterForClicks("AnyDown", "AnyUp")
    local toyIcon = toy.Icon or toy:CreateTexture(nil, "ARTWORK")
    toyIcon:SetSize(18, 18)
    toyIcon:ClearAllPoints()
    toyIcon:SetPoint("CENTER", 0, 0)
    toyIcon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    toyIcon:SetTexture((C_Spell and C_Spell.GetSpellTexture and C_Spell.GetSpellTexture(addon.Data.TOY.spellID))
        or (C_Item and C_Item.GetItemIconByID and C_Item.GetItemIconByID(addon.Data.TOY.itemID))
        or "Interface\\Icons\\INV_Misc_QuestionMark")
    toy.Icon = toyIcon
    local toyMask = toy:CreateMaskTexture(nil, "ARTWORK")
    toyMask:SetTexture("Interface\\Common\\common-iconmask", "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
    toyMask:SetAllPoints(toyIcon)
    toyIcon:AddMaskTexture(toyMask)
    -- HIGHLIGHT：模板自带 questlog-icon-setting（齿轮）悬停图集（SharedUIPanelTemplates.xml:2241-2247），
    -- 照 roster（本文件 roster 段同逻辑）：遍历 regions 找到无 parentKey 的 HIGHLIGHT 层，
    -- 换成玩具图标纹理（同 TexCoord 裁边）、ADD 混合 + 0.4 透明度。
    for _, region in ipairs({ toy:GetRegions() }) do
        if region.GetDrawLayer and region:GetDrawLayer() == "HIGHLIGHT" and region ~= toyIcon then
            region:SetTexture(toyIcon:GetTexture())
            region:SetTexCoord(0.08, 0.92, 0.08, 0.92)
            region:SetAllPoints(toyIcon)
            region:SetBlendMode("ADD")
            region:SetAlpha(0.4)
        end
    end
    local toyCooldown = CreateFrame("Cooldown", nil, toy, "CooldownFrameTemplate")
    toyCooldown:SetAllPoints(toyIcon)
    toy.Cooldown = toyCooldown
    toy:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        -- SetItemByID 自带玩具名；信息未缓存时退到 API 名称（原 StatsPanel.lua:197-213 逻辑）。
        if not GameTooltip:SetItemByID(addon.Data.TOY.itemID) then
            local toyName
            if C_ToyBox and C_ToyBox.GetToyInfo then
                _, toyName = C_ToyBox.GetToyInfo(addon.Data.TOY.itemID)
            end
            if not toyName and C_Item and C_Item.GetItemNameByID then
                toyName = C_Item.GetItemNameByID(addon.Data.TOY.itemID)
            end
            if toyName then GameTooltip:SetText(toyName, 1, 0.82, 0) end
        end
        GameTooltip:Show()
    end)
    toy:SetScript("OnLeave", function() GameTooltip:Hide() end)
    bar.ToyButton = toy

    --- 冷却与持有态刷新（SPELL_UPDATE_COOLDOWN / NEW_TOY_ADDED 事件与按钮创建时调用）。
    function addon.MapPanel.UpdateToyButton()
        if not bar.ToyButton then return end
        local start, duration = addon.Stats:GetToyCooldown()
        if start and duration and duration > 0 then
            bar.ToyButton.Cooldown:SetCooldown(start, duration)
        else
            bar.ToyButton.Cooldown:Clear()
        end
        if addon.Stats:HasToy() then
            bar.ToyButton.Icon:SetVertexColor(1, 1, 1)
        else
            bar.ToyButton.Icon:SetVertexColor(0.4, 0.4, 0.4)
        end
    end
    addon.MapPanel.UpdateToyButton()

    -- 原 WorldQuestTab 的 SortDropdown（全局名 FML）位置改为「角色统计」；
    -- r003 起让出最左位，锚到机器人按钮右侧。
    local roster = CreateFrame("Button", nil, bar, "UIPanelIconDropdownButtonTemplate")
    roster:SetSize(22, 22)
    roster:SetPoint("LEFT", toy, "RIGHT", 6, 0)
    if roster.Icon then
        roster.Icon:SetAtlas("warbands-icon", true) -- WorldQuestTab.xml:294 实证
        roster.Icon:SetSize(18, 18)
        -- 模板的 HIGHLIGHT 层自带 questlog-icon-setting（齿轮）图集
        -- （SharedUIPanelTemplates.xml:2241-2247），只换 Icon 不够，悬停高亮仍是齿轮材质、
        -- 与 warbands 图标不匹配（用户 2026-10-28）。该纹理没有 parentKey，
        -- 遍历 regions 找到 HIGHLIGHT 层，换成同一图集并贴住 Icon（照齿轮做法：ADD 混合）。
        for _, region in ipairs({ roster:GetRegions() }) do
            if region.SetAtlas and region.GetDrawLayer and region:GetDrawLayer() == "HIGHLIGHT" then
                region:SetAtlas("warbands-icon", false)
                region:SetAllPoints(roster.Icon)
                region:SetBlendMode("ADD")
                region:SetAlpha(0.4)
            end
        end
    end
    roster:SetScript("OnClick", function()
        if addon.RosterWindow then addon.RosterWindow:Toggle() end
    end)
    roster:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(L["ROSTER_TITLE"], 1, 0.82, 0)
        GameTooltip:Show()
    end)
    roster:SetScript("OnLeave", function() GameTooltip:Hide() end)
    bar.RosterButton = roster

    -- 第二阶段 9.4.2：TopBar 临时类型下拉，置于战团按钮与过滤器之间。
    -- 单选：全部 / 地下堡 / 仪式场地 / 丰饶区域；默认「全部」。
    -- 语义上优先于过滤菜单里的类型过滤，但资料片过滤仍生效（Catalog:IsVisible）。
    local typeDropdown = CreateFrame("DropdownButton", nil, bar, "WowStyle1DropdownTemplate")
    -- 不要把高度压到 18：WowStyle1DropdownTemplate 原生 120x25，Text 用 TOP 锚定 -8、
    -- Arrow 锚 RIGHT -3（Blizzard_Menu/Mainline/MenuTemplates.xml:3-39），mainline mixin 无
    -- OnSizeChanged 重排，压矮会让文本偏上、箭头偏位（用户 2026-10-30 截图）。只改宽度。
    typeDropdown:SetWidth(110)
    typeDropdown:SetPoint("LEFT", roster, "RIGHT", 6, 0)
    typeDropdown:SetupMenu(function(_, root)
        for _, item in ipairs({
            { value = "all", text = "FILTER_DROPDOWN_ALL" },
            { value = "delve", text = "FILTER_DROPDOWN_DELVE" },
            { value = "ritual", text = "FILTER_DROPDOWN_RITUAL" },
            { value = "abundance", text = "FILTER_DROPDOWN_ABUNDANCE" },
        }) do
            root:CreateRadio(L[item.text] or item.value, function() return panelTypeFilter == item.value end,
                function()
                    if InCombatLockdown() then return end
                    panelTypeFilter = item.value
                    QueueRefresh(0)
                end)
        end
    end)
    typeDropdown:SetDefaultText(L["FILTER_DROPDOWN_ALL"] or "All")
    bar.TypeDropdown = typeDropdown

    local filter = CreateFrame("DropdownButton", nil, bar, "WowStyle1FilterDropdownTemplate")
    filter:SetSize(90, 18)
    filter:SetPoint("LEFT", typeDropdown, "RIGHT", 6, 0)
    filter:SetupMenu(BuildFilterMenu)
    bar.FilterDropdown = filter

    -- 搜索条纳入 TopBar（bar）内，与过滤器互斥替换（对齐 WQT UpdateTopBar，WorldQuestTab.lua:1461-1468）；
    -- 之前它是 host 顶部的独立整宽占位体，展开时落在内容区顶部，不符合「控件在顶栏」的要求（用户 2026-10-28）。
    -- 锚到 roster 右到 toggle 左之间，天然填充顶栏剩余空间。
    searchBar = CreateFrame("Frame", nil, bar)
    searchBar:SetHeight(20) -- 对齐 WQT SearchBox 的 Size y=20
    -- 左右锚 + 固定高度 → 在 TopBar 内垂直居中（TOPLEFT/BOTTOMRIGHT 双锚会与 SetHeight 冲突、把高度压扁）。
    searchBar:SetPoint("LEFT", typeDropdown, "RIGHT", 2, 0)
    searchBar:SetPoint("RIGHT", bar, "RIGHT", -2, 0) -- toggle 在下方才创建，创建后重设到其左侧
    searchBar:Hide()
    bar.SearchBar = searchBar

    -- 搜索栏铺满整行，对齐 adePT 的搜索栏（`adePortalTab\UI\WorldMapPanel.lua:577-580`：
    -- EditBox 左右各留 12、高 22、直接用 `SearchBoxTemplate` 原生外观，不额外画背景）。
    -- 之前是 180 宽靠右 + 自绘蓝色底，左侧空一大片（用户 2026-10-27）。
    local searchHolder = CreateFrame("Frame", nil, searchBar)
    searchHolder:SetHeight(22)
    searchHolder:SetPoint("LEFT", searchBar, "LEFT", 12, 0)
    searchHolder:SetPoint("RIGHT", searchBar, "RIGHT", -12, 0)

    local search = CreateFrame("EditBox", nil, searchHolder, "SearchBoxTemplate")
    search:SetHeight(22)
    search:SetPoint("TOPLEFT", searchHolder, "TOPLEFT", 0, 0)
    search:SetPoint("BOTTOMRIGHT", searchHolder, "BOTTOMRIGHT", 0, 0)
    search:SetAutoFocus(false)
    search:SetMaxLetters(100)
    if search.Instructions then search.Instructions:SetText(L["searchDelves"]) end
    search:SetScript("OnTextChanged", function(self)
        if SearchBoxTemplate_OnTextChanged then SearchBoxTemplate_OnTextChanged(self) end
        searchText = self:GetText() or ""
        QueueRefresh(0.1)
    end)
    search:SetScript("OnEscapePressed", function(self)
        self:SetText("")
        self:ClearFocus()
    end)
    search:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
    bar.SearchBox = search

    -- 搜索开关：模板原生 26x25（MenuTemplates.xml:56-57），WQT 也不改尺寸，只换图标图集
    -- （WorldQuestTab.xml:729-740：normalAtlas=common-search-magnifyingglass，icon 14x14）。
    local toggle = CreateFrame("CheckButton", nil, bar, "WowStyle2IconButtonTemplate")
    toggle:SetPoint("RIGHT", bar, "RIGHT", 0, 0)
    -- 三个属性与 WQT 完全一致（WorldQuestTab.xml:737-739）。
    toggle.normalAtlas = "common-search-magnifyingglass"
    toggle.iconWidth = 14
    toggle.iconHeight = 14

    -- 模板无条件给 Background 设底板图集 common-dropdown-c-button（MenuTemplates.lua:1166-1183），
    -- 这就是「放大镜多了个图标背景」。直接隐藏底板纹理。
    if toggle.Background then toggle.Background:Hide() end
    -- 模板没有 HIGHLIGHT 纹理，WQT 在 XML 里自己补了一个（WorldQuestTab.xml:741-749），
    -- 锚点只有 CENTER，尺寸由 mixin 的 SetAtlas 给。
    local toggleHighlight = toggle:CreateTexture(nil, "HIGHLIGHT")
    toggleHighlight:SetPoint("CENTER", toggle, "CENTER", 2, -1)
    toggle.Highlight = toggleHighlight

    -- ⚠ 必须覆盖模板自带的 `OnButtonStateChanged`（WowStyle2IconButtonMixin 那份）。
    -- 基类只认 `normalAtlas`、用 `TextureKitConstants.UseAtlasSize` → 图标被设成图集原始尺寸
    -- （比 14x14 大一圈），这就是「大一号的图标常驻」（用户 2026-10-27 反馈）。
    -- WQT 是靠自己的 mixin 覆盖掉的（WorldQuestTab.lua:2340-2356）：给了 iconWidth/iconHeight
    -- 就用 IgnoreAtlasSize + 显式 SetSize。照抄如下。
    function toggle:OnButtonStateChanged()
        local icon = self.normalAtlas
        if not icon then return end
        local width, height = self.iconWidth or 14, self.iconHeight or 14
        if self.Icon then
            self.Icon:SetAtlas(icon, false)
            self.Icon:SetSize(width, height)
            -- WQT 在 OnLoad 里做的位移 `SetDisplacedRegions(2, -1, Icon, Highlight)`
            -- （WorldQuestTab.lua:2336-2337）。
            self.Icon:ClearAllPoints()
            self.Icon:SetPoint("CENTER", self, "CENTER", 2, -1)
            -- 照 WQT（WorldQuestTab.lua:2343-2351）：常规（未勾选）饱和度 0.5 显灰，
            -- 搜索中（勾选）饱和度 1 显亮。之前漏了这行，导致放大镜永远白色（用户 2026-10-28）。
            local saturation = self:GetChecked() and 1 or 0.5
            self.Icon:SetVertexColor(saturation, saturation, saturation)
        end
        if self.Highlight then
            self.Highlight:SetAtlas(icon, false)
            self.Highlight:SetSize(width, height)
        end
    end
    toggle:OnButtonStateChanged()
    -- 保底：每次显示都按上面的规格重设一次，避免模板内部在别的时机又改回去。
    toggle:HookScript("OnShow", function(self) self:OnButtonStateChanged() end)
    -- searchBar 的右边要顶到放大镜左侧，但 searchBar 先于 toggle 创建（前向引用），这里补一次锚定。
    -- searchBar 右边顶到放大镜左侧。之前这里直接再 SetPoint 一次，导致 right 同时存在
    -- 「bar 右 -2」与「toggle 左 -6」两个锚，再加上搜索框内边距 12，右侧留出 18px 空隙
    -- （用户 2026-10-28）。ClearAllPoints 后重设：左右各 2px，+ 内边距 12 = 两侧视觉间距都是 14，
    -- 与左侧「搜索框 → 战团角色统计按钮」的间距一致。
    if bar.SearchBar then
        bar.SearchBar:ClearAllPoints()
        bar.SearchBar:SetPoint("LEFT", typeDropdown, "RIGHT", 2, 0)
        bar.SearchBar:SetPoint("RIGHT", toggle, "LEFT", -2, 0)
    end
    toggle:SetScript("OnClick", function(self)
        local checked = self:GetChecked()
        if addon.db then addon.db.searchVisible = checked end
        searchBar:SetShown(checked)
        -- 对齐 WQT UpdateTopBar（WorldQuestTab.lua:1461-1468）：搜索时隐藏过滤器，二者互斥替换。
        if bar.FilterDropdown then bar.FilterDropdown:SetShown(not checked) end
        if checked then
            search:SetFocus()
        else
            if SearchBoxTemplate_ClearText then SearchBoxTemplate_ClearText(search) end
            searchText = ""
        end
        QueueRefresh(0)
    end)
    if addon.db and addon.db.searchVisible then
        toggle:SetChecked(true)
        searchBar:Show()
    end
    bar.SearchToggle = toggle

    topBar = bar
    return bar
end

-------------------------------------------------------------------------------
-- 面板
-------------------------------------------------------------------------------

local function EnsurePanel()
    if panel then return panel end
    if not QuestMapFrame then return nil end

    -- 地基统一由主插件公共函数创建：库 CreateContentFrameForTab（自动 Link）、
    -- parent 覆盖回 ContentsAnchor（Mapster 拖动层）、三次锚定兜底、
    -- HIGH / +200 / Toplevel / Mouse、背景、边框、齿轮，全部实证 hack 都在公共库内。
    -- 锚点与偏移保持 v4 逐像素一致（0,-29 / -22,0），不改动几何。
    panel = MapTab.CreateContentFrame(tabButton, "ADEMapTabDelveWorldMapPanel", {
        addBorder = true,
        onSettingsClick = function() addon.MapPanel:ToggleSettings() end,
    })

    EnsureTopBar(panel)

    -- 现代 ScrollBox 列表与 MinimalScrollBar 的创建 / 初始化统一走主插件公共函数
    -- （WQT WorldQuestTab.lua:1470-1482 同款），范围由 ScrollUtil 自动维护。
    -- r003：统计面板已删除，列表直接从面板顶部起（topFrame 缺省 = panel TOPLEFT 0,-4）。
    scrollBox, scrollBar, view = MapTab.CreateScrollBox(panel, {
        rightX = -12,
        extent = 38,
        initializer = function(button, elementData)
            if elementData.isHeader then
                addon.DelveEntry:UpdateHeader(button, elementData.title, elementData.count, elementData.expanded)
                -- UpdateHeader 末尾会清掉脚本，折叠开关必须在它之后挂。
                button:SetScript("OnClick", function()
                    addon.MapPanel:ToggleExpansion(elementData.expansion)
                end)
            else
                addon.DelveEntry:Update(button, elementData.entry)
            end
        end,
    })

    emptyText = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    emptyText:SetPoint("CENTER", scrollBox, "CENTER", 0, 0)
    emptyText:SetTextColor(0.7, 0.7, 0.7)
    emptyText:Hide()

    settingsFrame = addon.Settings:Create(panel)
    settingsFrame:Hide()

    panel:HookScript("OnShow", function()
        addon.MapPanel:RegisterEvents()
        QueueRefresh(0)
    end)
    -- 切到别的 Tab / 关地图都要回到列表页，否则下次点回来仍停在设置页（adePortalTab 同逻辑）。
    -- 落点必须是面板自身的 OnHide：切 Tab 时是 LibWorldMapTabs 的 SetDisplayMode 把
    -- contentFrame 直接 SetShown(false)（LibWorldMapTabs.lua:328-330），只有面板自己的
    -- OnHide 会触发；WorldMapOnShow 只在「地图整块打开」时触发，切 Tab 根本不走它。
    -- 该落点由主插件公共函数 MapTab.HookOnHideReset 固化，避免误改回 WorldMapOnShow。
    MapTab.HookOnHideReset(panel, function()
        addon.MapPanel:UnregisterEvents()
        if currentMode == "list" then return end
        currentMode = "list"
        if settingsFrame then settingsFrame:Hide() end
    end)

    return panel
end

local function EnsureTab()
    if tabButton then return tabButton end
    -- 库实例由主插件唯一提供；CreateTab 内部已处理 12.x SetChecked 图标尺寸修复。
    tabButton = MapTab.CreateTab({
        name = "ADEMapTabDelveWorldMapTab",
        tooltipText = L["TAB_TOOLTIP"] or "Delves",
        activeAtlas = TAB_ICON_ATLAS,
        inactiveAtlas = TAB_ICON_ATLAS,
        iconAtlas = TAB_ICON_ATLAS,
        iconSize = 20,
        onMouseUp = function() QueueRefresh(0) end,
    })

    -- 面板与 Tab 的绑定不再在这里手动做：EnsurePanel 用公共函数的
    -- CreateContentFrameForTab(tabButton, ...) 创建面板（WQT 同款写法，
    -- WorldQuestTab.lua:523-525），库在创建时已经 LinkTabToContentFrame 并登记进
    -- lib.contentFrames，显示/隐藏也由 SetDisplayMode 统一管理
    -- （LibWorldMapTabs.lua:288-298、328-330），不会出现「内容区全空」。

    return tabButton
end

-------------------------------------------------------------------------------
-- 列表刷新
-------------------------------------------------------------------------------

-- 设置模式下藏起列表相关帧，让设置面板占满整块面板。
-- 与 adePortalTab 的 ApplySettingsMode 同名同职责（手册 §14.2）：WQT 的 TopBar / 齿轮属于列表 frame，
-- 切设置时随列表消失，只剩设置页自己的关闭按钮；齿轮保持在面板上沿、不再变叉号。
-- 边框同样二选一：设置页自带 BorderFrame（WQT Settings.xml:769），两个外扩 3px 的边框叠在一起会互相啃。
local function ApplySettingsMode(active)
    if not panel then return end
    if topBar then topBar:SetShown(not active) end
    if panel.SettingsButton then panel.SettingsButton:SetShown(not active) end
    if panel.BorderFrame then panel.BorderFrame:SetShown(not active) end
    if settingsFrame then settingsFrame:SetShown(active) end
end

function addon.MapPanel.Refresh()
    if not panel or not scrollBox then return end

    ApplySettingsMode(currentMode == "settings")

    -- r003：统计面板已删除，列表固定从面板顶部起（CreateScrollBox 缺省锚 panel TOPLEFT 0,-4，
    -- 与 adePortalTab 无统计面板时的锚法一致），无需每次刷新重锚。

    if currentMode ~= "list" then
        scrollBox:Hide()
        scrollBar:Hide()
        emptyText:Hide()
        return
    end
    scrollBox:Show()
    scrollBar:Show()

    local groups = addon.Catalog:Build(searchText)
    local dataProvider = CreateDataProvider()

    for _, group in ipairs(groups) do
        if #group.entries > 0 then
            local label = group.expansion == "tww" and L["EXPANSION_TWW"] or L["EXPANSION_MIDNIGHT"]
            local collapsed = addon.db and addon.db.collapsedExpansions
                and addon.db.collapsedExpansions[group.expansion]
            dataProvider:Insert({
                isHeader = true,
                title = label,
                count = #group.entries,
                expansion = group.expansion,
                expanded = not collapsed,
            })
            if not collapsed then
                for _, entry in ipairs(group.entries) do
                    dataProvider:Insert({ entry = entry })
                end
            end
        end
    end

    scrollBox:SetDataProvider(dataProvider, ScrollBoxConstants.RetainScrollPosition)

    local count = addon.Catalog:CountVisible(groups)
    if count == 0 then
        emptyText:SetText((searchText ~= "" and L["noDelveSearchResults"]) or L["noDelvesAvailable"])
        emptyText:Show()
    else
        emptyText:Hide()
    end
end

--- 资料片分组折叠开关（状态存 addon.db.collapsedExpansions）。
function addon.MapPanel:ToggleExpansion(expansion)
    if not expansion or not addon.db then return end
    local collapsed = addon.db.collapsedExpansions or {}
    addon.db.collapsedExpansions = collapsed
    collapsed[expansion] = not collapsed[expansion]
    addon.MapPanel.Refresh()
end

function addon.MapPanel:ToggleSettings()
    currentMode = (currentMode == "settings") and "list" or "settings"
    ApplySettingsMode(currentMode == "settings")
    addon.MapPanel.Refresh()
end

-------------------------------------------------------------------------------
-- 事件（DelveCompanion 模式：可见时注册，隐藏时注销）
-------------------------------------------------------------------------------

local WATCHED_EVENTS = {
    "AREA_POIS_UPDATED",
    "CRITERIA_UPDATE",
    "ACHIEVEMENT_EARNED",
    "QUEST_LOG_UPDATE",
    "SPELL_UPDATE_COOLDOWN",
    "NEW_TOY_ADDED",
}

function addon.MapPanel:RegisterEvents()
    for _, event in ipairs(WATCHED_EVENTS) do
        f:RegisterEvent(event)
    end
end

function addon.MapPanel:UnregisterEvents()
    for _, event in ipairs(WATCHED_EVENTS) do
        f:UnregisterEvent(event)
    end
end

f:SetScript("OnEvent", function(_, event)
    if not IsPanelVisible() then return end
    if event == "SPELL_UPDATE_COOLDOWN" or event == "NEW_TOY_ADDED" then
        addon.MapPanel.UpdateToyButton()
        return
    end
    if event == "AREA_POIS_UPDATED" then
        addon.Scanner:Invalidate()
    end
    QueueRefresh(0.05)
end)

-------------------------------------------------------------------------------
-- 生命周期
-------------------------------------------------------------------------------

function addon.MapPanel.Initialize()
    if not QuestMapFrame then return end

    -- WQT 顺序（WorldQuestTab.lua:523-525）：先拿 Tab，再由库按 Tab 造内容框架，
    -- 这样 CreateContentFrameForTab 才能把面板登记进 lib.contentFrames。
    EnsureTab()
    EnsurePanel()

    if addon.db and addon.db.defaultTab == true and not IsDefaultTabClaimedByOthers() then
        MapTab.SetDisplayMode(tabButton)
    end

    if QuestMapFrame and QuestMapFrame.ValidateTabs then QuestMapFrame:ValidateTabs() end
end

function addon.MapPanel.Open()
    addon.MapPanel.Initialize()
    MapTab.Open(tabButton)
    QueueRefresh(0)
end

function addon.MapPanel.RefreshPanel()
    addon.Scanner:Invalidate()
    QueueRefresh(0)
end
