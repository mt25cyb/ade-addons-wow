------------------------------------------------------------
-- 公共日期格式化 API（供 ADE 系列插件调用）。
-- 底本：Z_AchievementDateFormat 的 XFormatShortDate（两位年补 20）；
--       7 预设 + Custom 来自 Krowi_AchievementFilter/Options/EventReminders.lua:54-73；
--       %B/%b/%A/%a 本地名称替换参考其 Gui/EventReminder/AlertSystem.lua:305-343。
-- 本模块只负责格式化，不持有设置、不挂 hook。
------------------------------------------------------------
local lib = ResolveBOFNamespace("ade_UIKit")
if not lib then return end

local date, time = date, time
local sformat, tinsert = string.format, table.insert

--- 7 个预设 + Custom 回退值（与 Krowi 原串逐字一致，含时分）。
lib.DATE_FORMATS = {
    [1] = "%d/%m/%Y %R",
    [2] = "%d/%m/%Y %I:%M %p",
    [3] = "%m/%d/%Y %R",
    [4] = "%m/%d/%Y %I:%M %p",
    [5] = "%Y/%m/%d %R",
    [6] = "%Y/%m/%d %I:%M %p",
    [7] = "%c",
}
lib.DATE_PRESET_COUNT = 7
lib.DATE_CUSTOM_DEFAULT = "%m/%d/%Y %R"

function lib.DatePresetFormat(index)
    local i = tonumber(index)
    if not i or i < 1 or i > lib.DATE_PRESET_COUNT then return nil end
    return lib.DATE_FORMATS[i]
end

function lib.DatePresetKeys()
    local keys = {}
    for i = 1, lib.DATE_PRESET_COUNT do tinsert(keys, tostring(i)) end
    tinsert(keys, "custom")
    return keys
end

-- 多字节安全的「取前三字」：Krowi AlertSystem.lua:305-310 的同款实现。
local firstThreeCharacters = "^" .. ("[%z\1-\127\194-\244][\128-\191]*"):rep(3)
local function Abbreviate(name)
    return name:match(firstThreeCharacters) or name
end

--- 把 %B/%b/%A/%a 替换为暴雪本地化名称。
-- 名称来源为暴雪全局 CALENDAR_FULLDATE_MONTH_NAMES / CALENDAR_WEEKDAY_NAMES
-- （FrameXMLBase/Constants.lua:314、325），无需自备或臆造中文本地化表。
function lib.LocalizeDateFormat(fmt, timeValue)
    if not fmt then return fmt end
    local hasB = fmt:find("%%B", 1, true) ~= nil
    local hasb = fmt:find("%%b", 1, true) ~= nil
    local hasA = fmt:find("%%A", 1, true) ~= nil
    local hasa = fmt:find("%%a", 1, true) ~= nil
    if not (hasB or hasb or hasA or hasa) then return fmt end

    local t = date("*t", timeValue)
    local months = _G.CALENDAR_FULLDATE_MONTH_NAMES
    local weekdays = _G.CALENDAR_WEEKDAY_NAMES
    if (hasB or hasb) and months and months[t.month] then
        if hasB then fmt = fmt:gsub("%%B", months[t.month]) end
        if hasb then fmt = fmt:gsub("%%b", Abbreviate(months[t.month])) end
    end
    if (hasA or hasa) and weekdays and weekdays[t.wday] then
        if hasA then fmt = fmt:gsub("%%A", weekdays[t.wday]) end
        if hasa then fmt = fmt:gsub("%%a", Abbreviate(weekdays[t.wday])) end
    end
    return fmt
end

--- 统一格式出口。
-- @param day, month, year 来自 GetAchievementInfo / GetAchievementComparisonInfo 的日期（year 可为两位年）
-- @param fmt strftime 格式串；nil 或空串时使用 Z 插件观感 "%Y/%m/%d"
-- @param opts table 可选：{ localeNames = false } 关闭 %B/%b/%A/%a 的本机名称替换
-- @return string|nil
function lib.FormatDate(day, month, year, fmt, opts)
    if not day or not month then return nil end
    local d, m = tonumber(day), tonumber(month)
    if not d or not m then return nil end
    local y = tonumber(year) or 0
    if y < 100 then y = 2000 + y end

    local ok, ts = pcall(time, { year = y, month = m, day = d, hour = 0, min = 0, sec = 0 })
    if not ok or not ts then return nil end

    if fmt == nil or fmt == "" then return date("%Y/%m/%d", ts) end
    if not (opts and opts.localeNames == false) then
        fmt = lib.LocalizeDateFormat(fmt, ts)
    end
    return date(fmt, ts)
end
