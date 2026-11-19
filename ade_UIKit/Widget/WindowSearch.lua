------------------------------------------------------------
-- 设置窗口：搜索 UI 挂接（b028 自 WindowMixin.lua 拆出；b029 由 WindowSearchUI.lua 更名）。
-- 搜索算法本体在 Widget/Search.lua（Internal.Search）；本文件只负责
-- 搜索框/范围复选框的事件接线与结果页组装。
------------------------------------------------------------
local lib = ResolveBOFNamespace("ade_UIKit")
if not lib then return end

local Internal = lib.Internal
local WindowMixin = Internal.Mixins.Window
local Protected = Internal.Protected

-- [[ 搜索 ]] --  KAF WindowSearch.lua:33-98（当前 Tab + 仅名称，无勾选框）
function WindowMixin:LoadSearch()
    -- KAF WindowSearch.lua:36-37：必须用 HookScript，否则覆盖 SearchBoxTemplate 自带的占位符隐藏与清除按钮。
    self.SearchBox:HookScript("OnTextChanged", function(box, userInput)
        if box.Instructions then box.Instructions:SetShown(box:GetText() == "") end
        if userInput or self.Searching then self:OnSearch(box:GetText()) end
    end)
    self.SearchBox:HookScript("OnHide", function(box) box:SetText("") end)
    self.SearchBox:SetScript("OnEscapePressed", function(edit)
        if self.Searching then self:ShowSection(self.SectionId, nil, true) end
        edit:ClearFocus()
    end)
    -- KAF WindowSearch.lua:39-49：范围（每个 Tab）与广度（描述）勾选后重跑当前搜索。
    self.SearchAll:SetScript("OnClick", function(button)
        self.SearchEveryTab = button:GetChecked() and true or false
        Internal.SetShared("SearchAll", self.SearchEveryTab)
        if self.Searching then self:OnSearch(self.SearchBox:GetText()) end
    end)
    self.SearchBroad:SetScript("OnClick", function(button)
        self.BroadSearch = button:GetChecked() and true or false
        Internal.SetShared("SearchBroad", self.BroadSearch)
        if self.Searching then self:OnSearch(self.SearchBox:GetText()) end
    end)
end

-- KAF WindowSearch.lua:56-78：命中行按 Tab 分组（勾选"搜索全部"时每个 Tab 一个标题），
-- 分区名可点击打开——跨 Tab 的走 ShowTab 回到那个 Tab。
function WindowMixin:SearchElements(text)
    local everyTab = self.SearchEveryTab and #Internal.Tabs > 1
    local list = {}
    for _, group in ipairs(Internal.Search(text, everyTab, self.Tab, self.BroadSearch)) do
        local tab = group.Tab
        if everyTab then list[#list + 1] = { Kind = "Header", Text = tab.Config.name } end
        for _, section in ipairs(group.Sections) do
            list[#list + 1] = { Kind = "SearchHeading", Text = section.Name,
                OnClick = function() self:ShowTab(tab, section.Id) end }
            for _, row in ipairs(section.Rows) do list[#list + 1] = row end
        end
    end
    if #list == 0 then list[1] = { Kind = "Note", Text = self.Strings.NoResults } end
    return list
end

function WindowMixin:OnSearch(text, scrollPosition)
    text = text and text:gsub("^%s+", ""):gsub("%s+$", "") or ""
    if text == "" then
        if self.Searching and self:IsShown() then self:ShowSection(self.SectionId, nil, true) end
        return
    end
    self.Searching = true
    self.PageTitle:SetText(self.Strings.SearchResults)
    self.Filling = true
    Protected(self.RefreshNav, self)
    Protected(self.FillPage, self, scrollPosition or ScrollBoxConstants.DiscardScrollPosition, self:SearchElements(text))
    self:EndFill()
end
