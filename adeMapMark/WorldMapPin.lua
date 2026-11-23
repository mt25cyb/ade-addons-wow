--[[
adeMapMark - WorldMapPin（世界地图 Pin 与 DataProvider）
定位：官方 MapCanvas 体系的标记渲染、交互、缩放自适应
体系：ADE v6.5
来源：_temp/_map/old_dev/BDmap_ade/BDmap.lua:718-1035（Pin/Provider/高亮）
计划：_docs/plans/adeMapMark-dev-plan.md §2.5、§3 踩坑
]]

local addonName = ...
local ns = _G.adeMapMark
local L = ns.L

local PIN_TEMPLATE = "adeMapMarkWorldMapPinTemplate"

-- 读世界地图画布缩放（用于抵消系统缩放，避免放大后标记缩成小点）
-- 仅本文件使用，不导出
local function GetWorldMapCanvasScale()
    local sc = WorldMapFrame and WorldMapFrame.ScrollContainer
    if sc and sc.Child and sc.Child.GetScale then
        local s = sc.Child:GetScale()
        if s and s > 0 then return s end
    end
    return 1.0
end

-- 把完整备注中的换行转为空格，用于单行预览
local function GetDisplayNote(fullNote)
    if not fullNote or fullNote:match("^%s*$") then return "" end
    return fullNote:gsub("\n", " ")
end
ns.GetDisplayNote = GetDisplayNote

-- ---------------------------------------------------------------------------
-- Pin 鼠标交互（Panel 与收藏列表共用）
-- ---------------------------------------------------------------------------

function ns.Pin_OnMouseUp(pin, button)
    local data = pin.data
    if not data then return end
    local px, py = ns.decodeCoord(data.coord)

    if button == "RightButton" then
        if C_Map.CanSetUserWaypointOnMap and not C_Map.CanSetUserWaypointOnMap(data.mapID) then
            ns.Print("|cffff4444" .. L.ERR_NAV_UNSUPPORTED .. "|r")
            return
        end
        local db = ns.db()
        if db.settings.useTomTom and C_AddOns.IsAddOnLoaded("TomTom") and _G.TomTom and _G.TomTom.AddWaypoint then
            _G.TomTom:AddWaypoint(data.mapID, px, py, {
                title = data.title, persistent = false,
                minimap = true, world = true, silent = true, from = addonName,
            })
        else
            local wp = UiMapPoint.CreateFromCoordinates(data.mapID, px, py)
            if wp then
                C_Map.SetUserWaypoint(wp)
                if C_SuperTrack and C_SuperTrack.SetSuperTrackedUserWaypoint then
                    C_SuperTrack.SetSuperTrackedUserWaypoint(true)
                end
            end
        end
    elseif button == "LeftButton" and ns.Panel then
        -- 外挂标记同样进主面板编辑模块；坐标/标题由 OpenForEdit 置为只读
        ns.Panel.OpenForEdit(data)
    end
end

function ns.Pin_OnEnter(pin)
    local data = pin.data
    if not data then return end
    if ns.Plus and ns.Plus.OnPinEnter and ns.Plus.OnPinEnter(pin, data) then return end

    local c = data.color or { r = 0.2, g = 1, b = 0.73 }
    local hexColor = string.format("|cff%02x%02x%02x", math.floor((c.r or 1) * 255 + 0.5), math.floor((c.g or 1) * 255 + 0.5), math.floor((c.b or 1) * 255 + 0.5))
    local hasTitle = data.title and data.title:trim() ~= ""
    local hasNote = data.note and data.note:trim() ~= ""
    -- 纯文本标记（有标题、无备注、无图标）同样要弹提示框：数据包的点大多属于此类
    if not hasTitle and not hasNote and not data.source then return end

    GameTooltip:SetOwner(pin, "ANCHOR_RIGHT")
    if hasTitle then GameTooltip:SetText(hexColor .. data.title .. "|r") end
    if hasNote then GameTooltip:AddLine(data.note, 1, 1, 1, false) end
    if data.source then
        GameTooltip:AddLine("|cff88aaff" .. L.PROVIDER_SOURCE .. ": " .. tostring(data.source), 0.53, 0.67, 1, false)
    end
    GameTooltip:Show()
end

-- ---------------------------------------------------------------------------
-- 高亮
-- ---------------------------------------------------------------------------

function ns.ShowPinHighlight(pin, data)
    if not pin or not data then return end
    -- 背景高亮：鼠标指向时铺一层与清单行同款的高亮，取代原先效果不明显的文字叠加
    if pin.hoverBG then pin.hoverBG:Show() end
    if data.icon then
        if not pin.highlight then
            pin.highlight = pin:CreateTexture(nil, "OVERLAY")
            pin.highlight:SetBlendMode("ADD")
            pin.highlight:SetAlpha(0.4)
        end
        -- 图标+文本模式下只高亮图标区；铺满整个 Pin 会盖住文字
        pin.highlight:ClearAllPoints()
        if pin.icon and pin.icon:IsShown() then
            pin.highlight:SetAllPoints(pin.icon)
        else
            pin.highlight:SetAllPoints(pin)
        end
        if ns.ApplyIconTexture then ns.ApplyIconTexture(pin.highlight, data.icon, data.iconCrop) end
        if data.iconRotation and pin.highlight.SetRotation then
            pin.highlight:SetRotation(-math.rad(data.iconRotation))
        end
    end
    -- 纯文本标记不再叠加文字副本：文字含内联 |cff，SetVertexColor 对它无效，几乎看不出变化
end

function ns.HidePinHighlight(pin)
    if not pin then return end
    if pin.hoverBG then pin.hoverBG:Hide() end
    if pin.highlight then pin.highlight:Hide() end
end

-- ---------------------------------------------------------------------------
-- Mixin（全局名须与 XML 的 mixin 属性一致）
-- ---------------------------------------------------------------------------

adeMapMarkWorldMapPinMixin = CreateFromMixins(MapCanvasPinMixin)

function adeMapMarkWorldMapPinMixin:OnLoad()
    self:UseFrameLevelType("PIN_FRAME_LEVEL_AREA_POI")
    self:SetScalingLimits(1, 1.0, 1.3)
    -- 悬停背景高亮：铺在文字/图标之后，随 Pin 尺寸自适应
    self.hoverBG = self:CreateTexture(nil, "BACKGROUND")
    self.hoverBG:SetAllPoints()
    self.hoverBG:SetTexture("Interface\\QuestFrame\\UI-QuestLogTitleHighlight")
    self.hoverBG:SetBlendMode("ADD")
    self.hoverBG:SetAlpha(0.5)
    self.hoverBG:Hide()
    -- 不继承 GameFontNormal：带 Font 模板时，一旦 SetFont 未生效/被重置，FontString 会回退到
    -- 模板字体（GameFontNormal 字号更大且无 OUTLINE），正是「变大 + 描边消失」的来源。
    self.text = self:CreateFontString(nil, "OVERLAY")
    self.text:SetPoint("CENTER")
    -- 与旧版 BDmap_ade / BDmap 的小地图做法一致（BDmapPlus.lua:1010-1011）：关掉像素网格吸附，
    -- 避免同一字号在不同 Pin 上被量化成不同字形与描边。
    if self.text.SetSnapToPixelGrid then self.text:SetSnapToPixelGrid(false) end
end

-- 防战斗中 ADDON_ACTION_BLOCKED（计划 §三）
adeMapMarkWorldMapPinMixin.SetPassThroughButtons = function() end

function adeMapMarkWorldMapPinMixin:OnAcquired(dataIndex, data, x, y)
    ns.HidePinHighlight(self)
    -- Pin 被池化复用：先清掉上一条标记的文字/图标，避免图标点残留文字、纯文本点残留图标
    self.text:Hide()
    if self.icon then self.icon:Hide() end
    self.data = data
    self.dataIndex = dataIndex
    self:SetPosition(x, y)

    -- 字体源加兜底，不直接依赖运行时可变的全局 Font 对象
    local fontPath = (GameFontNormal and GameFontNormal:GetFont()) or STANDARD_TEXT_FONT
    local iconSize = data.iconSize or ns.db().settings.lastSize
    local zoomAdj = math.pow(GetWorldMapCanvasScale(), 0.3)
    local c = ns.cloneColor(data.color)
    local cr, cg, cb = c.r, c.g, c.b
    if data.isGrayscale then
        local lum = cr * 0.299 + cg * 0.587 + cb * 0.114
        cr, cg, cb = lum, lum, lum
    end

    -- 字体状态无条件全量重设，与本次是不是图标点无关。Pin 是池化复用的：上一次若被用作
    -- 图标点，Plus 分支 return true 会整段跳过 SetFont，字体状态就随这个 Pin 带到下一条标记上。
    -- 字号由各标记自己的 textSize 决定并取整（数据包可为不同点设计不同字号）；
    -- 未提供时用全局默认字号，与 iconSize 解耦。外挂/本地同一路径。
    local fontSizeWM = math.max(math.floor((data.textSize or ns.DEFAULT_TEXT_SIZE) * zoomAdj + 0.5), 8)
    self.text:SetFont(fontPath, fontSizeWM, "OUTLINE")
    self.text:SetShadowOffset(0, 0)
    self.text:SetShadowColor(0, 0, 0, 0)
    self.text:SetTextColor(1, 1, 1, 1)
    self.text:SetAlpha(c.a or 1)

    -- 显示模式：全局选项只决定「图标与文本同时存在」时如何呈现；仅有一种时总显示那一种。
    local showIcon, showText = ns.GetIconTextVisibility(data)
    local iconSizeWM = math.max(iconSize * zoomAdj, 1)   -- 与 Icons.lua 的 OnPinAcquired 保持一致
    if showIcon and ns.Plus and ns.Plus.OnPinAcquired then
        ns.Plus.OnPinAcquired(self, data, iconSize, zoomAdj)
    end

    if showText then
        local hexColor = string.format("|cff%02x%02x%02x", math.floor(cr * 255 + 0.5), math.floor(cg * 255 + 0.5), math.floor(cb * 255 + 0.5))
        self.text:SetText(hexColor .. (data.title or L.MARK_UNNAMED) .. "|r")
        self.text:Show()
    end

    if showIcon and showText and self.icon then
        -- 图标+文本：垂直排列，图标在上、文本在下，两者 X 轴中心对齐。
        local gap = 2 * zoomAdj
        local tw = math.max(self.text:GetStringWidth(), 1)
        local th = math.max(self.text:GetStringHeight(), 1)
        local w = math.max(iconSizeWM, tw) + 8
        local h = iconSizeWM + gap + th + 8
        self.icon:ClearAllPoints()
        self.icon:SetSize(iconSizeWM, iconSizeWM)
        self.icon:SetPoint("TOP", self, "TOP", 0, -4)
        self.text:ClearAllPoints()
        self.text:SetPoint("TOP", self.icon, "BOTTOM", 0, -gap)
        self:SetSize(math.floor(w), math.floor(h))
    elseif showIcon then
        -- 仅图标：显式重设居中锚点。Pin 池化复用时图标可能残留上一轮的 TOP 锚点
        -- （如刚从「图标+文本」切回），不重置会偏移并溢出 Pin 边界。
        if self.icon then
            self.icon:ClearAllPoints()
            self.icon:SetPoint("CENTER", 0, 0)
            self.icon:SetSize(iconSizeWM, iconSizeWM)
        end
        self:SetSize(math.floor(iconSizeWM), math.floor(iconSizeWM))
    else
        -- 仅文本：沿用原有居中文本布局
        self.text:ClearAllPoints()
        self.text:SetPoint("CENTER", 0, 0)
        local sw = math.max(self.text:GetStringWidth(), 10)
        local sh = math.max(self.text:GetStringHeight(), 10)
        self:SetSize(math.floor(sw + 16 * zoomAdj), math.floor(sh + 12 * zoomAdj))
    end

    -- 消除池化 Pin 与新建 Pin 的缩放差：Blizzard_MapCanvas.lua:251-307 的 AcquirePin 不调用
    -- ApplyCurrentScale，OnReleased（MapCanvas_DataProviderBase.lua:203-211）也只做 RemoveAllTags。
    -- zoomLevels 未就绪时（地图刚打开、缩放层未初始化）GetCanvasZoomPercent 会在
    -- MapCanvas_ScrollContainerMixin.lua:696 索引 nil，故用官方守卫 MapCanvasMixin:HasZoomLevels
    -- （Blizzard_MapCanvas.lua:794-796）先行判断。
    -- 依据：MapCanvas_DataProviderBase.lua:444-446、514-528；Blizzard_MapCanvas.lua:769-779 为批量刷新。
    local map = self:GetMap()
    if self.ApplyCurrentScale and map and map.HasZoomLevels and map:HasZoomLevels() then
        self:ApplyCurrentScale()
    else
        -- 地图首次打开时缩放层尚未就绪，本轮 Pin 未应用系统缩放（图标视觉偏小）。
        -- 标记待重刷，等 WorldMapFrame 显示稳定后由下方 OnShow 钩子补一次 ApplyCurrentScale。
        ns._zoomLevelsPendingRefresh = true
    end
end

function adeMapMarkWorldMapPinMixin:OnMouseUp(button) ns.Pin_OnMouseUp(self, button) end
function adeMapMarkWorldMapPinMixin:OnMouseEnter()
    ns.ShowPinHighlight(self, self.data)
    ns.Pin_OnEnter(self)
end
function adeMapMarkWorldMapPinMixin:OnMouseLeave()
    ns.HidePinHighlight(self)
    GameTooltip:Hide()
end

-- ---------------------------------------------------------------------------
-- DataProvider
-- ---------------------------------------------------------------------------

local DataProvider = CreateFromMixins(MapCanvasDataProviderMixin)
_G.adeMapMarkDataProvider = DataProvider
ns.DataProvider = DataProvider

function DataProvider:RemoveAllData()
    if self:GetMap() then self:GetMap():RemoveAllPinsByTemplate(PIN_TEMPLATE) end
end

local refreshQueued = false
function DataProvider:RefreshAllData()
    if not self:GetMap() then return end
    -- 同一帧内的多次刷新合并为一次：回调总是重新读 db.markers / GetProviderMarkers() 的最新值，
    -- 语义等价；避免重复 RemoveAllPinsByTemplate + AcquirePin 造成 Pin 池分配抖动。
    if refreshQueued then return end
    refreshQueued = true
    C_Timer.After(0, function()
        refreshQueued = false
        if not DataProvider:GetMap() then return end
        DataProvider:RemoveAllData()
        local mapID = DataProvider:GetMap():GetMapID()
        if not mapID then return end
        local db = ns.db()
        for i, data in ipairs(db.markers) do
            if data.mapID == mapID and data.isVisible ~= false then
                local x, y = ns.decodeCoord(data.coord)
                DataProvider:GetMap():AcquirePin(PIN_TEMPLATE, i, data, x, y)
            end
        end
        -- 外挂标记：dataIndex 偏移 100000 避免冲突（计划 §2.5）
        for j, data in ipairs(ns:GetProviderMarkers()) do
            if data.mapID == mapID and data.isVisible ~= false then
                local x, y = ns.decodeCoord(data.coord)
                DataProvider:GetMap():AcquirePin(PIN_TEMPLATE, 100000 + j, data, x, y)
            end
        end
    end)
end

function ns.RefreshMapPins()
    if DataProvider:GetMap() then DataProvider:RefreshAllData() end
end

function ns.RefreshAllPins()
    ns.RefreshMapPins()
    if ns.Plus and ns.Plus.RefreshMinimapPins then pcall(ns.Plus.RefreshMinimapPins) end
end

-- ---------------------------------------------------------------------------
-- 收藏列表点击时的 Pin 闪光（保留旧版机制）
-- ---------------------------------------------------------------------------

local pingFrame
function ns.PingPin(data)
    if not data or not DataProvider:GetMap() then return end
    local targetPin
    for pin in DataProvider:GetMap():EnumeratePinsByTemplate(PIN_TEMPLATE) do
        if pin.data and pin.data.mapID == data.mapID and pin.data.coord == data.coord and pin.data.title == data.title then
            targetPin = pin
            break
        end
    end
    if not targetPin then return end

    if not pingFrame then
        pingFrame = CreateFrame("Frame", nil, targetPin)
        pingFrame:SetSize(80, 80)
        pingFrame:SetFrameStrata("TOOLTIP")
        pingFrame.tex = pingFrame:CreateTexture(nil, "OVERLAY")
        pingFrame.tex:SetAtlas("AftLevelup-WhiteStarBurst")
        pingFrame.tex:SetBlendMode("ADD")
        pingFrame.tex:SetAllPoints()
        pingFrame.tex:SetVertexColor(1, 1, 1, 0.6)
        local ag = pingFrame:CreateAnimationGroup()
        -- 对齐旧版 BDmap.lua:1001-1017：两段 Alpha 频闪，无 Scale 补间
        local a1 = ag:CreateAnimation("Alpha")
        a1:SetOrder(1); a1:SetFromAlpha(0); a1:SetToAlpha(1); a1:SetDuration(0.1)
        local a2 = ag:CreateAnimation("Alpha")
        a2:SetOrder(2); a2:SetFromAlpha(1); a2:SetToAlpha(0); a2:SetStartDelay(0.1); a2:SetDuration(0.1)
        ag:SetScript("OnFinished", function() pingFrame:Hide() end)
        pingFrame.anim = ag
    end
    pingFrame:SetParent(targetPin)
    pingFrame:ClearAllPoints()
    pingFrame:SetPoint("CENTER", targetPin, "CENTER")
    pingFrame:Show()
    pingFrame.anim:Stop()
    pingFrame.anim:Play()
end

-- 缩放时重排（旧版经验：ZoomIn/ZoomOut 后视觉尺寸需重算）
ns.RegisterOnAddonLoaded(function()
    local sc = WorldMapFrame and WorldMapFrame.ScrollContainer
    if not sc then return end
    local function refresh()
        C_Timer.After(0, function() ns.RefreshMapPins() end)
    end
    ns.hookScript(sc, "OnZoomChanged", refresh)
    if sc.ZoomIn then ns.hookScript(sc.ZoomIn, "OnClick", refresh) end
    if sc.ZoomOut then ns.hookScript(sc.ZoomOut, "OnClick", refresh) end

    -- 首次打开地图时 OnAcquired 早于缩放层初始化，ApplyCurrentScale 被守卫跳过，
    -- 图标偏小。显示后延迟补一次刷新，让 Pin 按已就绪的缩放层重新渲染。
    -- 只做一次（标志由 OnAcquired 置位），避免每次开关地图都重排。
    ns.hookScript(WorldMapFrame, "OnShow", function()
        if not ns._zoomLevelsPendingRefresh then return end
        C_Timer.After(0.1, function()
            if not ns._zoomLevelsPendingRefresh then return end
            ns._zoomLevelsPendingRefresh = nil
            ns.RefreshMapPins()
        end)
    end)
end)
