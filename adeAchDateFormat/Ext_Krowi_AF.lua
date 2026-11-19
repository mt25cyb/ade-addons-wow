-- adeAchDateFormat — Krowi_AchievementFilter 行日期扩展（v6.5-r004 起改名 Ext_Krowi_AF.lua，
-- 对齐 Extend/Ext_*.lua 扩展文件命名惯例；逻辑不变）。
-- 机制已由 Z_AchievementDateFormat 扩展在游戏内证实：hook 基类 Update 覆盖 Small/Normal/Light 行。
-- 本文件只改 DateCompleted 文本，不改可见性（兼容 Krowi 的 HideDateCompleted 选项）。
local ADF = _G.adeAchDateFormat
if not ADF then return end
local L = ADF.L or {}

local function KrowiEnabled()
    return ADF.db == nil or ADF:Get("enableKrowi") ~= false
end

local function FormatKrowiButton(self)
    if not KrowiEnabled() then return end
    if not self.Completed or not self.DateCompleted then return end
    local achievement = self.Achievement
    if not achievement or not achievement.Id then return end
    local _, _, _, _, month, day, year = GetAchievementInfo(achievement.Id)
    if not month then return end
    local text = ADF.FormatDate(day, month, year)
    if text then self.DateCompleted:SetText(text) end
end

local hooked = false
local function HookKrowiUI()
    if hooked or not KrowiEnabled() then return end
    local mixin = _G.KrowiAF_AchievementButtonMixin
    if not mixin or type(mixin.Update) ~= "function" then return end
    hooked = true
    hooksecurefunc(mixin, "Update", FormatKrowiButton)
    ADF:Print(L.MSG_KROWI_HOOKED or "Krowi's Achievement Filter date hook installed.")
end

local function RefreshVisible()
    if not KrowiEnabled() then return end
    local frames = {
        _G.KrowiAF_AchievementsFrame and _G.KrowiAF_AchievementsFrame.ScrollView,
        _G.KrowiAF_SummaryFrame and _G.KrowiAF_SummaryFrame.AchievementsFrame
            and _G.KrowiAF_SummaryFrame.AchievementsFrame.ScrollView,
        _G.KrowiAF_AchievementCalendarFrame and _G.KrowiAF_AchievementCalendarFrame.SideFrame
            and _G.KrowiAF_AchievementCalendarFrame.SideFrame.AchievementsFrame
            and _G.KrowiAF_AchievementCalendarFrame.SideFrame.AchievementsFrame.ScrollView,
    }
    for _, scrollView in ipairs(frames) do
        if scrollView and scrollView.GetFrames then
            for _, button in ipairs(scrollView:GetFrames()) do
                pcall(FormatKrowiButton, button)
            end
        end
    end
end
ADF.RegisterRefresh(RefreshVisible)

-- Krowi 可能先于本插件加载：加载时立即试挂一次，并注册 ADDON_LOADED 兜底。
local f = CreateFrame("Frame")
f:RegisterEvent("ADDON_LOADED")
f:SetScript("OnEvent", function(_, event, arg1)
    if event == "ADDON_LOADED" and arg1 == "Krowi_AchievementFilter" then
        HookKrowiUI()
        f:UnregisterEvent("ADDON_LOADED")
    end
end)
HookKrowiUI()
