--[==[ LibWMT_LeatrixMaps_Patch.lua — LibWorldMapTabs × Leatrix Maps 简易地图框体补丁
适用：12.x（TOC 120105）。修复 Leatrix Maps「使用简易地图框体」开启时，所有经
LibWorldMapTabs 创建的世界地图 Tab 内容面板（WorldQuestTab / adeMapTab_Portal /
adeMapTab_Delve / adeMapMark 等）相对原生任务日志上移 21px、顶部控件落入新标题栏的偏移。

一、根因（全部为磁盘实证，路径:行号）
  · 暴雪原生标准：QuestMapFrame.xml:490（QuestScrollFrame TOPLEFT y=-29）、:848/:937
    （MapLegend / EventsFrame 锚 ContentsAnchor y=-29 / x=-22）、:479-480（QuestsFrame
    锚 ContentsAnchor、右侧 -22）。ContentsAnchor 定义于 :466-473。
  · 第三方全部照抄这个 -29 基准：
      adeMapTab/Public/MapTab.lua:43-44（ANCHOR_TOP_Y=-29 / ANCHOR_RIGHT_X=-22）、
      :186-187（内容帧双锚 ContentsAnchor）、:189-191（三次重锚兜底）；
      adeMapMark/Settings.lua:396（contentFrame SetAllPoints(ContentsAnchor)）、
      :401-405（主面板/设置面板锚 ContentsAnchor y=-29 / x=-22）；
      WorldQuestTab/WorldQuestTab.xml:621-622（WQT_WorldQuestFrame 锚 ContentsAnchor
      y=-29 / x=-22）、WorldQuestTab.lua:2124-2125（world 模式改锚 contentFrame，同为 -29）。
  · Leatrix Maps「简单框体」把原生内容整体下移 50px 避开新标题栏：
      Leatrix_Maps.lua:735-740（QuestScrollFrame: TOPLEFT 0,-50 / BOTTOMRIGHT 0,0）、
      :744-752（MapLegend / EventsFrame: 锚 ContentsAnchor 0,-50 / -22,0）、
      :755-773（DetailsFrame 下移 47px）、:783-791（搜索框/设置按钮移入标题栏）。
    Leatrix 只认识原生帧，不认识 LibWorldMapTabs 动态创建的 contentFrame
    （库 LibWorldMapTabs.lua:294-296 SetAllPoints(ContentsAnchor)、:312 SetParent、:314 登记）。
    → 第三方内容仍停在 -29，比原生少下移 21px（50-29），即用户观察到的偏移。

二、修法（本补丁，零侵入）
  不改动任何插件或库副本：工作区内 adeMapTab / adeMapMark / WorldQuestTab 各内嵌一份
  LibWorldMapTabs（LibStub minor 6 单例，先加载者胜出，库 :20/:22），改任何一份都不可靠。
  补丁在运行时取 LibStub("LibWorldMapTabs", true) 单例，扫描 lib.contentFrames 及其子帧、
  QuestMapFrame / ContentsAnchor 的直接子帧，把「TOPLEFT 锚到 ContentsAnchor 或全铺
  ContentsAnchor 的 contentFrame、y≈-29」的帧重锚（其余锚点原样保留，右侧 -22 不变）。
  全铺型 contentFrame（WQT / adeMapMark 的容器，y=0）本身不动，避免与 WQT 主界面叠加。
  r002：目标值由 -50 再下沉到 -80，让出各插件外扩到面板上方的顶栏（见第六节）。

三、生效判据（不依赖 Leatrix 的 local 表）
  LeaMapsLC / LeaLockList 是 Leatrix 的 local（Leatrix_Maps_Library.lua:11、
  Leatrix_Maps.lua:16），外部读不到；故用两条可观测条件：
    a) SavedVariables 全局 LeaMapsDB["SimpleMapFrame"] == "On"（Leatrix_Maps.toc:9、
       Leatrix_Maps.lua:8640 LoadVarChk / :8750 保存 / :339 运行判据）；
    b) 行为确认 QuestScrollFrame 的 TOPLEFT y≈-50（Leatrix_Maps.lua:739 已执行）。
       ElvUI 皮肤冲突锁定 SimpleMapFrame（:8738，:339 的 not LeaLockList 分支）时
       QuestScrollFrame 不会被改成 -50，判据天然排除，不会误修。
  开关切换需 /reload（Leatrix_Maps.lua:7807 ReloadCheck），重载后判据自动重算。

四、时序（覆盖所有重锚路径）
  · PLAYER_LOGIN / PLAYER_ENTERING_WORLD / ADDON_LOADED(Blizzard_WorldMap) /
    PLAYER_REGEN_ENABLED：延迟 0s + 0.2s 各应用一次（覆盖 adeMapTab 基座的
    RunNextFrame / C_Timer.After(0.1) 三次兜底，MapTab.lua:189-191）。
  · EventRegistry「WorldMapOnShow」（Blizzard_WorldMap.lua:375 触发）与
    QuestMapFrame OnShow/OnHide（Leatrix 同在 :798-804 挂 SetFrameLayout）后重新扫描。
  · 实例级 hooksecurefunc(frame, "SetPoint")：任何后续重锚（WQT ChangeAnchorLocation
    :2122-2130、各插件自建重锚）之后下一帧回放修正；hooksecurefunc(lib,
    "LinkTabToContentFrame") 捕获之后新建的 contentFrame（库 :297/:302）。
  · 战斗中不触碰锚点（Leatrix 自身也用 CanChange 防护，:342-344/:735）。

五、API 依据（12.x）
  GetNumPoints / GetPoint(anchorIndex) → point, relativeTo, relativePoint, offsetX, offsetY /
  ClearAllPoints / SetPoint / Frame:GetChildren：
    z-ref_wow-dev-doc/wow_API_wiki.gg/_2-1_Widget_API.md:147,153,155,163,731
  （同族别名 AdjustPointsOffset:145 会连底边一起移动、SetPointsOffset:165 会覆盖全部锚点，
    均不适用；GetPointByName:157 只能取单点，保留全部锚点需遍历，故用 GetNumPoints+GetPoint）
  C_Timer.After(seconds, callback)：_1-1_Main.md:9813
  hooksecurefunc(tbl, name, hook)：_1-1_Main.md:13761（实例级钩子实证：
    MapPinEnhanced_FixTrackerPatch/Core.lua:149-152）
  C_AddOns.IsAddOnLoaded：Leatrix_Maps.lua:314 同款用法
  _docs/api/api-changes-overview-12.x.md 无上述接口移除/迁移记录。

六、r002 再下沉（用户 2026-11-23 反馈：溢出修好后，顶栏标题等控件被遮盖）
  r001 把面板改到 -50 后溢出消失，但各插件顶栏仍落在 Leatrix 标题栏内：
    · MapTab.CreateTopBar（adeMapTab/Public/MapTab.lua:273-282）：bar 锚 panel 上方
      +30、高 26 → 顶边 = panel.top + 30，底边 = panel.top + 4；
    · WQT TopBar（WorldQuestTab.xml:650-658）：BOTTOM→父 TOP y=4、Size y=26 → 同样 +30；
    · 齿轮按钮（MapTab.lua:217、WorldQuestTab.xml:418/771、adeMapMark/Settings.lua:446）：
      TOPRIGHT panel +25；边框（WorldMapPanel.lua:658）+7、滚动条（MapTab.lua:309）+2。
  即顶栏占据 panel.top 上方 4~30px。panel 在 -50 时顶栏位于距内容区顶部 20~46px，
  正压在 Leatrix 标题栏（原生内容下移到 -50 让出的 0~50px，Leatrix_Maps.lua:737-740）
  内；第三方面板 FrameLevel = qmf+200（MapTab.lua:194）远高于标题栏，于是把标题栏里的
  地图标题 / 搜索框 / 设置按钮盖住（用户截图现象）。
  要让顶栏顶边落到 50px 线以下：panel.top = -50 - 30 = -80（顶边恰好 50px、底边 76px，
  与 panel 内容区 80px 仍保留原设计的 4px 间隙；与原生内容起始线 -50 对齐）。
  SnapTop 同时识别 -29（源值）与上一版目标 -50（r001 已应用状态），统一改到当前目标；
  目标可用 /lwmtlmp offset <n> 会话内微调（默认 80 → y=-80），/reload 复位。
]==]
local ADDON = ...

-- 原生标准 / Leatrix 简易框体 / 补丁目标（证据见文件头）
local NATIVE_TOP_Y = -29        -- 第三方 contentFrame 的原生锚（修正源值）
local LEATRIX_TOP_Y = -50       -- Leatrix 把原生任务列表下移到的位置（生效判据）
local PATCH_TOP_Y = -80         -- r002 目标：比 -50 再下沉 30px，让出顶栏（第六节）
local appliedTopY = LEATRIX_TOP_Y -- 上次应用的目标值（兼容 r001 已应用 / offset 热调）
local EPS = 0.6
local RETRY_DELAY = 0.2

local LibStub = LibStub
local C_Timer = C_Timer
local hooksecurefunc = hooksecurefunc
local InCombatLockdown = InCombatLockdown
local C_AddOns = C_AddOns
local type, ipairs, math_abs, tostring = type, ipairs, math.abs, tostring

local applying = false          -- 本补丁自身重锚的重入保护
local scheduled = false         -- 两阶段应用去抖
local mapHooked = false
local wmfHooked = false
local libHooked = false
local hookedFrames = 0
local lastFixed = {}

local OWNER = {}                    -- EventRegistry 回调 owner
local IsSecret = _G.issecretvalue   -- 12.x secret 值防护（Leatrix_Maps.lua:559/:760 同款）
local function Num(v)
    return type(v) == "number" and not (IsSecret and IsSecret(v))
end

-- 前向声明：帧级 SetPoint 钩子在 Schedule 定义之前就要引用它；不使用任何 _G 全局函数。
local ApplyAll, Schedule

local function GetLib()
    return LibStub and LibStub("LibWorldMapTabs", true) or nil
end

--- Leatrix 简易框体是否真实生效：插件已加载 + SV 开关 On + 原生任务列表已被下移到 -50。
local function Active()
    if C_AddOns and C_AddOns.IsAddOnLoaded and not C_AddOns.IsAddOnLoaded("Leatrix_Maps") then
        return false
    end
    local db = _G.LeaMapsDB
    if type(db) ~= "table" or db["SimpleMapFrame"] ~= "On" then return false end
    local qsf = _G.QuestScrollFrame
    if not qsf or not qsf.GetNumPoints then return false end
    for i = 1, qsf:GetNumPoints() do
        local point, _, _, _, y = qsf:GetPoint(i)
        if point == "TOPLEFT" and Num(y) and math_abs(y - LEATRIX_TOP_Y) < 1 then
            return true
        end
    end
    return false
end

--- 全铺 ContentsAnchor 的 contentFrame 集合（SetAllPoints(ca)：TOPLEFT y≈0，rel=ca）。
--- 这些容器本身不改；锚到它们且 y=-29 的帧（如 WQT_WorldQuestFrame）需要改。
local function BuildSpreadSet(lib, ca)
    local spread = {}
    for _, cf in ipairs(lib.contentFrames or {}) do
        if cf and cf.GetNumPoints then
            for i = 1, cf:GetNumPoints() do
                local point, rel, _, _, y = cf:GetPoint(i)
                if point == "TOPLEFT" and rel == ca and Num(y) and math_abs(y) < EPS then
                    spread[cf] = true
                    break
                end
            end
        end
    end
    return spread
end

--- 候选帧：库登记的全部 contentFrame、它们的直接子帧、QuestMapFrame 与 ContentsAnchor
--- 的直接子帧。排除暴雪原生内容帧（Leatrix 自己会改它们，见 :737-773）。
local function CollectFrames(lib, qmf, ca)
    local seen, list = {}, {}
    -- 暴雪原生内容帧统一排除：Leatrix 会把 MapLegend / EventsFrame 也改成 -50（:749），
    -- 而 r002 起 -50 同时是「上一版补丁值」的识别源，不排除会误改原生帧。
    local function isNative(f)
        return f == qmf.QuestsFrame or f == qmf.MapLegend or f == qmf.EventsFrame
            or f == qmf.DetailsFrame or f == qmf.ContentsAnchor
    end
    local function add(f)
        if f and type(f) == "table" and not seen[f] and not isNative(f) then
            seen[f] = true
            list[#list + 1] = f
        end
    end
    local function addChildren(f)
        if f and f.GetChildren then
            for _, child in ipairs({ f:GetChildren() }) do add(child) end
        end
    end
    for _, cf in ipairs(lib.contentFrames or {}) do
        add(cf)
        addChildren(cf)
    end
    addChildren(ca)
    addChildren(qmf)
    return list
end

--- 把单个帧的 TOPLEFT y≈-29（源值）或 y≈appliedTopY（上一版/上次补丁值）改为
--- PATCH_TOP_Y，其它锚点原样重设（ClearAllPoints 后逐个 SetPoint）。
--- 已是目标值的帧不再重锚，避免每次 ApplyAll 都无谓 ClearAllPoints。
local function SnapTop(frame, ca, spread)
    if not frame or not frame.GetNumPoints then return false end
    local n = frame:GetNumPoints()
    if n == 0 then return false end
    local points, hit = {}, false
    for i = 1, n do
        local point, rel, relPoint, x, y = frame:GetPoint(i)
        if point == "TOPLEFT" and Num(y)
            and (math_abs(y - NATIVE_TOP_Y) < EPS or math_abs(y - appliedTopY) < EPS)
            and math_abs(y - PATCH_TOP_Y) >= EPS
            and (rel == ca or spread[rel] == true) then
            y = PATCH_TOP_Y
            hit = true
        end
        points[i] = { point, rel, relPoint, x, y }
    end
    if not hit then return false end
    applying = true
    frame:ClearAllPoints()
    for i = 1, #points do
        local p = points[i]
        -- GetPoint 的 relativePoint / 偏移可能为 nil，SetPoint 需要完整 5 参（缺省值补齐）。
        frame:SetPoint(p[1], p[2], p[3] or p[1], p[4] or 0, p[5] or 0)
    end
    applying = false
    return true
end

--- 帧级 SetPoint 万能回放钩子：任何插件路径的后续重锚之后下一帧重新扫描。
local function InstallSetPointHook(frame)
    if frame._LWMTPatchHooked then return end
    frame._LWMTPatchHooked = true
    hookedFrames = hookedFrames + 1
    hooksecurefunc(frame, "SetPoint", function()
        if applying or not Active() then return end
        Schedule()
    end)
end

ApplyAll = function()
    if not Active() or applying or (InCombatLockdown and InCombatLockdown()) then return end
    local lib = GetLib()
    local qmf = _G.QuestMapFrame
    if not lib or not qmf or not qmf.ContentsAnchor then return end
    local ca = qmf.ContentsAnchor
    -- 所有库登记的内容帧都装 SetPoint 钩子（含全铺型容器）：插件对容器的
    -- SetAllPoints / 重锚同样可能是后续偏移来源，确保任何路径之后都回放修正。
    for _, cf in ipairs(lib.contentFrames or {}) do
        if cf and cf.SetPoint then InstallSetPointHook(cf) end
    end
    local spread = BuildSpreadSet(lib, ca)
    local frames = CollectFrames(lib, qmf, ca)
    lastFixed = {}
    for _, frame in ipairs(frames) do
        if SnapTop(frame, ca, spread) then
            InstallSetPointHook(frame)
            lastFixed[#lastFixed + 1] = frame.GetName and (frame:GetName() or "(匿名帧)") or "(匿名帧)"
        end
    end
    -- 循环结束后才更新，保证本轮 SnapTop 仍能识别上一版目标值。
    appliedTopY = PATCH_TOP_Y
end

--- 两阶段应用：下一帧（等 Leatrix SetFrameLayout 与库创建完成）+ 0.2s（等基座三次兜底）。
Schedule = function()
    if scheduled then return end
    scheduled = true
    C_Timer.After(0, function()
        ApplyAll()
        C_Timer.After(RETRY_DELAY, function()
            scheduled = false
            ApplyAll()
        end)
    end)
end

local function HookLib()
    if libHooked then return end
    local lib = GetLib()
    if not lib or not lib.LinkTabToContentFrame then return end
    libHooked = true
    hooksecurefunc(lib, "LinkTabToContentFrame", function()
        Schedule()
    end)
end

local function HookMap()
    -- WorldMapFrame 属 Blizzard_WorldMap（LoD），首次 HookMap 时可能还不存在，单独重试。
    local wmf = _G.WorldMapFrame
    if wmf and not wmfHooked then
        wmfHooked = true
        wmf:HookScript("OnShow", function() Schedule() end)
    end
    if mapHooked then return end
    local qmf = _G.QuestMapFrame
    if not qmf then return end
    mapHooked = true
    if EventRegistry and EventRegistry.RegisterCallback then
        EventRegistry:RegisterCallback("WorldMapOnShow", function() Schedule() end, OWNER)
    end
    qmf:HookScript("OnShow", function() Schedule() end)
    qmf:HookScript("OnHide", function() Schedule() end)
end

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:SetScript("OnEvent", function(_, event, arg1)
    if event == "ADDON_LOADED" and arg1 ~= ADDON and arg1 ~= "Blizzard_WorldMap"
        and arg1 ~= "Blizzard_UIPanels_Game" then
        return
    end
    HookLib()
    HookMap()
    Schedule()
end)

--- 诊断：/lwmtlmp status | apply | offset <n>
SLASH_LWMTLMP1 = "/lwmtlmp"
SlashCmdList.LWMTLMP = function(msg)
    msg = (msg or ""):lower():gsub("^%s+", ""):gsub("%s+$", "")
    local tag = "|cff00d9ffLibWMT-Leatrix 补丁|r "
    if msg == "apply" then
        scheduled = false
        ApplyAll()
        Schedule()
        print(tag .. "已手动重新应用。")
        return
    end
    -- r002：会话内微调下沉量（默认 80 → y=-80）。已在 ApplyAll 末尾同步 appliedTopY，
    -- 故 SnapTop 能识别旧目标并一次性改到新目标；/reload 复位为默认 -80。
    local offset = msg:match("^offset%s+(-?%d+)")
    if offset then
        local n = math_abs(tonumber(offset) or 80)
        if n < 29 or n > 160 then
            print(tag .. "offset 需在 29~160 之间（默认 80，输入正数即下沉像素）。")
            return
        end
        PATCH_TOP_Y = -n
        scheduled = false
        ApplyAll()
        Schedule()
        print(tag .. "目标顶部 y 已设为 " .. PATCH_TOP_Y .. "（会话内有效，/reload 复位）。")
        return
    end
    local db = _G.LeaMapsDB
    local dbOn = type(db) == "table" and db["SimpleMapFrame"] == "On"
    local loaded = C_AddOns and C_AddOns.IsAddOnLoaded and C_AddOns.IsAddOnLoaded("Leatrix_Maps")
    local qsfY = "无"
    local qsf = _G.QuestScrollFrame
    if qsf and qsf.GetNumPoints then
        for i = 1, qsf:GetNumPoints() do
            local point, _, _, _, y = qsf:GetPoint(i)
            if point == "TOPLEFT" then
                qsfY = (y ~= nil) and (Num(y) and tostring(y) or "受限(secret)") or "无"
                break
            end
        end
    end
    local lib = GetLib()
    print(tag .. "Leatrix Maps：" .. (loaded and "已加载" or "未加载")
        .. "；简易地图框体(SV)：" .. (dbOn and "On" or "Off/无")
        .. "；原生任务列表 TOPLEFT y=" .. qsfY)
    print(tag .. "LibWorldMapTabs：" .. (lib and ("已找到，contentFrames=" .. #(lib.contentFrames or {})) or "未找到")
        .. "；生效判据：" .. (Active() and "通过" or "未通过")
        .. "；补丁目标 y=" .. PATCH_TOP_Y
        .. "；已装帧钩子：" .. hookedFrames)
    print(tag .. "上次应用修正帧（" .. #lastFixed .. "）：" .. (#lastFixed > 0 and table.concat(lastFixed, ", ") or "无"))
    print(tag .. "命令：/lwmtlmp status | apply | offset <n>")
end
