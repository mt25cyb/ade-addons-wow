-- adeStatPlus — 设置窗口：基于 ade_UIKit（v6.5）原生 RegisterTab。
-- 旧 Options/Settings.lua 的三页映射为两页（按已确认口径不设配置档管理页）：
--   general（常规/字体/文本风格/格式/来源/自动隐藏/背景/进度条/显示排序） + charpanel（条/图形）。
-- 旧卡片（ADE.CreateCard）映射为 subheading 分组标题，选项缩进其下。
-- 联动禁用用函数式 disabled（UIKit 每次 Refresh 重估），颜色用官方 ColorPickerFrame
-- （12.x 契约 SetupColorPickerAndShow(info)，实证 Blizzard_ColorPickerFrame/Mainline）。
local ns = _G.adeStatPlus
if not ns then return end
local L = ns.L or {}

local function GetOF()
    local lib = GetBlizzOptionsFrame and GetBlizzOptionsFrame("ade_UIKit", true)
    if lib then return lib end
    return BOF_LIBS and BOF_LIBS["ade_UIKit"]
end

local function CopyValue(v)
    if type(v) ~= "table" then return v end
    local copy = {}
    for key, sub in pairs(v) do copy[key] = CopyValue(sub) end
    return copy
end

local function SameValue(a, b)
    if type(a) ~= "table" or type(b) ~= "table" then return a == b end
    for key, value in pairs(a) do if not SameValue(value, b[key]) then return false end end
    for key in pairs(b) do if a[key] == nil then return false end end
    return true
end

local function SplitKey(key) return key:match("^([^%.]+)%.(.+)$") end

local function ReadPath(t, key)
    if type(t) ~= "table" or type(key) ~= "string" then return nil end
    local first, rest = SplitKey(key)
    if rest then
        if type(t[first]) ~= "table" then return nil end
        return ReadPath(t[first], rest)
    end
    return t[key]
end

local function WritePath(t, key, value)
    if type(t) ~= "table" then return end
    local first, rest = SplitKey(key)
    if rest then
        if type(t[first]) ~= "table" then t[first] = {} end
        WritePath(t[first], rest, value)
    else
        t[key] = value
    end
end

local function P() return ns.db and ns.db.profile or {} end

local sectionSpecs = {}
local Options = {}
ns.Options = Options
local Bump -- 前向声明：KeySpec 的 after 缺省时调用
local tab

--- 补上 UIKit 行契约：get/set/default 直接转发到 ADEDB_ADESTATPLUS.profile 的点分路径。
local function KeySpec(section, spec, key, after)
    spec.key = key
    spec.get = spec.get or function() return ReadPath(P(), key) end
    spec.set = spec.set or function(value)
        if not ns.db then return end
        WritePath(ns.db.profile, key, value)
        if after then after(value) else Bump() end
    end
    spec.default = ReadPath(ns.defaults and ns.defaults.profile, key)
    sectionSpecs[section] = sectionSpecs[section] or {}
    sectionSpecs[section][#sectionSpecs[section] + 1] = spec
    return spec
end

--- 变更统一出口：全量刷新视图 + 重估联动禁用（对齐旧 ns.RefreshAllViews + SyncSegmentedDisabled）。
Bump = function()
    if ns.RefreshAllViews then ns.RefreshAllViews() end
    if tab and tab.Refresh then tab:Refresh() end
end

local function Items(map)
    local arr = {}
    for value, text in pairs(map) do arr[#arr + 1] = { value = value, text = text } end
    return arr
end

local sections = { general = {}, charpanel = {} }

-- ============ general 页（旧 BuildDataPanel 全量映射） ============
sections.general[#sections.general + 1] = { kind = "subheading", label = L["TAB_GENERAL"] }
sections.general[#sections.general + 1] = KeySpec("general",
    { kind = "toggle", label = L["OPT_LOCK"] }, "panel.locked")
sections.general[#sections.general + 1] = KeySpec("general",
    { kind = "toggle", label = L["OPT_MINIMAP_HIDE"] }, "minimap.hide", function()
        if ns.minimapBtn and ns.minimapBtn.RefreshShown then ns.minimapBtn:RefreshShown() end
    end)
sections.general[#sections.general + 1] = KeySpec("general",
    { kind = "toggle", label = L["OPT_SHOW_GROUP_NAMES"] }, "panel.showGroupNames")
sections.general[#sections.general + 1] = KeySpec("general",
    { kind = "toggle", label = L["OPT_ABBR"] }, "abbr")
sections.general[#sections.general + 1] = KeySpec("general",
    { kind = "range", label = L["OPT_SCALE"], min = 0.5, max = 2.0, step = 0.05 }, "panel.scale")

sections.general[#sections.general + 1] = { kind = "subheading", label = L["OPT_FONT"] }
-- 下拉行保存引用：LSM 介质由其它插件加载时才注册（字母序可能晚于本插件），
-- 动态下拉（LSM 介质 / 推荐来源）传**函数式 items**（UIKit b025：每次行渲染求值）：
-- 第三方介质注册与外部来源插件加载都晚于本插件（字母序），静态数组会固化加载期快照。
sections.general[#sections.general + 1] = KeySpec("general",
    -- 菜单项文字直接用该字体渲染（UIKit b032：spec.preview → {font=path}，DBM 同款效果）；
    -- 存档值仍是介质 key，名字→路径由 Media.FontPath 解析。
    { kind = "select", label = L["OPT_FONT"], items = function() return ns.Media.FontItems() end,
        preview = function(key) return { font = ns.Media.FontPath(key) } end }, "font.face")
sections.general[#sections.general + 1] = KeySpec("general",
    { kind = "range", label = L["OPT_FONT_SIZE"], min = 8, max = 24, step = 1 }, "font.size")
sections.general[#sections.general + 1] = KeySpec("general",
    { kind = "select", label = L["OPT_OUTLINE"], items = Items({
        NONE = L["OUTLINE_NONE"], OUTLINE = L["OUTLINE_NORMAL"], THICKOUTLINE = L["OUTLINE_THICK"],
    }) }, "font.outline")

-- 数值显示风格（D53）：分段开启时禁用 joinedAlign，关闭时禁用 name/data 对齐与拆分
sections.general[#sections.general + 1] = { kind = "subheading", label = L["OPT_TEXT_STYLE"] }
sections.general[#sections.general + 1] = KeySpec("general",
    { kind = "toggle", label = L["OPT_SEGMENTED"] }, "format.segmented")
sections.general[#sections.general + 1] = KeySpec("general",
    { kind = "select", label = L["OPT_JOINED_ALIGN"], items = Items({
        LEFT = L["ALIGN_LEFT"], CENTER = L["ALIGN_CENTER"], RIGHT = L["ALIGN_RIGHT"],
    }), disabled = function() return P().format.segmented == true end }, "format.joinedAlign")
sections.general[#sections.general + 1] = KeySpec("general",
    { kind = "select", label = L["OPT_NAME_ALIGN"], items = Items({
        LEFT = L["ALIGN_LEFT"], RIGHT = L["ALIGN_RIGHT"],
    }), disabled = function() return P().format.segmented ~= true end }, "format.nameAlign")
sections.general[#sections.general + 1] = KeySpec("general",
    { kind = "select", label = L["OPT_DATA_ALIGN"], items = Items({
        LEFT = L["ALIGN_LEFT"], RIGHT = L["ALIGN_RIGHT"],
    }), disabled = function() return P().format.segmented ~= true end }, "format.dataAlign")
sections.general[#sections.general + 1] = KeySpec("general",
    { kind = "select", label = L["OPT_SECONDARY_PARTS"], items = Items({
        VALUE = L["PARTS_VALUE"], PERCENT = L["PARTS_PERCENT"],
        VALUE_PERCENT = L["PARTS_VALUE_PERCENT"], PERCENT_VALUE = L["PARTS_PERCENT_VALUE"],
    }), disabled = function() return P().format.segmented ~= true end }, "format.secondaryParts")
sections.general[#sections.general + 1] = KeySpec("general",
    { kind = "select", label = L["OPT_TERTIARY_PARTS"], items = Items({
        VALUE = L["PARTS_VALUE"], PERCENT = L["PARTS_PERCENT"],
        VALUE_PERCENT = L["PARTS_VALUE_PERCENT"], PERCENT_VALUE = L["PARTS_PERCENT_VALUE"],
    }), disabled = function() return P().format.segmented ~= true end }, "format.tertiaryParts")

sections.general[#sections.general + 1] = { kind = "subheading", label = L["OPT_FORMAT"] }
sections.general[#sections.general + 1] = KeySpec("general",
    { kind = "range", label = L["OPT_PERCENT_DECIMALS"], min = 0, max = 3, step = 1 }, "format.percentDecimals")
sections.general[#sections.general + 1] = KeySpec("general",
    { kind = "range", label = L["OPT_ILVL_DECIMALS"], min = 0, max = 3, step = 1 }, "format.ilvlDecimals")
sections.general[#sections.general + 1] = KeySpec("general",
    { kind = "select", label = L["OPT_VERS_MODE"], items = Items({
        combined = L["VERS_COMBINED"], split = L["VERS_SPLIT"],
    }) }, "format.versatility")

-- 推荐值来源（D88）
sections.general[#sections.general + 1] = { kind = "subheading", label = L["OPT_SOURCE"] }
do
    local function SourceItems()
        local sourceItems = { { value = "none", text = L["SOURCE_NONE"] } }
        for _, adapter in ipairs(ns.Registry.Sources.ListAvailable()) do
            sourceItems[#sourceItems + 1] = { value = adapter.key, text = adapter.label }
        end
        -- 「无来源」置顶，其余按显示名排序
        table.sort(sourceItems, function(a, b)
            if (a.value == "none") ~= (b.value == "none") then return a.value == "none" end
            return a.text < b.text
        end)
        return sourceItems
    end
    sections.general[#sections.general + 1] = KeySpec("general",
        { kind = "select", label = L["OPT_SOURCE"], items = function() return SourceItems() end }, "recommendSource")
end

-- 自动隐藏属性（D55/D61）
sections.general[#sections.general + 1] = { kind = "subheading", label = L["GRP_AUTO_HIDE"] }
sections.general[#sections.general + 1] = KeySpec("general",
    { kind = "toggle", label = L["OPT_AUTO_HIDE_STATS"] }, "panel.autoHideStats")
sections.general[#sections.general + 1] = KeySpec("general",
    { kind = "toggle", label = L["OPT_HIDE_LEVEL_AT_MAX"] }, "panel.hideLevelAtMax")

-- 背景分组：颜色改用 kind="color" 色块控件（UIKit b034；旧 execute+onClick 是错用按钮）
-- 存档 {r,g,b} 表 ↔ hex 适配（color 控件契约：get/set/default 均为 8 位 AARRGGBB）
local function ColorTableToHex(c)
    return string.format("ff%02x%02x%02x", math.floor(c.r * 255 + 0.5), math.floor(c.g * 255 + 0.5), math.floor(c.b * 255 + 0.5))
end
local function HexToColorTable(hex, fallback)
    local c = CreateColorFromHexString(hex)
    if not c then return fallback.r, fallback.g, fallback.b end
    return c.r, c.g, c.b
end
sections.general[#sections.general + 1] = { kind = "subheading", label = L["OPT_BG"] }
sections.general[#sections.general + 1] = KeySpec("general",
    { kind = "toggle", label = L["OPT_BG_ENABLE"] }, "panel.background.enabled")
sections.general[#sections.general + 1] = KeySpec("general",
    { kind = "toggle", label = L["OPT_BG_BORDER"] }, "panel.background.border")
sections.general[#sections.general + 1] = KeySpec("general",
    { kind = "range", label = L["OPT_BG_ALPHA"], min = 0, max = 1, step = 0.05 }, "panel.background.color.a")
sections.general[#sections.general + 1] = {
    kind = "color", label = L["OPT_BG_COLOR"] or "Background color",
    -- default 取 ns.defaults.profile.panel.background.color（默认 0.04,0.04,0.04 → ff0a0a0a）
    default = ColorTableToHex(ns.defaults.profile.panel.background.color),
    get = function() return ColorTableToHex(P().panel.background.color) end,
    set = function(hex)
        if not ns.db then return end
        local cur = P().panel.background.color
        cur.r, cur.g, cur.b = HexToColorTable(hex, cur)
        if ns.RefreshAllViews then ns.RefreshAllViews() end
    end,
}

-- 进度条分组（数据面板）：条高度在 embedded 时禁用（D53 联动）
sections.general[#sections.general + 1] = { kind = "subheading", label = L["GRP_BARS"] }
sections.general[#sections.general + 1] = KeySpec("general",
    { kind = "toggle", label = L["OPT_BAR_ENABLED"] }, "bars.enabled")
sections.general[#sections.general + 1] = KeySpec("general",
    { kind = "select", label = L["OPT_BAR_STYLE"], items = Items({
        separate = L["BAR_STYLE_SEPARATE"], embedded = L["BAR_STYLE_EMBEDDED"],
    }) }, "bars.style")
sections.general[#sections.general + 1] = KeySpec("general",
    { kind = "select", label = L["OPT_BAR_TEXTURE"],
      items = function() return ns.Media.TextureItems() end,
      -- 菜单项铺满该材质（UIKit b032：spec.preview → 路径 string，DBM 同款效果）
      preview = function(key) return ns.Media.TexturePath(key) end }, "bars.texture")
sections.general[#sections.general + 1] = KeySpec("general",
    { kind = "range", label = L["OPT_BAR_HEIGHT"], min = 4, max = 24, step = 1,
      disabled = function() return P().bars.style == "embedded" end }, "bars.height")
sections.general[#sections.general + 1] = KeySpec("general",
    { kind = "range", label = L["OPT_BAR_BG_ALPHA"], min = 0, max = 1, step = 0.05 }, "bars.bgAlpha")
sections.general[#sections.general + 1] = KeySpec("general",
    { kind = "range", label = L["OPT_BAR_TEXTURE_ALPHA"], min = 0, max = 1, step = 0.05 }, "bars.textureAlpha")
sections.general[#sections.general + 1] = KeySpec("general",
    { kind = "toggle", label = L["OPT_BAR_SPARK"] }, "bars.spark")
sections.general[#sections.general + 1] = KeySpec("general",
    { kind = "toggle", label = L["OPT_BAR_THRESHOLD"] }, "bars.showThreshold")

-- 显示/颜色/排序分组（D88）：排序窗口属第二批，按钮保留并提示
sections.general[#sections.general + 1] = { kind = "subheading", label = L["GRP_DISPLAY_COLOR_SORT"] }
sections.general[#sections.general + 1] = KeySpec("general",
    { kind = "toggle", label = L["OPT_COLOR_ILVL_BY_QUALITY"] }, "panel.colorIlvlByQuality")
sections.general[#sections.general + 1] = KeySpec("general",
    { kind = "toggle", label = L["OPT_AUTO_COLOR_DURABILITY"] }, "panel.autoColorDurability")
sections.general[#sections.general + 1] = KeySpec("general",
    { kind = "toggle", label = L["OPT_SORT_SECONDARY_BY_SOURCE"] }, "order.secondaryBySource")
sections.general[#sections.general + 1] = {
    kind = "execute", text = L["BTN_SORT_WINDOW"] or "Sort window",
    onClick = function()
        if ns.SortWindow and ns.SortWindow.Toggle then ns.SortWindow.Toggle() end
    end,
}

-- ============ charpanel 页（旧 BuildCharPanel 全量映射；UI 属第二批，字段先落） ============
sections.charpanel[#sections.charpanel + 1] = { kind = "subheading", label = L["GRP_BARS"] }
sections.charpanel[#sections.charpanel + 1] = KeySpec("charpanel",
    { kind = "toggle", label = L["OPT_CP_BAR_ENABLED"] }, "charPanel.bars.enabled")
sections.charpanel[#sections.charpanel + 1] = KeySpec("charpanel",
    { kind = "select", label = L["OPT_BAR_TEXTURE"],
      items = function() return ns.Media.TextureItems() end,
      preview = function(key) return ns.Media.TexturePath(key) end }, "charPanel.bars.texture")
sections.charpanel[#sections.charpanel + 1] = KeySpec("charpanel",
    { kind = "range", label = L["OPT_BAR_BG_ALPHA"], min = 0, max = 1, step = 0.05 }, "charPanel.bars.bgAlpha")
sections.charpanel[#sections.charpanel + 1] = KeySpec("charpanel",
    { kind = "range", label = L["OPT_BAR_TEXTURE_ALPHA"], min = 0, max = 1, step = 0.05 }, "charPanel.bars.textureAlpha")
sections.charpanel[#sections.charpanel + 1] = KeySpec("charpanel",
    { kind = "toggle", label = L["OPT_BAR_SPARK"] }, "charPanel.bars.spark")
sections.charpanel[#sections.charpanel + 1] = KeySpec("charpanel",
    { kind = "toggle", label = L["OPT_BAR_THRESHOLD"] }, "charPanel.bars.showThreshold")

-- 图形内嵌（Radar/Ring）已删除（用户 2026-11-17：实测问题较大）；charts 存档键不再消费。

-- ============ 分组计数 / 重置 / 构建 ============
local function CountChanged()
    local count = 0
    for _, specs in pairs(sectionSpecs) do
        for _, spec in ipairs(specs) do
            if spec.get and spec.default ~= nil and not SameValue(spec.get(), spec.default) then
                count = count + 1
            end
        end
    end
    return count
end

local function ResetSection(id)
    local specs = sectionSpecs[id]
    if not specs then return false end
    local changed = false
    for _, spec in ipairs(specs) do
        if spec.get and spec.set and spec.default ~= nil and not SameValue(spec.get(), spec.default) then
            spec.set(CopyValue(spec.default))
            changed = true
        end
    end
    if changed then Bump() end
    return changed
end

local function Build()
    if tab then return tab end
    local lib = GetOF()
    if not lib then return nil end
    tab = lib.RegisterTab({
        name = ns.title,
        saved = ns.db or {},
        groups = {
            { name = L["TAB_GENERAL"], sections = { "general" } },
            { name = L["TAB_CHARPANEL"], sections = { "charpanel" } },
        },
        sectionName = function(id)
            if id == "general" then return L["TAB_GENERAL"] or id end
            if id == "charpanel" then return L["TAB_CHARPANEL"] or id end
            return id
        end,
        elements = function(id) return sections[id] or {} end,
        landing = function() return "general" end,
        changedCount = CountChanged,
        resetSection = ResetSection,
        onCreated = function() end,
    })
    if lib.RegisterOptionsStub then
        lib.RegisterOptionsStub({
            title = ns.title,
            version = ns.version,
            tab = tab,
        })
    end
    return tab
end

function Options.Open()
    if not Build() then return false end
    if tab.Toggle then tab:Toggle() end
    return true
end

function Options.SyncDisabled()
    if tab and tab.Refresh then tab:Refresh() end
end

function Options.Init()
    -- 加载期注册 tab 与原生「打开选项」stub 页（Core:Init 调用；KAF Stub 同款时点）。
    -- ade_UIKit 为 ## Dependencies 硬依赖，此处失败直接 error 暴露，不做静默降级。
    if not Build() then
        error("adeStatPlus: 加载期注册设置页失败（ade_UIKit RegisterTab 不可用）")
    end
end

--- 主设置窗 shell 帧（SortWindow 锚定用）。
--- 帧在首次打开时才由 UIKit 惰性创建；未创建时先 Open 一次再取。
function Options.GetWindowFrame()
    if not tab then return nil end
    local frame = tab:GetFrame()
    if not frame then
        tab:Open()
        frame = tab:GetFrame()
    end
    return frame
end
