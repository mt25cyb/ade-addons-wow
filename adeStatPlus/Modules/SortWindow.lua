--[==[ 显示 / 排序 / 颜色 独立窗口（F4 / D11 / D33 / D41–D47）
    控件排列严格对齐 MightStats（Options.lua:98-186）：绝对 SetPoint、行内
    勾选框(x25)→标签(x60)→▲(x178)→▼(x213)→颜色块(x269)，行距 26，
    原生四态箭头纹理 + 原生 ColorPickerFrame:SetupColorPickerAndShow。
    本轮修订（用户 2026-11-08 四次澄清）：
      · 去掉窗口标题；固定位置不可拖动，父为主设置窗口，双点锚 TOPRIGHT/BOTTOMRIGHT
        到主窗口左外侧（安全间距），高度自动跟随主窗口；内容走滚动容器可滚动。
      · 列标题与组设置名黄色、两侧带隔离横线（复刻基座 AceGUI Heading：
        AceGUIWidget-Heading.lua:39,85-101 的 fileID 137057 + TexCoord(0.81,0.94,0.5,1)）；
        各选项文本白色，按钮文本保持 UIPanelButtonTemplate 原样。
      · 组设置名「排序」→「设置」；新增「主要属性组设置」段（排序按钮固定禁用）。
      · 第一块中属于分组的项加「(组)」后缀，其颜色块固定禁用。
      · 启用「依属性推荐值来源」时**只**禁用次属性组排序，不再牵连其它块。
      · 底部同排三按钮：重置显示 / 重置排序 / 重置颜色。
    v6.5：主窗锚定走 ns.Options.GetWindowFrame（UIKit RegisterTab 共享窗，惰性建）；
    滚动容器为基座 widget/ScrollFrame.lua:24-56 的 scrollBar="auto" 分支逐字内联
    （ScrollFrameTemplate + MinimalScrollBar，ScrollUtil 自动维护范围）；ns 头统一
    走全局私有表。 ]==]
-- ADE v6.5：ns 统一走全局私有表（Core/InitDB 同一表）
local addonName = ...
local ns = _G.adeStatPlus or {}
_G.adeStatPlus = ns

local SortWindow = {}
ns.SortWindow = SortWindow

local PANEL_W = 340
local ROW_STEP = 26
local SECTION_STEP = 24
local CHECK_STEP = 26
local ANCHOR_GAP = 12
local YELLOW = { 1, 0.82, 0 }

local window, scroll, scrollContent, contentHeight
local L
local rowWidgets = {}
local Refresh

local function CopyArray(src)
    local out = {}
    for i, v in ipairs(src) do out[i] = v end
    return out
end

local function Label(parent, text, x, y, color, justify, width)
    local fs = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    fs:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    fs:SetText(text)
    fs:SetTextColor(color[1], color[2], color[3])
    if justify then fs:SetJustifyH(justify) end
    if width then fs:SetWidth(width) end
    return fs
end

--- 组设置名：整行居中，两侧横线（基座分组隔离线同款纹理）。
local function SectionLabel(parent, text, y)
    local fs = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    fs:SetPoint("TOP", parent, "TOP", 12, y)
    fs:SetText(text)
    fs:SetTextColor(YELLOW[1], YELLOW[2], YELLOW[3])

    -- 只给每段横线一个垂直锚点 + 一个水平对端锚点，避免两个 TOP* 互相牵拉
    local left = parent:CreateTexture(nil, "BACKGROUND")
    left:SetTexture(137057)
    left:SetTexCoord(0.81, 0.94, 0.5, 1)
    left:SetHeight(8)
    left:SetPoint("TOPLEFT", parent, "TOPLEFT", 24, y - 3)
    left:SetPoint("RIGHT", fs, "LEFT", -5, 0)
    local right = parent:CreateTexture(nil, "BACKGROUND")
    right:SetTexture(137057)
    right:SetTexCoord(0.81, 0.94, 0.5, 1)
    right:SetHeight(8)
    right:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -8, y - 3)
    right:SetPoint("LEFT", fs, "RIGHT", 5, 0)
    return fs
end

local function ArrowButton(parent, direction, x, y, callback)
    local button = CreateFrame("Button", nil, parent)
    button:SetSize(24, 24)
    button:SetPoint("TOPLEFT", parent, "TOPLEFT", x + 4, y)
    local base = "Interface\\Buttons\\UI-ScrollBar-Scroll" .. direction .. "Button-"
    for _, state in ipairs({
        { "SetNormalTexture", "Up" }, { "SetPushedTexture", "Down" },
        { "SetDisabledTexture", "Disabled" }, { "SetHighlightTexture", "Highlight" },
    }) do
        local texture = button:CreateTexture(nil, "ARTWORK")
        texture:SetTexture(base .. state[2])
        texture:SetTexCoord(0.20, 0.80, 0.25, 0.75)
        texture:SetAllPoints(button)
        button[state[1]](button, texture)
    end
    button:SetScript("OnClick", callback)
    return button
end

local function MakeButton(parent, text, x, y, width, callback)
    local button = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    button:SetSize(width, 24)
    button:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    button:SetText(text)
    button:SetScript("OnClick", callback)
    return button
end

local function Check(parent, x, y, text)
    local check = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
    check:SetSize(26, 26)
    check:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    Label(parent, text, x + 31, y - 6, { 1, 1, 1 }, "LEFT", 240)
    return check
end

local function DisplayName(key, isGroup)
    local def = ns.StatDefs[key]
    local text
    if def then text = ns.L[def.labelKey]
    elseif ns.GROUP_LABEL_KEYS[key] then text = ns.L[ns.GROUP_LABEL_KEYS[key]]
    else text = key end
    if isGroup then text = text .. " " .. L["SORT_GROUP_SUFFIX"] end
    return text
end

local function ConfigFor(key, source)
    if source == "groups" then return ns.db.profile.groups[key] end
    if source == "others" then return ns.db.profile.others[key] end
    return ns.db.profile.stats[key]
end

local function RowColor(key, source)
    local cfg = ConfigFor(key, source)
    if cfg and cfg.color then return ns.ColorRGB(cfg.color) end
    local def = ns.StatDefs[key]
    if def and def.color then return ns.ColorRGB(def.color) end
    return 1, 1, 1
end

local function RowEnabled(key, source)
    local cfg = ConfigFor(key, source)
    return not cfg or cfg.enabled ~= false
end

local function SetRowEnabled(key, source, value)
    local cfg = ConfigFor(key, source)
    if cfg then cfg.enabled = value end
end

local function SetRowColor(key, source, r, g, b)
    local cfg = ConfigFor(key, source)
    if cfg then cfg.color = { r = r, g = g, b = b } end
end

local function OpenColor(key, source)
    if not ColorPickerFrame or not ColorPickerFrame.SetupColorPickerAndShow then return end
    local r, g, b = RowColor(key, source)
    local oR, oG, oB = r, g, b
    ColorPickerFrame:SetupColorPickerAndShow({
        r = r, g = g, b = b, hasOpacity = false,
        swatchFunc = function()
            local cr, cg, cb = ColorPickerFrame:GetColorRGB()
            SetRowColor(key, source, cr, cg, cb)
            Refresh()
        end,
        cancelFunc = function()
            SetRowColor(key, source, oR, oG, oB)
            Refresh()
        end,
    })
end

local function Move(list, index, delta)
    local target = index + delta
    if target < 1 or target > #list then return end
    list[index], list[target] = list[target], list[index]
    Refresh()
end

--- 创建一行（控件只建一次；数据由 Refresh 重填）。
---@param section string 所属段，用于判定「依来源」时是否禁用排序
local function CreateRow(parent, y, list, index, source, section, allowMove)
    local row = { list = list, index = index, source = source,
                  section = section, allowMove = allowMove }
    row.check = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
    row.check:SetSize(26, 26)
    row.check:SetPoint("TOPLEFT", parent, "TOPLEFT", 25, y)
    row.check:SetScript("OnClick", function(self)
        SetRowEnabled(row.id, row.source, self:GetChecked() == true)
        ns.Panel.RefreshAll()
    end)
    row.label = Label(parent, "", 60, y - 6, { 1, 1, 1 }, "LEFT", 110)
    row.up = ArrowButton(parent, "Up", 174, y, function() Move(row.list, row.index, -1) end)
    row.down = ArrowButton(parent, "Down", 209, y, function() Move(row.list, row.index, 1) end)
    local colorButton = CreateFrame("Button", nil, parent)
    colorButton:SetSize(24, 22)
    colorButton:SetPoint("TOPLEFT", parent, "TOPLEFT", 269, y - 1)
    row.swatch = colorButton:CreateTexture(nil, "ARTWORK")
    row.swatch:SetAllPoints()
    colorButton:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square")
    colorButton:SetScript("OnClick", function() OpenColor(row.id, row.source) end)
    row.colorButton = colorButton
    rowWidgets[#rowWidgets + 1] = row
    return row
end

--- 重填全部行（换序 / 配置变更后调用；控件不重建）。
Refresh = function()
    ns.Panel.RefreshAll()
    if not window then return end
    local profile = ns.db.profile
    local bySource = profile.order.secondaryBySource
    local sourcePriority = bySource and ns.Registry.Sources.GetPriority()
    local hasSource = ns.Registry.Sources.GetActive() ~= nil
    -- 「依来源」排序由设置页选项控制（D88），此处仅据此禁用次属性组排序调整（D43）
    local secondaryLocked = bySource and sourcePriority ~= nil

    for _, row in ipairs(rowWidgets) do
        local id = row.list[row.index]
        row.id = id
        local isGroup = ns.GROUP_LABEL_KEYS[id] ~= nil
        if row.list == profile.order.blocks then
            row.source = isGroup and "groups" or "others"
        end
        row.label:SetText(DisplayName(id, isGroup))
        row.check:SetChecked(RowEnabled(id, row.source))
        local locked = (row.list == profile.order.blocks)
            and (id == "primary" or id == "secondary")
        if locked then row.check:Disable(); row.check:SetAlpha(0.55)
        else row.check:Enable(); row.check:SetAlpha(1) end

        -- 分组项的颜色块固定禁用（D46）
        local r, g, b = RowColor(id, row.source)
        row.swatch:SetColorTexture(r, g, b)
        if isGroup then
            row.colorButton:Disable()
            row.swatch:SetAlpha(0.35)
        else
            row.colorButton:Enable()
            row.swatch:SetAlpha(1)
        end

        local disabled = (not row.allowMove)
            or (row.section == "secondary" and secondaryLocked)
        row.up:SetEnabled(not disabled and row.index > 1)
        row.down:SetEnabled(not disabled and row.index < #row.list)
    end
end
ns.SortWindow.Refresh = Refresh

local function ResetDisplay()
    local d = ns.defaults.profile
    for key, cfg in pairs(ns.db.profile.stats) do
        cfg.enabled = d.stats[key] and d.stats[key].enabled ~= false
    end
    for key, cfg in pairs(ns.db.profile.others) do
        cfg.enabled = d.others[key] and d.others[key].enabled ~= false
    end
    for key, cfg in pairs(ns.db.profile.groups) do
        cfg.enabled = d.groups[key] and d.groups[key].enabled ~= false
    end
    Refresh()
end

local function ResetOrder()
    local d = ns.defaults.profile.order
    local o = ns.db.profile.order
    o.blocks = CopyArray(d.blocks)
    o.primary = CopyArray(d.primary)
    o.secondary = CopyArray(d.secondary)
    o.tertiary = CopyArray(d.tertiary)
    o.defensive = CopyArray(d.defensive)
    o.secondaryBySource = false
    Refresh()
end

local function ResetColors()
    for _, cfg in pairs(ns.db.profile.stats) do cfg.color = nil end
    for _, cfg in pairs(ns.db.profile.others) do cfg.color = nil end
    for _, cfg in pairs(ns.db.profile.groups) do cfg.color = nil end
    Refresh()
end

local function BuildContent(parent)
    local profile = ns.db.profile
    local y = -12
    local gapY = 6

    -- 列标题（黄色）
    Label(parent, L["SORT_COL_SHOW"], 25, y, YELLOW)
    Label(parent, L["SORT_COL_ORDER"], 190, y, YELLOW)
    Label(parent, L["SORT_COL_COLOR"], 266, y, YELLOW)
    y = y - 22

    -- 段 1：分组设置
    SectionLabel(parent, L["SORT_GROUP"], y)
    y = y - SECTION_STEP
    for i = 1, #profile.order.blocks do
        local key = profile.order.blocks[i]
        local source = ns.GROUP_LABEL_KEYS[key] and "groups" or "others"
        CreateRow(parent, y, profile.order.blocks, i, source, "blocks", true)
        y = y - ROW_STEP
    end

    -- 段 2：主要属性组设置（新增，排序按钮固定禁用）
    SectionLabel(parent, L["SORT_PRIMARY"], y - gapY)
    y = y - SECTION_STEP - gapY
    for i = 1, #profile.order.primary do
        CreateRow(parent, y, profile.order.primary, i, "stats", "primary", false)
        y = y - ROW_STEP
    end

    -- 段 3：次级属性组设置
    SectionLabel(parent, L["SORT_SECONDARY"], y - gapY)
    y = y - SECTION_STEP - gapY
    -- 「依属性推荐值来源排序副属性」已移至设置页「显示/颜色/排序」分组（D88）
    for i = 1, #profile.order.secondary do
        CreateRow(parent, y, profile.order.secondary, i, "stats", "secondary", true)
        y = y - ROW_STEP
    end

    -- 段 4：第三属性组设置
    SectionLabel(parent, L["SORT_TERTIARY"], y - gapY)
    y = y - SECTION_STEP - gapY
    for i = 1, #profile.order.tertiary do
        CreateRow(parent, y, profile.order.tertiary, i, "stats", "tertiary", true)
        y = y - ROW_STEP
    end

    -- 段 5：防护属性组设置（「仅防护专精显示」选项已删除，D54）
    SectionLabel(parent, L["SORT_DEFENSIVE"], y - gapY)
    y = y - SECTION_STEP - gapY
    for i = 1, #profile.order.defensive do
        CreateRow(parent, y, profile.order.defensive, i, "stats", "defensive", true)
        y = y - ROW_STEP
    end

    -- 底部同排三按钮
    y = y - 6
    MakeButton(parent, L["SORT_RESET_DISPLAY"], 10, y, 90, ResetDisplay)
    MakeButton(parent, L["SORT_RESET_ORDER"], 110, y, 90, ResetOrder)
    MakeButton(parent, L["SORT_RESET_COLOR"], 210, y, 90, ResetColors)
    y = y - 34
    return -y + 12
end

--[==[ 滚动容器（基座 widget/ScrollFrame.lua:24-56 的 scrollBar="auto" 分支逐字内联）。
    ScrollFrameTemplate 自带 MinimalScrollBar；ScrollUtil.InitScrollFrameWithScrollBar
    内部绑定 OnScrollRangeChanged 自动维护范围（禁手动 SetMinMaxValues/SetValue）。
    内容高度变化只需 content:SetHeight(...) 即可驱动。 ]==]
local function CreateAutoScrollFrame(parent)
    --@diagnostic disable-next-line: undefined-global
    local ScrollUtil = ScrollUtil
    local scroll = CreateFrame("ScrollFrame", nil, parent, "ScrollFrameTemplate", {
        scrollBarX = 8,
        scrollBarTopY = -2,
        scrollBarBottomY = 4,
        scrollBarHideIfUnscrollable = true, -- auto：内容无需滚动时自动隐藏滚动条
    })
    -- scroll.ScrollBar 是模板自带的 MinimalScrollBar（LuaLS 未收录属误报）
    ScrollUtil.InitScrollFrameWithScrollBar(scroll, scroll.ScrollBar)
    local content = CreateFrame("Frame", nil, scroll)
    content:SetSize(1, 1)
    scroll:SetScrollChild(content)
    scroll.content = content
    return scroll, content
end

local function BuildWindow()
    -- 主设置窗 shell 由 UIKit RegisterTab 惰性创建；未创建时 GetWindowFrame 先 Open 一次。
    -- tab:GetFrame() 返回共享窗口本体（PortraitFrameTemplate 原生 Frame，可直接作父/锚定）。
    local mainFrame = ns.Options and ns.Options.GetWindowFrame and ns.Options.GetWindowFrame()
    if not mainFrame then return false end

    -- 父为主设置窗口 → 主窗口隐藏时自动隐藏；双点锚 → 高度跟随主窗口
    window = CreateFrame("Frame", "adeStatPlusSortWindow", mainFrame, "BackdropTemplate")
    window:SetWidth(PANEL_W)
    window:SetFrameStrata("DIALOG")
    window:SetPoint("TOPRIGHT", mainFrame, "TOPLEFT", -ANCHOR_GAP, 0)
    window:SetPoint("BOTTOMRIGHT", mainFrame, "BOTTOMLEFT", -ANCHOR_GAP, 0)
    -- 固定位置：不 SetMovable / 不 RegisterForDrag
    window:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true, tileSize = 32, edgeSize = 24,
        insets = { left = 6, right = 6, top = 6, bottom = 6 },
    })
    window:SetBackdropColor(0.08, 0.08, 0.08, 1)
    window:Hide()
    table.insert(UISpecialFrames, "adeStatPlusSortWindow")

    local close = CreateFrame("Button", nil, window, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", -3, -3)
    close:SetScript("OnClick", function() window:Hide() end)

    -- 滚动容器（基座 12.x 封装等价内联，widget/ScrollFrame.lua:24-56）
    scroll, scrollContent = CreateAutoScrollFrame(window)
    scroll:SetPoint("TOPLEFT", window, "TOPLEFT", 8, -32)
    scroll:SetPoint("BOTTOMRIGHT", window, "BOTTOMRIGHT", -30, 8)
    scrollContent:SetWidth(PANEL_W - 40)
    contentHeight = BuildContent(scrollContent)
    -- 基座 ADE.UpdateScrollFrame 等价：SetHeight 后 OnScrollRangeChanged 自动驱动滚动条
    scrollContent:SetHeight(contentHeight)
    window:SetScript("OnShow", Refresh)
    return true
end

function SortWindow.Toggle()
    if not window then
        -- 排序窗口锚在主设置窗口左侧；设置窗在首次打开时才由 UIKit 惰性创建。
        -- 斜杠命令 /adsp sort 可能先于设置窗口触发，此时先建锚（GetWindowFrame
        -- 会临时打开一次设置页）。
        if not BuildWindow() then return end
        window:Show()
        return
    end
    window:SetShown(not window:IsShown())
end

function SortWindow.Init()
    L = ns.L
end
