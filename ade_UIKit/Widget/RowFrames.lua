------------------------------------------------------------
-- 所有行的 Lua 构建器。逐块复刻 KAF Libs/Krowi_Options/RowFrames.lua。
-- 无 XML 虚拟模板（KAF :8-12 的多副本重名理由），全部由工厂构建、建好即隐藏。
------------------------------------------------------------
local lib = ResolveBOFNamespace("ade_UIKit")
if not lib then return end

local Internal = lib.Internal
local build, mixins, geometry = Internal.Build, Internal.Mixins, Internal.Geometry

-- [[ Pieces ]] --  KAF RowFrames.lua:27-69
local function Text(frame, layer, font, justifyH, justifyV)
    local text = frame:CreateFontString(nil, layer, font)
    if justifyH then text:SetJustifyH(justifyH) end
    if justifyV then text:SetJustifyV(justifyV) end
    return text
end
build.Text = Text

local function Color(frame, layer, r, g, b, a, subLevel)
    local texture = frame:CreateTexture(nil, layer, nil, subLevel)
    texture:SetColorTexture(r, g, b, a)
    return texture
end
build.Color = Color

local function StateAtlas(button, atlas)
    local texture = button:CreateTexture()
    texture:SetAtlas(atlas)
    texture:SetAllPoints()
    return texture
end

local function Finish(frame, mixin, scripts)
    if mixin then Mixin(frame, mixin) end
    for script, method in next, scripts or {} do
        if script ~= "OnLoad" then
            local fn = frame[method]
            if not fn then return end
            frame:SetScript(script, fn)
        end
    end
    if scripts and scripts.OnLoad and frame[scripts.OnLoad] then frame[scripts.OnLoad](frame) end
    return frame
end
build.Finish = Finish

local function Row(frameType, parent)
    local row = CreateFrame(frameType, nil, parent)
    row:Hide()
    return row
end
build.Row = Row

-- [[ Controls ]] --

function build.CheckButton(parent) -- KAF :75-84
    local button = CreateFrame("CheckButton", nil, parent)
    button:SetMotionScriptsWhileDisabled(true)
    button:SetSize(30, 29)
    button:SetNormalTexture(StateAtlas(button, "checkbox-minimal"))
    button:SetPushedTexture(StateAtlas(button, "checkbox-minimal"))
    button:SetCheckedTexture(StateAtlas(button, "checkmark-minimal"))
    button:SetDisabledCheckedTexture(StateAtlas(button, "checkmark-minimal-disabled"))
    return button
end

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
local function SetKeyPieces(button, file)
    for _, name in ipairs(keyPieces) do button[name]:SetTexture(file) end
end

function build.KeyButton(parent) -- KAF :103-143
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
    return Finish(button, mixins.KeyButton,
        { OnMouseDown = "OnMouseDown", OnMouseUp = "Lift", OnShow = "Lift", OnEnable = "Lift" })
end

local iconButtonScripts = { "OnShow", "OnMouseDown", "OnMouseUp", "OnEnter", "OnLeave", "OnEnable", "OnDisable" }
local function IconButton(parent, normalAtlas, disabledAtlas) -- KAF :152-166
    local button = CreateFrame("Button", nil, parent)
    button:SetSize(26, 25)
    button.Background = button:CreateTexture(nil, "BACKGROUND")
    button.Background:SetPoint("CENTER")
    button.Icon = button:CreateTexture(nil, "OVERLAY")
    button.Icon:SetPoint("CENTER")
    Mixin(button, WowStyle2IconButtonMixin)
    button.normalAtlas, button.disabledAtlas = normalAtlas, disabledAtlas
    for _, script in ipairs(iconButtonScripts) do
        if button[script] then button:SetScript(script, button[script]) end
    end
    if button.OnLoad then button:OnLoad() end
    return button
end

function build.Select(parent) -- KAF :168-179
    local select = CreateFrame("Frame", nil, parent)
    select:SetSize(250, 26)
    select.IncrementButton = IconButton(select, "common-dropdown-icon-next", "common-dropdown-icon-next-disabled")
    select.DecrementButton = IconButton(select, "common-dropdown-icon-back", "common-dropdown-icon-back-disabled")
    select.Dropdown = CreateFrame("DropdownButton", nil, select, "WowStyle2DropdownTemplate")
    select.Dropdown:SetSize(220, 26)
    select.Dropdown:SetPoint("CENTER")
    Mixin(select, DropdownWithSteppersMixin)
    if select.OnLoad then select:OnLoad() end
    return select
end

-- [[ Header / sub-heading / note ]] --  KAF :183-205
function build.HeaderRow(parent)
    local row = Row("Frame", parent)
    row.Text = Text(row, "ARTWORK", "GameFontHighlightLarge", "LEFT")
    row.Text:SetPoint("BOTTOMLEFT", 6, 6)
    row.Text:SetPoint("RIGHT", -6, 0)
    return Finish(row, mixins.TextRow)
end

function build.SubHeadingRow(parent)
    local row = Row("Frame", parent)
    row.Text = Text(row, "ARTWORK", "GameFontHighlight", "LEFT")
    row.Text:SetPoint("LEFT", 16, 0)
    row.Text:SetPoint("RIGHT", -16, 0)
    return Finish(row, mixins.TextRow)
end

function build.NoteRow(parent)
    local row = Row("Frame", parent)
    row.Text = Text(row, "ARTWORK", "GameFontDisable", "LEFT", "TOP")
    row.Text:SetPoint("TOPLEFT", 16, -4)
    row.Text:SetPoint("BOTTOMRIGHT", -16, 0)
    return Finish(row, mixins.TextRow)
end

local function Hover(row, layer, subLevel)
    local hover = Color(row, layer or "BACKGROUND", 1, 1, 1, 0.05, subLevel)
    hover:SetAllPoints()
    hover:Hide()
    return hover
end
build.Hover = Hover

-- [[ An option ]] --  KAF :217-269
function build.OptionRow(parent)
    local row = Row("Frame", parent)
    row:EnableMouse(true)
    row.Hover = Hover(row)
    row.Label = Text(row, "ARTWORK", "GameFontNormal", "LEFT")
    row.Label:SetWordWrap(true)
    row.Label:SetMaxLines(2)
    row.Label:SetPoint("LEFT", 16, 0)
    row.ReloadIcon = row:CreateTexture(nil, "ARTWORK")
    row.ReloadIcon:SetTexture("Interface\\Buttons\\UI-RefreshButton")
    row.ReloadIcon:SetSize(12, 12)
    row.ReloadIcon:SetPoint("LEFT", row.Label, "RIGHT", 6, 0)
    row.ReloadIcon:Hide()
    row.ChangedBar = Color(row, "ARTWORK", 1, 0.82, 0, 1)
    row.ChangedBar:SetWidth(2)
    row.ChangedBar:SetPoint("TOPLEFT", 0, -4)
    row.ChangedBar:SetPoint("BOTTOMLEFT", 0, 4)
    row.ChangedBar:Hide()
    local reset = CreateFrame("Button", nil, row)
    reset:SetSize(12, 12)
    reset:SetPoint("RIGHT", row.Label, "LEFT", -2, 0)
    reset:SetNormalAtlas("common-icon-undo")
    reset:SetHighlightAtlas("common-icon-undo", "ADD")
    reset:Hide()
    row.Reset = reset
    row.Toggle = build.CheckButton(row)
    row.Toggle:Hide()
    row.Range = CreateFrame("Frame", nil, row, "MinimalSliderWithSteppersTemplate")
    row.Range:SetSize(geometry.SliderWidth, 20)
    row.Range:Hide()
    row.Select = build.Select(row)
    row.Select:Hide()
    row.Execute = CreateFrame("Button", nil, row, "UIPanelButtonNoTooltipTemplate")
    row.Execute:SetSize(200, 22)
    row.Execute:Hide()
    row.Input = CreateFrame("EditBox", nil, row, "InputBoxTemplate")
    row.Input:SetAutoFocus(false)
    row.Input:SetSize(240, 20)
    row.Input:Hide()
    row.Key1 = build.KeyButton(row)
    row.Key1:Hide()
    row.Key2 = build.KeyButton(row)
    row.Key2:SetPoint("LEFT", row.Key1, "RIGHT")
    row.Key2:Hide()
    return Finish(row, mixins.OptionRow, { OnLoad = "OnLoad", OnEnter = "OnEnter", OnLeave = "OnLeave" })
end

-- [[ Sub / grid ]] --  KAF :273-301
function build.SubRow(parent)
    local row = Row("Frame", parent)
    row.Text = Text(row, "ARTWORK", "GameFontHighlight", "LEFT")
    row.Text:SetPoint("LEFT", 16, 0)
    row.All = CreateFrame("Button", nil, row, "UIPanelButtonNoTooltipTemplate")
    row.All:SetSize(70, 20)
    row.None = CreateFrame("Button", nil, row, "UIPanelButtonNoTooltipTemplate")
    row.None:SetSize(70, 20)
    row.None:SetPoint("LEFT", row.All, "RIGHT", 6, 0)
    return Finish(row, mixins.SubRow, { OnLoad = "OnLoad" })
end

function build.GridHeaderRow(parent) -- KAF :287-290：纯列标题行，All/None 属于 SubRow
    local row = Row("Frame", parent)
    return Finish(row, mixins.GridHeaderRow, { OnLoad = "OnLoad" })
end

function build.GridRow(parent)
    local row = Row("Frame", parent)
    row:EnableMouse(true)
    row.Hover = Hover(row)
    row.Label = Text(row, "ARTWORK", "GameFontNormal", "LEFT")
    row.Label:SetWordWrap(false)
    row.Label:SetWidth(180)
    row.Label:SetPoint("LEFT", 16, 0)
    return Finish(row, mixins.GridRow, { OnLoad = "OnLoad", OnEnter = "OnEnter", OnLeave = "OnLeave" })
end

local function ArrowButton(parent, direction)
    local button = CreateFrame("Button", nil, parent)
    button:SetSize(22, 22)
    button:SetNormalTexture("Interface\\Buttons\\Arrow-" .. direction .. "-Up")
    button:SetPushedTexture("Interface\\Buttons\\Arrow-" .. direction .. "-Down")
    button:SetDisabledTexture("Interface\\Buttons\\Arrow-" .. direction .. "-Disabled")
    return button
end

function build.TabRow(parent)
    local row = Row("Frame", parent)
    row:EnableMouse(true)
    row.Hover = Hover(row)
    row.Position = Text(row, "ARTWORK", "GameFontDisable", "RIGHT")
    row.Position:SetWidth(20)
    row.Position:SetPoint("LEFT", 10, 0)
    row.Label = Text(row, "ARTWORK", "GameFontNormal", "LEFT")
    row.Label:SetWordWrap(false)
    row.Label:SetPoint("LEFT", 70, 0)
    row.Source = Text(row, "ARTWORK", "GameFontDisableSmall", "LEFT")
    row.Source:SetPoint("LEFT", row.Label, "RIGHT", 8, 0)
    row.ShowCheck = build.CheckButton(row)
    row.ShowCheck:SetPoint("LEFT", geometry.TabCheckX or 34, 0)
    row.Up = ArrowButton(row, "Up")
    row.Down = ArrowButton(row, "Down")
    row.Down:SetPoint("LEFT", row.Up, "RIGHT", 4, 0)
    return Finish(row, mixins.TabRow, { OnLoad = "OnLoad", OnEnter = "OnEnter", OnLeave = "OnLeave" })
end

-- [[ Search heading / link ]] --  KAF :338-365
function build.SearchHeadingRow(parent)
    local row = Row("Button", parent)
    row.MouseoverOverlay = Color(row, "BACKGROUND", 0.1, 0.1, 0.1, 1)
    row.MouseoverOverlay:SetBlendMode("ADD")
    row.MouseoverOverlay:SetAllPoints()
    row.MouseoverOverlay:Hide()
    row.Title = Text(row, "ARTWORK", "GameFontNormalLarge", "LEFT", "TOP")
    row.Title:SetPoint("TOPLEFT", 16, -16)
    return Finish(row, mixins.SearchHeadingRow, { OnClick = "OnClick", OnEnter = "OnEnter", OnLeave = "OnLeave" })
end

function build.LinkRow(parent)
    local row = Row("Button", parent)
    row.Text = Text(row, "ARTWORK", "GameFontNormal", "LEFT")
    row.Text:SetWordWrap(false)
    row.Text:SetPoint("LEFT", 16, 0)
    row.Detail = Text(row, "ARTWORK", "GameFontDisableSmall", "LEFT")
    row.Detail:SetWordWrap(false)
    row.Detail:SetPoint("LEFT", row.Text, "RIGHT", 10, 0)
    row.Detail:SetPoint("RIGHT", -16, 0)
    local highlight = row:CreateTexture()
    highlight:SetColorTexture(1, 1, 1, 0.08)
    highlight:SetBlendMode("ADD")
    highlight:SetAllPoints()
    row:SetHighlightTexture(highlight)
    return Finish(row, mixins.LinkRow, { OnClick = "OnClick" })
end

-- [[ Cards ]] --  KAF :367-425
local cardEdges = { -- 尺寸（宽或高）+ 两条锚点，照 KAF RowFrames.lua:372-377
    { nil, 1, "TOPLEFT", 0, 0, "TOPRIGHT", 0, 0 },
    { nil, 1, "BOTTOMLEFT", 0, 0, "BOTTOMRIGHT", 0, 0 },
    { 1, nil, "TOPLEFT", 0, -1, "BOTTOMLEFT", 0, 1 },
    { 1, nil, "TOPRIGHT", 0, -1, "BOTTOMRIGHT", 0, 1 },
}
function build.Card(parent)
    local card = CreateFrame("Button", nil, parent)
    local border = geometry.CardBorderColor or { 1, 1, 1, 0.12 }
    card.Fill = Color(card, "BACKGROUND", 0, 0, 0, 0.35)
    card.Fill:SetAllPoints()
    card.PictureArea = Color(card, "BORDER", 0, 0, 0, 0.5)
    card.PictureArea:SetHeight(geometry.CardPictureHeight or 86)
    card.PictureArea:SetPoint("TOPLEFT", 1, -1)
    card.PictureArea:SetPoint("TOPRIGHT", -1, -1)
    card.Hover = Hover(card, "BORDER", 1)
    card.Picture = card:CreateTexture(nil, "ARTWORK")
    card.Picture:SetPoint("TOPLEFT", card.PictureArea)
    card.Picture:SetPoint("BOTTOMRIGHT", card.PictureArea)
    card.Icon = card:CreateTexture(nil, "ARTWORK")
    card.Icon:SetSize(48, 48)
    card.Icon:SetPoint("CENTER", card.PictureArea)
    card.Icon:Hide()
    card.Name = Text(card, "ARTWORK", "GameFontNormal", "LEFT")
    card.Name:SetWordWrap(false)
    card.Line = Text(card, "ARTWORK", "GameFontDisableSmall", "LEFT", "TOP")
    card.Line:SetPoint("TOPLEFT", card.Name, "BOTTOMLEFT", 0, -3)
    card.PictureLine = Color(card, "OVERLAY", unpack(border))
    card.PictureLine:SetHeight(1)
    card.PictureLine:SetPoint("TOPLEFT", card.PictureArea, "BOTTOMLEFT")
    card.PictureLine:SetPoint("TOPRIGHT", card.PictureArea, "BOTTOMRIGHT")
    card.Edges = {}
    for _, spec in ipairs(cardEdges) do
        local edge = Color(card, "OVERLAY", unpack(border))
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
    return Finish(card, mixins.Card, { OnClick = "OnClick", OnEnter = "OnEnter", OnLeave = "OnLeave" })
end

function build.CardRow(parent)
    local row = Row("Frame", parent)
    return Finish(row, mixins.CardRow, { OnLoad = "OnLoad" })
end
