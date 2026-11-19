------------------------------------------------------------
-- 卡片行族（b028 自 RowFrames.lua / RowMixins.lua 拆出；b029 由 RowCards.lua 更名）：
-- Card（图片/图标/名称/说明/边框悬停 + 「新」标签）、CardRow（三卡一行）。
-- 尺寸/裁剪辅助（CardWidth/CardCrop/CardRowHeight）供窗口页计算高度。
------------------------------------------------------------
local lib = ResolveBOFNamespace("ade_UIKit")
if not lib then return end

local Internal = lib.Internal
local build, mixins, geometry = Internal.Build, Internal.Mixins, Internal.Geometry

-- [[ 构建 ]] --  KAF RowFrames.lua:359-410
local cardEdges = { -- 尺寸（宽或高）+ 两条锚点，照 KAF RowFrames.lua:372-377
    { nil, 1, "TOPLEFT", 0, 0, "TOPRIGHT", 0, 0 },
    { nil, 1, "BOTTOMLEFT", 0, 0, "BOTTOMRIGHT", 0, 0 },
    { 1, nil, "TOPLEFT", 0, -1, "BOTTOMLEFT", 0, 1 },
    { 1, nil, "TOPRIGHT", 0, -1, "BOTTOMRIGHT", 0, 1 },
}
function build.Card(parent)
    local card = CreateFrame("Button", nil, parent)
    local border = geometry.CardBorderColor or { 1, 1, 1, 0.12 }
    card.Fill = build.Color(card, "BACKGROUND", 0, 0, 0, 0.35)
    card.Fill:SetAllPoints()
    card.PictureArea = build.Color(card, "BORDER", 0, 0, 0, 0.5)
    card.PictureArea:SetHeight(geometry.CardPictureHeight or 86)
    card.PictureArea:SetPoint("TOPLEFT", 1, -1)
    card.PictureArea:SetPoint("TOPRIGHT", -1, -1)
    card.Hover = build.Hover(card, "BORDER", 1)
    card.Picture = card:CreateTexture(nil, "ARTWORK")
    card.Picture:SetPoint("TOPLEFT", card.PictureArea)
    card.Picture:SetPoint("BOTTOMRIGHT", card.PictureArea)
    card.Icon = card:CreateTexture(nil, "ARTWORK")
    card.Icon:SetSize(48, 48)
    card.Icon:SetPoint("CENTER", card.PictureArea)
    card.Icon:Hide()
    card.Name = build.Text(card, "ARTWORK", "GameFontNormal", "LEFT")
    card.Name:SetWordWrap(false)
    card.Line = build.Text(card, "ARTWORK", "GameFontDisableSmall", "LEFT", "TOP")
    card.Line:SetPoint("TOPLEFT", card.Name, "BOTTOMLEFT", 0, -3)
    card.PictureLine = build.Color(card, "OVERLAY", unpack(border))
    card.PictureLine:SetHeight(1)
    card.PictureLine:SetPoint("TOPLEFT", card.PictureArea, "BOTTOMLEFT")
    card.PictureLine:SetPoint("TOPRIGHT", card.PictureArea, "BOTTOMRIGHT")
    card.Edges = {}
    for _, spec in ipairs(cardEdges) do
        local edge = build.Color(card, "OVERLAY", unpack(border))
        if spec[1] then edge:SetWidth(spec[1]) else edge:SetHeight(spec[2]) end
        edge:SetPoint(spec[3], spec[4], spec[5])
        edge:SetPoint(spec[6], spec[7], spec[8])
        card.Edges[#card.Edges + 1] = edge
    end
    card.NewFeature = CreateFrame("Frame", nil, card, "NewFeatureLabelTemplate")
    card.NewFeature:SetScale(0.8)
    card.NewFeature:SetSize(1, 1)
    card.NewFeature:SetPoint("RIGHT", card.PictureArea, "BOTTOMRIGHT", -11.25, -17.5)
    card.NewFeature:Hide()
    return build.Finish(card, mixins.Card, { OnClick = "OnClick", OnEnter = "OnEnter", OnLeave = "OnLeave" })
end

function build.CardRow(parent)
    local row = build.Row("Frame", parent)
    return build.Finish(row, mixins.CardRow, { OnLoad = "OnLoad" })
end

-- [[ 尺寸与裁剪辅助 ]] --  KAF RowMixins.lua:818-852
Internal.CardColumns = 3
local cardGap, cardBorder = 12, 1
local cardTextInset, nameTop, lineGap, cardBottom, newGap = 10, 8, 3, 10, 6
local borderHoverColor = { 1, 0.82, 0, 0.6 }

function Internal.CardWidth(rowWidth)
    return (rowWidth - (Internal.CardColumns - 1) * cardGap) / Internal.CardColumns
end
function Internal.CardCrop(picture, cardWidth)
    local pictureHeight = geometry.CardPictureHeight
    local width = cardWidth - 2 * cardBorder
    if not picture.Width or not picture.Height or picture.Width <= 0 or picture.Height <= 0 then return 0, 1, 0, 1 end
    local scale = math.max(width / picture.Width, pictureHeight / picture.Height)
    local coords, part = picture.TexCoords or { 0, 1, 0, 1 }, picture.Part or {}
    local shownWidth = width / scale / picture.Width
    local shownHeight = pictureHeight / scale / picture.Height
    local left = (1 - shownWidth) * (part.X or 0)
    local top = (1 - shownHeight) * (part.Y or 0)
    local u, v = coords[2] - coords[1], coords[4] - coords[3]
    return coords[1] + u * left, coords[1] + u * (left + shownWidth),
        coords[3] + v * top, coords[3] + v * (top + shownHeight)
end
function Internal.CardRowHeight(window, element)
    local lineWidth = Internal.CardWidth(window:PageWidth()) - 2 * cardTextInset
    local nameHeight, lineHeight = 0, 0
    for _, card in ipairs(element.Cards or {}) do
        nameHeight = math.max(nameHeight, window:MeasureText(card.Name, "GameFontNormal", 1000))
        if card.Text and card.Text ~= "" then
            lineHeight = math.max(lineHeight, window:MeasureText(card.Text, "GameFontDisableSmall", lineWidth))
        end
    end
    return 2 * cardBorder + geometry.CardPictureHeight + nameTop + nameHeight
        + (lineHeight > 0 and lineGap + lineHeight or 0) + cardBottom + cardGap
end

-- [[ 行为 ]] --  KAF RowMixins.lua:854-928：三卡一行，图片区 86px，边框随悬停变亮。
mixins.CardRow = mixins.CardRow or {}
function mixins.CardRow:OnLoad()
    self.Cards = {}
    for i = 1, Internal.CardColumns do self.Cards[i] = build.Card(self) end
end
function mixins.CardRow:Init(element, window)
    self.Element = element
    local width = Internal.CardWidth(window:PageWidth())
    for i, frame in ipairs(self.Cards) do
        local card, x = element.Cards[i], (i - 1) * (width + cardGap)
        frame:ClearAllPoints()
        frame:SetPoint("TOPLEFT", x, 0)
        frame:SetPoint("BOTTOMLEFT", x, cardGap)
        frame:SetWidth(width)
        frame:SetShown(card ~= nil)
        if card then frame:Init(card, width) end
    end
end
mixins.Card = mixins.Card or {}
function mixins.Card:Init(card, width)
    self.Card = card
    self.Picture:SetShown(card.Picture ~= nil)
    self.Icon:SetShown(card.Picture == nil and card.Icon ~= nil)
    if card.Picture then
        self.Picture:SetTexture(card.Picture)
        self.Picture:SetTexCoord(Internal.CardCrop(card, width))
    elseif card.Icon then
        self.Icon:SetTexture(card.Icon)
    end
    local newWidth = 0
    local feature = self.NewFeature
    if feature then
        if feature.BGLabel then feature.BGLabel:SetPoint("RIGHT", 0.5, -0.5) end
        if feature.Label then feature.Label:SetPoint("RIGHT", 0, 0) end
        if card.IsNew then
            newWidth = feature.Label and (feature.Label:GetStringWidth() * feature:GetScale() + newGap) or 0
        end
        feature:SetShown(card.IsNew and true or false)
    end
    self.Name:ClearAllPoints()
    self.Name:SetPoint("TOPLEFT", self.PictureArea, "BOTTOMLEFT", cardTextInset - cardBorder, -nameTop)
    self.Name:SetPoint("TOPRIGHT", self.PictureArea, "BOTTOMRIGHT", -(cardTextInset - cardBorder) - newWidth, -nameTop)
    self.Name:SetText(card.Name or "")
    self.Line:SetWidth(width - 2 * cardTextInset)
    self.Line:SetText(card.Text or "")
    self:SetHovered(self:IsMouseOver())
end
function mixins.Card:SetHovered(hovered)
    self.Hover:SetShown(hovered)
    local color = hovered and borderHoverColor or geometry.CardBorderColor
    for _, edge in ipairs(self.Edges or {}) do edge:SetColorTexture(unpack(color)) end
end
function mixins.Card:OnEnter() self:SetHovered(true) end
function mixins.Card:OnLeave() self:SetHovered(false) end
function mixins.Card:OnClick() if self.Card and self.Card.OnClick then self.Card.OnClick() end end
