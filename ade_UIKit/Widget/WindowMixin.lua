------------------------------------------------------------
-- 窗口核心：WindowMixin + WindowPage + WindowSearch（KAF 三文件合并，去掉 Help 全部调用）。
-- 每个文件向同一 mixin 表追加方法，从不替换（KAF WindowMixin.lua:39-45）。
------------------------------------------------------------
local lib = ResolveBOFNamespace("ade_UIKit")
if not lib then return end

local L, Internal = lib.L, lib.Internal
local WindowMixin = Internal.Mixins.Window

local function Protected(func, ...)
    if type(func) ~= "function" then return false end
    local args, count = { ... }, select("#", ...)
    return xpcall(function() return func(unpack(args, 1, count)) end, CallErrorHandler)
end
local function Ask(fallback, func, ...)
    if type(func) ~= "function" then return fallback end
    local ok, result = Protected(func, ...)
    if ok then return result end
    return fallback
end

function lib.GetStrings()
    return {
        Overview = L["BOF_OVERVIEW"] or "概览", Search = L["BOF_SEARCH"] or "搜索",
        SearchAll = L["BOF_SEARCH_ALL"] or "搜索全部标签页", SearchBroad = L["BOF_SEARCH_BROAD"] or "搜索描述",
        SearchResults = L["BOF_SEARCH_RESULTS"] or "搜索结果", NoResults = L["BOF_NO_RESULTS"] or "未找到任何内容",
        Defaults = L["BOF_DEFAULTS"] or "恢复默认值", ResetSection = L["BOF_RESET_SECTION"] or "将 %s 的所有选项恢复默认值？",
        ChangedCount = L["BOF_CHANGED_COUNT"] or "%d 项已更改", ReloadText = L["BOF_RELOAD_TEXT"] or "部分更改在重载后生效",
        ReloadNow = L["BOF_RELOAD_NOW"] or "立即重载", NotBound = L["BOF_NOT_BOUND"] or "未绑定",
        PressAKey = L["BOF_PRESS_A_KEY"] or "按下按键",
        All = L["BOF_ALL"] or "All", None = L["BOF_NONE"] or "None",
    }
end

-- [[ 核心状态 ]] --  KAF WindowMixin.lua:47-78
function WindowMixin:OnLoad()
    self.CloseButton:SetScript("OnClick", function() self:Hide() end)
    if self.ClosePanelButton then self.ClosePanelButton:SetScript("OnClick", function() self:Hide() end) end
    self.CloseButton:SetText(CLOSE)
    if self.NineSlice and self.NineSlice.Text then self.NineSlice.Text:SetText(SETTINGS_TITLE) end
    self.TabButtons = {}
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

-- [[ Tabs ]] --  KAF WindowMixin.lua:83-148
function WindowMixin:RefreshTabs()
    local tabs = Internal.Tabs
    for i, tab in ipairs(tabs) do
        local button = self.TabButtons[i]
        if not button then
            button = CreateFrame("Button", nil, self, "MinimalTabTemplate")
            button:SetHeight(37)
            if i == 1 then button:SetPoint("TOPLEFT", self, "TOPLEFT", 32, -27)
            else button:SetPoint("TOPLEFT", self.TabButtons[i - 1], "TOPRIGHT", 5, 0) end
            button:SetScript("OnClick", function(clicked)
                if clicked.Tab == self.Tab then return end
                PlaySound(SOUNDKIT.IG_CHARACTER_INFO_TAB) -- KAF WindowMixin.lua:97
                self:ShowTab(clicked.Tab)
            end)
            self.TabButtons[i] = button
        end
        button.Tab = tab
        button.Text:SetText(tab.Config.name)
        button:SetWidth(button.Text:GetStringWidth() + 40)
        if button.SetSelected then button:SetSelected(tab == self.Tab) end
        button:Show()
    end
    for i = #tabs + 1, #self.TabButtons do self.TabButtons[i]:Hide() end
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
local function FitButton(button)
    button:SetWidth(math.max(96, (button:GetFontString() and button:GetFontString():GetStringWidth() or 0) + 24))
end
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
    FitButton(self.DefaultsButton)
    self.ReloadButton:SetText(s.ReloadNow)
    self.ReloadText:SetText(lib.Markup.Reload .. " " .. s.ReloadText)
end

-- [[ 页面加载 ]] --  KAF WindowPage.lua:97-101
function WindowMixin:LoadPage()
    self.DefaultsButton:SetScript("OnClick", function() self:OnDefaultsClick() end)
    self.CancelButton:SetScript("OnClick", function() self:CancelConfirm() end)
    self.ReloadButton:SetScript("OnClick", function() if not InCombatLockdown() then ReloadUI() end end)
end

-- [[ 导航 ]] --  KAF WindowPage.lua:105-116；无「概览」，首个组头占概览位置。
function WindowMixin:RefreshNav()
    local config = self.Config
    local list = {}
    for i, group in ipairs(config.groups) do
        -- 组间隔条只在非首组前插入：首组头贴导航树顶部，不留空白（用户实测要求；KAF 视觉同此）。
        if i > 1 then list[#list + 1] = { Kind = "NavSpacer" } end
        list[#list + 1] = { Kind = "NavHeader", Text = group.name or group.Name or "", Index = ((i - 1) % 3) + 1 }
        for _, id in ipairs(group.sections or group.Sections or {}) do
            list[#list + 1] = {
                Kind = "NavButton", Id = id,
                Text = Ask(id, config.sectionName or config.SectionName, id),
                IsNew = Ask(false, config.isNew or config.IsNew, id) and true or false,
            }
        end
    end
    self.NavScrollBox:SetDataProvider(CreateDataProvider(list), ScrollBoxConstants.RetainScrollPosition)
end

-- [[ 分区与页面 ]] --  KAF WindowPage.lua:120-261
local function Flatten(elements)
    return Internal.Flatten(elements, Internal.Kinds)
end

local function Signed(option)
    return (option.Id or "") .. "|" .. option:GetLabel()
end

local function Drawn(element, kind)
    local drawn = {}
    if element.Kind == "Link" then drawn[1] = tostring(element.Detail or "")
    elseif kind and kind.Cells then
        for i, cell in ipairs(kind.Cells(element) or {}) do drawn[i] = Signed(cell) end
    end
    return #drawn > 0 and (" [" .. table.concat(drawn, ", ") .. "]") or ""
end

local function Signature(elements)
    local parts = {}
    for i, element in ipairs(elements) do
        local kind = Internal.Kinds[element.Kind]
        local option, with
        if kind and kind.Options then option, with = kind.Options(element) end
        local beside = with and not with:IsHidden() and ("+" .. (with.Id or "")) or ""
        parts[i] = element.Kind .. ":" .. (option and (Signed(option) .. beside) or tostring(element.Key or element.Text or element.Label or ""))
            .. Drawn(element, kind)
    end
    return table.concat(parts, "\n")
end

local function SignatureOf(elements)
    return Ask(nil, Signature, elements)
end

local function ReadPage(window, id)
    local ok, elements, signature = Protected(function()
        local elements = Flatten(window.Config.elements(id))
        return elements, Signature(elements)
    end)
    if ok then return elements, signature end
end

local function DefaultsShown(window, confirming)
    return confirming ~= nil or not window.Searching and window.SectionId ~= nil
end

function WindowMixin:ShowSection(id, optionId, keepSearchText)
    local config = self.Config
    local elements, signature = ReadPage(self, id)
    if not elements and self.SectionId and self.SectionId ~= id then self:ReloadSection(); return end
    self.SectionId = id
    self.Searching = nil
    self.Confirming = nil
    if not keepSearchText and self.SearchBox:GetText() ~= "" then self.SearchBox:SetText("") end
    Protected(config.onSectionShown, id)
    self.PageTitle:SetText(Ask(id, config.sectionName, id))
    self.DefaultsButton:SetShown(DefaultsShown(self))
    self.Filling = true
    Protected(self.RefreshNav, self)
    local ok = Protected(self.FillPage, self, ScrollBoxConstants.DiscardScrollPosition, elements or {}, signature or "")
    if ok and elements and self.Saved then self.Saved.LastSection = id end
    self:EndFill()
    if optionId and self.ScrollToOption then self:ScrollToOption(optionId) end
end

-- Config.Tab:Refresh 的入口：就地刷新当前分区（KAF WindowMixin.lua:256 的 Refresh 包装）。
function WindowMixin:RefreshPage()
    self:Refresh()
end

function WindowMixin:ScrollToOption(optionId)
    for _, element in ipairs(self.Elements or {}) do
        local kind = Internal.Kinds[element.Kind]
        local option = kind and kind.Options and select(1, kind.Options(element))
        if option and option.Id == optionId then
            self.PageScrollBox:ScrollToElementData(element, ScrollBoxConstants.AlignCenter)
            return
        end
    end
end

function WindowMixin:FillPage(scrollPosition, elements, signature)
    if not elements then elements, signature = ReadPage(self, self.SectionId)
    elseif not signature then signature = SignatureOf(elements) end
    local filled = elements ~= nil and signature ~= nil
    self.Elements = filled and elements or {}
    self.Signature = filled and signature or ""
    self.PageScrollBox:SetDataProvider(CreateDataProvider(self.Elements), scrollPosition)
    self:RefreshFooter()
    return filled
end

function WindowMixin:ReloadSection()
    if not self:IsShown() or not self.SectionId then return end
    if self.Searching then self:OnSearch(self.SearchBox:GetText(), ScrollBoxConstants.RetainScrollPosition); return end
    self:FillPage(ScrollBoxConstants.RetainScrollPosition)
end

local refreshing
local function RefreshRefreshing() refreshing:Refresh() end
local function RefreshRow(frame)
    local row = frame.Row
    if row and row.Refresh then
        refreshing = row
        xpcall(RefreshRefreshing, CallErrorHandler)
        refreshing = nil
    end
end

function WindowMixin:Refresh()
    if not self:IsShown() then return end
    self.PageScrollBox:ForEachFrame(RefreshRow)
    self:RefreshFooter()
end

function WindowMixin:EndKeyCaptures()
    self.PageScrollBox:ForEachFrame(function(frame)
        local row = frame.Row
        if row and row.EndKeyCapture then row:EndKeyCapture() end
    end)
end

-- [[ 页脚 / 确认 / 默认值 ]] --  KAF WindowPage.lua:269-409
function WindowMixin:RefreshFooter()
    local confirming = self:ConfirmingHere()
    if not confirming then self.Confirming = nil end
    self.CancelButton:SetShown(confirming)
    self.PageTitle:SetShown(not confirming)
    self.ChangedText:ClearAllPoints()
    self.ChangedText:SetPoint("RIGHT", confirming and self.CancelButton or self.DefaultsButton, "LEFT", -8, 0)
    if confirming then
        self.ChangedText:SetPoint("LEFT", self.PageTitle, "LEFT")
        self.ChangedText:SetFontObject("GameFontHighlight")
        self.ChangedText:SetText(confirming.Text)
        self.DefaultsButton:SetText(YES)
        self.DefaultsButton:SetEnabled(true)
    else
        local count = (not self.Searching and self.SectionId ~= nil) and tonumber(Ask(0, self.Config.changedCount, self.SectionId)) or 0
        self.ChangedText:SetFontObject("GameFontDisableSmall")
        self.ChangedText:SetText(count > 0 and self.Strings.ChangedCount:format(count) or "")
        self.DefaultsButton:SetText(self.Strings.Defaults)
        self.DefaultsButton:SetEnabled(count > 0)
    end
    FitButton(self.DefaultsButton)
    self.DefaultsButton:SetShown(DefaultsShown(self, confirming))
    local reload = self.ReloadPending and true or false
    self.ReloadBackground:SetShown(reload)
    self.ReloadText:SetShown(reload)
    self.ReloadButton:SetShown(reload)
    self.ReloadButton:SetEnabled(not self:InCombat())
end

local function NeedsReload(option)
    return option ~= nil and option.GetNeedsReload ~= nil and option:GetNeedsReload()
end

function WindowMixin:OnOptionChanged(option, with)
    if NeedsReload(option) or NeedsReload(with) then self.ReloadPending = true end
    if not self.SectionId or self.Searching and option and option.Type == "range" then
        self:Refresh()
        return
    end
    local elements, signature
    if self.Searching then
        elements = self:SearchElements(self.SearchBox:GetText())
        signature = SignatureOf(elements)
    else
        elements, signature = ReadPage(self, self.SectionId)
    end
    if signature and signature ~= self.Signature then
        self:FillPage(ScrollBoxConstants.RetainScrollPosition, elements, signature)
    else
        self:Refresh()
    end
end

function WindowMixin:AskConfirm(text, onYes)
    if self.Searching then self.Confirming = { Search = true, Text = text, OnYes = onYes }
    elseif self.SectionId then self.Confirming = { SectionId = self.SectionId, Text = text, OnYes = onYes }
    else return end
    self:RefreshFooter()
end
function WindowMixin:ConfirmingHere()
    local c = self.Confirming
    if not c then return nil end
    if self.Searching then return c.Search and c or nil end
    return c.SectionId == self.SectionId and c or nil
end
function WindowMixin:CancelConfirm()
    self.Confirming = nil
    self:RefreshFooter()
end
function WindowMixin:OnDefaultsClick()
    local confirming = self:ConfirmingHere()
    if confirming then
        self.Confirming = nil
        confirming.OnYes()
        self:RefreshFooter()
        return
    end
    local id = self.SectionId
    if not id then return end
    self:AskConfirm(self.Strings.ResetSection:format(tostring(Ask(id, self.Config.sectionName, id))),
        function() if Ask(true, self.Config.resetSection, id) then self.ReloadPending = true end; self:ReloadSection() end)
end

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
