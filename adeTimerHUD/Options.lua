-- adeTimerHUD / Options.lua — 设置页（ade_UIKit v6.5 RegisterTab + RegisterOptionsStub）
-- 范式实证 adeChatBar/Options.lua:9-158：RegisterTab(sections/groups/sectionName/elements/
-- landing/changedCount/resetSection) → RegisterOptionsStub。
-- v3（2026-11-20，规划 §九）：四组字体（时间/闹钟/日期/星期）以 subheading 分组，
-- 每组 face/outline/color（字号固定不进设置）；新增缩放滑条与「水平居中」execute 行；
-- 字体行逐条 append（r003 教训：数组构造器不会展开嵌套表）；
-- 联动禁用用函数式 disabled（实证 adeStatPlus/Options.lua:129）。
-- r018（规划 §十六）：新增第六组 font.prefix（缩写前缀独立 FS），showPrefix 关闭时禁用。
-- r019（规划 §十七）：日期格式 9 项带括号说明；dateShowYear → dateHideYear；新增 weekdayStyle 下拉。
local addonName = ...
local ns = _G.adeTimerHUD or {}
_G.adeTimerHUD = ns
local L = ns.L or {}

local function GetOF()
    if ns.UIKit then return ns.UIKit end  -- Core 加载期缓存（adeBagPack/Options.lua:7 同款）
    local lib = GetBlizzOptionsFrame and GetBlizzOptionsFrame("ade_UIKit", true)
    if lib then return lib end
    return BOF_LIBS and BOF_LIBS["ade_UIKit"]
end

local function P()
    return (ns.db and ns.db.settings) or {}
end

local function CopyValue(v)
    if type(v) ~= "table" then return v end
    local copy = {}
    for key, sub in pairs(v) do copy[key] = CopyValue(sub) end
    return copy
end

-- 多级键路径（v3：font.time.color 三级；gmatch 分段后用索引语法，
-- 兼容任意层级的 settings.* 键）
local function ReadPath(t, key)
    local cur = t
    for seg in key:gmatch("[^%.]+") do
        if type(cur) ~= "table" then return nil end
        cur = cur[seg]
    end
    return cur
end

local function WritePath(t, key, value)
    local segs = {}
    for seg in key:gmatch("[^%.]+") do segs[#segs + 1] = seg end
    local cur = t
    for i = 1, #segs - 1 do
        if type(cur[segs[i]]) ~= "table" then cur[segs[i]] = {} end
        cur = cur[segs[i]]
    end
    cur[segs[#segs]] = value
end

local function KeySpec(spec, key)
    spec.key = key
    spec.get = spec.get or function() return ReadPath(P(), key) end
    spec.set = spec.set or function(value)
        WritePath(ns.db.settings, key, value)
        ns.Clock.ApplyAll()
    end
    if spec.default == nil then spec.default = ReadPath(ns.defaults.settings, key) end
    return spec
end

local function Items(tbl)
    local out = {}
    for value, text in pairs(tbl) do out[#out + 1] = { value = value, text = text } end
    return out
end

-- 日期格式预设 9 项（规划 §十七）：fmt=格式串，style=括号说明的三语键。
-- 首项 fmt=nil 表示按 locale 取默认格式；{EN_MON_*} 占位符取模块内英文月份表。
local DATE_PRESETS = {
    { fmt = nil, style = "DATE_STYLE_LOCAL" },
    { fmt = "{EN_MON_SHORT} %d, %Y", style = "DATE_STYLE_US" },
    { fmt = "%d {EN_MON_SHORT} %Y", style = "DATE_STYLE_UK" },
    { fmt = "%m/%d/%Y", style = "DATE_STYLE_US" },
    { fmt = "%d/%m/%Y", style = "DATE_STYLE_UK" },
    { fmt = "%m-%d-%Y", style = "DATE_STYLE_US" },
    { fmt = "%d-%m-%Y", style = "DATE_STYLE_UK" },
    { fmt = "%m.%d.%Y", style = "DATE_STYLE_US" },
    { fmt = "%d.%m.%Y", style = "DATE_STYLE_UK" },
}
local function DateFormatItems()
    local out = {}
    for _, preset in ipairs(DATE_PRESETS) do
        local fmt = preset.fmt or ns.defaults.settings.dateFormat
        local ok, rendered = pcall(ns.Clock.FormatDateText, fmt, not P().dateHideYear)
        out[#out + 1] = { value = fmt, text = (ok and rendered or fmt) .. " (" .. (L[preset.style] or "") .. ")" }
    end
    return out
end

-- 星期样式标签按当天实际星期动态生成（函数式 items 每次刷新重求值，
-- 实证 ade_UIKit/Widget/OptionRow.lua:74-78），与日期格式下拉口径一致。
local WEEKDAY_STYLES = {
    { value = "LOCAL_FULL", label = "WEEKDAY_LOCAL_FULL" },
    { value = "LOCAL_SHORT", label = "WEEKDAY_LOCAL_SHORT" },
    { value = "EN_FULL", label = "WEEKDAY_EN_FULL" },
    { value = "EN_SHORT", label = "WEEKDAY_EN_SHORT" },
}
local function WeekdayStyleItems()
    local out = {}
    for _, item in ipairs(WEEKDAY_STYLES) do
        local ok, rendered = pcall(ns.Clock.FormatWeekday, item.value)
        out[#out + 1] = { value = item.value,
            text = (L[item.label] or item.value) .. "（" .. (ok and rendered or "") .. "）" }
    end
    return out
end

-- v3 字体三件套：face/outline/color（字号在 Clock.lua 固定 64/10/20±8，设置项不含大小）
-- 下拉函数式 items + preview（adeStatPlus/Options.lua:113 范式）
-- classColor=true：颜色行改「使用职业色」开关 + 同行色块（UIKit b051 ToggleColorOption，
-- 加载时序兜底用本地等价实现；勾选时色块禁用，关闭时用自定义色）。
local function ToggleColorRow(toggleSpec, colorSpec)
    local kit = GetOF()
    if kit and kit.ToggleColorOption then return kit.ToggleColorOption(toggleSpec, colorSpec) end
    local ownDisabled = colorSpec.disabled
    colorSpec.disabled = function()
        if toggleSpec.get and toggleSpec.get() == true then return true end
        if type(ownDisabled) == "function" then return ownDisabled() == true end
        return ownDisabled == true
    end
    toggleSpec.kind, colorSpec.kind, toggleSpec.with = "toggle", "color", colorSpec
    return toggleSpec
end

local function FontRows(groupKey, disabled, noColor, classColor)
    local base = "font." .. groupKey
    local rows = {
        KeySpec({ kind = "select", label = L.OPT_FONT,
            items = function() return ns.Media.FontItems() end,
            preview = function(key) return { font = ns.Media.FontPath(key) } end,
            disabled = disabled }, base .. ".face"),
        KeySpec({ kind = "select", label = L.OPT_OUTLINE, items = Items({
            NONE = L.OUTLINE_NONE, OUTLINE = L.OUTLINE_NORMAL, THICKOUTLINE = L.OUTLINE_THICK,
        }), disabled = disabled }, base .. ".outline"),
    }
    -- 闹钟颜色固定由剩余时间分级决定，不暴露 color 行
    if not noColor then
        local colorSpec = KeySpec({ kind = "color", label = L.OPT_COLOR, disabled = disabled }, base .. ".color")
        if classColor then
            local toggleSpec = KeySpec({ label = L.LABEL_USE_CLASS_COLOR,
                disabled = disabled }, base .. ".useClassColor")
            rows[#rows + 1] = ToggleColorRow(toggleSpec, colorSpec)
        else
            rows[#rows + 1] = colorSpec
        end
    end
    return rows
end

local sections = {
    clock = {
        { kind = "note", text = L.NOTE_CLOCK or "" },

        { kind = "subheading", label = L.SUBH_CONTENT or "Content" },
        KeySpec({ kind = "toggle", label = L.LABEL_SHOWN }, "shown"),
        KeySpec({ kind = "select", label = L.OPT_TIMESOURCE, items = Items({
            SERVER = L.SRC_SERVER, LOCAL = L.SRC_LOCAL,
        }) }, "timeSource"),
        KeySpec({ kind = "toggle", label = L.LABEL_SHOW_PREFIX }, "showPrefix"),
        KeySpec({ kind = "toggle", label = L.LABEL_USE24 }, "use24"),
        KeySpec({ kind = "select", label = L.OPT_MERIDIEM,
            items = function() return ns.TimeFormat.Styles() end,
            disabled = function()
                local tf = ns.TimeFormat
                return P().use24 == true or not (tf and tf.CanUseChinese(P().forceChineseMeridiem))
            end }, "meridiemStyle"),
        KeySpec({ kind = "select", label = L.OPT_DATEMODE, items = Items({
            NONE = L.DATE_NONE, DATE = L.DATE_DATE, WEEKDAY = L.DATE_WEEKDAY, BOTH = L.DATE_BOTH,
        }) }, "dateMode"),
        KeySpec({ kind = "select", label = L.OPT_DATEFORMAT,
            items = function() return DateFormatItems() end,
            disabled = function() return P().dateMode == "NONE" end }, "dateFormat"),
        KeySpec({ kind = "toggle", label = L.LABEL_DATE_HIDE_YEAR,
            disabled = function() return P().dateMode == "NONE" end }, "dateHideYear"),
        KeySpec({ kind = "select", label = L.OPT_WEEKDAY_STYLE,
            items = function() return WeekdayStyleItems() end,
            disabled = function() return P().dateMode == "NONE" end }, "weekdayStyle"),
        KeySpec({ kind = "toggle", label = L.OPT_ALARM_ENABLED }, "alarm.show"),
        { kind = "note", text = L.NOTE_ALARM_WARN_MINUTES or "" },
        KeySpec({ kind = "range", label = L.LABEL_ALARM_WARN_MINUTES, min = 1, max = 5, step = 0.5,
            disabled = function() return P().alarm.show ~= true end }, "alarm.warnMinutes"),
        KeySpec({ kind = "toggle", label = L.LABEL_ALARM_FLASH,
            disabled = function() return P().alarm.show ~= true end }, "alarm.flash"),

        { kind = "subheading", label = L.SUBH_APPEARANCE or "Appearance" },
        KeySpec({ kind = "toggle", label = L.LABEL_LOCKED }, "frameLocked"),
        KeySpec({ kind = "toggle", label = L.LABEL_SHOW_BORDER }, "showBorder"),
        KeySpec({ kind = "color", label = L.LABEL_FRAME_COLOR }, "frameColor"),
        KeySpec({ kind = "range", label = L.LABEL_FRAME_ALPHA, min = 0, max = 1, step = 0.05 }, "frameAlpha"),
        KeySpec({ kind = "color", label = L.LABEL_BORDER_COLOR }, "borderColor"),
        KeySpec({ kind = "range", label = L.LABEL_SCALE, min = 0.5, max = 2, step = 0.05 }, "panelScale"),
        KeySpec({ kind = "range", label = L.LABEL_PANEL_ALPHA, min = 0, max = 1, step = 0.05 }, "panelAlpha"),
        { kind = "note", text = L.NOTE_CHILD_FONT_OFFSET or "" },
        KeySpec({ kind = "range", label = L.LABEL_CHILD_FONT_OFFSET, min = -8, max = 8, step = 1 }, "childFontOffset"),
        -- execute 行必须用 onClick（UIKit OptionRow.lua:618-628：execute 类型 onClick 优先于
        -- set，spec 的 func 字段不被消费）。
        { kind = "execute", label = L.LABEL_CENTER_X, onClick = function()
            ns.Clock.CenterHorizontally()
        end },
        { kind = "execute", label = L.LABEL_CENTER_PANEL, onClick = function()
            ns.Clock.CenterPanelHorizontally()
        end },
        { kind = "execute", label = L.LABEL_RESET_POSITION, onClick = function()
            ns.Clock.ResetPosition()
        end },
    },
}

-- 非 CJK 客户端：格式下拉默认禁用，按 row.key 定位在下拉前插入专用开关与说明；
-- CJK 端两行都不出现（该设置在这些客户端无意义）。
-- 加载期用本地表判定，不依赖 TimeFormat 模块是否已就绪——避免该模块异常时
-- 整个 Options.lua 中断（表现为设置页与入口同时消失）。
if not ({ zhCN = true, zhTW = true, koKR = true })[GetLocale()] then
    for i, row in ipairs(sections.clock) do
        if row.key == "meridiemStyle" then
            table.insert(sections.clock, i, { kind = "note", text = L.NOTE_FORCE_CHINESE_MERIDIEM or "" })
            table.insert(sections.clock, i + 1, KeySpec({ kind = "toggle", label = L.LABEL_FORCE_CHINESE_MERIDIEM }, "forceChineseMeridiem"))
            break
        end
    end
end

-- 字体分组：FontRows() 返回的是「行数组」，Lua 数组构造器不会展开嵌套表，
-- 必须逐行 append；否则 UIKit 收到 kind=nil / label=nil 的嵌套表会渲染成空行（空选项）。
local clockRows = sections.clock
local function AddRow(row) clockRows[#clockRows + 1] = row end
local function AddRows(rows)
    for _, row in ipairs(rows) do AddRow(row) end
end

-- 字体分组：六组（time/alarm/date/weekday/meridiem/prefix），字号固定不进选项
AddRow({ kind = "subheading", label = L.SUBH_FONT_TIME or "Time Font" })
AddRows(FontRows("time"))
AddRow({ kind = "subheading", label = L.SUBH_FONT_ALARM or "Alarm Font" })
AddRows(FontRows("alarm", function() return P().alarm.show ~= true end, true))
AddRow({ kind = "subheading", label = L.SUBH_FONT_DATE or "Date Font" })
AddRows(FontRows("date", function() return P().dateMode == "NONE" end))
AddRow({ kind = "subheading", label = L.SUBH_FONT_WEEKDAY or "Weekday Font" })
AddRows(FontRows("weekday", function()
    local dm = P().dateMode
    return dm == "NONE" or dm == "DATE"
end))
AddRow({ kind = "subheading", label = L.SUBH_FONT_MERIDIEM or "AM/PM Font" })
AddRows(FontRows("meridiem", function() return P().use24 == true end, false, true))
AddRow({ kind = "subheading", label = L.SUBH_FONT_PREFIX or "Prefix Font" })
AddRows(FontRows("prefix", function() return P().showPrefix ~= true end, false, true))

local sectionNames = {
    clock = L.SEC_CLOCK,  -- v2：「时钟与外观」→「时钟面板」
}
local sectionKeys = {
    clock = {
        "shown", "use24", "frameLocked", "showBorder", "frameColor", "frameAlpha", "borderColor", "panelScale", "panelAlpha", "childFontOffset",
        "timeSource", "showPrefix", "meridiemStyle", "forceChineseMeridiem", "dateMode", "dateFormat", "dateHideYear", "weekdayStyle",
        "alarm.show", "alarm.warnMinutes", "alarm.flash",
        "font.time.face", "font.time.outline", "font.time.color",
        "font.alarm.face", "font.alarm.outline",
        "font.date.face", "font.date.outline", "font.date.color",
        "font.weekday.face", "font.weekday.outline", "font.weekday.color",
        "font.meridiem.face", "font.meridiem.outline", "font.meridiem.useClassColor", "font.meridiem.color",
        "font.prefix.face", "font.prefix.outline", "font.prefix.useClassColor", "font.prefix.color",
    },
}

local function SameValue(a, b)
    if type(a) ~= "table" or type(b) ~= "table" then return a == b end
    for key, value in pairs(a) do if not SameValue(value, b[key]) then return false end end
    for key in pairs(b) do if a[key] == nil then return false end end
    return true
end

local function CountChanged()
    local count = 0
    for _, keys in pairs(sectionKeys) do
        for _, key in ipairs(keys) do
            if not SameValue(ReadPath(P(), key), ReadPath(ns.defaults.settings, key)) then
                count = count + 1
            end
        end
    end
    return count
end

local function ResetSection(id)
    local keys = sectionKeys[id]
    if not keys or not ns.db then return false end
    local changed = false
    for _, key in ipairs(keys) do
        local value = ReadPath(ns.db.settings, key)
        local def = ReadPath(ns.defaults.settings, key)
        if not SameValue(value, def) then
            WritePath(ns.db.settings, key, CopyValue(def))
            changed = true
        end
    end
    if changed then ns.Clock.ApplyAll() end
    return changed
end

local tab

local function Build()
    if tab then return tab end
    local lib = GetOF()
    if not lib then return nil end
    tab = lib.RegisterTab({
        name = ns.title,
        saved = ns.db or {},
        groups = {
            -- v2：字体并入「时钟面板」分组，布局 section（时间偏移）随功能删除
            { name = L.GROUP_CLOCK or "Clock", sections = { "clock" } },
        },
        sectionName = function(id) return sectionNames[id] or id end,
        elements = function(id) return sections[id] or sections.clock end,
        landing = function() return "clock" end,
        changedCount = CountChanged,
        resetSection = ResetSection,
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

--- 加载期注册 tab 与原生 stub 页（Core:Init 调用；adeBagPack/Options.lua:321-327 同款）。
--- ade_UIKit 为 ## Dependencies 硬依赖，失败直接 error 暴露，不做静默降级。
function ns.InitOptionsStub()
    if not Build() then
        error("adeTimerHUD: 加载期注册设置页失败（ade_UIKit RegisterTab 不可用）")
    end
end

function ns.OpenSettings()
    local t = Build()
    if t then t:Open("clock") end
end

function ns.RefreshOptions()
    if tab and tab.Refresh then tab:Refresh() end
end
