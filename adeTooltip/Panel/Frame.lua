------------------------------------------------------------
-- 重繪面板：框、池、量尺、像素工具、外觀常數
--
-- 物品／法術提示改成「原生 tooltip 留在底下當定位與夾邊的替身（alpha 0、padding 撐大），
-- 旁邊畫一個自己的 panel」。這支只管 panel 本身；藏原生在 Native.lua、流程在 Try.lua。
--
-- ⚠ panel 是**自己的** frame（parent UIParent；預覽時 parent 是設定視窗），上面的欄位隨便寫。
-- ⚠ 量測與排版**只讀自己記的數字**（panel.width／panel.height），不讀 panel:GetWidth()。
------------------------------------------------------------
local ns = _G.adeTooltip or {}
_G.adeTooltip = ns

local S = ns.Secret
local Media = ns.Media

ns.Panel = ns.Panel or {}
local Panel = ns.Panel

local WHITE = Media.WHITE8X8

function Panel.Option(key)
    local p = ns.settings and ns.settings.panel
    return not p or p[key] ~= false
end

Panel.LOOK = {
    PAD = 10, PAD_TOP_EXTRA = 2, PAD_BOTTOM_EXTRA = -2,
    MIN_W = 220, MAX_W = 440, PROSE_W = 300,
    COLUMN_GAP = 12, ROW_GAP = 2, HEADER_GAP = 4, HEADER_BOTTOM = 6,
    LINE_ALPHA = 0.22, RULE_SPACE = 8, DIAMOND = 5, DIAMOND_ALPHA = 0.9,
    TEXT_MID = 0.46, CAPTION_GRAY = 0.65, CAPTION_LINE_GAP = 8,
    TEXT = { 1, 1, 1 }, SECONDARY = { 0.65, 0.65, 0.65 }, DIM = { 0.45, 0.45, 0.45 },
    UNUSABLE = { 1, 0.34, 0.28 }, DESCRIPTION = { 1, 1, 1 },
    ICON_ITEM = 40, ICON_SPELL = 36, ICON_GAP = 10,
    BADGE_GAP = 4, BADGE_H = 16, BADGE_PAD = 10, BADGE_BG = 0.08,
    FOOTER_BG = 0.102, FOOTER_TOP = 9, FOOTER_PAD = 6,
    CLOSE_SIZE = 16, CLOSE_LEN = 11, CLOSE_THICK = 1.5,
    TAG_H = 16, TAG_PAD = 8, TAG_GAP = 2, TAG_BG = 0.08,
    EDGE_MARGIN = 4,
    SMALL_SHRINK = 2, SMALL_MIN = 9, BIG_GROW = 2, STAT_GROW = 3,
    EFFECT = { 0.48, 0.88, 0.48 }, ITEM_LEVEL = { 1, 0.84, 0.36 },
    FLAVOR = { 0.86, 0.74, 0.45 }, SET_NAME = { 1, 0.82, 0 },
    STAT_SHADE = { primary = 1, secondary = 0.85, tertiary = 0.85, other = 0.7 },
    CREATED_ICON = 24, REAGENT_ICON = 14,
    BAR_W = 54, BAR_H = 6, FRAME_GAP = 6,
    ICON_UNIT = 40, UNIT_MIN_W = 250, UNIT_HEADER_GAP = 3, NAME_GROW = 3,
    DETAIL = { 0.82, 0.82, 0.82 },
    PLATE_BORDER = 0.8, PLATE_FILL = 0.14, PLATE_TEXT = 0.55,
    FADE = 0.3,
}
local LOOK = Panel.LOOK

local function EffectiveScale(region)
    local ok, scale = pcall(region.GetEffectiveScale, region)
    scale = ok and S.PlainNumber(scale)
    if scale and scale > 0 then return scale end
end
Panel.EffectiveScale = EffectiveScale

function Panel.Scale(panel, n)
    if n == 0 then return 0 end
    local scale = EffectiveScale(panel)
    if scale and PixelUtil and PixelUtil.GetNearestPixelSize then
        return PixelUtil.GetNearestPixelSize(n, scale)
    end
    return n
end

function Panel.Pixel(panel, n)
    n = math.floor((n or 1) + 0.5)
    if n <= 0 then return 0 end
    local scale = EffectiveScale(panel)
    local factor = PixelUtil and PixelUtil.GetPixelToUIUnitFactor and PixelUtil.GetPixelToUIUnitFactor()
    if not (scale and factor) then return n end
    return n * factor / scale
end

function Panel.Snap(panel, value)
    local scale = EffectiveScale(panel)
    if scale and PixelUtil and PixelUtil.GetNearestPixelSize then
        return PixelUtil.GetNearestPixelSize(value, scale)
    end
    return math.floor(value + 0.5)
end

local function ReadFont(obj, fallbackSize)
    local path, size, flags
    if obj and obj.GetFont then path, size, flags = obj:GetFont() end
    if type(path) ~= "string" or path == "" then path = Media.Font("default") end
    if type(size) ~= "number" or size <= 0 then size = fallbackSize end
    if type(flags) ~= "string" then flags = "" end
    local sx, sy, sr, sg, sb, sa = 1, -1, 0, 0, 0, 0.9
    if obj and obj.GetShadowOffset then
        local ox, oy = obj:GetShadowOffset()
        if type(ox) == "number" then sx, sy = ox, oy end
    end
    if obj and obj.GetShadowColor then
        local r, g, b, a = obj:GetShadowColor()
        if type(r) == "number" then sr, sg, sb, sa = r, g, b, a or 1 end
    end
    return { font = path, size = size, flags = flags, shadow = { sx, sy, sr, sg, sb, sa } }
end

local function Derive(base, size)
    return { font = base.font, size = size, flags = base.flags, shadow = base.shadow }
end

function Panel.Styles()
    local title = ReadFont(_G.GameTooltipHeaderText, 14)
    local body = ReadFont(_G.GameTooltipText, 12)
    local small = math.max(LOOK.SMALL_MIN, body.size - LOOK.SMALL_SHRINK)
    return {
        title = title,
        heading = Derive(title, math.max(body.size, title.size - 2)),
        body = body,
        small = Derive(body, small),
        caption = Derive(body, small),
        big = Derive(body, body.size + LOOK.BIG_GROW),
        name = Derive(title, title.size + LOOK.NAME_GROW),
        stat = Derive(body, body.size + LOOK.STAT_GROW),
    }
end

function Panel.ApplyFont(fs, style)
    if fs.mtFont ~= style.font or fs.mtSize ~= style.size or fs.mtFlags ~= style.flags then
        local ok = pcall(fs.SetFont, fs, style.font, style.size, style.flags)
        if not ok or not fs:GetFont() then
            fs:SetFont(Media.Font("default"), style.size, style.flags)
        end
        fs.mtFont, fs.mtSize, fs.mtFlags = style.font, style.size, style.flags
    end
    local sh = style.shadow
    if sh and fs.mtShadow ~= sh then
        fs:SetShadowOffset(sh[1], sh[2])
        fs:SetShadowColor(sh[3], sh[4], sh[5], sh[6])
        fs.mtShadow = sh
    end
end

local ruler, rulerHolder
local function Ruler()
    if ruler then return ruler end
    rulerHolder = CreateFrame("Frame", nil, UIParent)
    rulerHolder:SetSize(1, 1)
    rulerHolder:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", 0, 0)
    rulerHolder:SetAlpha(0)
    ruler = rulerHolder:CreateFontString(nil, "OVERLAY")
    ruler:SetPoint("TOPLEFT")
    Panel.ApplyFont(ruler, ReadFont(_G.GameTooltipText, 12))
    return ruler
end

function Panel.SyncRuler(panel)
    Ruler()
    local ps, us = EffectiveScale(panel), EffectiveScale(UIParent)
    if ps and us then rulerHolder:SetScale(ps / us) end
end

Panel.ICON_TEXT_GAP = 3

local function ParseIcon(code)
    if code:sub(2, 2) == "T" then
        local body = code:match("^|T(.-)|t$")
        if not body then return end
        local p = {}
        for v in (body .. ":"):gmatch("(.-):") do p[#p + 1] = v end
        local icon = { file = tonumber(p[1]) or p[1], h = tonumber(p[2]), w = tonumber(p[3]) }
        local tw, th, l, r, t, b = tonumber(p[6]), tonumber(p[7]), tonumber(p[8]), tonumber(p[9]), tonumber(p[10]), tonumber(p[11])
        if tw and th and tw > 0 and th > 0 and l and r and t and b then
            icon.coords = { l / tw, r / tw, t / th, b / th }
        end
        return icon
    end
    local body = code:match("^|A:?(.-)|a$")
    if not body then return end
    local p = {}
    for v in (body .. ":"):gmatch("(.-):") do p[#p + 1] = v end
    return { atlas = p[1], h = tonumber(p[2]), w = tonumber(p[3]) }
end

local function IconCount(text)
    local n = 0
    for _ in text:gmatch("|[TA]") do n = n + 1 end
    return n
end

function Panel.SplitIcons(text)
    if type(text) ~= "string" or IconCount(text) ~= 1 then return nil, text, nil end
    local code, rest = text:match("^(|T[^|]*|t)%s?(.*)$")
    if not code then code, rest = text:match("^(|A[^|]*|a)%s?(.*)$") end
    if code then return ParseIcon(code), rest, nil end
    local before
    before, code = text:match("^(.-)%s?(|T[^|]*|t)$")
    if not code then before, code = text:match("^(.-)%s?(|A[^|]*|a)$") end
    if code then return nil, before, ParseIcon(code) end
    return nil, text, nil
end

function Panel.IconSize(icon, style)
    local h = (icon.h and icon.h > 0) and icon.h or style.size
    local w = (icon.w and icon.w > 0) and icon.w or h
    return w, h
end

local function MeasureRaw(text, style)
    if type(text) ~= "string" or text == "" then return 0 end
    local fs = Ruler()
    Panel.ApplyFont(fs, style)
    fs:SetText(text)
    local w = fs.GetUnboundedStringWidth and fs:GetUnboundedStringWidth() or fs:GetStringWidth()
    return S.PlainNumber(w) or 0
end
Panel.MeasureRaw = MeasureRaw

function Panel.Measure(text, style)
    if type(text) ~= "string" or text == "" then return 0 end
    local lead, body, trail = Panel.SplitIcons(text)
    local w = MeasureRaw(body, style)
    for _, icon in ipairs({ lead or false, trail or false }) do
        if icon then
            local iw = Panel.IconSize(icon, style)
            w = w + iw + ((body ~= "") and Panel.ICON_TEXT_GAP or 0)
        end
    end
    return w
end

function Panel.Text(panel, style)
    panel.textsUsed = panel.textsUsed + 1
    local fs = panel.texts[panel.textsUsed]
    if not fs then
        fs = panel:CreateFontString(nil, "OVERLAY")
        fs:SetJustifyV("TOP")
        fs:SetWordWrap(true)
        panel.texts[panel.textsUsed] = fs
    end
    Panel.ApplyFont(fs, style)
    fs:ClearAllPoints()
    fs:Show()
    return fs
end

function Panel.SecretText(panel, style, slot)
    panel.secretTexts = panel.secretTexts or {}
    slot = slot or "target"
    local fs = panel.secretTexts[slot]
    if not fs then
        fs = panel:CreateFontString(nil, "OVERLAY")
        fs:SetJustifyV("TOP")
        fs:SetWordWrap(false)
        panel.secretTexts[slot] = fs
    end
    Panel.ApplyFont(fs, style)
    fs:ClearAllPoints()
    fs:Show()
    return fs
end

function Panel.Texture(panel, sublevel)
    panel.texturesUsed = panel.texturesUsed + 1
    local tex = panel.textures[panel.texturesUsed]
    if not tex then
        tex = Media.NoSnap(panel:CreateTexture(nil, "ARTWORK"))
        panel.textures[panel.texturesUsed] = tex
    end
    tex:SetTexture(WHITE)
    tex:SetTexCoord(0, 1, 0, 1)
    tex:SetDrawLayer("ARTWORK", sublevel or 0)
    tex:SetRotation(0)
    if tex.mtBlend then tex:SetBlendMode("BLEND"); tex.mtBlend = nil end
    tex:SetVertexColor(1, 1, 1, 1)
    tex:ClearAllPoints()
    tex:Show()
    return tex
end

function Panel.Clear(panel)
    for i = 1, #panel.texts do panel.texts[i]:Hide() end
    for i = 1, #panel.textures do panel.textures[i]:Hide() end
    panel.textsUsed, panel.texturesUsed = 0, 0
    for _, fs in pairs(panel.secretTexts or {}) do fs:Hide() end
    panel.icon:Hide(); panel.iconBorder:Hide()
    panel.badge:Hide(); panel.badgeFill:Hide(); panel.badgeText:Hide()
    panel.footer:Hide()
    if panel.close then panel.close:Hide() end
    if panel.tag then panel.tag:Hide() end
end

local function MakeTexture(parent, layer, sublevel)
    local tex = Media.NoSnap(parent:CreateTexture(nil, layer, nil, sublevel or 0))
    tex:SetTexture(WHITE)
    return tex
end

local owners = {}

local function Create(tip, state)
    local parent = UIParent
    if state.isPreview then
        local ok, p = pcall(tip.GetParent, tip)
        if ok and p then parent = p end
    end
    local panel = CreateFrame("Frame", nil, parent)
    if not state.isPreview then
        local ok, strata = pcall(tip.GetFrameStrata, tip)
        strata = ok and S.PlainText(strata)
        panel:SetFrameStrata(strata or "TOOLTIP")
    end
    panel:Hide()

    panel.texts, panel.textsUsed = {}, 0
    panel.textures, panel.texturesUsed = {}, 0

    panel.bg = MakeTexture(panel, "BACKGROUND")
    panel.bg:SetAllPoints()
    panel.footer = MakeTexture(panel, "BORDER")
    panel.edges = {}
    for i = 1, 4 do panel.edges[i] = MakeTexture(panel, "OVERLAY", 7) end

    panel.icon = MakeTexture(panel, "ARTWORK", 2)
    panel.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    panel.iconBorder = MakeTexture(panel, "ARTWORK", 1)
    panel.badge = MakeTexture(panel, "ARTWORK", 1)
    panel.badgeFill = MakeTexture(panel, "ARTWORK", 2)
    panel.badgeText = panel:CreateFontString(nil, "OVERLAY")
    Panel.ApplyFont(panel.badgeText, ReadFont(_G.GameTooltipText, 12))
    panel.badgeText:SetPoint("CENTER", panel.badge, "CENTER", 0, 0)

    state.panel = panel
    owners[panel] = tip
    return panel
end

function Panel.Get(tip, state)
    return state.panel or Create(tip, state)
end

function Panel.FadeOut(panel, instant)
    local group = panel.fadeGroup
    panel.faded = true
    if instant then
        if group and group:IsPlaying() then group:Stop() end
        panel:SetAlpha(0)
        return
    end
    if not group then
        group = panel:CreateAnimationGroup()
        local alpha = group:CreateAnimation("Alpha")
        alpha:SetFromAlpha(1); alpha:SetToAlpha(0); alpha:SetDuration(LOOK.FADE)
        group:SetToFinalAlpha(true)
        panel.fadeGroup = group
    end
    if not group:IsPlaying() then group:Play() end
end

function Panel.Unfade(panel)
    if not panel or not panel.faded then return end
    panel.faded = nil
    local group = panel.fadeGroup
    if group and group:IsPlaying() then group:Stop() end
    panel:SetAlpha(1)
end

function Panel.SyncLevel(panel, tip)
    local ok, level = pcall(tip.GetFrameLevel, tip)
    level = ok and S.PlainNumber(level)
    if not level then return end
    if panel.syncedLevel ~= level then
        panel.syncedLevel = level
        panel:SetFrameLevel(level + 5)
        if panel.extrasBox then panel.extrasBox:SetFrameLevel(level + 5) end
    end
end

function Panel.LayoutEdges(panel)
    local px = Panel.Pixel(panel, 1)
    local e = panel.edges
    for i = 1, 4 do e[i]:ClearAllPoints() end
    e[1]:SetPoint("TOPLEFT"); e[1]:SetPoint("TOPRIGHT"); e[1]:SetHeight(px)
    e[2]:SetPoint("BOTTOMLEFT"); e[2]:SetPoint("BOTTOMRIGHT"); e[2]:SetHeight(px)
    e[3]:SetPoint("TOPLEFT", 0, -px); e[3]:SetPoint("BOTTOMLEFT", 0, px); e[3]:SetWidth(px)
    e[4]:SetPoint("TOPRIGHT", 0, -px); e[4]:SetPoint("BOTTOMRIGHT", 0, px); e[4]:SetWidth(px)
    panel.px = px
end

function Panel.BaseBorderColor()
    local g = ns.settings and ns.settings.general
    local bc = g and g.borderColor
    local a = bc and bc.a or 1
    if g and g.borderClassColor ~= false then
        local cls = ns.playerClass
        local c = cls and ((_G.CUSTOM_CLASS_COLORS and _G.CUSTOM_CLASS_COLORS[cls])
            or (_G.RAID_CLASS_COLORS and _G.RAID_CLASS_COLORS[cls]))
        if c and type(c.r) == "number" then return c.r, c.g, c.b, a end
    end
    if bc then return bc.r, bc.g, bc.b, a end
    return 0.18, 0.18, 0.18, 1
end

function Panel.BorderColor(state)
    local c = state and state.borderColor
    if c then return c[1], c[2], c[3], c[4] or 1 end
    return Panel.BaseBorderColor()
end

function Panel.PaintEdges(panel, state)
    local r, gg, b, a = Panel.BorderColor(state)
    for i = 1, 4 do panel.edges[i]:SetVertexColor(r, gg, b, a or 1) end
    panel.iconBorder:SetVertexColor(r, gg, b, a or 1)
    local tint = panel.badgeTint
    if tint then
        local k = LOOK.PLATE_BORDER
        panel.badge:SetVertexColor(tint[1] * k, tint[2] * k, tint[3] * k, 0.9)
    else
        panel.badge:SetVertexColor(r, gg, b, a or 1)
    end
    if panel.tag then panel.tag.border:SetVertexColor(r, gg, b, a or 1) end
end

local function AnchoredSide(tip)
    local ok, n = pcall(tip.GetNumPoints, tip)
    n = ok and S.PlainNumber(n)
    if not n then return nil end
    local h, v
    for i = 1, n do
        local okP, point, rel, relPoint, x, y = pcall(tip.GetPoint, tip, i)
        if not okP then return nil end
        if S.IsSecret(point) or S.IsSecret(rel) or S.IsSecret(relPoint) or S.IsSecret(x) or S.IsSecret(y) then return nil end
        if type(point) == "string" then
            if not h and point:find("RIGHT") then h = "RIGHT" end
            if not h and point:find("LEFT") then h = "LEFT" end
            if not v and point:find("TOP") then v = "TOP" end
            if not v and point:find("BOTTOM") then v = "BOTTOM" end
        end
    end
    return h or "LEFT", v or "TOP"
end
Panel.AnchoredSide = AnchoredSide

local function GridOffset(panel, tip, side, vside)
    local okX, x = pcall(side == "RIGHT" and tip.GetRight or tip.GetLeft, tip)
    local okY, y = pcall(vside == "BOTTOM" and tip.GetBottom or tip.GetTop, tip)
    if not okX or not okY then return nil end
    if S.IsSecret(x) or S.IsSecret(y) then return nil end
    if type(x) ~= "number" or type(y) ~= "number" then return nil, nil, nil, nil, true end
    local tipScale, panelScale = EffectiveScale(tip), EffectiveScale(panel)
    if not (tipScale and panelScale) then return nil, nil, nil, nil, true end
    x, y = x * tipScale / panelScale, y * tipScale / panelScale
    return Panel.Snap(panel, x) - x, Panel.Snap(panel, y) - y, x, y
end

local function ReadPoints(tip)
    local ok, n = pcall(tip.GetNumPoints, tip)
    n = ok and S.PlainNumber(n)
    if not n then return nil end
    local points = {}
    for i = 1, n do
        local okP, point, rel, relPoint, x, y = pcall(tip.GetPoint, tip, i)
        if not okP then return nil end
        if S.IsSecret(point) or S.IsSecret(rel) or S.IsSecret(relPoint) or S.IsSecret(x) or S.IsSecret(y) then return nil end
        points[i] = { point, rel, relPoint, x or 0, y or 0 }
    end
    return points
end

function Panel.PanelFor(frame)
    if type(frame) ~= "table" or not (ns.Skin and ns.Skin.State) then return nil end
    local st = ns.Skin.State[frame]
    local panel = st and st.panel
    if panel and panel:IsShown() then return panel end
end

local function PanelOf(rel, tip, panel)
    if rel == tip then return nil end
    local other = Panel.PanelFor(rel)
    if other ~= panel then return other end
end

local MAX_CHAIN = 8
local followers = {}
local following = false
Panel.followers = followers

local function Reanchor(frame, point, rel, relPoint, x, y)
    following = true
    pcall(function() frame:ClearAllPoints(); frame:SetPoint(point, rel, relPoint, x, y) end)
    following = false
end

function Panel.Follow(frame)
    if type(frame) ~= "table" or followers[frame] or type(frame.SetPoint) ~= "function" then return end
    followers[frame] = {}
    hooksecurefunc(frame, "SetPoint", function(self, point, rel, relPoint, x, y)
        if following then return end
        if S.IsSecret(point) or S.IsSecret(rel) or S.IsSecret(relPoint) or S.IsSecret(x) or S.IsSecret(y) then return end
        if type(rel) == "string" then rel = _G[rel] end
        if type(relPoint) == "number" then relPoint, x, y = point, relPoint, x end
        local rec = followers[self]
        rec.panel = nil
        if type(point) ~= "string" then return end
        local panel = Panel.PanelFor(rel)
        if not panel then return end
        relPoint = type(relPoint) == "string" and relPoint or point
        rec[1], rec[2], rec[3], rec[4], rec[5], rec.panel = point, rel, relPoint, x or 0, y or 0, panel
        local gx, gy = Panel.GapOffset(point, relPoint, Panel.Scale(self, LOOK.FRAME_GAP))
        Reanchor(self, point, panel, relPoint, (x or 0) + gx, (y or 0) + gy)
    end)
end

function Panel.ReturnFollowers(gone)
    for frame, rec in pairs(followers) do
        if rec.panel == gone then
            rec.panel = nil
            Reanchor(frame, rec[1], rec[2], rec[3], rec[4], rec[5])
        end
    end
end

local SIDECARS = { "AppearanceTooltipTooltip" }

function Panel.AdoptSidecar(frame)
    if type(frame) ~= "table" then return false end
    if type(frame.SetIgnoreParentAlpha) == "function" then pcall(frame.SetIgnoreParentAlpha, frame, true) end
    Panel.Follow(frame)
    return true
end

function Panel.AdoptKnownSidecars()
    for _, name in ipairs(SIDECARS) do
        local frame = _G[name]
        if frame then Panel.AdoptSidecar(frame) end
    end
end

local applying = {}

local function DependsOn(region, target, depth)
    if region == target then return true end
    if not owners[region] or not region.anchored or not region.anchorArgs then return false end
    if depth >= MAX_CHAIN then return true end
    for _, a in ipairs(region.anchorArgs) do
        if DependsOn(a[2], target, depth + 1) then return true end
    end
    return false
end

function Panel.AnchoredOn(panel, target)
    return panel ~= target and DependsOn(panel, target, 0)
end

local function Untangle(panel, sig, args)
    for _, a in ipairs(args) do
        local rel = a[2]
        if owners[rel] and not applying[rel] and DependsOn(rel, panel, 0) then Panel.Align(rel, owners[rel]) end
    end
    local out
    for i, a in ipairs(args) do
        local rel = a[2]
        if owners[rel] and DependsOn(rel, panel, 0) then
            if not out then out = {}; for j, b in ipairs(args) do out[j] = b end end
            out[i] = { a[1], owners[rel], a[3], a[4], a[5] }
        end
    end
    if not out then return sig, args end
    return tostring(sig) .. "|untangled", out
end

local function Apply(panel, sig, args)
    if panel.alignSig == sig and panel.anchored then return true end
    applying[panel] = true
    sig, args = Untangle(panel, sig, args)
    applying[panel] = nil
    panel:ClearAllPoints()
    for _, a in ipairs(args) do panel:SetPoint(a[1], a[2], a[3], a[4], a[5]) end
    panel.alignSig, panel.anchorArgs, panel.anchored = sig, args, true
    return true
end

local function Keep(panel, tip, provisional)
    if panel.anchored then return true end
    if panel.anchorArgs then return Apply(panel, panel.alignSig, panel.anchorArgs) end
    return Apply(panel, "provisional", provisional or { { "TOPLEFT", tip, "TOPLEFT", 0, 0 } })
end

local function Reserve(panel, depth)
    local top = panel.clampOwnTop or 0
    local states = ns.Skin and ns.Skin.State
    if states and depth < MAX_CHAIN then
        for _, st in pairs(states) do
            local p = st.panel
            if p and p ~= panel and p.mirrorOf == panel and p:IsShown() then
                top = math.max(top, Reserve(p, depth + 1))
            end
        end
    end
    return top
end

function Panel.ClampReserve(panel)
    if not panel or panel.clampOwnTop == nil then return nil end
    return Reserve(panel, 0), panel.clampMargin or 0
end

local function SetMirror(panel, target) panel.mirrorOf = target end

function Panel.GapOffset(point, relPoint, gap)
    if type(point) ~= "string" or type(relPoint) ~= "string" then return 0, 0 end
    local p, r = point:upper(), relPoint:upper()
    local dx, dy = 0, 0
    if p:find("RIGHT", 1, true) and r:find("LEFT", 1, true) then dx = -gap
    elseif p:find("LEFT", 1, true) and r:find("RIGHT", 1, true) then dx = gap end
    if p:find("BOTTOM", 1, true) and r:find("TOP", 1, true) then dy = gap
    elseif p:find("TOP", 1, true) and r:find("BOTTOM", 1, true) then dy = -gap end
    return dx, dy
end

local function Mirror(panel, tip, points)
    local mirrored, target = {}, nil
    for i, p in ipairs(points) do
        local other = PanelOf(p[2], tip, panel)
        if other then target = other end
        mirrored[i] = { p[1], other or p[2], p[3], p[4], p[5] }
    end
    if not target then return nil end
    local tipScale, panelScale = EffectiveScale(tip), EffectiveScale(panel)
    local ratio = (tipScale and panelScale) and (tipScale / panelScale) or 1
    local sig = {}
    local gap = Panel.Scale(panel, LOOK.FRAME_GAP)
    for i, p in ipairs(mirrored) do
        p[4], p[5] = Panel.Snap(panel, p[4] * ratio), Panel.Snap(panel, p[5] * ratio)
        if p[2] ~= points[i][2] then
            local gx, gy = Panel.GapOffset(p[1], p[3], gap)
            p[4], p[5] = p[4] + gx, p[5] + gy
        end
        sig[i] = ("%s|%s|%s|%.3f|%.3f"):format(p[1], tostring(p[2]), tostring(p[3]), p[4], p[5])
    end
    SetMirror(panel, target)
    return Apply(panel, "mirror:" .. table.concat(sig, ";"), mirrored)
end

local function StableGrid(panel, tip, corner, dx, dy, rawX, rawY)
    if panel.gridCorner == corner and panel.gridTip == tip and panel.gridRawX then
        local half = Panel.Pixel(panel, 1) * 0.5
        if math.abs(rawX - panel.gridRawX) <= half and math.abs(rawY - panel.gridRawY) <= half then
            dx, dy = panel.gridDX, panel.gridDY
            rawX, rawY = panel.gridRawX, panel.gridRawY
        end
    end
    panel.gridCorner, panel.gridTip = corner, tip
    panel.gridRawX, panel.gridRawY, panel.gridDX, panel.gridDY = rawX, rawY, dx, dy
    return dx, dy
end

function Panel.EmbeddedHost(tip)
    if not tip.GetOwner then return nil end
    local ok, owner = pcall(tip.GetOwner, tip)
    if not ok or S.IsSecret(owner) or type(owner) ~= "table" then return nil end
    local okH, host = pcall(function()
        if owner.IsEmbedded == true then return owner:GetParent():GetParent() end
    end)
    if okH and type(host) == "table" and not S.IsSecret(host) then return host, owner end
end

local function ShoppingTips(owner)
    local ok, list = pcall(function() return owner.shoppingTooltips end)
    if ok and type(list) == "table" and not S.IsSecret(list) then return list[1], list[2] end
end

local function SideFromPoints(points)
    for _, p in ipairs(points) do
        if type(p[1]) == "string" then
            if p[1]:find("LEFT", 1, true) then return "RIGHT" end
            if p[1]:find("RIGHT", 1, true) then return "LEFT" end
        end
    end
end

local function GuessSide(host)
    local okL, left = pcall(host.GetLeft, host)
    local okR, right = pcall(host.GetRight, host)
    left, right = okL and S.PlainNumber(left), okR and S.PlainNumber(right)
    if not (left and right) then
        local x, scale = S.PlainNumber((GetCursorPosition())), EffectiveScale(UIParent)
        if not (x and scale) then return "RIGHT" end
        local okW, width = pcall(host.GetWidth, host)
        left = x / scale
        right = left + (okW and S.PlainNumber(width) or 0)
    end
    local screen = S.PlainNumber(GetScreenWidth())
    if not screen then return "RIGHT" end
    local room = screen - right
    return (room >= LOOK.MAX_W * 2 or room >= left) and "RIGHT" or "LEFT"
end

local function HostNeighbor(tip, owner, side)
    local first, second = ShoppingTips(owner)
    local inner, outer = first, second
    if side == "RIGHT" then inner, outer = second, first end
    if not inner or tip ~= outer then return nil end
    local ok, shown = pcall(inner.IsShown, inner)
    if ok and not S.IsSecret(shown) and shown then return inner end
end

local function ClampBesideHost(panel, owner)
    local top, bottom = panel.clampOwnTop or 0, panel.totalHeight or panel.height or 0
    local first, second = ShoppingTips(owner)
    for _, shop in ipairs({ first or false, second or false }) do
        local other = shop and Panel.PanelFor(shop)
        if other then
            top = math.max(top, other.clampOwnTop or 0)
            bottom = math.max(bottom, other.totalHeight or other.height or 0)
        end
    end
    local margin = panel.clampMargin or 0
    local insetTop, insetBottom = top + margin, (panel.height or 0) - bottom - margin
    local sig = ("%.3f|%.3f|%.3f"):format(margin, insetTop, insetBottom)
    if panel.hostClampSig == sig then return end
    panel.hostClampSig = sig
    panel:SetClampRectInsets(-margin, margin, insetTop, insetBottom)
    panel:SetClampedToScreen(true)
end

local function ClearHostClamp(panel)
    if not panel.hostClampSig then return end
    panel.hostClampSig = nil
    panel:SetClampedToScreen(false)
    panel:SetClampRectInsets(0, 0, 0, 0)
end

local function AlignBesideHost(panel, tip, host, owner)
    panel.besideHost = true
    ClampBesideHost(panel, owner)
    local gap = Panel.Scale(panel, LOOK.FRAME_GAP)
    local points = ReadPoints(tip)
    if points and #points == 0 then
        return Keep(panel, tip, { { "TOPLEFT", host, "TOPRIGHT", gap, 0 } })
    end
    local side = points and SideFromPoints(points)
    local guessed = not side
    if guessed then side = GuessSide(host) end
    local neighbor = HostNeighbor(tip, owner, side)
    local other = neighbor and Panel.PanelFor(neighbor)
    local rel = other or neighbor or host
    local point, relPoint, dx, dy = "TOPLEFT", "TOPRIGHT", gap, 0
    if side == "LEFT" then point, relPoint, dx = "TOPRIGHT", "TOPLEFT", -gap end
    if not other then
        local fx, fy, rawX, rawY = GridOffset(panel, rel, side, "TOP")
        if fx then
            fx, fy = StableGrid(panel, rel, "TOP" .. side, fx, fy, rawX, rawY)
            dx, dy = dx + fx, fy
        end
    end
    SetMirror(panel, other)
    local sig = ("host:%s|%s|%s|%.3f|%.3f%s"):format(point, tostring(rel), relPoint, dx, dy, guessed and "|guess" or "")
    return Apply(panel, sig, { { point, rel, relPoint, dx, dy } })
end

function Panel.Align(panel, tip)
    local host, owner = Panel.EmbeddedHost(tip)
    if host then return AlignBesideHost(panel, tip, host, owner) end
    panel.besideHost = nil
    ClearHostClamp(panel)

    local points = ReadPoints(tip)
    if not points then return false end
    if #points == 0 then return Keep(panel, tip) end
    if Mirror(panel, tip, points) then return true end
    SetMirror(panel, nil)

    local side, vside = AnchoredSide(tip)
    if not side then return false end
    local dx, dy, rawX, rawY, unlaid = GridOffset(panel, tip, side, vside)
    if unlaid then return Keep(panel, tip) end
    if not dx then return false end
    local corner = vside .. side
    dx, dy = StableGrid(panel, tip, corner, dx, dy, rawX, rawY)
    if vside == "BOTTOM" then
        dy = dy + ((panel.totalHeight or panel.height or 0) - (panel.height or 0))
    end
    local sig = ("own:%s|%s|%.3f|%.3f"):format(corner, tostring(tip), dx, dy)
    return Apply(panel, sig, { { corner, tip, corner, dx, dy } })
end

function Panel.Detach(panel, keep)
    panel:ClearAllPoints()
    panel.anchored = false
    if not keep then
        SetMirror(panel, nil)
        panel.besideHost = nil
        ClearHostClamp(panel)
        panel.alignSig, panel.anchorArgs = nil, nil
        panel.gridCorner, panel.gridTip, panel.gridRawX = nil, nil, nil
    end
end
