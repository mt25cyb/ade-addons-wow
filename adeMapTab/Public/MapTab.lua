--[==[ adeMapTab / Public/MapTab.lua
基于 LibWorldMapTabs 的「世界地图标签页」公共函数库（LibStub:NewLibrary("AdeMapTab-1.0", 1)）。

定位：本插件是纯库插件，只提供布局 / 控件 / 生命周期的公共构件，不含任何业务数据、
不含文案、不注册设置页与小地图图标。落地功能由子插件承载（ADE v6.5 迁移计划 §2.4 / §2.5）。

设计依据（全部为磁盘实证，非推测）：
  · LibWorldMapTabs minor 6：CreateTab / CreateContentFrameForTab / LinkTabToContentFrame /
    SetDisplayMode 五个 Public API；displayMode 由库按注册序分配 "LWMT_%d"。
  · WorldQuestTab 12.1.05（z-ref_addons_retail\WorldQuestTab）：ContentAnchor 锚定、
    TopBar 26px、WowScrollBoxList + MinimalScrollBar、设置页骨架与行高。
  · v4 adeDelveTab / adePortalTab 的 WorldMapPanel 地基：parent 覆盖回 ContentsAnchor
    （Mapster 拖动层）、三次锚定兜底、OnHide 重置、Tab 图标 SetChecked 尺寸修复。

红线（勿改）：
  · 禁止 SetAllPoints(QuestMapFrame) 兜底（Leatrix_Maps 下会铺满任务框架）。
  · 禁止给 QuestMapFrame / ContentsAnchor 挂 OnSizeChanged 重锚。
  · 禁止绕过库传自定义值给官方 QuestMapFrame:SetDisplayMode（taint）。
  · 切 Tab 的「设置页回列表」重置必须挂面板自身 OnHide，不能用 WorldMapOnShow。
  · 12.x ScrollFrameTemplate 的滚动条是 MinimalScrollBar，禁 SetMinMaxValues /
    SetValueStep / SetValue，范围由 ScrollUtil 自动维护。 ]==]

local MAJOR, MINOR = "AdeMapTab-1.0", 1
local MapTab = LibStub:NewLibrary(MAJOR, MINOR)
if not MapTab then return end

local CreateFrame = CreateFrame
local C_Timer = C_Timer
local InCombatLockdown = InCombatLockdown
local RunNextFrame = RunNextFrame
local hooksecurefunc = hooksecurefunc
local type, pairs, wipe = type, pairs, wipe
local tinsert = tinsert

-- ADE v6.5：图标绘制优先走 ade_UIKit 的三态 API（FilePath / FileID / Atlas）。
-- UIKit 是软依赖：本库 TOC 不强制依赖它，缺失时回退原生 SetAtlas / SetTexCoord。
local function GetOF()
    if type(_G.GetBlizzOptionsFrame) ~= "function" then return nil end
    return _G.GetBlizzOptionsFrame("ade_UIKit", true)
end

-- 面板锚定的唯一尺寸基准；数值与 v4 改造前逐像素一致（DevSpec §10.2 / §10.3 保持现状）。
local ANCHOR_TOP_Y = -29
local ANCHOR_RIGHT_X = -22
local PANEL_LEVEL_OFFSET = 200

-- ============ 库实例与默认页签协商 ============

--- 取得 LibWorldMapTabs 单例（本插件 TOC 保证其已加载）。
---@return table lib
function MapTab.GetLib()
    return LibStub("LibWorldMapTabs")
end

--- WorldQuestTab 已开启「默认页签」时让位：同一 LibWorldMapTabs 实例下默认页签只能有一个。
---@return boolean claimed
function MapTab.IsDefaultTabClaimed()
    local wqt = _G.WQT
    if type(wqt) ~= "table" then return false end
    local settings = wqt.settings
    if type(settings) ~= "table" then return false end
    local general = settings.general
    if type(general) ~= "table" then return false end
    return general.defaultTab == true
end

-- ============ Tab ============

--- 创建世界地图侧边 Tab，并固化 12.x 图标修复。
--- spec = {
---   name = string,                 全局帧名（可选，缺省由库分配）
---   tooltipText = string,
---   activeAtlas / inactiveAtlas = string,   图集类图标（与 texture 二选一）
---   activeTexture / inactiveTexture = string|number,   贴图类图标
---   icon = table,                   ADE v6.5 三态描述 {atlas=...}/{fileID=...}/{texture=...}
---   iconAtlas = string,             兼容字段：ApplyIcon 时重设的图集（图集类必填）
---   iconSize = number,             默认 20（库的 SetChecked 会改回 28，故必须修复）
---   texCoord = {l,r,t,b},          贴图类可选裁边
---   selectedAlpha = number,        SelectedTexture 透明度（可选）
---   autoShow = boolean,            默认 true；false = 调用方自行显隐（战斗保护场景，
---                                 需等 tabButton 赋值完成后再调 SafeSetVisible）
---   onMouseUp = function(),        左键且 upInside 时触发
--- }
---@param spec table
---@return table tab
function MapTab.CreateTab(spec)
    local lib = MapTab.GetLib()
    local tab = lib:CreateTab({
        tooltipText = spec.tooltipText,
        activeAtlas = spec.activeAtlas,
        inactiveAtlas = spec.inactiveAtlas,
        activeTexture = spec.activeTexture,
        inactiveTexture = spec.inactiveTexture,
    }, spec.name)

    local iconSize = spec.iconSize or 20
    local coords = spec.texCoord
    local function ApplyIcon(self)
        if not self.Icon then return end
        -- ADE v6.5：优先用 UIKit 的三态图标 API；spec.icon 为三态描述表，
        -- spec.iconAtlas 是 v5 兼容字段（自动转成 { atlas = ... }）。
        local descriptor = spec.icon
        if not descriptor and spec.iconAtlas then
            descriptor = { atlas = spec.iconAtlas }
        end
        local of = descriptor and GetOF()
        if of and of.ApplyIcon then
            of.ApplyIcon(self.Icon, descriptor, { size = iconSize, texcoord = coords })
            return
        end
        -- UIKit 未加载时回退原生写法：库 SetChecked 的 atlas 分支会重设 Icon，
        -- 这里把图集与尺寸一并固化回 iconSize（LibWorldMapTabs.lua:58-95 会改成 28x28）。
        if descriptor and type(descriptor) == "table" then
            if descriptor.atlas then
                self.Icon:SetAtlas(descriptor.atlas, false)
            elseif descriptor.fileID ~= nil or descriptor.texture ~= nil then
                self.Icon:SetTexture(descriptor.fileID or descriptor.texture)
            end
        elseif spec.iconAtlas then
            self.Icon:SetAtlas(spec.iconAtlas, false)
        end
        self.Icon:SetSize(iconSize, iconSize)
        if coords then self.Icon:SetTexCoord(coords[1], coords[2], coords[3], coords[4]) end
    end
    ApplyIcon(tab)
    hooksecurefunc(tab, "SetChecked", ApplyIcon)

    if spec.selectedAlpha and tab.SelectedTexture then
        tab.SelectedTexture:SetAlpha(spec.selectedAlpha)
    end

    -- 默认与 v4 Delve 一致（非战斗 Show）。Portal 传 autoShow=false，
    -- 在 EnsureTab 中待 tabButton 赋值完成后再调 SafeSetVisible，保留战斗保护专用分支。
    if spec.autoShow ~= false and not InCombatLockdown() then
        tab:Show()
    end

    if spec.onMouseUp then
        tab:HookScript("OnMouseUp", function(_, button, upInside)
            if button ~= "LeftButton" or not upInside then return end
            spec.onMouseUp()
        end)
    end

    return tab
end

-- ============ 内容框架 ============

--- 由库按 Tab 创建内容框架，并补齐所有实证地基。
--- 内部依次：CreateContentFrameForTab（自动 Link）→ 非战斗 Hide → parent 覆盖回
--- ContentsAnchor → 三次锚定兜底 → strata/level/toplevel/mouse → 背景。
--- opts = {
---   addBorder = boolean,         建 QuestLogBorderFrameTemplate 边框（Delve 用）
---   onSettingsClick = function,   建 15x16 齿轮按钮并绑定点击（可选）
---   topY = number, rightX = number,   锚点偏移（缺省 -29 / -22）
--- }
---@param tab table
---@param name string
---@param opts table|nil
---@return table panel
function MapTab.CreateContentFrame(tab, name, opts)
    opts = opts or {}
    local lib = MapTab.GetLib()

    -- 必须早于内容框架创建：CreateContentFrameForTab 需要 tab.displayMode（库 :289-291）。
    local panel = lib:CreateContentFrameForTab(tab, "BackdropTemplate", name)
    if not InCombatLockdown() then panel:Hide() end

    -- ⚠ LinkTabToContentFrame 会把 parent 设成 QuestMapFrame（库 :312），而整张地图框架
    -- 是 Mapster 的拖动层，点面板空白区会把地图拖走（用户 2026-10-28 实证）。
    -- SetParent 不影响库托管（登记靠 tinsert），且必须在锚定之前。
    local qmf = _G.QuestMapFrame
    if qmf and qmf.ContentsAnchor then
        panel:SetParent(qmf.ContentsAnchor)
    end

    local topY = opts.topY or ANCHOR_TOP_Y
    local rightX = opts.rightX or ANCHOR_RIGHT_X
    local function anchorPanel()
        local ca = _G.QuestMapFrame and _G.QuestMapFrame.ContentsAnchor
        if not ca then return end
        -- 锚点未就绪时保持锚 ContentsAnchor 即可：尺寸为 0 只是暂时不显示，
        -- 不等于铺满；后续 RunNextFrame / C_Timer 会补锚（Leatrix_Maps 实证）。
        panel:ClearAllPoints()
        panel:SetPoint("TOPLEFT", ca, "TOPLEFT", 0, topY)
        panel:SetPoint("BOTTOMRIGHT", ca, "BOTTOMRIGHT", rightX, 0)
    end
    anchorPanel()
    RunNextFrame(anchorPanel)
    C_Timer.After(0.1, anchorPanel)

    panel:SetFrameStrata("HIGH")
    panel:SetFrameLevel(((qmf and qmf.GetFrameLevel and qmf:GetFrameLevel()) or 0) + PANEL_LEVEL_OFFSET)
    panel:SetToplevel(true)
    panel:EnableMouse(true)
    panel:EnableMouseWheel(true)

    -- 背景铺满整块面板（WorldQuestTab.xml:639-647 双锚、无内缩）。
    local background = panel:CreateTexture(nil, "BACKGROUND")
    background:SetAtlas("QuestLog-main-background", true)
    background:SetAllPoints(panel)
    panel.Background = background

    if opts.addBorder then
        -- 模板自带外扩锚，不写 SetAllPoints（会被压成与面板同尺寸、被背景盖住）。
        -- 模板的 frameLevel="100" 是绝对值，须显式抬到面板之上。
        local border = CreateFrame("Frame", nil, panel, "QuestLogBorderFrameTemplate")
        border:SetFrameLevel(panel:GetFrameLevel() + 2)
        panel.BorderFrame = border
    end

    if opts.onSettingsClick then
        -- 齿轮不在 TopBar 内，落在顶栏行右端、面板右外侧 19px（WQT :765-796）。
        local button = CreateFrame("Button", nil, panel)
        button:SetSize(15, 16)
        button:SetPoint("TOPRIGHT", panel, "TOPRIGHT", 19, 25)
        local gear = button:CreateTexture(nil, "ARTWORK")
        gear:SetSize(16, 16)
        gear:SetAtlas("questlog-icon-setting", false)
        gear:SetPoint("CENTER", 0, 0)
        local highlight = button:CreateTexture(nil, "HIGHLIGHT")
        highlight:SetAtlas("questlog-icon-setting", false)
        highlight:SetAllPoints(gear)
        highlight:SetBlendMode("ADD")
        button:SetScript("OnClick", opts.onSettingsClick)
        panel.SettingsButton = button
        panel.GearIcon = gear
    end

    return panel
end

--- 把「切 Tab 回列表页」重置挂在面板自身 OnHide。
--- 切 Tab 时是库 SetDisplayMode 直接 contentFrame:SetShown(false)（库 :328-330），
--- 只有面板自己的 OnHide 会触发；WorldMapOnShow 只在地图整块打开时触发，切 Tab 不走它。
---@param panel table
---@param onHide function
function MapTab.HookOnHideReset(panel, onHide)
    panel:HookScript("OnHide", onHide)
end

-- ============ 显示模式 ============

--- 只走库的 SetDisplayMode；禁止绕过库传自定义 displayMode 给官方函数（taint）。
---@param tab table
function MapTab.SetDisplayMode(tab)
    if not tab or not tab.displayMode then return end
    MapTab.GetLib():SetDisplayMode(tab.displayMode)
end

--- 打开世界地图并切到指定 Tab（库没有默认页签 API，须调用方主动切）。
--- Blizzard_WorldMap 是按需加载插件，未加载时先显式拉起（12.x 命名空间 API）。
---@param tab table
function MapTab.Open(tab)
    if not _G.WorldMapFrame then
        C_AddOns.LoadAddOn("Blizzard_WorldMap")
    end
    local wmf = _G.WorldMapFrame
    if not wmf then return end
    if not wmf:IsShown() then
        if _G.ToggleWorldMap then _G.ToggleWorldMap() else _G.ShowUIPanel(wmf) end
    end
    MapTab.SetDisplayMode(tab)
end

-- ============ 顶栏与搜索 ============

--- WQT 风格顶栏容器：面板内顶部 0~26 那一行，浮在内容区上沿之外。
---@param panel table
---@param opts table|nil {left, right, y, height, levelOffset}
---@return table bar
function MapTab.CreateTopBar(panel, opts)
    opts = opts or {}
    local bar = CreateFrame("Frame", nil, panel)
    bar:SetPoint("TOPLEFT", panel, "TOPLEFT", opts.left or 2, opts.y or 30)
    bar:SetPoint("TOPRIGHT", panel, "TOPRIGHT", opts.right or -2, opts.y or 30)
    bar:SetHeight(opts.height or 26)
    -- 顶栏控件要压在边框纹理之上。
    bar:SetFrameLevel((panel:GetFrameLevel() or 1) + (opts.levelOffset or 4))
    return bar
end

-- 说明：搜索框（SearchBoxTemplate + 放大镜）与复选行不做公共化。
-- 两个子插件的这两处构件各自带业务绑定与实证 hack：
--   · Delve 放大镜覆写 WowStyle2IconButtonMixin:OnButtonStateChanged（图标尺寸 / 饱和度 /
--     位移，用户 2026-10-27、10-28 实证修复）；
--   · 两个 SettingsPanel 的复选行带 tooltip、父子联动灰显、RefreshState、db 键联动。
-- 抽成公共库会丢失这些修复，故按「逐行复刻」保留在子插件内（开发计划 §十 风险 6）。

-- ============ 滚动容器 ============

--- 现代 ScrollBox 列表（WQT 列表页同款）：WowScrollBoxList + MinimalScrollBar。
--- opts = { topFrame, topY, rightX, extent, initializer, resetter, padding }
---@param panel table
---@param opts table
---@return table scrollBox, table scrollBar, table view
function MapTab.CreateScrollBox(panel, opts)
    local scrollBox = CreateFrame("Frame", nil, panel, "WowScrollBoxList")
    if opts.topFrame then
        scrollBox:SetPoint("TOPLEFT", opts.topFrame, "BOTTOMLEFT", 0, opts.topY or -2)
    else
        scrollBox:SetPoint("TOPLEFT", panel, "TOPLEFT", 0, opts.topY or -4)
    end
    scrollBox:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", opts.rightX or -12, 0)

    -- 滚动条挂在面板右侧 +8，从面板顶 +2 贯穿到底 -4（WQT :881-886）。
    local scrollBar = CreateFrame("EventFrame", nil, panel, "MinimalScrollBar")
    scrollBar:SetPoint("TOPLEFT", panel, "TOPRIGHT", 8, 2)
    scrollBar:SetPoint("BOTTOMLEFT", panel, "BOTTOMRIGHT", 8, -4)
    scrollBar:SetFrameStrata("HIGH")

    local pad = opts.padding or { 2, 4, 2, 2 }
    local view = CreateScrollBoxListLinearView(pad[1], pad[2], pad[3], pad[4])
    if opts.extent then view:SetElementExtent(opts.extent) end
    if opts.initializer then view:SetElementInitializer("Button", opts.initializer) end
    if opts.resetter then view:SetElementResetter(opts.resetter) end
    ScrollUtil.InitScrollBoxListWithScrollBar(scrollBox, scrollBar, view)

    return scrollBox, scrollBar, view
end

--- 老式 ScrollFrame（设置页 / Portal 列表页同款）：ScrollFrameTemplate + MinimalScrollBar。
--- ⚠ 滚动条范围由 ScrollUtil 自动维护，只调 Update()，不碰范围 / 步进 / 值。
--- opts = { name, contentName, topY, rightX, bottomRightY, scrollBarToPanel, onSizeChanged }
---@param panel table
---@param opts table
---@return table scroll, table content, table bar
function MapTab.CreateScrollFrame(panel, opts)
    local scroll = CreateFrame("ScrollFrame", opts.name, panel, "ScrollFrameTemplate")
    scroll:ClearAllPoints()
    scroll:SetPoint("TOPLEFT", panel, "TOPLEFT", opts.left or 2, opts.topY or -5)
    scroll:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", opts.rightX or -2, opts.bottomRightY or 14)

    local content = CreateFrame("Frame", opts.contentName, scroll)
    content:SetSize(1, 1)
    scroll:SetScrollChild(content)

    local bar = scroll.ScrollBar
    if bar then
        bar:ClearAllPoints()
        bar:SetPoint("TOPLEFT", panel, "TOPRIGHT", 8, 2)
        bar:SetPoint("BOTTOMLEFT", panel, "BOTTOMRIGHT", 8, -4)
        bar:Update()
    end

    if opts.onSizeChanged then
        scroll:HookScript("OnSizeChanged", opts.onSizeChanged)
    end

    return scroll, content, bar
end

-- ============ 设置页骨架 ============

--- WQT 设置页骨架（两个 v4 插件的 Settings:Create 逐行同构，故抽成公共函数）。
--- opts = {
---   title, closeTooltip = string,
---   onClose = function(), onShow = function(frame),
---   init = function(frame, scroll, bar),   追加子插件专属字段 / 钩子
--- }
--- 返回 frame，带 Content / Scroll / CloseButton / TitleText / BorderFrame /
--- rows / collapsed / UpdateScrollRange，供子插件 Layout / Refresh 继续消费。
---@param parent table
---@param opts table
---@return table frame
function MapTab.CreateSettingsFrame(parent, opts)
    local frame = CreateFrame("Frame", nil, parent)
    frame:SetAllPoints(parent)
    frame:SetFrameLevel((parent:GetFrameLevel() or 0) + 5)

    -- 图集不按原尺寸，靠 TexCoord 截一块深色区域（WQT Settings.xml:756-766）。
    local background = frame:CreateTexture(nil, "BACKGROUND")
    background:SetAtlas("newplayerchat-signup-background", false)
    background:SetVertexColor(0.22, 0.21, 0.21)
    background:SetTexCoord(0.1, 0.85, 0.2, 0.5)
    background:SetAllPoints(frame)

    local border = CreateFrame("Frame", nil, frame, "QuestLogBorderFrameTemplate")
    border:SetFrameLevel(frame:GetFrameLevel() + 2)
    frame.BorderFrame = border

    local title = frame:CreateFontString(nil, "ARTWORK", "Game15Font_Shadow")
    title:SetPoint("BOTTOM", border, "TOP", -1, 3)
    title:SetText(opts.title)
    frame.TitleText = title

    -- 关闭按钮与顶栏齿轮严格一致：15x16、锚 parent TOPRIGHT 19,25。
    local close = CreateFrame("Button", nil, frame)
    close:SetSize(15, 16)
    close:SetPoint("TOPRIGHT", parent, "TOPRIGHT", 19, 25)
    local closeTexture = close:CreateTexture(nil, "ARTWORK")
    closeTexture:SetAtlas("common-search-clearbutton", false)
    closeTexture:SetAlpha(0.5)
    closeTexture:SetAllPoints(close)
    close:SetScript("OnClick", opts.onClose)
    close:SetScript("OnEnter", function(self)
        closeTexture:SetAlpha(1)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(opts.closeTooltip)
        GameTooltip:Show()
    end)
    close:SetScript("OnLeave", function()
        closeTexture:SetAlpha(0.5)
        GameTooltip:Hide()
    end)
    frame.CloseButton = close

    -- 滚动容器复用同库的 CreateScrollFrame（12.x MinimalScrollBar 正确写法）。
    -- 设置页的边距默认值（2,-5 / -2,14）与 v4 逐像素一致。
    local scroll, content, bar = MapTab.CreateScrollFrame(frame, {})
    frame.Content = content
    frame.Scroll = scroll

    -- 内容高度变化后请控制器重算滑块（ScrollControllerMixin:Update）。
    function frame.UpdateScrollRange()
        if not bar then return end
        scroll:UpdateScrollChildRect()
        bar:Update()
    end

    frame.rows = {}
    frame.collapsed = {}
    if opts.init then opts.init(frame, scroll, bar) end
    if opts.onShow then
        frame:HookScript("OnShow", function() opts.onShow(frame) end)
    end
    return frame
end

-- ============ 设置页控件行（WQT 规格） ============

--- 可折叠分组标题：Options_ListExpand_* 三件套 + GameFontHighlightMedium。
---@param parent table
---@param text string
---@param onClick function
---@param width number|nil
---@return table button
function MapTab.CreateCategoryButton(parent, text, onClick, width)
    local button = CreateFrame("Button", nil, parent)
    button:SetHeight(34)
    if width then button:SetWidth(width) end

    local left = button:CreateTexture(nil, "BACKGROUND")
    left:SetAtlas("Options_ListExpand_Left", true)
    left:SetPoint("LEFT", 10, 0)
    local right = button:CreateTexture(nil, "BACKGROUND")
    right:SetAtlas("Options_ListExpand_Right", true)
    right:SetPoint("RIGHT", -10, 0)
    local middle = button:CreateTexture(nil, "BACKGROUND")
    middle:SetAtlas("_Options_ListExpand_Middle", false)
    middle:SetHorizTile(true)
    middle:SetPoint("TOPLEFT", left, "TOPRIGHT")
    middle:SetPoint("BOTTOMRIGHT", right, "BOTTOMLEFT")

    -- 高亮三件套（WQT_SettingCategoryTemplate，v4 SettingsPanel.lua:125-140）。
    local hlLeft = button:CreateTexture(nil, "HIGHLIGHT")
    hlLeft:SetAtlas("Section_Expand_glowing_Left", true)
    hlLeft:SetAlpha(0.7)
    hlLeft:SetPoint("TOPLEFT", left, "TOPLEFT", 0, -1)
    local hlRight = button:CreateTexture(nil, "HIGHLIGHT")
    hlRight:SetAtlas("Section_Expand_glowing_right", true)
    hlRight:SetAlpha(0.7)
    hlRight:SetPoint("TOPRIGHT", right, "TOPRIGHT", 0, -1)
    local hlMiddle = button:CreateTexture(nil, "HIGHLIGHT")
    hlMiddle:SetAtlas("Section_Expand_glowing_middle", false)
    hlMiddle:SetHorizTile(true)
    hlMiddle:SetAlpha(0.7)
    hlMiddle:SetPoint("TOPLEFT", hlLeft, "TOPRIGHT")
    hlMiddle:SetPoint("BOTTOMRIGHT", hlRight, "BOTTOMLEFT")

    local label = button:CreateFontString(nil, "ARTWORK", "GameFontHighlightMedium")
    label:SetPoint("LEFT", 30, -1)
    label:SetPoint("RIGHT", -30, -1)
    label:SetJustifyH("CENTER")
    label:SetText(text)

    if onClick then button:SetScript("OnClick", onClick) end
    button.Label = label
    -- 折叠态右端图集切换由调用方改 button.Right:SetAtlas（v4 Delve SettingsPanel.lua:383）。
    button.Right = right
    return button
end

-- ============ 刷新节流 ============

--- 一次性去抖刷新队列：短时间内的多次请求合并为一次 C_Timer.After。
---@param callback function
---@return function queue(delay)
function MapTab.NewRefreshQueue(callback)
    local queued = false
    return function(delay)
        if queued then return end
        queued = true
        C_Timer.After(delay or 0.05, function()
            queued = false
            callback()
        end)
    end
end

-- ============ 深拷贝（供子插件初始化嵌套存档表） ============

--- 递归拷贝 table，避免把默认值的表引用直接挂到存档（会污染默认值）。
---@param value any
---@return any
function MapTab.CopyTable(value)
    if type(value) ~= "table" then return value end
    local copy = {}
    for k, v in pairs(value) do
        copy[k] = MapTab.CopyTable(v)
    end
    return copy
end
