------------------------------------------------------------
-- 键位按钮（单控件，b028 自 RowFrames.lua / RowMixins.lua 拆出；b029 由 RowKeyButton.lua 更名）：
-- 银色九宫格按键外观 + 按下/抬起贴图切换。消费者：OptionRow 的 Key1/Key2。
------------------------------------------------------------
local lib = ResolveBOFNamespace("ade_UIKit")
if not lib then return end

local Internal = lib.Internal
local build, mixins = Internal.Build, Internal.Mixins

-- [[ KeyButton 构建器 ]] --  KAF RowFrames.lua:68-143
local silver = "Interface\\Buttons\\UI-Silver-Button-Up"
local keyCorners = {
    { "TopLeft", "TOPLEFT", 0, 0.09375, 0, 0.1875 },
    { "TopRight", "TOPRIGHT", 0.53125, 0.625, 0, 0.1875 },
    { "BottomLeft", "BOTTOMLEFT", 0, 0.09375, 0.625, 0.8125 },
    { "BottomRight", "BOTTOMRIGHT", 0.53125, 0.625, 0.625, 0.8125 },
}
local keyEdges = {
    { "TopMiddle", "TOPLEFT", "TopLeft", "TOPRIGHT", "BOTTOMRIGHT", "TopRight", "BOTTOMLEFT", 0.09375, 0.53125, 0, 0.1875 },
    { "MiddleLeft", "TOPRIGHT", "TopLeft", "BOTTOMRIGHT", "BOTTOMLEFT", "BottomLeft", "TOPLEFT", 0, 0.09375, 0.1875, 0.625 },
    { "MiddleRight", "TOPRIGHT", "TopRight", "BOTTOMRIGHT", "BOTTOMLEFT", "BottomRight", "TOPLEFT", 0.53125, 0.625, 0.1875, 0.625 },
    { "BottomMiddle", "TOPLEFT", "BottomLeft", "TOPRIGHT", "BOTTOMRIGHT", "BottomRight", "BOTTOMLEFT", 0.09375, 0.53125, 0.625, 0.8125 },
    { "MiddleMiddle", "TOPLEFT", "TopLeft", "BOTTOMRIGHT", "BOTTOMRIGHT", "BottomRight", "TOPLEFT", 0.09375, 0.53125, 0.1875, 0.625 },
}
local keyPieces = { "TopLeft", "TopRight", "BottomLeft", "BottomRight", "TopMiddle", "MiddleLeft", "MiddleRight", "BottomMiddle", "MiddleMiddle" }

function build.KeyButton(parent)
    local button = CreateFrame("Button", nil, parent)
    button:SetSize(160, 22)
    for _, corner in ipairs(keyCorners) do
        local piece = button:CreateTexture(nil, "BACKGROUND")
        piece:SetTexture(silver)
        piece:SetSize(12, 6)
        piece:SetPoint(corner[2])
        piece:SetTexCoord(corner[3], corner[4], corner[5], corner[6])
        button[corner[1]] = piece
    end
    for _, edge in ipairs(keyEdges) do
        local piece = button:CreateTexture(nil, "BACKGROUND")
        piece:SetTexture(silver)
        piece:SetPoint(edge[2], button[edge[3]], edge[4])
        piece:SetPoint(edge[5], button[edge[6]], edge[7])
        piece:SetTexCoord(edge[8], edge[9], edge[10], edge[11])
        button[edge[1]] = piece
    end
    local selected = button:CreateTexture(nil, "OVERLAY")
    selected:SetTexture("Interface\\Buttons\\UI-Silver-Button-Select")
    selected:SetBlendMode("ADD")
    selected:SetSize(160, 20)
    selected:SetPoint("CENTER", 0, -3)
    selected:Hide()
    button.SelectedHighlight = selected
    local text = button:CreateFontString()
    text:SetWidth(150)
    text:SetPoint("CENTER", 0, -1)
    text:SetMaxLines(1)
    button:SetFontString(text)
    button.Text = text
    button:SetNormalFontObject("GameFontHighlightSmall")
    button:SetHighlightFontObject("GameFontHighlightSmall")
    button:SetDisabledFontObject("GameFontDisableSmall")
    button:SetHighlightTexture("Interface\\Buttons\\UI-Silver-Button-Highlight", "ADD")
    button:GetHighlightTexture():SetTexCoord(0, 1, 0.03, 0.7175)
    return build.Finish(button, mixins.KeyButton,
        { OnMouseDown = "OnMouseDown", OnMouseUp = "Lift", OnShow = "Lift", OnEnable = "Lift" })
end

-- [[ KeyButton 行为 ]] --  KAF RowMixins.lua:109-127
mixins.KeyButton = mixins.KeyButton or {}
local KeyButtonMixin = mixins.KeyButton

function KeyButtonMixin:SetPieces(file)
    for _, piece in ipairs(keyPieces) do self[piece]:SetTexture(file) end
end
function KeyButtonMixin:OnMouseDown()
    if self:IsEnabled() then self:SetPieces("Interface\\Buttons\\UI-Silver-Button-Down") end
end
function KeyButtonMixin:Lift() self:SetPieces("Interface\\Buttons\\UI-Silver-Button-Up") end
