--[==[ 角色面板内嵌（F13 / D49 / D59 / D65 / D66）
    位置：
      · 进度条 = 加在**原生对应属性行的下面**（StatMarks/Bars.lua:1819-1960
        的 AttachBar 实证：visual:SetParent(row) + BOTTOMLEFT/BOTTOMRIGHT 锚到 row，
        并增高原生行为条腾出空间）。
    滚动（D66）：纯原生 ScrollFrame 无滚动条但支持滚轮（基座 widget/ScrollFrame.lua:35-44
        的 scrollBar="none" 分支逐字内联为 CreatePlainScrollFrame）。
        把 CharacterStatsPane 整体 SetParent 到 scrollChild（StatMarks
        Bars.lua:25-40、:853-909 的 AdoptStatsPane；DCSLayouts.lua:18-55 同为
        reparent 原生子帧到自建容器）：这是 12.x 上被认可的做法，因为
        PaperDollFrame_UpdateStats 只重锚行、从不重锚/重父 pane 本身。
        内容高度按 StatMarks :1366-1435 实测「最底可见子帧 bottom」计算。
    不改写原生脚本、不改 PAPERDOLL_STATCATEGORIES；所有自建帧可完整恢复。
    战斗中（InCombatLockdown）不 reparent / 不改尺寸，离开战斗由
        PLAYER_REGEN_ENABLED 补偿一轮。
    secret 纪律：数值只经 Collector.ReadSecondaryValues，绝不比较/算术 secret。
    变更（用户 2026-11-17）：图形内嵌（Radar/Ring 图）功能删除（实测问题较大），
    ShiftDown/shiftedRows 等链头偏移机制一并移除；ADDON_LOADED 过滤修正——12.x 角色面板
    打包在 Blizzard_UIPanels_Game（Mainline TOC 含 CharacterFrame.xml/PaperDollFrame.xml，
    z-ref 实证），独立的 Blizzard_CharacterFrame addon 名已不存在，原过滤恒 return 使
    事件挂载点失效，改为任何 ADDON_LOADED 都尝试补挂载（幂等）。
    v6.5：唯一基座调用 ADE.CreateScrollFrame 已内联；ns 头统一走全局私有表。 ]==]
-- ADE v6.5：ns 统一走全局私有表（Core/InitDB 同一表）
local addonName = ...
local ns = _G.adeStatPlus or {}
_G.adeStatPlus = ns

local CharPanel = {}
ns.CharPanel = CharPanel

local SECONDARY = { "crit", "haste", "mastery", "vers" }
local BAR_H = 8
local BAR_TEXT_GAP = 3
local BAR_BOTTOM_OFFSET = 2
local ROW_INSET = 11
local SCROLL_BOTTOM_PAD = 8

local pane, bars = nil, {}
local scrollFrame, scrollChild
local mounted = false
local eventFrame
local hooked = false
local grownRows = {}          -- [原生行] = { height, labelShift, valueShift }
local UpdateScrollRange       -- 前向声明：EnsureScroll 的 OnSizeChanged 引用
local PositionBarTick         -- 前向声明：EnsureBar 的 OnSizeChanged 引用

local function Cfg() return ns.db.profile.charPanel end

--[==[ 纯原生 ScrollFrame（基座 widget/ScrollFrame.lua:35-44 的 scrollBar="none"
    分支逐字内联）：不套 ScrollFrameTemplate，就没有模板 OnLoad 创建的滚动条；
    滚轮滚动自己处理。返回 scroll, child（child 为 ScrollChild）。 ]==]
local function CreatePlainScrollFrame(parent)
    local scroll = CreateFrame("ScrollFrame", nil, parent)
    scroll:EnableMouseWheel(true)
    scroll:SetScript("OnMouseWheel", function(_, delta)
        local range = scroll:GetVerticalScrollRange()
        if range <= 0 then return end
        local cur = scroll:GetVerticalScroll()
        scroll:SetVerticalScroll(math.max(0, math.min(range, cur - delta * 20)))
    end)
    local content = CreateFrame("Frame", nil, scroll)
    content:SetSize(1, 1)
    scroll:SetScrollChild(content)
    scroll.content = content
    return scroll, content
end

-- 暴雪本地化 STAT_* 全局（StatMarks/Bars.lua:141-150 同款），运行时读取。
local NATIVE_LABELS = {
    crit = "STAT_CRITICAL_STRIKE", haste = "STAT_HASTE",
    mastery = "STAT_MASTERY", vers = "STAT_VERSATILITY",
}

local function BuildLabelMap()
    local fmt = STAT_FORMAT or "%s:"
    local map = {}
    for key, globalName in pairs(NATIVE_LABELS) do
        local name = _G[globalName]
        if type(name) == "string" then
            map[string.format(fmt, name)] = key
        end
    end
    return map
end

local function ForEachStatRow(callback)
    if not pane then return end
    -- statsFramePool 为 12.x 原生运行期字段（实证 StatMarks/Bars.lua:2127-2149）
    ---@diagnostic disable-next-line: undefined-field
    local pool = pane.statsFramePool
    if pool and pool.EnumerateActive then
        for row in pool:EnumerateActive() do callback(row) end
        return
    end
    -- 回退：遍历 pane 的直接子帧（StatMarks/Bars.lua:2127-2149 同款）
    for i = 1, select("#", pane:GetChildren()) do
        local child = select(i, pane:GetChildren())
        if child.Label and child.Value then callback(child) end
    end
end

local function MatchStatRow(row, labelMap)
    if row.Label and row.Label.GetText then
        local label = row.Label:GetText()
        if type(label) == "string" and not ns.Collector.IsSecret(label) then
            return labelMap[label]
        end
    end
    return nil
end

--- 解析原生两个类别帧（StatMarks/Bars.lua:1099-1123）。
local function ResolveCategories()
    if not pane then return nil, nil end
    local attr, enh = pane.AttributesCategory, pane.EnhancementsCategory
    if attr and enh then return attr, enh end
    local attrTitle, enhTitle = STAT_CATEGORY_ATTRIBUTES, STAT_CATEGORY_ENHANCEMENTS
    for i = 1, select("#", pane:GetChildren()) do
        local child = select(i, pane:GetChildren())
        local title = child.Title and child.Title.GetText and child.Title:GetText()
        if title then
            if not attr and attrTitle and title == attrTitle then attr = child end
            if not enh and enhTitle and title == enhTitle then enh = child end
        end
    end
    return attr, enh
end

--- 找「强化属性」组下的第一条原生行（第一锚点 relTo == EnhancementsCategory）。
--- 供 IsPaneReady 判断「原生行已构建」——条挂载重试的收敛条件。
local function FirstEnhancementsRow(enhCat)
    local byAnchor = {}
    ForEachStatRow(function(row)
        if row:IsShown() then
            local _, relTo = row:GetPoint(1)
            if relTo then byAnchor[relTo] = row end
        end
    end)
    return byAnchor[enhCat]
end

--- 原生行是否就绪（供 OnShow 重试判断）：强化组类别与其下首行均已存在。
local function IsPaneReady()
    if not pane or not pane:IsShown() then return false end
    local _, enh = ResolveCategories()
    if not enh then return false end
    return FirstEnhancementsRow(enh) ~= nil
end

--[==[ 滚动容器（D66）：把原生 pane 整体移入自建 ScrollFrame 的 scrollChild。
    viewport 铺满 CharacterFrameInsetRight；滚动条模式 none（无条、可滚轮）。
    实证 StatMarks/Bars.lua:1482-1513（SetupScroll）、:853-909（AdoptStatsPane）。 ]==]
local function EnsureScroll()
    if scrollFrame and scrollChild then return true end
    local inset = _G.CharacterFrameInsetRight
        or (_G.CharacterFrame and _G.CharacterFrame.InsetRight)
    if not (inset and pane) then return false end

    -- 父级用 PaperDollFrame（保持 pane 原有的可见性链），锚点仍落在 inset 上
    local parent = _G.PaperDollFrame or inset
    local scroll, child = CreatePlainScrollFrame(parent)
    scroll:SetPoint("TOPLEFT", inset, "TOPLEFT", 0, 0)
    scroll:SetPoint("BOTTOMRIGHT", inset, "BOTTOMRIGHT", 0, 0)
    scroll:SetFrameLevel(inset:GetFrameLevel() + 1)
    -- viewport 首帧宽度可能为 0；尺寸落定后重新测量内容高度，避免不滚动
    scroll:SetScript("OnSizeChanged", function()
        if mounted and pane and pane:IsShown() then UpdateScrollRange() end
    end)
    scrollFrame, scrollChild = scroll, child
    return true
end

--- 把 pane reparent 到 scrollChild（战斗中跳过，避免 taint）。
local function AdoptPane()
    if not (pane and scrollChild) or InCombatLockdown() then return end
    if pane:GetParent() ~= scrollChild then
        pane:SetParent(scrollChild)
        pane:ClearAllPoints()
        pane:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 0, 0)
    end
end

--- 按「最底可见子帧」实测内容高度（StatMarks/Bars.lua:1366-1435 同款）。
--- 增高行与链头偏移都已体现在子帧的 bottom 上，无需单独累加。
UpdateScrollRange = function()
    if not (scrollFrame and scrollChild and pane) or InCombatLockdown() then return end
    local w = scrollFrame:GetWidth()
    if w and w > 0 then
        scrollChild:SetWidth(w)
        pane:SetWidth(w)
    end
    local viewHeight = scrollFrame:GetHeight()
    if not viewHeight or viewHeight <= 0 then return end

    local top = scrollChild:GetTop()
    local lowest
    if top then
        for i = 1, select("#", pane:GetChildren()) do
            local child = select(i, pane:GetChildren())
            if child:IsShown() and child.GetBottom then
                local bottom = child:GetBottom()
                -- 布局尚未解析时可能拿不到数值；跳过该帧（非静默造值）
                if type(bottom) == "number" and (not lowest or bottom < lowest) then
                    lowest = bottom
                end
            end
        end
    end
    -- r008：测量失败（装备变动时行池正在重建，子帧尚未布局 → top/lowest 无效）时
    -- 不再写尺寸——原逻辑会把 pane 高度强行压到 viewHeight，超出视口的内容被
    -- ScrollFrame 裁掉，表现为「角色面板原有内容消失」。保留原生尺寸，等下一轮补测。
    if not top or not lowest then return end
    local contentHeight = (top - lowest) + SCROLL_BOTTOM_PAD
    if contentHeight < viewHeight then contentHeight = viewHeight end
    scrollChild:SetHeight(contentHeight)
    pane:SetHeight(contentHeight)
end

--- 读取帧的第 1 个锚点（可能多点锚，只取第 1 个用于 y 位移/还原）。
local function FirstAnchor(frame)
    if not frame or not frame.GetPoint or not frame.GetNumPoints
        or frame:GetNumPoints() < 1 then return nil end
    local point, relTo, relPoint, x, y = frame:GetPoint(1)
    return { point, relTo, relPoint, x, y }
end

local function ApplyAnchor(frame, a)
    if a then frame:SetPoint(a[1], a[2], a[3], a[4], a[5]) end
end

--- 把 FontString 沿 y 上移 delta（保持增高行后文字仍在原来的顶部位置，
--- 避免 Label/Value 在增高行里垂直居中导致与进度条错位；
--- 实证 StatMarks/Bars.lua:1855-1921 的 labelDelta / valueDelta）。
--- 返回 { 原始锚点, 写入后锚点 }，供 Restore 做「仅当我们的偏移仍在」守卫。
local function ShiftFontString(fs, delta)
    local a = FirstAnchor(fs)
    if not a then return nil end
    local written = { a[1], a[2], a[3], a[4], (a[5] or 0) + delta }
    fs:SetPoint(written[1], written[2], written[3], written[4], written[5])
    return { base = a, written = written }
end

--- r008：无条件还原 FontString 到我们记录的原始锚点。
--- 原守卫要求当前锚点精确匹配我们写入的偏移才还原；装备变动时暴雪会重锚池化行，
--- 守卫一旦失效，上一轮的 +delta 位移就残留下来，下一轮 Relayout 又以残留位置为基线
--- 再上移 delta —— 文字逐次上飘，几次换装后全部离开可视区（用户实测面板变空）。
--- 暴雪对同一行的锚点定义是稳定的，写回 base 只会回到原生位置，不会破坏其新布局。
local function RestoreFontString(fs, rec)
    if not rec or not fs then return end
    ApplyAnchor(fs, rec.base)
end

--- 恢复上一轮对原生行的高度与 FontString 锚点（每轮重排前调用，防累积）。
local function Restore()
    for row, rec in pairs(grownRows) do
        grownRows[row] = nil
        if row.SetHeight then row:SetHeight(rec.height) end
        RestoreFontString(row.Label, rec.labelShift)
        RestoreFontString(row.Value, rec.valueShift)
    end
end

local function EnsureBar(key)
    local visual = bars[key]
    if visual then return visual end
    local bar = CreateFrame("StatusBar", nil, UIParent, "BackdropTemplate")
    bar:SetHeight(BAR_H)
    bar:SetMinMaxValues(0, 100)
    local bg = bar:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints(bar)
    bg:SetColorTexture(0, 0, 0, 0.6)
    local tick = bar:CreateTexture(nil, "OVERLAY")
    tick:SetColorTexture(1, 1, 1, 0.9)
    tick:SetWidth(1)
    local spark = bar:CreateTexture(nil, "OVERLAY", nil, 4)
    spark:SetTexture("Interface\\CastingBar\\UI-CastingBar-Spark")
    spark:SetBlendMode("ADD")
    spark:SetSize(12, 12)
    visual = { bar = bar, bg = bg, tick = tick, spark = spark }
    -- 与 Bars.lua 同款：条宽解析完成后按缓存阀值重定位刻度
    bar:SetScript("OnSizeChanged", function()
        if visual.threshold then PositionBarTick(visual, visual.threshold) end
    end)
    bars[key] = visual
    return visual
end

--- 角色面板条：按实际阀值定位刻度（D71，与 Bars.PositionTicks 同款）。
PositionBarTick = function(visual, threshold)
    local bar = visual.bar
    local w = bar:GetWidth()
    if not w or w <= 0 then return end
    local tickX = math.min(math.max(math.min(1, threshold / 100) * w, 1), math.max(1, w - 1))
    visual.tick:ClearAllPoints()
    visual.tick:SetPoint("TOP", bar, "TOPLEFT", tickX, 2)
    visual.tick:SetPoint("BOTTOM", bar, "BOTTOMLEFT", tickX, -2)
    visual.tick:Show()
end

local function ApplyBar(visual, key, row, value, threshold)
    local cfg = Cfg().bars
    local def = ns.StatDefs[key]
    -- D85：others 组配置在 profile.others[key]，其余在 profile.stats[key]
    local scfg = (def.group == "others") and ns.db.profile.others[key] or ns.db.profile.stats[key]
    local cr, cg, cb = ns.ColorRGB((scfg and scfg.color) or def.color)
    visual.bar:SetParent(row)
    visual.bar:ClearAllPoints()
    visual.bar:SetPoint("BOTTOMLEFT", row, "BOTTOMLEFT", ROW_INSET, BAR_BOTTOM_OFFSET)
    visual.bar:SetPoint("BOTTOMRIGHT", row, "BOTTOMRIGHT", -ROW_INSET, BAR_BOTTOM_OFFSET)
    visual.bar:SetHeight(BAR_H)
    visual.bar:SetFrameLevel(row:GetFrameLevel() + 2)
    visual.bar:SetStatusBarTexture(ns.Bars.TexturePath(cfg.texture))
    visual.bar:SetStatusBarColor(cr, cg, cb)
    visual.bg:SetAlpha(cfg.bgAlpha)
    -- D69：条材质透明度
    local fill = visual.bar:GetStatusBarTexture()
    if fill then fill:SetAlpha(cfg.textureAlpha) end
    -- D68：火花高度跟随条高度（D73 加大）
    visual.spark:SetSize(12, BAR_H + 16)
    if value then visual.bar:SetValue(value) else visual.bar:SetValue(0) end

    if cfg.showThreshold and threshold and type(threshold) == "number" and threshold > 0 then
        -- D71：按实际阀值定位；TOPLEFT/BOTTOMLEFT 相对点避免被挤到 50%
        visual.threshold = threshold
        PositionBarTick(visual, threshold)
    else
        visual.threshold = nil
        visual.tick:Hide()
    end
    if cfg.spark and value and value > 0 then
        local frac = math.min(1, value / 100)
        visual.spark:ClearAllPoints()
        visual.spark:SetPoint("CENTER", visual.bar, "LEFT", visual.bar:GetWidth() * frac, 0)
        visual.spark:Show()
    else
        visual.spark:Hide()
    end
    visual.bar:Show()
end

local function HideBars()
    for _, visual in pairs(bars) do visual.bar:Hide() end
end

--- 每次原生重排后重新挂载（hooksecurefunc 后置钩子）。
function CharPanel.Relayout()
    if not mounted or not pane or not pane:IsShown() then return end
    Restore()
    local cfg = Cfg()
    local values = ns.Collector.ReadSecondaryValues(SECONDARY)
    local thresholds = cfg.bars.showThreshold and ns.Registry.Sources.GetThresholds() or nil

    if cfg.bars.enabled then
        local labelMap = BuildLabelMap()
        ForEachStatRow(function(row)
            if not row:IsShown() then return end
            local key = MatchStatRow(row, labelMap)
            if not key then return end
            local visual = EnsureBar(key)
            -- 增高原生行让条落在对应原生值下面。链式锚下更高的行会自动把
            -- 后续行推下去（StatMarks/Bars.lua:14-23），无需额外偏移。
            -- 同时把 Label/Value 上移 delta/2，避免文字在增高行里垂直居中而与条错位。
            if not grownRows[row] then
                local base = row:GetHeight()
                local extra = BAR_TEXT_GAP + BAR_H + BAR_BOTTOM_OFFSET
                local delta = extra / 2
                grownRows[row] = { height = base }
                row:SetHeight(base + extra)
                grownRows[row].labelShift = ShiftFontString(row.Label, delta)
                grownRows[row].valueShift = ShiftFontString(row.Value, delta)
            end
            ApplyBar(visual, key, row, values[key], thresholds and thresholds[key])
        end)
    else
        HideBars()
    end

    -- D66：滚动容器必须在布局完成后测量（增高行都已生效）
    if EnsureScroll() then
        AdoptPane()
        UpdateScrollRange()
        if scrollFrame then scrollFrame:Show() end
    end
    return IsPaneReady()
end

--- 配置变更 / 数值刷新入口。
function CharPanel.Refresh()
    if not mounted then return end
    CharPanel.Relayout()
end

local function OnEvent(self, event, name)
    -- ADDON_LOADED 不按名字过滤：12.x 角色面板打包在 Blizzard_UIPanels_Game（Mainline
    -- TOC 含 CharacterFrame.xml/PaperDollFrame.xml，z-ref 实证），原「Blizzard_CharacterFrame」
    -- addon 名已不存在，过滤恒 return 使事件挂载点失效。pane 已挂载时这里是幂等 Relayout。
    if event == "ADDON_LOADED" and mounted then return end
    if not pane then pane = _G.CharacterStatsPane end
    if pane and not mounted then
        mounted = true
        if not hooked and type(PaperDollFrame_UpdateStats) == "function" then
            hooksecurefunc("PaperDollFrame_UpdateStats", function()
                -- r008：同帧重建竞态——Relayout 返回 false 表示原生行还没就绪
                -- （IsPaneReady 找不到强化组首行）。原逻辑只测一次就压了 pane 尺寸，
                -- 内容被裁；改为下一帧补测一次（OnShow 的 ticker 不覆盖装备变动路径）。
                if not CharPanel.Relayout() and pane and pane:IsShown() then
                    C_Timer.After(0.05, function()
                        if pane and pane:IsShown() then CharPanel.Relayout() end
                    end)
                end
            end)
            hooked = true
        end
        if pane.HookScript then
            pane:HookScript("OnShow", function()
                CharPanel.Relayout()
                -- D88：更稳健的重试——原生 stats 行在 OnShow 之后才重建，过早 Relayout
                -- 会因行未就绪而留空（偶发需等数秒）。ticker 每 0.05s 重试，直到
                -- IsPaneReady（强化组首行就绪）即停，最多 2s；首帧竞态与重开均覆盖。
                local tries = 0
                C_Timer.NewTicker(0.05, function(self)
                    tries = tries + 1
                    local ok = CharPanel.Relayout()
                    if ok or tries >= 40 or not (pane and pane:IsShown()) then self:Cancel() end
                end)
            end)
            pane:HookScript("OnHide", function()
                Restore()
                HideBars()
                -- viewport 与 pane 的可见性链相同，pane 隐藏时一并隐藏
                if scrollFrame then scrollFrame:Hide() end
            end)
        end
        -- 首帧竞态：Blizzard 可能尚未完成第一次行构建（StatMarks/Bars.lua:1454）
        C_Timer.After(0, function() CharPanel.Relayout() end)
    elseif mounted then
        -- 战斗中跳过的 reparent / 尺寸更新在离开战斗后补偿一轮
        CharPanel.Relayout()
    end
end

function CharPanel.Init()
    eventFrame = CreateFrame("Frame")
    eventFrame:SetScript("OnEvent", OnEvent)
    eventFrame:RegisterEvent("ADDON_LOADED")
    eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    eventFrame:RegisterEvent("ACTIVE_PLAYER_SPECIALIZATION_CHANGED")
    eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
    ns.Collector.RegisterRefresh(CharPanel.Refresh)
    pane = _G.CharacterStatsPane
    OnEvent(eventFrame, "PLAYER_ENTERING_WORLD")
end
