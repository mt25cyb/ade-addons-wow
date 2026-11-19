-- adeAchDateFormat — 格式适配层：把本插件设置翻译成 ade_UIKit.FormatDate 调用。
-- 唯一格式出口在 UIKit；本文件不再持有任何 strftime 实现。
local ADF = _G.adeAchDateFormat
if not ADF then return end
local L = ADF.L or {}

function ADF:GetFormatString()
    local preset = self:Get("dateFormat.preset")
    local fmt
    if preset == "custom" then
        local custom = self:Get("dateFormat.custom")
        if custom and custom ~= "" then
            fmt = custom
        else
            fmt = ADF.UIKit and ADF.UIKit.DATE_CUSTOM_DEFAULT or "%m/%d/%Y %R"
        end
    elseif ADF.UIKit and ADF.UIKit.DatePresetFormat then
        fmt = ADF.UIKit.DatePresetFormat(preset) or ADF.UIKit.DATE_CUSTOM_DEFAULT
    else
        fmt = "%Y/%m/%d"
    end
    -- hideTime（r006）：成就日期无时间，格式串里的 %R / %I:%M %p 会渲染成 00:00——
    -- 开启后剥掉时间 token（%c 整体不可拆，改用 %x 本地纯日期；FormatDate 最终走
    -- Lua date()，strftime 全集可用，见 UIKit Function/Format.lua:90）
    if self:Get("dateFormat.hideTime") then
        fmt = fmt:gsub("%%R", ""):gsub("%%I:%%M%s*%%p", "")
        if fmt:find("%%c") then fmt = "%x" end
        fmt = fmt:gsub("%s+$", "")
    end
    return fmt
end

--- 与 Z 插件同签名：FormatDate(day, month, year) → string|nil。
function ADF.FormatDate(day, month, year)
    local lib = ADF.UIKit
    if not lib or not lib.FormatDate then
        if not month or not day then return nil end
        local y = tonumber(year) or 0
        if y < 100 then y = 2000 + y end
        return string.format("20%02d/%02d/%02d", y % 100, month, day)
    end
    return lib.FormatDate(day, month, year, ADF:GetFormatString())
end

--- 成就链接 tooltip 的中文正则替换仍在本插件内（UIKit 不做文本改写）。
function ADF.FormatAchievementString(head, m, d, y, tail)
    if not m then return nil end
    local fmt = ADF:GetFormatString()
    local lib = ADF.UIKit
    local text
    if lib and lib.FormatDate then
        text = lib.FormatDate(d, m, y, fmt)
    else
        local yy = tonumber(y) or 0
        if yy < 100 then yy = 2000 + yy end
        text = string.format("20%02d/%02d/%02d", yy % 100, m, d)
    end
    if not text then return nil end
    return tostring(head or "") .. text .. tostring(tail or "")
end
