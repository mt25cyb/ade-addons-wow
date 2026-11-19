------------------------------------------------------------
-- 设置窗口：页脚（确认条 / 变更计数 / 重载提示）与默认值流程
-- （b028 自 WindowMixin.lua 拆出）。
-- RefreshFooter 是页脚唯一排版入口；OnOptionChanged 决定签名比对后的重填或就地刷新。
------------------------------------------------------------
local lib = ResolveBOFNamespace("ade_UIKit")
if not lib then return end

local Internal = lib.Internal
local WindowMixin = Internal.Mixins.Window
local Protected, Ask = Internal.Protected, Internal.Ask

-- [[ 页面按钮 ]] --  KAF WindowPage.lua:97-101
function WindowMixin:LoadPage()
    self.DefaultsButton:SetScript("OnClick", function() self:OnDefaultsClick() end)
    self.CancelButton:SetScript("OnClick", function() self:CancelConfirm() end)
    self.ReloadButton:SetScript("OnClick", function() if not InCombatLockdown() then ReloadUI() end end)
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
    Internal.FitButton(self.DefaultsButton)
    self.DefaultsButton:SetShown(Internal.DefaultsShown(self, confirming))
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
        signature = Internal.SignatureOf(elements)
    else
        elements, signature = Internal.ReadPageOf(self, self.SectionId)
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
