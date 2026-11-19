------------------------------------------------------------
-- 窗口核心（b028 拆分说明）：
--   Widget/WindowTabs.lua     顶部插件切换标签（经 lib.CreateScrollableTabStrip API）
--   Widget/WindowPage.lua     导航树 + 分区/页面填充与就地刷新
--   Widget/WindowFooter.lua   页脚（确认条/变更计数/重载提示）与默认值流程
--   Widget/WindowSearch.lua   搜索框接线（算法在 Widget/Search.lua）
-- 本文件仅保留窗口生命周期、字符串应用与 tooltip 转发。每个文件向同一
-- mixin 表追加方法，从不替换（KAF WindowMixin.lua:39-45）。
------------------------------------------------------------
local lib = ResolveBOFNamespace("ade_UIKit")
if not lib then return end

local L, Internal = lib.L, lib.Internal
local WindowMixin = Internal.Mixins.Window
local Protected, Ask = Internal.Protected, Internal.Ask

function lib.GetStrings()
    return {
        Overview = L["BOF_OVERVIEW"], Search = L["BOF_SEARCH"],
        SearchAll = L["BOF_SEARCH_ALL"], SearchBroad = L["BOF_SEARCH_BROAD"],
        SearchResults = L["BOF_SEARCH_RESULTS"], NoResults = L["BOF_NO_RESULTS"],
        Defaults = L["BOF_DEFAULTS"], ResetSection = L["BOF_RESET_SECTION"],
        ChangedCount = L["BOF_CHANGED_COUNT"], ReloadText = L["BOF_RELOAD_TEXT"],
        ReloadNow = L["BOF_RELOAD_NOW"], NotBound = L["BOF_NOT_BOUND"],
        PressAKey = L["BOF_PRESS_A_KEY"],
        All = L["BOF_ALL"], None = L["BOF_NONE"],
    }
end
-- [[ 核心状态 ]] --  KAF WindowMixin.lua:47-78
function WindowMixin:OnLoad()
    self.CloseButton:SetScript("OnClick", function() self:Hide() end)
    if self.ClosePanelButton then self.ClosePanelButton:SetScript("OnClick", function() self:Hide() end) end
    self.CloseButton:SetText(CLOSE)
    if self.NineSlice and self.NineSlice.Text then self.NineSlice.Text:SetText(SETTINGS_TITLE) end
    self.TabButtons = {} -- 兼容字段：b028 起标签按钮由 TabStrip 管理
    self:LoadLayout()
    self:LoadSearch()
    self:LoadPage()
end

function WindowMixin:Init(window)
    if window.Size then self:SetHeight(math.max(window.Size[2], Internal.Geometry.MinHeight)) end
    self:ApplyWidth()
    -- KAF WindowMixin.lua:73-76：恢复上次的搜索范围与广度勾选。
    self.SearchEveryTab = window.SearchAll and true or false
    self.SearchAll:SetChecked(self.SearchEveryTab)
    self.BroadSearch = window.SearchBroad and true or false
    self.SearchBroad:SetChecked(self.BroadSearch)
    if window.Point then
        self:ClearAllPoints()
        self:SetPoint(window.Point[1], UIParent, window.Point[2], window.Point[3], window.Point[4])
    end
    self:Layout()
end

function WindowMixin:ShowTab(tab, sectionId, optionId)
    if self.Tab ~= tab then
        local saved = tab:GetSaved()
        self:EndKeyCaptures()
        self.Tab = tab
        self.Config, self.Strings, self.Saved = tab.Config, lib.GetStrings(), saved
        self.SectionId, self.Searching, self.Confirming = nil, nil, nil
        if self.AppliedStrings ~= self.Strings then
            self.AppliedStrings = self.Strings
            self:ApplyStrings()
        end
        self:RefreshTabs()
    end
    self:Show()
    self:ShowSection(sectionId or Ask(nil, self.Config.landing) or "overview", optionId)
end
local shownEvents = { "PLAYER_REGEN_DISABLED", "PLAYER_REGEN_ENABLED", "UI_SCALE_CHANGED", "DISPLAY_SIZE_CHANGED" }
function WindowMixin:OnShow()
    for _, event in ipairs(shownEvents) do self:RegisterEvent(event) end
    self:ApplyWidth(true)
end
function WindowMixin:OnHide()
    for _, event in ipairs(shownEvents) do self:UnregisterEvent(event) end
    self:EndKeyCaptures()
    self.Confirming = nil
    self:HideTooltip()
end
function WindowMixin:OnEvent(event)
    if event == "UI_SCALE_CHANGED" or event == "DISPLAY_SIZE_CHANGED" then self:ApplyWidth(true); return end
    self.CombatStarting = event == "PLAYER_REGEN_DISABLED"
    if self.CombatStarting then Protected(self.EndKeyCaptures, self) end
    Protected(self.Refresh, self)
    self.CombatStarting = nil
end
function WindowMixin:InCombat() return self.CombatStarting or InCombatLockdown() end

-- [[ 文字 ]] --  KAF WindowMixin.lua:155-177（去右栏与搜索勾选框）
function WindowMixin:ApplyStrings()
    local s = self.Strings
    if self.SearchBox.Instructions then self.SearchBox.Instructions:SetText(s.Search) end
    -- KAF WindowMixin.lua:158-161：两个搜索复选框的标签文字，并把点按区扩到标签上。
    self.SearchAllLabel:SetText(s.SearchAll)
    self.SearchAll:SetHitRectInsets(0, -(self.SearchAllLabel:GetStringWidth() + 4), 0, 0)
    self.SearchBroadLabel:SetText(s.SearchBroad)
    self.SearchBroad:SetHitRectInsets(0, -(self.SearchBroadLabel:GetStringWidth() + 4), 0, 0)
    self.CancelButton:SetText(NO) -- KAF WindowMixin.lua:176：确认条的「否」在文字上串时设一次
    self.DefaultsButton:SetText(s.Defaults)
    Internal.FitButton(self.DefaultsButton)
    self.ReloadButton:SetText(s.ReloadNow)
    self.ReloadText:SetText(lib.Markup.Reload .. " " .. s.ReloadText)
end

-- [[ Tooltip 转发 ]] --  KAF 用 Krowi_Tooltip（右栏），本库统一走原生 GameTooltip。
function WindowMixin:OnRowEnter(option, row, x)
    if self.Tooltip then self.Tooltip:ShowRow(option, row, x) end
end
function WindowMixin:OnRowLeave(option)
    if self.Tooltip then self.Tooltip:HideRow(option) end
end
function WindowMixin:HideTooltip()
    if self.Tooltip then self.Tooltip:HideAll() end
end
