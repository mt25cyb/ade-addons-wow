------------------------------------------------------------
-- 窗口布局：内框 atlas 切片、两栏锚点、拖拽/缩放、测量、PageWidth。
-- 复刻 KAF WindowLayout.lua:61-155,220-355；删除 Help 列与折叠相关全部逻辑。
------------------------------------------------------------
local lib = ResolveBOFNamespace("ade_UIKit")
if not lib then return end

local Internal = lib.Internal
local WindowMixin = Internal.Mixins.Window
local g = Internal.Geometry

local bodyInsets = { Left = g.BodyLeft, Top = g.BodyTop, Right = g.BodyRight, Bottom = g.BodyBottom }
local navLeftPad, navWidth, navBarX = 50, g.NavWidth, 6
local pageInsets = { Left = 1, Right = g.PageRightPad, Pad = 25 }
-- KAF WindowLayout.lua:27：Options_HorizontalDivider 原生尺寸 630（Get-Atlas.ps1 实测），页眉居中铺开
local dividerWidth = 630

-- KAF WindowLayout.lua:61-67，去掉 HelpDivider/Help 两列，只剩 Left/Nav/Divider/Page/Right。
local innerColumns = { Left = { 0, 30 }, Nav = { 30, 199 }, Divider = { 199, 201 }, Flat = { 201, 856 }, Right = { 856, 886 } }
local innerRows = { Top = { 0, 90 }, Middle = { 90, 440 }, Bottom = { 440, 618 } }
local innerSlices = {
    { Key = "Left", Atlas = "Left" }, { Key = "Nav", Atlas = "Nav" }, { Key = "Divider", Atlas = "Divider" },
    { Key = "Page", Atlas = "Flat" }, { Key = "Right", Atlas = "Right" },
}
local innerRowAnchors = { Top = { "TOP", 0, "TOP", -90 }, Middle = { "TOP", -90, "BOTTOM", 178 }, Bottom = { "BOTTOM", 178, "BOTTOM", 0 } }

function WindowMixin:CreateInnerFrame()
    local info = C_Texture.GetAtlasInfo("Options_InnerFrame")
    if not info then return end
    local function U(x) return info.leftTexCoord + (info.rightTexCoord - info.leftTexCoord) * x / info.width end
    local function V(y) return info.topTexCoord + (info.bottomTexCoord - info.topTexCoord) * y / info.height end
    self.InnerSlices = {}
    for _, column in ipairs(innerSlices) do
        local x = innerColumns[column.Atlas]
        for row, y in next, innerRows do
            local slice = self:CreateTexture(nil, "BACKGROUND", nil, 1)
            slice:SetTexture(info.file or info.filename)
            slice:SetTexCoord(U(x[1]), U(x[2]), V(y[1]), V(y[2]))
            self.InnerSlices[column.Key .. row] = slice
        end
    end
end

function WindowMixin:LayoutInnerFrame(navEnd)
    if not self.InnerSlices then return end
    local columns = {
        Left = { "LEFT", 0, "LEFT", 30 },
        Nav = { "LEFT", 30, "LEFT", navEnd },
        Divider = { "LEFT", navEnd, "LEFT", navEnd + 2 },
        Page = { "LEFT", navEnd + 2, "RIGHT", -30 },
        Right = { "RIGHT", -30, "RIGHT", 0 },
    }
    local frame = self.InnerFrame
    for key, x in next, columns do
        for row, y in next, innerRowAnchors do
            local slice = self.InnerSlices[key .. row]
            slice:ClearAllPoints()
            slice:SetPoint("TOPLEFT", frame, y[1] .. x[1], x[2], y[2])
            slice:SetPoint("BOTTOMRIGHT", frame, y[3] .. x[3], x[4], y[4])
        end
    end
end

local navKinds = {
    NavHeader = { Build = "NavHeaderRow", Height = 30 },
    NavButton = { Build = "NavButtonRow", Height = 20 },
    NavSpacer = { Build = "NavSpacerRow", Height = 18 },
}

function WindowMixin:LoadLayout()
    self:RegisterForDrag("LeftButton")
    self:CreateInnerFrame()
    self.Measure = self:CreateFontString(nil, "ARTWORK", "GameFontDisable")
    self.Measure:Hide()
    self.Measure:SetJustifyH("LEFT")
    Internal.InitList(self, self.NavScrollBox, self.NavScrollBar, navKinds, navLeftPad, 2)
    Internal.InitList(self, self.PageScrollBox, self.PageScrollBar, Internal.Kinds, pageInsets.Pad, 2, pageInsets.Right)
    self.ResizeButton:SetScript("OnMouseDown", function() self:StartSizing("BOTTOM") end)
    self.ResizeButton:SetScript("OnMouseUp", function()
        self:StopMovingOrSizing()
        Internal.SetShared("Size", { self:GetWidth(), self:GetHeight() })
        self:SavePoint()
        self:ReloadSection()
    end)
end

function WindowMixin:NavEnd() return g.NavEnd end

function WindowMixin:PageWidth()
    return self:GetWidth() - (bodyInsets.Left - bodyInsets.Right) - self:NavEnd()
        - pageInsets.Left - pageInsets.Right - pageInsets.Pad
end

function WindowMixin:MeasureText(text, font, width)
    self.Measure:SetFontObject(font or "GameFontDisable")
    self.Measure:SetWidth(width or 0)
    self.Measure:SetText(text or "")
    return self.Measure:GetStringHeight()
end

function WindowMixin:OnNavScrollBarShown(shown)
    if self.Filling then self.LayoutPending = true; return end
    self:Layout()
end

function WindowMixin:EndFill()
    self.Filling = nil
    if self.LayoutPending then self.LayoutPending = nil; self:Layout() end
end

function WindowMixin:Layout()
    local body = self.Body
    local navEnd = self:NavEnd()
    body:ClearAllPoints()
    body:SetPoint("TOPLEFT", self, "TOPLEFT", bodyInsets.Left, bodyInsets.Top)
    body:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT", bodyInsets.Right, bodyInsets.Bottom)
    self:LayoutInnerFrame(navEnd)

    self.SearchBox:ClearAllPoints()
    self.SearchBox:SetPoint("BOTTOMRIGHT", body, "TOPRIGHT", 0, 20)

    -- KAF WindowLayout.lua:315-320：两个搜索复选框贴在关闭键左侧，标签贴各自复选框右侧。
    self.SearchAllLabel:ClearAllPoints()
    self.SearchAllLabel:SetPoint("RIGHT", self.CloseButton, "LEFT", -16, 0)
    self.SearchAll:ClearAllPoints()
    self.SearchAll:SetPoint("RIGHT", self.SearchAllLabel, "LEFT", -2, 0)
    self.SearchBroad:ClearAllPoints()
    self.SearchBroad:SetPoint("RIGHT", self.SearchBroadLabel, "LEFT", -2, 0)

    self.NavScrollBox:ClearAllPoints()
    self.NavScrollBox:SetPoint("TOPLEFT", body, "TOPLEFT", -navLeftPad, -4)
    self.NavScrollBox:SetPoint("BOTTOMLEFT", body, "BOTTOMLEFT", -navLeftPad, 4)
    self.NavScrollBox:SetWidth(navLeftPad + navWidth)
    self.NavScrollBar:ClearAllPoints()
    self.NavScrollBar:SetPoint("TOPLEFT", self.NavScrollBox, "TOPRIGHT", navBarX, 2)
    self.NavScrollBar:SetPoint("BOTTOMLEFT", self.NavScrollBox, "BOTTOMRIGHT", navBarX, 7)

    local pageLeft = navEnd + 16
    local pageRight = self:GetWidth() - (bodyInsets.Left - bodyInsets.Right) - 4
    self.PageTitle:ClearAllPoints()
    self.PageTitle:SetPoint("TOPLEFT", body, "TOPLEFT", pageLeft + 7, -22)
    self.PageTitle:SetPoint("RIGHT", self.DefaultsButton, "LEFT", -6, 0)
    self.DefaultsButton:ClearAllPoints()
    self.DefaultsButton:SetPoint("TOPRIGHT", body, "TOPRIGHT", -40, -16)
    self.CancelButton:ClearAllPoints()
    self.CancelButton:SetPoint("RIGHT", self.DefaultsButton, "LEFT", -6, 0)
    self.Divider:ClearAllPoints()
    self.Divider:SetWidth(math.min(dividerWidth, pageRight - pageLeft))
    self.Divider:SetPoint("TOP", body, "TOPLEFT", (pageLeft + pageRight) / 2, -50)

    self.PageScrollBox:ClearAllPoints()
    self.PageScrollBox:SetPoint("TOPLEFT", body, "TOPLEFT", navEnd + pageInsets.Left, -58)
    self.PageScrollBox:SetPoint("BOTTOMRIGHT", body, "BOTTOMRIGHT", -pageInsets.Right, 0)
    self.PageScrollBar:ClearAllPoints()
    self.PageScrollBar:SetPoint("TOPLEFT", self.PageScrollBox, "TOPRIGHT", 0, -4)
    self.PageScrollBar:SetPoint("BOTTOMLEFT", self.PageScrollBox, "BOTTOMRIGHT", -1, 7)

    self.ReloadBackground:ClearAllPoints()
    self.ReloadBackground:SetPoint("TOPLEFT", body, "BOTTOMLEFT", 0, -6)
    self.ReloadBackground:SetPoint("BOTTOMRIGHT", self.CloseButton, "BOTTOMLEFT", -12, -2)
    self.ReloadText:ClearAllPoints()
    self.ReloadText:SetPoint("LEFT", self.ReloadBackground, "LEFT", 12, 0)
    self.ReloadButton:ClearAllPoints()
    self.ReloadButton:SetPoint("LEFT", self.ReloadText, "RIGHT", 12, 0)
end

function WindowMixin:OnSizeChanged() end
function WindowMixin:OnDragStart() self:StartMoving() end
function WindowMixin:OnDragStop()
    self:StopMovingOrSizing()
    self:SavePoint()
end

function WindowMixin:SavePoint()
    local point, _, relativePoint, x, y = self:GetPoint(1)
    Internal.SetShared("Point", { point, relativePoint, x, y })
end

function WindowMixin:ApplyWidth()
    self:SetWidth(g.WindowWidth)
end

-- 导航行 mixin（KAF WindowFrame.lua/WindowPage.lua 的 Nav 部分）
local function NavRow(parent, frameType)
    local row = CreateFrame(frameType or "Button", nil, parent)
    row:Hide()
    return row
end
function Internal.Build.NavHeaderRow(parent)
    local row = NavRow(parent, "Frame")
    row.Background = row:CreateTexture(nil, "ARTWORK") -- KAF WindowFrame.lua:51-52
    row.Background:SetPoint("TOPLEFT")
    return Internal.Build.Finish(row, Internal.Mixins.NavHeaderRow)
end
function Internal.Build.NavButtonRow(parent)
    local row = NavRow(parent, "Button")
    row.Texture = row:CreateTexture(nil, "BACKGROUND") -- KAF WindowFrame.lua:33-35
    row.Texture:SetPoint("CENTER")
    row.Texture:Hide()
    return Internal.Build.Finish(row, Internal.Mixins.NavButtonRow,
        { OnClick = "OnClick", OnEnter = "OnEnter", OnLeave = "OnLeave" })
end
function Internal.Build.NavSpacerRow(parent)
    return NavRow(parent, "Frame")
end

Internal.Mixins.NavHeaderRow = Internal.Mixins.NavHeaderRow or {}
function Internal.Mixins.NavHeaderRow:Init(element)
    -- KAF WindowFrame.lua:53-54：白色中号字，垂直居中在 LEFT 20；背景由构建器建。
    self.Label = self.Label or Internal.Build.Text(self, "OVERLAY", "GameFontHighlightMedium", "LEFT")
    self.Label:ClearAllPoints()
    self.Label:SetPoint("LEFT", 20, -1)
    self.Label:SetText(element.Text or "")
    self.Background:SetAtlas("Options_CategoryHeader_" .. (((element.Index or 1) - 1) % 3 + 1), true)
end
Internal.Mixins.NavButtonRow = Internal.Mixins.NavButtonRow or {}
function Internal.Mixins.NavButtonRow:UpdateState()
    -- KAF WindowPage.lua:59-67：选中亮白字与 Options_List_Active，悬停 Options_List_Hover，其余隐藏。
    self.Label:SetFontObject(self.Selected and "GameFontHighlight" or "GameFontNormal")
    if self.Selected or self.Over then
        self.Texture:SetAtlas(self.Selected and "Options_List_Active" or "Options_List_Hover", true)
        self.Texture:Show()
    else
        self.Texture:Hide()
    end
end
function Internal.Mixins.NavButtonRow:Init(element, window)
    self.Element, self.Window = element, window
    self.Label = self.Label or Internal.Build.Text(self, "ARTWORK", "GameFontNormal", "LEFT")
    self.Label:ClearAllPoints()
    self.Label:SetPoint("TOPLEFT", 36, 1)
    self.Label:SetPoint("BOTTOMRIGHT", -6, 1)
    self.Label:SetWordWrap(false)
    self.Label:SetText(element.Text or "")
    -- KAF 的"新"标识不改变标题颜色（白色只给选中项，WindowPage.lua:60）。
    self.Selected = window and window.SectionId == element.Id and not window.Searching
    self.Over = self:IsMouseOver()
    self:UpdateState()
    -- KAF WindowFrame.lua:40-43 + WindowPage.lua:47-53：贴名字左侧，右对齐名字左沿。
    self.New = self.New or CreateFrame("Frame", nil, self, "NewFeatureLabelTemplate")
    self.New:SetScale(0.8)
    self.New:SetSize(1, 1)
    self.New:ClearAllPoints()
    self.New:SetPoint("BOTTOMRIGHT", self.Label, "LEFT", -4, -10)
    if self.New.BGLabel then self.New.BGLabel:SetPoint("RIGHT", 0.5, -0.5) end
    if self.New.Label then self.New.Label:SetPoint("RIGHT", 0, 0) end
    self.New:SetShown(element.IsNew and true or false)
    self.Id = element.Id
end
function Internal.Mixins.NavButtonRow:OnClick()
    if self.Window then self.Window:ShowSection(self.Id or (self.Element and self.Element.Id)) end
end
function Internal.Mixins.NavButtonRow:OnEnter()
    self.Over = true
    self:UpdateState()
end
function Internal.Mixins.NavButtonRow:OnLeave()
    self.Over = nil
    self:UpdateState()
end
Internal.Mixins.NavSpacerRow = Internal.Mixins.NavSpacerRow or {}
function Internal.Mixins.NavSpacerRow:Init() end
