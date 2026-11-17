------------------------------------------------------------
-- 原生 tooltip 在 panel 底下當替身：alpha 0、padding 撐到跟 panel 一樣大
--
-- 為什麼不直接 Hide：暴雪的比價框定位、螢幕邊夾邊、跟隨游標全部照**原生框**的尺寸算。
-- 原生框保持顯示、只是看不見，而且撐得跟 panel 一樣大 ⇒ 那些系統把兩者當成一個框，
-- 我們什麼定位都不用重寫。
--
-- 接觸面 #10（Core/Hooks.lua 檔頭）：SetAlpha 與 SetPadding 兩支 C 端定位 setter；
-- 只在 panel 成功顯示時寫，Restore 寫回原值。
-- 接觸面 #12：hooksecurefunc(tip, "Show"／"SetShown") 後掛勾，見下面 HookShow。
--
-- 暴雪自己也會動 padding：GameTooltip 的 OnShow／OnHide 會 ClearPadding（GameTooltip_CalculatePadding），
-- 所以第一次顯示時我們設的 padding 會被清掉一次 ⇒ Fit 不假設 padding 還是自己設的那個，
-- 每次都用 GetPadding 反推自然尺寸。
------------------------------------------------------------
local ns = _G.adeTooltip or {}
_G.adeTooltip = ns

local S = ns.Secret
local Panel = ns.Panel or {}
ns.Panel = Panel

Panel.Native = {}
local Native = Panel.Native

local function Plain(...)
    for i = 1, select("#", ...) do
        local v = select(i, ...)
        if type(v) ~= "number" or S.IsSecret(v) then return false end
    end
    return true
end

local function Log(fmt, ...)
    if ns.logEnabled and ns.Log then ns.Log(fmt, ...) end
end
local function Geo(tip)
    local okT, t = pcall(tip.GetTop, tip)
    local okB, b = pcall(tip.GetBottom, tip)
    local okH, h = pcall(tip.GetHeight, tip)
    return ("top=%s bottom=%s h=%s"):format(okT and ns.Describe and ns.Describe(t) or "?", okB and ns.Describe and ns.Describe(b) or "?", okH and ns.Describe and ns.Describe(h) or "?")
end

local function ReadPadding(tip)
    if not tip.GetPadding then return 0, 0, 0, 0 end
    local ok, r, b, l, t = pcall(tip.GetPadding, tip)
    if not ok then return end
    r, b, l, t = r or 0, b or 0, l or 0, t or 0
    if not Plain(r, b, l, t) then return end
    return r, b, l, t
end

local function Near(a, b) return math.abs(a - b) < 0.01 end

local NATIVE_TEXT_INSET = 20
function Native.ContentWidth(tip, state)
    local okW, w = pcall(tip.GetWidth, tip)
    if not okW or not Plain(w) then return nil end
    local pr = ReadPadding(tip)
    if not pr then return nil end
    local saved, set = state and state.native, state and state.paddingSet
    if saved and set and Near(pr, saved.right) and not Near(set[1], saved.right) then return nil end
    local natural = w - (saved and (pr - saved.right) or 0)
    return math.max(0, natural - NATIVE_TEXT_INSET)
end

local hooked = {}
local RestoreClearedPadding

local function HookShow(tip, state)
    if hooked[tip] then return end
    hooked[tip] = true
    local function repress(self)
        if state.native then
            Native.Repress(self, state)
            RestoreClearedPadding(self, state)
            if state.panel then Panel.Unfade(state.panel) end
        end
    end
    if tip.Show then hooksecurefunc(tip, "Show", repress) end
    if tip.SetShown then
        hooksecurefunc(tip, "SetShown", function(self, shown)
            if S.IsSecret(shown) or shown then repress(self) end
        end)
    end
end

function Native.Hide(tip, state)
    local saved = state.native
    if not saved then
        local okA, alpha = pcall(tip.GetAlpha, tip)
        alpha = okA and S.PlainNumber(alpha)
        if not alpha then return false end
        if alpha < 1 then alpha = 1 end
        local r, b, l, t = ReadPadding(tip)
        if not r then return false end
        saved = { alpha = alpha, right = r, bottom = b, left = l, top = t }
        if tip.GetClampRectInsets then
            local okI, il, ir, it, ib = pcall(tip.GetClampRectInsets, tip)
            if okI and Plain(il, ir, it, ib) then saved.insets = { il, ir, it, ib } end
        end
        state.native = saved
    end
    HookShow(tip, state)
    tip:SetAlpha(0)
    return true
end

function RestoreClearedPadding(tip, state)
    local saved, set = state.native, state.paddingSet
    if not saved or not set then return false end
    if Near(set[1], saved.right) and Near(set[2], saved.bottom) then return false end
    local pr, pb = ReadPadding(tip)
    if not pr then return false end
    if Near(pr, saved.right) and Near(pb, saved.bottom) then
        tip:SetPadding(set[1], set[2], saved.left, saved.top)
        if ns.logEnabled then Log("原生 padding 被清掉 ⇒ 補回 %.1f,%.1f  %s", set[1], set[2], Geo(tip)) end
        return true
    end
    return false
end
Native.RestoreClearedPadding = RestoreClearedPadding

function Native.Fit(tip, state, partial)
    local saved, panel = state.native, state.panel
    if not saved or not panel or not panel.width or not panel.height then return end
    if RestoreClearedPadding(tip, state) then
        if not Panel.Align(panel, tip) then return false end
        return true
    end
    local okS, shown = pcall(tip.IsShown, tip)
    if not okS or S.IsSecret(shown) or not shown then return end

    local okW, w = pcall(tip.GetWidth, tip)
    local okH, h = pcall(tip.GetHeight, tip)
    local pr, pb
    if okW and okH and Plain(w, h) then pr, pb = ReadPadding(tip) end
    if not pr then
        if panel.besideHost then return Panel.Align(panel, tip) end
        return false
    end

    local tipScale, panelScale = Panel.EffectiveScale(tip), Panel.EffectiveScale(panel)
    if not (tipScale and panelScale) then return false end
    local ratio = panelScale / tipScale
    local groupH = math.max(panel.totalHeight or panel.height, state.panelMaxTotalHeight or 0)
    local pw, ph = panel.width * ratio, groupH * ratio

    local naturalW = w - (pr - saved.right)
    local naturalH = h - (pb - saved.bottom)
    if partial then
        naturalW = math.max(naturalW, state.nativeSettledW or 0)
        naturalH = math.max(naturalH, state.nativeSettledH or 0)
    else
        state.nativeSettledW, state.nativeSettledH = naturalW, naturalH
    end
    state.nativeMaxW = math.max(state.nativeMaxW or 0, naturalW)
    state.nativeMaxH = math.max(state.nativeMaxH or 0, naturalH)
    pw, ph = math.max(pw, state.nativeMaxW), math.max(ph, state.nativeMaxH)
    local right = saved.right + math.max(0, pw - naturalW)
    local bottom = saved.bottom + math.max(0, ph - naturalH)
    if math.abs(right - pr) > 0.01 or math.abs(bottom - pb) > 0.01 then
        tip:SetPadding(right, bottom, saved.left, saved.top)
        state.paddingSet = state.paddingSet or {}
        state.paddingSet[1], state.paddingSet[2] = right, bottom
        if ns.logEnabled then Log("原生 SetPadding %.1f,%.1f（之前 %.1f,%.1f；自然 %.1fx%.1f 撐到 %.1fx%.1f）  %s",
            right, bottom, pr, pb, naturalW, naturalH, pw, ph, Geo(tip)) end
    end
    Native.UpdateClamp(tip, state, ratio)
    if not Panel.Align(panel, tip) then return false end
    return true
end

function Native.UpdateClamp(tip, state, ratio)
    local saved, panel = state.native, state.panel
    if not saved or not saved.insets or not panel or not tip.SetClampRectInsets then return end
    local top, margin = Panel.ClampReserve(panel)
    if not top then return end
    ratio = ratio or 1
    top, margin = top * ratio, margin * ratio
    local sig = ("%.3f|%.3f"):format(top, margin)
    if state.clampSig == sig then return end
    state.clampSig = sig
    tip:SetClampRectInsets(-margin, margin, top + margin, -margin)
    if ns.logEnabled then Log("原生 夾邊範圍 %.1f,%.1f,%.1f,%.1f  %s", -margin, margin, top + margin, -margin, Geo(tip)) end
end

function Native.Restore(tip, state)
    local saved = state.native
    state.native = nil
    local set = state.paddingSet
    state.paddingSet = nil
    if state.panel then
        state.panel:Hide()
        Panel.Detach(state.panel)
    end
    Panel.ResetNativeClose(tip)
    state.clampSig = nil
    if not saved then return end
    if S.IsForbiddenObject(tip) then return end
    if saved.insets and tip.SetClampRectInsets then
        tip:SetClampRectInsets(saved.insets[1], saved.insets[2], saved.insets[3], saved.insets[4])
    end
    local okS, shown = pcall(tip.IsShown, tip)
    if okS and not S.IsSecret(shown) and shown and set then
        local pr, pb = ReadPadding(tip)
        if pr and math.abs(pr - set[1]) < 0.01 and math.abs(pb - set[2]) < 0.01 then
            tip:SetPadding(saved.right, saved.bottom, saved.left, saved.top)
        end
    end
    local okA, alpha = pcall(tip.GetAlpha, tip)
    alpha = okA and S.PlainNumber(alpha)
    if alpha == nil or alpha == 0 then
        tip:SetAlpha(saved.alpha)
    end
end

function Native.Repress(tip, state)
    if not state.native then return end
    local ok, alpha = pcall(tip.GetAlpha, tip)
    alpha = ok and S.PlainNumber(alpha)
    if alpha and alpha ~= 0 then
        tip:SetAlpha(0)
        if ns.logEnabled then Log("原生 alpha 被改回 %.2f ⇒ 壓回 0", alpha) end
    end
end
