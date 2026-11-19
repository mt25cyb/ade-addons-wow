------------------------------------------------------------
-- 设置窗口：顶部插件切换标签（b028 自 WindowMixin.lua 拆出）。
-- 标签条的截断限宽与横向滚动已提炼为独立 API（Widget/ScrollTabs.lua 的
-- lib.CreateScrollableTabStrip），本文件只负责窗口侧的数据接线：
-- Internal.Tabs → strip:SetTabs、选中态、Tab 失效回退与搜索范围复选框显隐。
------------------------------------------------------------
local lib = ResolveBOFNamespace("ade_UIKit")
if not lib then return end

local Internal = lib.Internal
local WindowMixin = Internal.Mixins.Window

-- [[ Tabs ]] --  原 WindowMixin.lua:149-190（b027 滚动逻辑已上提至 TabStrip API）
function WindowMixin:RefreshTabs()
    if not self.TabStrip then
        self.TabStrip = lib.CreateScrollableTabStrip(self, {
            right = (Internal.Geometry.BodyRight or -18) - (Internal.Geometry.SearchWidth or 160),
            onSelect = function(_, tab)
                if tab == self.Tab then return end
                PlaySound(SOUNDKIT.IG_CHARACTER_INFO_TAB) -- KAF WindowMixin.lua:97
                self:ShowTab(tab)
            end,
        })
    end
    local tabs = Internal.Tabs
    local list = {}
    for _, tab in ipairs(tabs) do list[#list + 1] = { id = tab, text = tab.Config.name } end
    self.TabStrip:SetTabs(list)
    self.TabStrip:SetSelected(self.Tab)
    self:UpdateSearchAll() -- KAF WindowMixin.lua:111：Tab 数变了，搜索范围复选框的显示随之
    if self.Tab and not tContains(tabs, self.Tab) then
        self.Tab = nil
        if self:IsShown() and tabs[1] then self:ShowTab(tabs[1]) end
    end
end

-- KAF WindowMixin.lua:121-128：多 Tab 才显示"搜索全部"；广度标签贴它，否则贴关闭键；
-- 重载条右边界收到广度复选框左侧。
function WindowMixin:UpdateSearchAll()
    local several = #Internal.Tabs > 1
    self.SearchAll:SetShown(several)
    self.SearchAllLabel:SetShown(several)
    self.SearchBroadLabel:ClearAllPoints()
    self.SearchBroadLabel:SetPoint("RIGHT", several and self.SearchAll or self.CloseButton, "LEFT", -16, 0)
    self.ReloadBackground:SetPoint("BOTTOMRIGHT", self.SearchBroad, "BOTTOMLEFT", -12, -2)
end
