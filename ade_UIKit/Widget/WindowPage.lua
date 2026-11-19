------------------------------------------------------------
-- 设置窗口：导航与页面填充（b028 自 WindowMixin.lua 拆出）。
-- 导航树（RefreshNav）、分区读取与签名比对（ShowSection/FillPage/ReloadSection）、
-- 就地刷新（Refresh）、选项定位（ScrollToOption）与键位捕获收尾（EndKeyCaptures）。
------------------------------------------------------------
local lib = ResolveBOFNamespace("ade_UIKit")
if not lib then return end

local Internal = lib.Internal
local WindowMixin = Internal.Mixins.Window
local Protected, Ask = Internal.Protected, Internal.Ask

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
Internal.SignatureOf = SignatureOf -- 页脚变更重算（WindowFooter.lua）共用

local function ReadPage(window, id)
    local ok, elements, signature = Protected(function()
        local elements = Flatten(window.Config.elements(id))
        return elements, Signature(elements)
    end)
    if ok then return elements, signature end
end
Internal.ReadPageOf = ReadPage -- 页脚变更重算（WindowFooter.lua）共用

local function DefaultsShown(window, confirming)
    return confirming ~= nil or not window.Searching and window.SectionId ~= nil
end
Internal.DefaultsShown = DefaultsShown -- 页脚显隐（WindowFooter.lua）共用

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
