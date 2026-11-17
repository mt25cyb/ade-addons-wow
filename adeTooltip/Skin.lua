------------------------------------------------------------
-- Skin 引擎：每個 tooltip 一個自有的 overlay 框
--
-- 設計核心（taint 圍堵）：
--   * 背景、邊框、大陣營圖全部畫在**自己的** skin frame 上，暴雪 tooltip 只被動當定位參考。
--   * skin 是 tip 的 child、frameLevel 壓在 tip 之下 ⇒ 蓋不到文字。
--   * 上色一律 SetVertexColor（吃秘密分量）。
--   * per-tip 狀態放 State[tip]，暴雪物件上零欄位寫入。
------------------------------------------------------------
local ns = _G.adeTooltip or {}
_G.adeTooltip = ns

local S = ns.Secret
local P = ns.P
local Media = ns.Media

ns.Skin = {}
local Skin = ns.Skin

local State = {}      -- [tip] = state
Skin.State = State

function Skin.Get(tip)
    return tip and State[tip] or nil
end

function Skin.Each(fn)
    for tip, state in pairs(State) do
        fn(tip, state)
    end
end

------------------------------------------------------------
-- 共用輪詢：只有在有 tooltip 顯示中才跑
------------------------------------------------------------
local poll = ns.Metro.New(0.05, function(err) ns.ReportError(err) end)
Skin.Poll = poll.Add
Skin.Unpoll = poll.Remove

local shownCount = 0

local function NoteVisibility(state, visible)
    if state.visible == visible then return end
    state.visible = visible
    shownCount = shownCount + (visible and 1 or -1)
    if shownCount < 0 then shownCount = 0 end
    poll.SetEnabled(shownCount > 0)
end

------------------------------------------------------------
-- 一次性視覺中和：把暴雪自己的底框藏起來（alpha，不動結構、不掛勾）
------------------------------------------------------------
local function NeutralizeNineSlice(tip)
    if S.IsForbiddenObject(tip) then return end
    local nine = tip.NineSlice
    if nine and not S.IsForbiddenObject(nine) and nine.SetAlpha then
        pcall(nine.SetAlpha, nine, 0)
    end
end

function Skin.NeutralizeTemplateBar(tip)
    if S.IsForbiddenObject(tip) then return end
    local ok, name = pcall(tip.GetName, tip)
    if not ok or type(name) ~= "string" or S.IsSecret(name) then return end
    local tplBar = _G[name .. "StatusBar"]
    if tplBar and tplBar.SetAlpha then
        pcall(tplBar.SetAlpha, tplBar, 0)
    end
end

------------------------------------------------------------
-- skin 建立
------------------------------------------------------------
local function LowerSkinLevel(skin)
    local tip = skin:GetParent()
    if not tip or S.IsForbiddenObject(tip) then return end
    local ok, level = pcall(tip.GetFrameLevel, tip)
    if ok and type(level) == "number" and not S.IsSecret(level) then
        skin:SetFrameLevel(math.max(0, level - 1))
    end
end

function Skin.Attach(tip, opts)
    if not tip or State[tip] then return State[tip] end
    if S.IsForbiddenObject(tip) then return end

    local state = {}
    State[tip] = state
    state.keepScale = opts and opts.keepScale and true or nil

    local skin = CreateFrame("Frame", nil, tip)
    skin:SetAllPoints(tip)
    state.skin = skin

    local bg = Media.NoSnap(skin:CreateTexture(nil, "BACKGROUND"))
    bg:SetTexture(Media.WHITE8X8)
    state.bg = bg

    local edges = {}
    for i = 1, 4 do
        edges[i] = Media.NoSnap(skin:CreateTexture(nil, "BORDER"))
        edges[i]:SetTexture(Media.WHITE8X8)
    end
    state.edges = edges

    local mask = skin:CreateTexture(nil, "ARTWORK")
    mask:SetTexture("Interface\\Tooltips\\UI-Tooltip-Background")
    mask:SetBlendMode("ADD")
    if mask.SetGradient then
        mask:SetGradient("VERTICAL", CreateColor(0, 0, 0, 0), CreateColor(0.9, 0.9, 0.9, 0.4))
    end
    mask:Hide()
    state.mask = mask

    local faction = skin:CreateTexture(nil, "ARTWORK", nil, 1)
    faction:SetPoint("TOPRIGHT", skin, "TOPRIGHT", 18, 0)
    faction:SetBlendMode("ADD")
    faction:SetScale(0.24)
    faction:SetAlpha(0.40)
    faction:Hide()
    state.factionBig = faction

    skin:SetScript("OnShow", function(self)
        LowerSkinLevel(self)
        Skin.LayoutBorder(state)
        NeutralizeNineSlice(tip)
        Skin.NeutralizeTemplateBar(tip)
        Skin.RaiseAccents(tip)
        NoteVisibility(state, true)
        if ns.Panel then ns.Panel.OnSkinShow(tip, state) end
    end)
    skin:SetScript("OnHide", function()
        Skin.ClearTransient(tip)
        if ns.Panel then ns.Panel.OnSkinHide(tip, state) end
        NoteVisibility(state, false)
    end)

    LowerSkinLevel(skin)
    NeutralizeNineSlice(tip)
    Skin.NeutralizeTemplateBar(tip)
    Skin.ApplyBase(tip)
    return state
end

------------------------------------------------------------
-- 血條 / 模型的層級要明寫在 tip 之上
------------------------------------------------------------
function Skin.RaiseAccents(tip)
    local state = State[tip]
    if not state or S.IsForbiddenObject(tip) then return end
    local ok, level = pcall(tip.GetFrameLevel, tip)
    if not ok or type(level) ~= "number" or S.IsSecret(level) then return end
    if state.bar then state.bar:SetFrameLevel(level + (state.barHost and 6 or 1)) end
    if state.model then state.model:SetFrameLevel(level + (state.modelHost and 6 or 1)) end
end

------------------------------------------------------------
-- 基礎樣式
------------------------------------------------------------
local function SkinPixel(skin, n)
    n = math.floor((tonumber(n) or 0) + 0.5)
    if n <= 0 then return 0 end
    local ok, scale = pcall(skin.GetEffectiveScale, skin)
    scale = ok and S.PlainNumber(scale)
    if not (scale and scale > 0) then return P.Pixel(n) end
    return n * (PixelUtil and PixelUtil.GetPixelToUIUnitFactor and PixelUtil.GetPixelToUIUnitFactor() or 1) / scale
end
Skin.Pixel = SkinPixel

local function LayoutBorder(state)
    local g = ns.settings and ns.settings.general
    if not g then return end
    local inset = SkinPixel(state.skin, g.borderSize or 1)
    if state.borderInset == inset then return end
    state.borderInset = inset

    local bg = state.bg
    bg:ClearAllPoints()
    bg:SetPoint("TOPLEFT", inset, -inset)
    bg:SetPoint("BOTTOMRIGHT", -inset, inset)

    local e = state.edges
    for i = 1, 4 do
        e[i]:ClearAllPoints()
        e[i]:SetShown(inset > 0)
    end
    if inset > 0 then
        e[1]:SetPoint("TOPLEFT", 0, 0);    e[1]:SetPoint("TOPRIGHT", 0, 0);    e[1]:SetHeight(inset)
        e[2]:SetPoint("BOTTOMLEFT", 0, 0); e[2]:SetPoint("BOTTOMRIGHT", 0, 0); e[2]:SetHeight(inset)
        e[3]:SetPoint("TOPLEFT", 0, -inset);  e[3]:SetPoint("BOTTOMLEFT", 0, inset);  e[3]:SetWidth(inset)
        e[4]:SetPoint("TOPRIGHT", 0, -inset); e[4]:SetPoint("BOTTOMRIGHT", 0, inset); e[4]:SetWidth(inset)
    end

    local mask = state.mask
    mask:ClearAllPoints()
    mask:SetPoint("TOPLEFT", inset, -inset)
    mask:SetPoint("BOTTOMRIGHT", state.skin, "TOPRIGHT", -inset, -32)
end
Skin.LayoutBorder = LayoutBorder

function Skin.ApplyBase(tip)
    local state = State[tip]
    if not state or not ns.settings then return end
    local g = ns.settings.general

    if not state.keepScale and not S.IsForbiddenObject(tip) and tip.SetScale then
        pcall(tip.SetScale, tip, ns.settings and ns.settings.scale or 1)
    end

    state.borderInset = nil
    LayoutBorder(state)

    state.bg:SetTexture(Media.Background(g.bgfile))
    state.bg:SetTexCoord(0, 1, 0, 1)
    state.mask:SetShown(g.mask and true or false)

    Skin.ResetColors(tip)
end

function Skin.ApplyBaseAll()
    for tip in pairs(State) do
        Skin.ApplyBase(tip)
    end
end

------------------------------------------------------------
-- 內容色
------------------------------------------------------------
function Skin.SetBorderColor(tip, r, g, b, a)
    local state = State[tip]
    if not state then return end
    for i = 1, 4 do
        state.edges[i]:SetVertexColor(r, g, b, a or 1)
    end
    local c = state.borderColor
    if not c then c = {}; state.borderColor = c end
    c[1], c[2], c[3], c[4] = r, g, b, a or 1
end

function Skin.SetBackgroundColor(tip, r, g, b, a)
    local state = State[tip]
    if not state then return end
    state.bg:SetVertexColor(r, g, b, 1)
    state.bg:SetAlpha(S.PlainNumber(a) or 1)
end

function Skin.ResetColors(tip)
    local state = State[tip]
    if not state or not ns.settings then return end
    local g = ns.settings.general
    local bc, bgc = g.borderColor, g.background
    if ns.Panel and ns.Panel.BaseBorderColor then
        Skin.SetBorderColor(tip, ns.Panel.BaseBorderColor())
    else
        Skin.SetBorderColor(tip, bc.r, bc.g, bc.b, bc.a)
    end
    Skin.SetBackgroundColor(tip, bgc.r, bgc.g, bgc.b, bgc.a)
end

function Skin.SetFactionBig(tip, factionGroup)
    local state = State[tip]
    if not state then return end
    local group = S.PlainText(factionGroup)
    if group == "Alliance" or group == "Horde" then
        state.factionBig:SetTexture("Interface\\Timer\\" .. group .. "-Logo")
        state.factionBig:Show()
    else
        state.factionBig:Hide()
    end
end

------------------------------------------------------------
-- 單位暫態清理
------------------------------------------------------------
function Skin.ClearTransient(tip)
    local state = State[tip]
    if not state then return end
    state.unit = nil
    state.unitGuid = nil
    state.specGuid = nil
    state.specLine = nil
    state.isUnitTip = nil
    state.targetLine = nil
    state.lastSpellId = nil
    state.factionBig:Hide()
    Skin.ResetColors(tip)
    if ns.Bar then ns.Bar.Deactivate(tip) end
    if ns.Model then ns.Model.Clear(tip) end
end
