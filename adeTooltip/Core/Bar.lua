------------------------------------------------------------
-- 血條：自己的 StatusBar 放在 skin 上，不碰 GameTooltipStatusBar
--
-- 秘密值策略：
--   * 條值：UnitHealthPercent(unit, true, ScaleTo100) → SetValue(秘密數字)。
--   * 文字：AbbreviateNumbers / AbbreviateLargeNumbers（C 端、吃秘密）+ SetFormattedText（C 端）。
--   * 顏色：分量可能是秘密 → GetStatusBarTexture():SetVertexColor。
------------------------------------------------------------
local ns = _G.adeTooltip or {}
_G.adeTooltip = ns

local S = ns.Secret
local P = ns.P
local Media = ns.Media
local Skin = ns.Skin
local Colors = ns.Colors

ns.Bar = {}
local Bar = ns.Bar

local DEAD = DEAD

------------------------------------------------------------
-- 引擎血條閘
------------------------------------------------------------
local function EngineBarShown(tip)
    if tip ~= GameTooltip then return true end
    local revived = ns.Anchor and ns.Anchor.ReviveHealth and ns.Anchor.ReviveHealth(tip)
    if revived ~= nil then return revived end
    local eb = tip.StatusBar or GameTooltipStatusBar
    if not eb or S.IsForbiddenObject(eb) or not eb.IsShown then return true end
    local ok, shown = pcall(eb.IsShown, eb)
    if not ok or S.IsSecret(shown) then return true end
    return shown and true or false
end

local IS_CJK = (GetLocale() == "zhTW" or GetLocale() == "zhCN")
local Abbrev = (IS_CJK and AbbreviateNumbers) or AbbreviateLargeNumbers or AbbreviateNumbers

local function Ensure(tip)
    local state = Skin.Get(tip)
    if not state then return end
    if state.bar then return state.bar end

    local bar = CreateFrame("StatusBar", nil, state.skin)
    bar:SetMinMaxValues(0, 100)
    bar:SetValue(0)
    local tex = Media.NoSnap(bar:CreateTexture(nil, "ARTWORK"))
    bar:SetStatusBarTexture(tex)

    local bg = Media.NoSnap(bar:CreateTexture(nil, "BACKGROUND"))
    bg:SetAllPoints(bar)
    bg:SetTexture(Media.WHITE8X8)
    bg:SetVertexColor(0.2, 0.2, 0.2, 0.8)

    local edges = {}
    for i = 1, 4 do
        edges[i] = Media.NoSnap(bar:CreateTexture(nil, "BORDER"))
        edges[i]:SetTexture(Media.WHITE8X8)
        edges[i]:SetVertexColor(0, 0, 0, 1)
    end
    state.barEdges = edges

    local text = bar:CreateFontString(nil, "OVERLAY")
    text:SetPoint("CENTER", bar, "CENTER", 0, 0)
    state.barText = text

    bar:Hide()
    state.bar = bar
    Bar.ApplySettings(tip)
    Skin.RaiseAccents(tip)
    return bar
end
Bar.Ensure = Ensure

function Bar.ApplySettings(tip)
    local state = Skin.Get(tip)
    if not state or not state.bar or not ns.db then return end
    local sb = ns.settings.statusbar
    local bar = state.bar
    local host = state.barHost or state.skin
    if bar:GetParent() ~= host then bar:SetParent(host) end

    if not sb.enable then
        state.barUnit = nil
        bar:Hide()
    end

    bar:GetStatusBarTexture():SetTexture(Media.BarTexture(sb.texture))

    state.barPx = nil
    Bar.Layout(state)

    local text = state.barText
    text:SetFont(Media.Font("default"), tonumber(sb.fontSize) or 10, "THINOUTLINE")
    text:SetShown(sb.textFormat ~= "none")

    if state.barUnit then Bar.Refresh(tip) end
end

function Bar.Layout(state)
    local bar = state.bar
    if not bar or not ns.db then return end
    local sb = ns.settings.statusbar
    local host = state.barHost or state.skin
    local bw = Skin.Pixel(host, 1)
    if state.barPx == bw and state.barAnchor == host then return end
    state.barPx, state.barAnchor = bw, host
    local h = P.Scale(math.max(1, sb.height or 4))
    local gap = P.Scale(4)
    bar:ClearAllPoints()
    if sb.position == "top" then
        bar:SetPoint("BOTTOMLEFT", host, "TOPLEFT", bw, gap)
        bar:SetPoint("BOTTOMRIGHT", host, "TOPRIGHT", -bw, gap)
    else
        bar:SetPoint("TOPLEFT", host, "BOTTOMLEFT", bw, -gap)
        bar:SetPoint("TOPRIGHT", host, "BOTTOMRIGHT", -bw, -gap)
    end
    bar:SetHeight(h)

    local e = state.barEdges
    if e then
        e[1]:ClearAllPoints()
        e[1]:SetPoint("BOTTOMLEFT", bar, "TOPLEFT", -bw, 0)
        e[1]:SetPoint("BOTTOMRIGHT", bar, "TOPRIGHT", bw, 0)
        e[1]:SetHeight(bw)
        e[2]:ClearAllPoints()
        e[2]:SetPoint("TOPLEFT", bar, "BOTTOMLEFT", -bw, 0)
        e[2]:SetPoint("TOPRIGHT", bar, "BOTTOMRIGHT", bw, 0)
        e[2]:SetHeight(bw)
        e[3]:ClearAllPoints()
        e[3]:SetPoint("TOPRIGHT", bar, "TOPLEFT", 0, 0)
        e[3]:SetPoint("BOTTOMRIGHT", bar, "BOTTOMLEFT", 0, 0)
        e[3]:SetWidth(bw)
        e[4]:ClearAllPoints()
        e[4]:SetPoint("TOPLEFT", bar, "TOPRIGHT", 0, 0)
        e[4]:SetPoint("BOTTOMLEFT", bar, "BOTTOMRIGHT", 0, 0)
        e[4]:SetWidth(bw)
    end
end

function Bar.SetHost(tip, host)
    local state = Skin.Get(tip)
    if not state then return end
    if state.barHost == nil and host == nil then return end
    state.barHost = host
    if state.bar then
        Bar.ApplySettings(tip)
        Skin.RaiseAccents(tip)
    end
end

function Bar.ApplySettingsAll()
    Skin.Each(function(tip, state)
        if state.bar then Bar.ApplySettings(tip) end
    end)
end

local function ColorBar(bar, unit)
    local sb = ns.settings.statusbar
    local r, g, b
    if sb.color == "custom" then
        local c = sb.customColor or {}
        r, g, b = c.red or c.r, c.green or c.g, c.blue or c.b
    else
        local _, class = S.SafeCall(UnitClass, unit)
        if class then
            local plain = S.SafeValue(class)
            if plain then
                local c = RAID_CLASS_COLORS[plain]
                if c then r, g, b = c.r, c.g, c.b end
            elseif C_ClassColor and C_ClassColor.GetClassColor then
                local ok, c = pcall(C_ClassColor.GetClassColor, class)
                if ok and type(c) == "table" then r, g, b = c.r, c.g, c.b end
            end
        end
        if r == nil then
            r, g, b = Colors.UnitColor(unit)
            if g == 0.6 then g = 0.9 end
            if r == 1 and g == 1 and b == 1 then r, g, b = 0, 0.9, 0.1 end
        end
    end
    if r == nil then r, g, b = 0, 0.9, 0.1 end
    bar:GetStatusBarTexture():SetVertexColor(r, g, b, 1)
end

local function RefreshInner(tip, state)
    local unit = state.barUnit
    if not unit then return end
    if S.IsSecret(unit) then unit = "mouseover" end
    local exists = S.SafeCall(UnitExists, unit)
    if exists ~= nil and not S.IsSecret(exists) and not exists then return end
    local bar, text = state.bar, state.barText
    local sb = ns.settings.statusbar

    if S.SafeBool(UnitIsDeadOrGhost, unit) then
        bar:SetValue(0)
        if sb.textFormat ~= "none" then
            text:SetFormattedText("|cffffcc33<%s>|r", DEAD)
        end
        ColorBar(bar, unit)
        return
    end

    local percent
    if UnitHealthPercent then
        local ok, p = pcall(UnitHealthPercent, unit, true, CurveConstants and CurveConstants.ScaleTo100)
        if ok and p ~= nil then percent = p end
    end
    if percent ~= nil then
        bar:SetValue(percent)
    end

    local fmt = sb.textFormat
    if fmt == "percent" then
        if percent ~= nil then
            text:SetFormattedText("%.0f%%", percent)
        else
            text:SetText("")
        end
    elseif fmt == "healthmax" then
        text:SetFormattedText("%s / %s", Abbrev(UnitHealth(unit) or 0), Abbrev(UnitHealthMax(unit) or 1))
    elseif fmt == "healthmaxpercent" then
        if percent ~= nil then
            text:SetFormattedText("%s / %s (%.0f%%)", Abbrev(UnitHealth(unit) or 0), Abbrev(UnitHealthMax(unit) or 1), percent)
        else
            text:SetFormattedText("%s / %s", Abbrev(UnitHealth(unit) or 0), Abbrev(UnitHealthMax(unit) or 1))
        end
    end
    ColorBar(bar, unit)
end

function Bar.Refresh(tip)
    local state = Skin.Get(tip)
    if not state or not state.bar or not state.barUnit then return end
    if ns.settings.statusbar.hideInCombat and InCombatLockdown() then
        state.bar:Hide()
        return
    end
    if not EngineBarShown(tip) then
        state.bar:Hide()
        return
    end
    if not state.bar:IsShown() then state.bar:Show() end
    local ok, err = pcall(RefreshInner, tip, state)
    if not ok then
        ns.ReportError(err)
        state.barUnit = nil
        state.bar:Hide()
    end
end

function Bar.Activate(tip, unit)
    if not ns.db or not ns.settings.statusbar.enable then return end
    local bar = Ensure(tip)
    if not bar then return end
    Skin.NeutralizeTemplateBar(tip)
    local state = Skin.Get(tip)
    Bar.Layout(state)
    state.barUnit = unit
    Bar.Refresh(tip)
end

function Bar.OnEngineBar(tip)
    local state = Skin.Get(tip)
    if not state or not state.bar or not state.barUnit then return end
    Bar.Refresh(tip)
end

function Bar.Deactivate(tip)
    local state = Skin.Get(tip)
    if not state then return end
    state.barUnit = nil
    if state.bar then state.bar:Hide() end
end

------------------------------------------------------------
-- 輪詢：走 Skin.Poll 的共用 ticker
------------------------------------------------------------
local POLL = 0.15
Skin.Poll("bar", POLL, function()
    Skin.Each(function(tip, state)
        if state.barUnit and state.bar then
            Bar.Refresh(tip)
        end
    end)
end)
