------------------------------------------------------------
-- 重繪面板的流程：Try（post-call 進來）／Reconcile（下一幀對帳）／Release（內容被清掉）／Restore（退回原生）
--
--   1. 該型別的開關關 → Restore 後 return
--   1b. 戰鬥中隱藏 → 同上。
--   2. 同一件的重建（state.panelKey 相同、panel 顯示中）→ 當幀不解析、不重畫，只重壓 alpha、Fit，排一次 Reconcile
--   3. 新物件（key 不同、panel 沒顯示）→ 立刻畫，再排一次 Reconcile 補齊同一幀後加的行
--   4. Reconcile（C_Timer.After(0)，每個 state 同時只排一個）：CollectLines 重讀、比指紋
--   4b. 幾何只長不縮（同一件）
--   5. 輪詢（0.1 秒，只在有 tooltip 顯示時存在）
--   6. OnTooltipCleared → Release：先不拆，等下一幀；同一幀裡新的 post-call 會把它認領回去。
--
-- 單位（kind = "unit"）走同一條：開關、單位 token 的解析在 Panel/ReadUnit.lua 的 Panel.TryUnit，
-- 這裡多三件事——動態簽章、血條／3D 模型改貼面板、身分受限單位的收法。
------------------------------------------------------------
local ns = _G.adeTooltip or {}
_G.adeTooltip = ns

local S = ns.Secret
local Skin = ns.Skin
local Panel = ns.Panel or {}
ns.Panel = Panel
local Native = Panel.Native

local T = Enum and Enum.TooltipDataType or {}
local KIND = {}
if T.Item then KIND[T.Item] = "item" end
if T.Spell then KIND[T.Spell] = "spell" end
if T.Unit then KIND[T.Unit] = "unit" end
Panel.KIND = KIND

Panel.readers = Panel.readers or {}
Panel.views = Panel.views or {}

local POLL_INTERVAL = 0.1
local SETTLE = 0.3
Panel.SETTLE = SETTLE

Panel.settingsVersion = 0

local function Enabled(kind, state)
    if kind == "unit" then return state.panelUnit ~= nil end
    local db = ns.settings
    return db and db[kind] and db[kind].panel == true
end

local BLIZZ_PADDING_USERS = { "ItemTooltip", "BottomFontString" }
local function ShownRegion(region)
    if type(region) ~= "table" or not region.IsShown then return false end
    local ok, shown = pcall(region.IsShown, region)
    return not ok or S.IsSecret(shown) or shown and true or false
end
local function Eligible(tip)
    for _, key in ipairs(BLIZZ_PADDING_USERS) do
        if ShownRegion(tip[key]) then return false end
    end
    local okF, frames = pcall(function() return tip.insertedFrames end)
    if okF and type(frames) == "table" and not S.IsSecret(frames) then
        for i = 1, #frames do
            if ShownRegion(frames[i]) then return false end
        end
    end
    return true
end
Panel.Eligible = Eligible

local function ColorKey(c)
    if not c then return "-" end
    return ("%.3f,%.3f,%.3f"):format(c[1], c[2], c[3])
end

local function Dynamic(kind, state)
    if kind ~= "unit" or not Panel.UnitDynamic then return "" end
    return Panel.UnitDynamic(state) or ""
end

function Panel.Fingerprint(model, extra)
    local parts = { tostring(Panel.settingsVersion), tostring(model.numLines or 0), extra or "" }
    for _, row in ipairs(model.rows or {}) do
        parts[#parts + 1] = row.left or ""
        parts[#parts + 1] = row.right or ""
        parts[#parts + 1] = ColorKey(row.color)
        parts[#parts + 1] = ColorKey(row.rightColor)
        parts[#parts + 1] = row.price and tostring(row.price) or ""
    end
    return table.concat(parts, "\031")
end

function Panel.Key(kind, data)
    if type(data) ~= "table" then return nil end
    if kind == "unit" then
        local guid = S.PlainText(data.guid)
        return guid and ("unit:" .. guid) or nil
    end
    local id = S.PlainNumber(data.id)
    if id then return kind .. ":" .. id end
    local link = S.PlainText(data.hyperlink)
    if link and link ~= "" then return kind .. ":" .. link end
    return nil
end

local function Fingerprints(tip, state, kind, rows, n)
    local lineFP = Panel.Fingerprint({ rows = rows, numLines = n }, kind .. "|" .. (Panel.CompareHeaderText(tip) or ""))
    local dyn = Dynamic(kind, state)
    return lineFP .. "\030" .. dyn, lineFP, dyn
end

local function Shown(tip)
    local ok, shown = pcall(tip.IsShown, tip)
    return ok and not S.IsSecret(shown) and shown and true or false
end

local function Collect(tip, state, kind, data)
    if kind == "unit" and state.panelRestricted and Panel.CollectRestrictedLines then
        return Panel.CollectRestrictedLines(tip, data)
    end
    return Panel.CollectLines(tip, data)
end

Panel.UNIT_BLOCK_RESTRICTED = "unit:restricted"

local function NewSecretWidth(tip, state)
    if not state.panelRestricted then return nil, false end
    local cw = Native.ContentWidth(tip, state)
    if not cw then return nil, false end
    local old = state.secretContentW
    if old and (math.abs(cw - old) <= 0.5 or (state.secretWidthSettled and cw < old)) then return nil, true end
    return cw, true
end

local function Now() return GetTime and GetTime() or 0 end

local restoringAll = false

function Panel.Restore(tip, state)
    if not state then return end
    local wasUnit = state.panelKind == "unit" and (state.native or (state.panel and state.panel:IsShown()))
    local unitKey = wasUnit and (state.panelKey or (state.panelRestricted and Panel.UNIT_BLOCK_RESTRICTED))
    state.releasePending = nil
    state.hidePending = nil
    state.reconcileToken = (state.reconcileToken or 0) + 1
    state.reconcilePending = nil
    state.panelFingerprint, state.panelKey, state.panelFullLines, state.partialSince = nil, nil, nil, nil
    state.pendingFingerprint, state.pendingSince = nil, nil
    state.panelMaxWidth, state.panelMaxTotalHeight = nil, nil
    state.nativeMaxW, state.nativeMaxH = nil, nil
    state.nativeSettledW, state.nativeSettledH = nil, nil
    state.panelData, state.panelKind, state.panelLines = nil, nil, nil
    state.panelLineFingerprint, state.panelDyn, state.panelUnit, state.panelGuid = nil, nil, nil, nil
    state.panelRestricted = nil
    state.secretContentW, state.secretWidthSettled = nil, nil
    state.panelBorder, state.panelTargetFS = nil, nil
    if state.panelPolling then
        state.panelPolling = nil
        Skin.Unpoll(state)
    end
    if state.native or (state.panel and state.panel:IsShown()) then
        local gone = state.panel
        if gone then Panel.ReturnFollowers(gone) end
        Native.Restore(tip, state)
        if gone then
            Skin.Each(function(t2, s2)
                local p2 = s2.panel
                if p2 and s2.native and p2:IsShown() and Panel.AnchoredOn(p2, gone) then
                    if not Panel.Align(p2, t2) then Panel.Restore(t2, s2) end
                end
            end)
        end
    end
    if wasUnit then
        Panel.HostAccents(tip, state, nil)
        if not state.inUnitPostCall and state.isUnitTip and Shown(tip) and Panel.UnitFallback then
            Panel.UnitFallback(tip, state, unitKey, not restoringAll)
        end
    end
end

function Panel.HostAccents(tip, state, host)
    if ns.Bar and ns.Bar.SetHost then ns.Bar.SetHost(tip, host) end
    if ns.Model and ns.Model.SetHost then ns.Model.SetHost(tip, host) end
end

function Panel.Release(tip, state)
    if not state or not (state.native or (state.panel and state.panel:IsShown())) then return end
    state.releaseToken = (state.releaseToken or 0) + 1
    state.releasePending = true
    local token = state.releaseToken
    C_Timer.After(0, function()
        if state.releasePending and state.releaseToken == token then Panel.Restore(tip, state) end
    end)
end

function Panel.OnSkinHide(tip, state)
    if not state or not (state.native or (state.panel and state.panel:IsShown())) then return end
    state.hideToken = (state.hideToken or 0) + 1
    state.hidePending = true
    local token = state.hideToken
    C_Timer.After(0, function()
        if state.hidePending and state.hideToken == token then Panel.Restore(tip, state) end
    end)
end

function Panel.RestoreAll()
    restoringAll = true
    Skin.Each(function(tip, state) pcall(Panel.Restore, tip, state) end)
    restoringAll = false
end

function Panel.OnSkinShow(tip, state)
    if state and state.native then Native.Repress(tip, state) end
end

local function Render(tip, state, kind, data, rows, n, fingerprint, lineFP, dyn)
    local reader = Panel.readers[kind] or Panel.ReadFallback
    local model = reader(tip, data, kind, rows, n, state)
    if not model then return false end
    local panel = Panel.Get(tip, state)
    local view = (Panel.views[kind] or Panel.ViewFallback)(model, state)
    if not view or not Panel.RenderView(panel, tip, view, state) then return false end
    state.panelMaxWidth = math.max(state.panelMaxWidth or 0, panel.width or 0)
    state.panelMaxTotalHeight = math.max(state.panelMaxTotalHeight or 0, panel.totalHeight or panel.height or 0)
    if not Panel.Align(panel, tip) or not Native.Hide(tip, state) then return false end
    if Native.Fit(tip, state) == false then return false end
    Panel.Unfade(panel)
    panel:Show()
    Panel.HostAccents(tip, state, kind == "unit" and panel or nil)
    state.panelFingerprint = fingerprint
    state.panelLineFingerprint, state.panelDyn = lineFP, dyn
    state.panelSettings = Panel.settingsVersion
    state.panelLines = n
    return true
end

local Reconcile

local function ScheduleReconcile(tip, state)
    if state.reconcilePending then return end
    state.reconcilePending = true
    state.reconcileToken = state.reconcileToken or 0
    local token = state.reconcileToken
    C_Timer.After(0, function()
        if state.reconcileToken ~= token then return end
        state.reconcilePending = nil
        Reconcile(tip, state)
    end)
end

function Reconcile(tip, state)
    if not state.native or not state.panelData then return end
    if S.IsForbiddenObject(tip) or not Shown(tip) then Panel.Restore(tip, state); return end
    if not Eligible(tip) then Panel.Restore(tip, state); return end
    Native.Repress(tip, state)
    if state.panel then Panel.SyncLevel(state.panel, tip) end
    if state.panelKind == "unit" and Panel.UnitGone and Panel.UnitGone(state) then return end

    local rows, n = Collect(tip, state, state.panelKind, state.panelData)
    if not rows then Panel.Restore(tip, state); return end
    local secretW, measured = NewSecretWidth(tip, state)
    if measured then state.secretWidthSettled = true end
    local function wait()
        if Native.Fit(tip, state) == false then Panel.Restore(tip, state) return end
        ScheduleReconcile(tip, state)
    end
    local fingerprint, lineFP, dyn = Fingerprints(tip, state, state.panelKind, rows, n)
    local full = state.panelFullLines or 0

    if fingerprint == state.panelFingerprint and not secretW then
        state.partialSince, state.pendingFingerprint, state.pendingSince = nil, nil, nil
        state.panelFullLines, state.panelLines = math.max(full, n), n
        if Native.Fit(tip, state) == false then Panel.Restore(tip, state) end
        return
    end

    if state.panelSettings ~= Panel.settingsVersion then
    elseif secretW then
    elseif lineFP == state.panelLineFingerprint then
    elseif n < full then
        state.partialSince = state.partialSince or Now()
        state.pendingFingerprint, state.pendingSince = nil, nil
        if Now() - state.partialSince < SETTLE then return wait() end
    elseif n == full then
        state.partialSince = nil
        if state.pendingFingerprint ~= fingerprint then
            state.pendingFingerprint, state.pendingSince = fingerprint, Now()
            return wait()
        end
        if Now() - (state.pendingSince or Now()) < SETTLE then return wait() end
    end
    state.partialSince, state.pendingFingerprint, state.pendingSince = nil, nil, nil
    state.panelFullLines = n
    if secretW then
        state.secretContentW, state.panelMaxWidth = secretW, nil
    end
    if not Render(tip, state, state.panelKind, state.panelData, rows, n, fingerprint, lineFP, dyn) then
        Panel.Restore(tip, state)
    end
end
Panel.Reconcile = Reconcile

function Panel.Poke(tip, state)
    if not state or not state.native or not state.panelData then return end
    state.panelFingerprint = nil
    ScheduleReconcile(tip, state)
end

local function Tick(tip, state)
    if not state.native then
        state.panelPolling = nil
        Skin.Unpoll(state)
        return
    end
    if S.IsForbiddenObject(tip) or not Shown(tip) then Panel.Restore(tip, state); return end
    Native.Repress(tip, state)
    if state.panel then Panel.SyncLevel(state.panel, tip) end
    local okN, n = pcall(tip.NumLines, tip)
    n = okN and S.PlainNumber(n)
    if n and n ~= state.panelLines and state.panelData then
        ScheduleReconcile(tip, state)
    elseif state.panelKind == "unit" and state.panelData then
        local dyn = Panel.UnitDynamic and Panel.UnitDynamic(state)
        if dyn and dyn ~= state.panelDyn then ScheduleReconcile(tip, state) end
        if NewSecretWidth(tip, state) then ScheduleReconcile(tip, state) end
        if Panel.UnitTick then Panel.UnitTick(state) end
    end
    if Native.Fit(tip, state) == false then Panel.Restore(tip, state) end
end

local function StartPoll(tip, state)
    if state.panelPolling then return end
    state.panelPolling = true
    Skin.Poll(state, POLL_INTERVAL, function() Tick(tip, state) end)
end

function Panel.Try(tip, state, dataType, data)
    if not state or not ns.settings then return false end
    local kind = KIND[dataType] or dataType
    if (kind ~= "item" and kind ~= "spell" and kind ~= "unit") or not Enabled(kind, state) then
        Panel.Restore(tip, state)
        return false
    end
    if S.IsForbiddenObject(tip) or not Eligible(tip) then
        Panel.Restore(tip, state)
        return false
    end
    if ns.Anchor and ns.Anchor.ShouldHideNow and ns.Anchor.ShouldHideNow(tip) then
        Panel.Restore(tip, state)
        return false
    end

    local key = Panel.Key(kind, data)
    local panel = state.panel

    if key and key == state.panelKey and panel and panel:IsShown() and state.native then
        state.releasePending = nil
        state.hidePending = nil
        state.panelData, state.panelKind = data, kind
        local bc = kind == "unit" and state.panelBorder
        if bc and Skin.SetBorderColor then Skin.SetBorderColor(tip, bc[1], bc[2], bc[3], bc[4]) end
        Panel.PaintEdges(panel, state)
        Panel.Unfade(panel)
        if not Native.Hide(tip, state) or Native.Fit(tip, state, true) == false then
            Panel.Restore(tip, state)
            return false
        end
        ScheduleReconcile(tip, state)
        return true
    end

    local rows, n = Collect(tip, state, kind, data)
    if not rows then
        Panel.Restore(tip, state)
        return false
    end
    state.releasePending = nil
    state.hidePending = nil
    state.panelData, state.panelKind = data, kind
    state.panelMaxWidth, state.panelMaxTotalHeight = nil, nil
    state.nativeMaxW, state.nativeMaxH = nil, nil
    state.nativeSettledW, state.nativeSettledH = nil, nil
    state.pendingFingerprint, state.pendingSince, state.partialSince = nil, nil, nil
    state.secretWidthSettled = nil
    local fingerprint, lineFP, dyn = Fingerprints(tip, state, kind, rows, n)
    if not Render(tip, state, kind, data, rows, n, fingerprint, lineFP, dyn) then
        Panel.Restore(tip, state)
        return false
    end
    state.panelKey = key
    state.panelFullLines = n
    state.partialSince = nil
    ScheduleReconcile(tip, state)
    StartPoll(tip, state)
    return true
end

function Panel.ShowModel(tip, state, kind, model)
    if not state or S.IsForbiddenObject(tip) or not Eligible(tip) then return false end
    local panel = Panel.Get(tip, state)
    state.releasePending, state.hidePending = nil, nil
    state.panelMaxWidth, state.panelMaxTotalHeight = nil, nil
    state.nativeMaxW, state.nativeMaxH, state.nativeSettledW, state.nativeSettledH = nil, nil, nil, nil
    local view = (Panel.views[kind] or Panel.ViewFallback)(model, state)
    if not view or not Panel.RenderView(panel, tip, view, state)
        or not Panel.Align(panel, tip) or not Native.Hide(tip, state) or Native.Fit(tip, state) == false then
        Panel.Restore(tip, state)
        return false
    end
    state.panelMaxWidth = panel.width
    state.panelMaxTotalHeight = panel.totalHeight or panel.height
    Panel.Unfade(panel)
    panel:Show()
    Panel.HostAccents(tip, state, kind == "unit" and panel or nil)
    state.panelKey, state.panelKind, state.panelData = "static:" .. kind, kind, nil
    state.panelFingerprint, state.panelLineFingerprint, state.panelDyn = nil, nil, nil
    StartPoll(tip, state)
    return true
end

function Panel.Fail(tip, state)
    pcall(Panel.Restore, tip, state)
end
