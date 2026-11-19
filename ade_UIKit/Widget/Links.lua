------------------------------------------------------------
-- 搜索结果行族（b028 自 RowFrames.lua / RowMixins.lua 拆出；b029 由 RowLinks.lua 更名）：
-- SearchHeadingRow（分区标题，点击跳转）、LinkRow（链接行）。
------------------------------------------------------------
local lib = ResolveBOFNamespace("ade_UIKit")
if not lib then return end

local Internal = lib.Internal
local build, mixins = Internal.Build, Internal.Mixins

-- [[ 构建 ]] --  KAF RowFrames.lua:331-357
function build.SearchHeadingRow(parent)
    local row = build.Row("Button", parent)
    row.MouseoverOverlay = build.Color(row, "BACKGROUND", 0.1, 0.1, 0.1, 1)
    row.MouseoverOverlay:SetBlendMode("ADD")
    row.MouseoverOverlay:SetAllPoints()
    row.MouseoverOverlay:Hide()
    row.Title = build.Text(row, "ARTWORK", "GameFontNormalLarge", "LEFT", "TOP")
    row.Title:SetPoint("TOPLEFT", 16, -16)
    return build.Finish(row, mixins.SearchHeadingRow, { OnClick = "OnClick", OnEnter = "OnEnter", OnLeave = "OnLeave" })
end

function build.LinkRow(parent)
    local row = build.Row("Button", parent)
    row.Text = build.Text(row, "ARTWORK", "GameFontNormal", "LEFT")
    row.Text:SetWordWrap(false)
    row.Text:SetPoint("LEFT", 16, 0)
    row.Detail = build.Text(row, "ARTWORK", "GameFontDisableSmall", "LEFT")
    row.Detail:SetWordWrap(false)
    row.Detail:SetPoint("LEFT", row.Text, "RIGHT", 10, 0)
    row.Detail:SetPoint("RIGHT", -16, 0)
    local highlight = row:CreateTexture()
    highlight:SetColorTexture(1, 1, 1, 0.08)
    highlight:SetBlendMode("ADD")
    highlight:SetAllPoints()
    row:SetHighlightTexture(highlight)
    return build.Finish(row, mixins.LinkRow, { OnClick = "OnClick" })
end

-- [[ 行为 ]] --  KAF RowMixins.lua:722-734
mixins.SearchHeadingRow = mixins.SearchHeadingRow or {}
function mixins.SearchHeadingRow:Init(element) self.Title:SetText(element.Text or "") end
function mixins.SearchHeadingRow:OnClick() if self.Element and self.Element.OnClick then self.Element.OnClick() end end
function mixins.SearchHeadingRow:OnEnter() self.MouseoverOverlay:Show() end
function mixins.SearchHeadingRow:OnLeave() self.MouseoverOverlay:Hide() end

mixins.LinkRow = mixins.LinkRow or {}
function mixins.LinkRow:Init(element)
    self.Element = element
    self.Text:SetText(element.Text or "")
    self.Detail:SetText(element.Detail or "")
end
function mixins.LinkRow:OnClick() if self.Element and self.Element.OnClick then self.Element.OnClick() end end
