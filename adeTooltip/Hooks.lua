------------------------------------------------------------
-- 所有暴雪接觸點的唯一集中地（主力 = Panel 重繪；舊樣式保留為 panel=false 兜底）
--
-- 逐字對照 MiliUI_Tooltip/Core/Hooks.lua:61-397。ADE 差異：
--   * 初始化走 Core.lua 既有事件幀（PLAYER_LOGIN → ns:InitHooks()），不另建 init 幀。
--   * ns.db（根存档）→ ns.settings（活动配置档）已由各 Panel 文件自行处理。
--   * ns.Log / ns.Describe / ns.Record / ns.Fonts / ns.Model / ns.Item / ns.Spell
--     尚未移植 ⇒ 全部守卫；缺谁就跳过，绝不报 nil。
--   * ShouldClassic()：unit 两个开关都关（或 useNewLayout）⇒ 仍走旧样式 UnitLines。
------------------------------------------------------------
local ns = _G.adeTooltip or {}
_G.adeTooltip = ns

local S = ns.Secret
local Skin = ns.Skin
local Panel = ns.Panel or {}
ns.Panel = Panel
local UnitLines = ns.UnitLines
local Target = ns.Target
local Bar = ns.Bar

-- log/describe 守卫（参考源 Core/Init.lua:38-55 尚未移植）
local function Log(fmt, ...)
    if ns.logEnabled and ns.Log then ns.Log(fmt, ...) end
end

local TRACKED = {
    "GameTooltip", "ShoppingTooltip1", "ShoppingTooltip2", "ItemRefTooltip",
    "ItemRefShoppingTooltip1", "ItemRefShoppingTooltip2", "NamePlateTooltip",
    "FriendsTooltip",
}
local tracked = {}

-- 共同入口闸（对照 MiliUI Core/Hooks.lua:75-81）
local function Gate(tip)
    if not ns.settings then return end
    local state = Skin.Get(tip)
    if not state then return end
    if S.IsForbiddenObject(tip) then return end
    return state
end

------------------------------------------------------------
-- post-call 处理器
------------------------------------------------------------
local function OnUnit(tip, data)
    local state = Gate(tip)
    if not state then return end
    if not tip.GetUnit then return end
    local ok, _, unit = pcall(tip.GetUnit, tip)
    if not ok or not unit then return end

    -- 重繪面板（对照 MiliUI Core/Hooks.lua:98-112）
    if Panel.UnitWanted and Panel.UnitWanted() then
        state.inUnitPostCall = true
        local okTry, shown = xpcall(Panel.TryUnit, ns.ReportError, tip, state, unit, data)
        if not okTry then Panel.Fail(tip, state) end
        state.inUnitPostCall = nil
        if okTry and shown then
            state.unit = unit
            state.unitGuid = S.SafeCall(UnitGUID, unit)
            state.isUnitTip = true
            if ns.Model and ns.Model.OnUnit then xpcall(ns.Model.OnUnit, ns.ReportError, tip, state, unit) end
            if tip == GameTooltip and Bar then Bar.Activate(tip, unit) end
            return
        end
    end

    -- panel 关 / 尝试失败 ⇒ 旧样式兜底（对照 MiliUI Core/Hooks.lua:115-121）
    if not UnitLines then return end
    local applied = xpcall(UnitLines.Apply, ns.ReportError, tip, state, unit, false)
    if not applied then return end
    if Target then xpcall(Target.OnUnit, ns.ReportError, tip, state, unit) end
    if ns.Model and ns.Model.OnUnit then xpcall(ns.Model.OnUnit, ns.ReportError, tip, state, unit) end
    if tip == GameTooltip and Bar then Bar.Activate(tip, unit) end
end

-- 单位面板在 post-call 之外退回（对照 MiliUI Core/Hooks.lua:128-135）
local function UnitFallback(tip, state, key, block)
    if block then
        state.unitBlockKey, state.unitBlockUntil = key, GetTime() + 1
    end
    if S.IsForbiddenObject(tip) then return end
    Log("單位面板退回 ⇒ 舊樣式重跑 key=%s", tostring(key))
    tip:Show()
end

local T_ITEM = Enum and Enum.TooltipDataType and Enum.TooltipDataType.Item
local T_SPELL = Enum and Enum.TooltipDataType and Enum.TooltipDataType.Spell

local function AfterApply(tip, state, kind, dataType, data)
    if ns.Record and ns.Record.OnPostCall then
        xpcall(ns.Record.OnPostCall, ns.ReportError, tip, kind, data)
    end
    if not xpcall(Panel.Try, ns.ReportError, tip, state, dataType, data) then
        Panel.Fail(tip, state)
    end
end

local function OnItem(tip, data)
    local state = Gate(tip)
    if not state then return end
    if Bar then Bar.Deactivate(tip) end
    local link
    if tip.GetItem then
        local ok, _, l = pcall(tip.GetItem, tip)
        if ok then link = l end
    end
    if ns.Item and ns.Item.Apply then xpcall(ns.Item.Apply, ns.ReportError, tip, state, link) end
    AfterApply(tip, state, "item", T_ITEM, data)
end

local function OnSpell(tip, data)
    local state = Gate(tip)
    if not state then return end
    if Bar then Bar.Deactivate(tip) end
    local spellId = data and S.PlainNumber(data.id)
    if ns.Spell and ns.Spell.Apply then xpcall(ns.Spell.Apply, ns.ReportError, tip, state, spellId) end
    AfterApply(tip, state, "spell", T_SPELL, data)
end

local function OnUnitAura(tip, data)
    local state = Gate(tip)
    if not state then return end
    if Bar then Bar.Deactivate(tip) end
    if ns.Spell and ns.Spell.ApplyAura then xpcall(ns.Spell.ApplyAura, ns.ReportError, tip, state, data) end
end

------------------------------------------------------------
-- 巨集 / 動作條（對照 MiliUI Core/Hooks.lua:196-263）
------------------------------------------------------------
local function ResolveSpellIdFromToken(token)
    if type(token) == "number" then return token end
    if type(token) == "string" and token ~= "" and C_Spell and C_Spell.GetSpellInfo then
        local ok, info = pcall(C_Spell.GetSpellInfo, token)
        if ok and type(info) == "table" and type(info.spellID) == "number" then
            return info.spellID
        end
    end
end

local function ResolveMacroPayload(tip, macroId)
    if tip and tip.GetPrimaryTooltipData then
        local ok, data = pcall(tip.GetPrimaryTooltipData, tip)
        if ok and type(data) == "table" and type(data.lines) == "table"
            and type(data.lines[1]) == "table" and type(data.lines[1].tooltipID) == "number" then
            return data.lines[1].tooltipID
        end
    end
    if type(macroId) == "number" and type(GetMacroSpell) == "function" then
        local ok, a, b, c = pcall(GetMacroSpell, macroId)
        if ok then
            local spellId = ResolveSpellIdFromToken(a) or ResolveSpellIdFromToken(b) or ResolveSpellIdFromToken(c)
            if spellId then return spellId end
        end
    end
    if type(macroId) == "number" and type(GetMacroItem) == "function" then
        local ok, macroItem = pcall(GetMacroItem, macroId)
        if ok and macroItem then
            local okInfo, _, itemLink = pcall(C_Item.GetItemInfo, macroItem)
            if okInfo and type(itemLink) == "string" and itemLink ~= "" then
                return nil, itemLink
            end
        end
    end
end

local function MacroView(data, dataType, id, link)
    return { type = dataType, id = id, hyperlink = link, lines = type(data) == "table" and data.lines or nil }
end

local function RouteMacroPayload(tip, state, data, spellId, itemLink)
    if itemLink then
        if ns.Item and ns.Item.Apply then xpcall(ns.Item.Apply, ns.ReportError, tip, state, itemLink) end
        local itemId = tonumber(itemLink:match("item:(%d+)"))
        AfterApply(tip, state, "item", T_ITEM, MacroView(data, T_ITEM, itemId, itemLink))
    elseif spellId then
        if ns.Spell and ns.Spell.Apply then xpcall(ns.Spell.Apply, ns.ReportError, tip, state, spellId) end
        AfterApply(tip, state, "spell", T_SPELL, MacroView(data, T_SPELL, spellId, nil))
    else
        Panel.Restore(tip, state)
    end
end

local function OnMacro(tip, data)
    local state = Gate(tip)
    if not state then return end
    local macroId = data and S.PlainNumber(data.id)
    local spellId, itemLink = ResolveMacroPayload(tip, macroId)
    RouteMacroPayload(tip, state, data, spellId, itemLink)
end

------------------------------------------------------------
-- 非同步（觀察 / 成就）資料到貨後的刷新（對照 MiliUI Modules/UnitLines.lua:413-431）
------------------------------------------------------------
function ns.RefreshUnitTip(guid)
    local tip = _G.GameTooltip
    if not tip then return end
    local state = Skin.Get(tip)
    if not state or not state.unit then return end
    local ok, shown = pcall(tip.IsShown, tip)
    if not ok or S.IsSecret(shown) or not shown then return end
    if state.native and state.panelKind == "unit" then
        local same = ns.UnitInfo and ns.UnitInfo.GuidEquals and ns.UnitInfo.GuidEquals(state.panelGuid, guid)
        if same then Panel.Poke(tip, state) end
        return
    end
    local mouseoverGuid = S.SafeCall(UnitGUID, "mouseover")
    if mouseoverGuid ~= nil and ns.UnitInfo and ns.UnitInfo.GuidEquals
        and ns.UnitInfo.GuidEquals(mouseoverGuid, guid) then
        if UnitLines then UnitLines.Apply(tip, state, "mouseover", true) end
        if Target then Target.Update(tip, state) end
    end
end

------------------------------------------------------------
-- 設定套用總入口（設定面板 / 載入時）：對照 MiliUI Core/Hooks.lua:273-281
-- ADE 的 Core.lua 已有 ADT:ApplyAll()，這裡只在它之上補 Panel 的重置。
------------------------------------------------------------
ns:RegisterApply(function()
    Panel.settingsVersion = (Panel.settingsVersion or 0) + 1
    if Panel.RestoreAll then Panel.RestoreAll() end
    if Skin.ApplyBaseAll then Skin.ApplyBaseAll() end
    if Bar and Bar.ApplySettingsAll then Bar.ApplySettingsAll() end
    ns.Fire("SettingsApplied")
end)

------------------------------------------------------------
-- 滑開淡出（接觸面 #15；對照 MiliUI Core/Hooks.lua:286-299）
------------------------------------------------------------
local function OnFadeOut(tip)
    local state = Gate(tip)
    if not state then return end
    local panel = state.panel
    local instant = ns.settings and ns.settings.general and ns.settings.general.instantHide
    if instant then
        local ok, shown = pcall(tip.IsShown, tip)
        if not ok or S.IsSecret(shown) or not shown then return end
        if panel and panel:IsShown() and Panel.FadeOut then Panel.FadeOut(panel, true) end
        tip:Hide()
    elseif state.native and panel and panel:IsShown() and Panel.FadeOut then
        Panel.FadeOut(panel)
    end
end

------------------------------------------------------------
-- 初始化（對照 MiliUI Core/Hooks.lua:306-372 的 TrackTip / Install）
------------------------------------------------------------
local function TrackTip(tip, isPreview, opts)
    if not tip or tracked[tip] or S.IsForbiddenObject(tip) then return end
    local state = Skin.Attach(tip, opts)
    if not state then return end
    tracked[tip] = true
    if isPreview then state.isPreview = true end
    if tip.HasScript and tip:HasScript("OnTooltipCleared") then
        tip:HookScript("OnTooltipCleared", function(self)
            if S.IsForbiddenObject(self) then return end
            Skin.ClearTransient(self)
            Panel.Release(self, Skin.Get(self))
        end)
    end
    if tip.FadeOut and not isPreview then hooksecurefunc(tip, "FadeOut", OnFadeOut) end
end
ns.TrackTip = TrackTip

local function Install()
    Panel.UnitFallback = UnitFallback

    for _, name in ipairs(TRACKED) do TrackTip(_G[name]) end

    if TooltipDataProcessor and TooltipDataProcessor.AddTooltipPostCall and Enum and Enum.TooltipDataType then
        local T = Enum.TooltipDataType
        if T.Unit then TooltipDataProcessor.AddTooltipPostCall(T.Unit, OnUnit) end
        if T.Item then TooltipDataProcessor.AddTooltipPostCall(T.Item, OnItem) end
        if T.Spell then TooltipDataProcessor.AddTooltipPostCall(T.Spell, OnSpell) end
        if T.UnitAura then TooltipDataProcessor.AddTooltipPostCall(T.UnitAura, OnUnitAura) end
        if T.Macro then TooltipDataProcessor.AddTooltipPostCall(T.Macro, OnMacro) end
    end

    -- 右鍵提示移除（接觸面 #2）
    if GameTooltip_AddInstructionLine then
        hooksecurefunc("GameTooltip_AddInstructionLine", function(tt)
            if tt ~= GameTooltip then return end
            local state = Gate(tt)
            if not state or not state.isUnitTip then return end
            if UnitLines and UnitLines.RemoveRightClickHint then UnitLines.RemoveRightClickHint(tt) end
        end)
    end

    -- 一次性視覺中和：血條自己畫，暴雪那條藏掉（接觸面 #6）
    if GameTooltipStatusBar and GameTooltipStatusBar.SetAlpha then
        pcall(GameTooltipStatusBar.SetAlpha, GameTooltipStatusBar, 0)
    end
    local engineBar = GameTooltip and (GameTooltip.StatusBar or GameTooltipStatusBar)
    if engineBar and engineBar.HookScript and Bar and Bar.OnEngineBar then
        engineBar:HookScript("OnShow", function() Bar.OnEngineBar(GameTooltip) end)
        engineBar:HookScript("OnHide", function() Bar.OnEngineBar(GameTooltip) end)
    end
    if ItemRefCloseButton then
        ItemRefCloseButton:SetSize(14, 14)
        ItemRefCloseButton:SetPoint("TOPRIGHT", -4, -4)
        ItemRefCloseButton:SetNormalTexture("Interface\\Buttons\\UI-StopButton")
        ItemRefCloseButton:SetPushedTexture("Interface\\Buttons\\UI-StopButton")
        local tex = ItemRefCloseButton:GetNormalTexture()
        if tex then tex:SetVertexColor(0.9, 0.6, 0) end
    end
end

-- Core.lua 在 PLAYER_LOGIN 呼叫 ns:InitHooks()（取代参考源自建的 init 幀）
function ns:InitHooks()
    Install()
    -- 較晚才存在的 tooltip（NamePlateTooltip 類）補接管一次
    for _, name in ipairs(TRACKED) do TrackTip(_G[name]) end
    -- sidecar 接管（別家外觀預覽框貼面板）延到 Panel 完成移植後再接
    if Panel.AdoptKnownSidecars then Panel.AdoptKnownSidecars() end
end
