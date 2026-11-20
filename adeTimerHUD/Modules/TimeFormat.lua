--[==[ adeTimerHUD / Modules/TimeFormat.lua — 时段标记格式化 API（v4，规划 §十）
公开接口（脱库、只依赖本插件 Locales）：
  ns.TimeFormat.Format(hour, minute, style) → string
    · INTERNATIONAL（默认）：hour>=12 → "PM"，否则 "AM"
    · CHINESE：按本地日期分三套季节边界（见 SEASON_BOUNDS），左闭右开、分钟级；
               minute 参数自 r009 起参与判断（05:30 / 06:30 / 18:30 边界）。
    · ANCIENT：子时[0,2) / 丑时[2,4) / … / 亥时[22,24)，floor(hour/2)+1（整点）
  ns.TimeFormat.ChineseSeason() → "MID"|"SUMMER"|"WINTER"（本地日期，便于 /dump 验证）
  ns.TimeFormat.IsCJKLocale() → bool（zhCN/zhTW/koKR）
  ns.TimeFormat.CanUseChinese(force) → bool（CJK 端恒 true；非 CJK 端需 force）
  ns.TimeFormat.EffectiveStyle(style, force) → string（未获允许时回落 INTERNATIONAL）
  ns.TimeFormat.Styles() → {{value,text},...}
    函数式下拉项（调用时取 L，避免加载期文案未就绪）。
标签 CSV 走 Locales（用户可见文本不硬编码）；区间边界是规则数据，固定在模块内。
]==]
local addonName = ...
local ns = _G.adeTimerHUD or {}
_G.adeTimerHUD = ns

local L = ns.L or {}
local TimeFormat = {}
ns.TimeFormat = TimeFormat

-- 中文时段：7 个标签对应 [0,b1) … [b6,1440)，b 为当日分钟数。
-- 用户 2026-11-20 给定三套季节边界（左闭右开）：
--   春秋 2/6–5/5、8/6–11/5：傍晚 17:00–18:30 → b6=1110
--   夏   5/6–8/5：凌晨止于 05:30（b1=330）、晚上起于 19:00（b6=1140）
--   冬   11/6–2/5：凌晨止于 06:30（b1=390）、晚上起于 18:00（b6=1080）
local SEASON_BOUNDS = {
    MID = { 360, 480, 660, 780, 1020, 1110 },
    SUMMER = { 330, 480, 660, 780, 1020, 1140 },
    WINTER = { 390, 480, 660, 780, 1020, 1080 },
}

function TimeFormat.ChineseSeason()
    local t = date("*t")
    -- month*100+day：206–505 / 806–1105 春秋，506–805 夏，其余（含跨年 1106–205）冬
    local md = (tonumber(t.month) or 1) * 100 + (tonumber(t.day) or 1)
    if (md >= 206 and md <= 505) or (md >= 806 and md <= 1105) then
        return "MID"
    elseif md >= 506 and md <= 805 then
        return "SUMMER"
    end
    return "WINTER"
end

-- CJK 客户端集合沿用 Modules/Media.lua:20 实证口径；其余客户端缺中文字形
local CJK_LOCALES = { zhCN = true, zhTW = true, koKR = true }

local function Labels(csv)
    local out = {}
    for part in tostring(csv or ""):gmatch("[^,]+") do
        out[#out + 1] = part
    end
    return out
end

function TimeFormat.IsCJKLocale()
    return CJK_LOCALES[GetLocale()] == true
end

--- 非 CJK 端只有玩家显式开启「强制使用中文格式」后才允许中文/古代标签
function TimeFormat.CanUseChinese(force)
    return TimeFormat.IsCJKLocale() or force == true
end

--- 渲染前的样式钳制：未获允许时即使存档里存着中文/古代也回落国际通用
function TimeFormat.EffectiveStyle(style, force)
    if TimeFormat.CanUseChinese(force) then return style end
    return "INTERNATIONAL"
end

function TimeFormat.Format(hour, minute, style)
    local h = tonumber(hour) or 0
    if style == "CHINESE" then
        local labels = Labels(L.CN_PERIOD_LABELS)
        local mins = h * 60 + (tonumber(minute) or 0)
        if mins < 0 then mins = 0 elseif mins > 1439 then mins = 1439 end
        local bounds = SEASON_BOUNDS[TimeFormat.ChineseSeason()] or SEASON_BOUNDS.MID
        for i, b in ipairs(bounds) do
            if mins < b then return labels[i] or "" end
        end
        return labels[#labels] or ""
    elseif style == "ANCIENT" then
        local labels = Labels(L.ANCIENT_HOUR_LABELS)
        local i = math.floor(h / 2) + 1
        if i < 1 then i = 1 elseif i > #labels then i = #labels end
        return labels[i] or ""
    end
    return (h >= 12) and "PM" or "AM"
end

function TimeFormat.Styles()
    return {
        { value = "INTERNATIONAL", text = L.MERIDIEM_INTERNATIONAL or "AM/PM" },
        { value = "CHINESE", text = L.MERIDIEM_CHINESE or "Chinese" },
        { value = "ANCIENT", text = L.MERIDIEM_ANCIENT or "Ancient" },
    }
end

--[==[ 统一格式化（r021，规划 §十八）：时钟/日期/星期全部收拢到本模块，
Clock.lua 只负责布局与模块调度。英文月份/星期为静态表——暴雪无 locale 无关的
英文名称 API；本地全称走暴雪 CALENDAR_* 常量，本地缩写按 locale 自带表。 ]==]
local EN_MONTHS_FULL = { "January", "February", "March", "April", "May", "June",
    "July", "August", "September", "October", "November", "December" }
local EN_MONTHS_SHORT = { "Jan", "Feb", "Mar", "Apr", "May", "Jun",
    "Jul", "Aug", "Sep", "Oct", "Nov", "Dec" }
local EN_WEEKDAYS_FULL = { "Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday" }
local EN_WEEKDAYS_SHORT = { "Sun.", "Mon.", "Tue.", "Wed.", "Thu.", "Fri.", "Sat." }
-- 中文全称「星期X」/ 缩写「周X」（zhCN）；繁体缩写「週X」
local LOCAL_WEEKDAYS_FULL = {
    zhCN = { "星期日", "星期一", "星期二", "星期三", "星期四", "星期五", "星期六" },
    zhTW = { "星期日", "星期一", "星期二", "星期三", "星期四", "星期五", "星期六" },
}
local LOCAL_WEEKDAYS_SHORT = {
    zhCN = { "周日", "周一", "周二", "周三", "周四", "周五", "周六" },
    zhTW = { "週日", "週一", "週二", "週三", "週四", "週五", "週六" },
}

local function PlainReplace(fmt, pat, value)
    if not fmt:find(pat, 1, true) then return fmt end
    return fmt:gsub(pat, (tostring(value):gsub("%%", "%%%%")))
end

local function StripYear(text)
    if not text then return text end
    text = text:gsub("^%d%d%d%d年", "")
    text = text:gsub("[,，]%s*%d%d%d%d$", "")
    text = text:gsub("%s+%d%d%d%d$", "")
    text = text:gsub("[/%.%-]%d%d%d%d$", "")
    text = text:gsub("^%d%d%d%d[/%.%-]", "")
    return text
end

--- 12h 只转 1–12，时段标记由 Format 生成；冒号恒半角
function TimeFormat.ClockText(h, m, use24)
    h = tonumber(h) or 0
    if not use24 then
        h = h % 12
        if h == 0 then h = 12 end
    end
    return format("%d:%02d", h, m or 0)
end

--- 日期格式化：%B/%b 走暴雪本地化月份；{EN_MON_*} 走英文静态表
function TimeFormat.FormatDateText(fmt, showYear)
    fmt = tostring(fmt or "")
    if fmt == "" then fmt = "%Y/%m/%d" end
    local t = date("*t")
    local weekdays = _G.CALENDAR_WEEKDAY_NAMES
    local months = _G.CALENDAR_FULLDATE_MONTH_NAMES
    if weekdays and weekdays[t.wday] then
        fmt = PlainReplace(fmt, "%A", weekdays[t.wday])
        fmt = PlainReplace(fmt, "%a", weekdays[t.wday])
    end
    if months and months[t.month] then
        fmt = PlainReplace(fmt, "%B", months[t.month])
        fmt = PlainReplace(fmt, "%b", months[t.month])
    end
    fmt = PlainReplace(fmt, "{EN_MON_SHORT}", EN_MONTHS_SHORT[t.month] or "")
    fmt = PlainReplace(fmt, "{EN_MON_FULL}", EN_MONTHS_FULL[t.month] or "")
    local out = date(fmt)
    if showYear == false then out = StripYear(out) end
    return out
end

--- 星期文本：LOCAL_FULL / LOCAL_SHORT / EN_FULL / EN_SHORT
function TimeFormat.FormatWeekday(style)
    local idx = tonumber(date("*t").wday) or 1
    if style == "EN_FULL" then
        return EN_WEEKDAYS_FULL[idx] or ""
    elseif style == "EN_SHORT" then
        return EN_WEEKDAYS_SHORT[idx] or ""
    else
        local locale = GetLocale()
        local tbl = (style == "LOCAL_SHORT" and LOCAL_WEEKDAYS_SHORT[locale])
            or LOCAL_WEEKDAYS_FULL[locale]
        if tbl and tbl[idx] then return tbl[idx] end
        if style == "LOCAL_SHORT" then return EN_WEEKDAYS_SHORT[idx] or "" end
        local weekdays = _G.CALENDAR_WEEKDAY_NAMES
        return (weekdays and weekdays[idx]) or ""
    end
end
