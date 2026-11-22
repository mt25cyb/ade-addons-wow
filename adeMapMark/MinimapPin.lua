--[[
adeMapMark - MinimapPin（小地图 Pin / 玩家箭头 / 小地图选项）
体系：ADE v6.5；来源 BDmapPlus.lua 小地图段（923-1200）
--]]

local addonName = ...
local ns = _G.adeMapMark
local L = ns.L
local ICON_DIR = "Interface\\AddOns\\" .. addonName .. "\\Art\\CustomICON\\"

-- ============================================================================
-- [B] 小地图显示功能（含图标/文字渲染）
--     包含：Pin 渲染钩子、Pin 池管理、刷新/更新、玩家箭头、选项面板
-- ============================================================================

local HBDPins = LibStub and LibStub("HereBeDragons-Pins-2.0", true)

local minimapActivePins    = {}
local minimapPinPool       = {}
local minimapPinByData     = {}
local MAX_MINIMAP_PIN_POOL = 50
local MINIMAP_MIN_SIZE     = 80

-- ── B.1 小地图图标渲染 ───────────────────────────────────────────────────────

local function ApplyMinimapPinIcon(pin, data, db)
    if not data.icon then
        if pin.icon then pin.icon:Hide() end
        return false
    end
    if not pin.icon then
        pin.icon = pin:CreateTexture(nil, "ARTWORK")
        pin.icon:SetAllPoints()
        if pin.icon.SetSnapToPixelGrid then
            pin.icon:SetSnapToPixelGrid(false)
            pin.icon:SetTexelSnappingBias(0)
        end
    end
    local mmSize     = math.max(data.size or db.settings.lastSize, MINIMAP_MIN_SIZE)
    local iconSizeMM = math.floor(mmSize * 0.24 / 2) * 2  -- 小地图图标标记尺寸
    pin.text:Hide()
    pin.icon:Show()
    ns.ApplyIconTexture(pin.icon, data.icon, data.iconCrop)
    pin.icon:SetVertexColor(1, 1, 1)
    pin.icon:SetAlpha(data.color.a or 1)
    pin.icon:SetDesaturated(data.isGrayscale == true)
    pin.icon:SetRotation(-math.rad(data.iconRotation or 0))
    pin:SetSize(iconSizeMM, iconSizeMM)
    return true
end

-- ── B.2 小地图文字渲染 ────────────────────────────────────────────────────────

local function ApplyMinimapPinText(pin, data, db, fontPath, outline)
    local mmSize     = math.max(data.size or db.settings.lastSize, MINIMAP_MIN_SIZE)
    local fontSizeMM = math.floor((mmSize * 0.2) + 0.5)   -- 小地图文字标记尺寸
    local tC         = data.color or { r = 0.2, g = 1, b = 0.73 }
    local tr, tg, tb = tC.r, tC.g, tC.b
    if data.isGrayscale then
        local lum = tr * 0.299 + tg * 0.587 + tb * 0.114
        tr, tg, tb = lum, lum, lum
    end
    local hexColor   = string.format("|cff%02x%02x%02x", tr*255, tg*255, tb*255)
    pin.text:Show()
    pin.text:SetFont(fontPath, fontSizeMM, outline)
    pin.text:SetText(hexColor .. (data.title or L.MARK_UNNAMED) .. "|r")
    pin.text:SetAlpha(tC.a or 1)
    local tboxW = math.floor((pin.text:GetStringWidth()  + 10) / 2) * 2
    local tboxH = math.floor((pin.text:GetStringHeight() + 10) / 2) * 2
    pin:SetSize(tboxW, tboxH)
end

-- ── B.1~2 旋转小地图图标标记 ─────────────────────────────────────────────────

function ns.Plus.ApplyRotToMinimap(data, angle)
    local pin = minimapPinByData[data]
    if pin and pin.icon then
        pin.icon:SetRotation(-angle)
        ns.ApplyIconTexCoord(pin.icon, data.icon, data.iconCrop)
    end
end

-- ── B.3 Pin 池管理 ────────────────────────────────────────────────────────────

local function GetMinimapPinFromPool()
    local pin = tremove(minimapPinPool)
    if not pin then
        pin = CreateFrame("Button", nil, Minimap)
        pin:SetFrameStrata("MEDIUM")
        pin.text = pin:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        pin.text:SetPoint("CENTER")
        pin.text:SetShadowOffset(0, 0)
        if pin.text.SetSnapToPixelGrid then
            pin.text:SetSnapToPixelGrid(false)
        end
        -- 事件绑定在创建时做一次，复用后不需要重绑
        pin:SetScript("OnMouseUp", ns.Pin_OnMouseUp)
        pin:SetScript("OnEnter", function(self)
            local data = self.data
            if not data then return end
            if ns.Plus.OnPinEnter(self, data) then return end
            local hasTitle = data.title and data.title:trim() ~= ""
            local hasNote  = data.note  and data.note:trim()  ~= ""
            if hasTitle and not hasNote and not data.icon then return end

            local c        = data.color or { r = 0.2, g = 1, b = 0.73 }
            local hexColor = string.format("|cff%02x%02x%02x", c.r*255, c.g*255, c.b*255)
            GameTooltip:SetOwner(self, "ANCHOR_CURSOR_RIGHT")
            if hasTitle then GameTooltip:SetText(hexColor .. data.title .. "|r") end
            if hasNote  then GameTooltip:AddLine(data.note, 1, 1, 1, false)     end
            GameTooltip:Show()
        end)
        
        pin:SetScript("OnLeave", function(self)
        GameTooltip:Hide()
        end)
    else
        pin:SetParent(Minimap)
        pin:SetAlpha(1)
        pin.data      = nil
        pin.dataIndex = nil
    end
    return pin
end

-- ── B.4 全局刷新与单条更新 ───────────────────────────────────────────────────

local function RecycleAllPins()
    wipe(minimapPinByData)
    for _, pin in ipairs(minimapActivePins) do
        pin:Hide()
        if #minimapPinPool < MAX_MINIMAP_PIN_POOL then
            tinsert(minimapPinPool, pin)
        else
            pin:SetParent(nil)
        end
    end
    wipe(minimapActivePins)
end

function ns.Plus.RefreshMinimapPins()
    local db = _G["adeMapMarkDB"]
    if not db then return end
    RecycleAllPins()
    if not db.settings.showMinimapMarkers then
        if HBDPins then HBDPins:RemoveAllMinimapIcons("adeMapMark") end
        return
    end
    if not HBDPins then return end
    local mapID = C_Map.GetBestMapForUnit("player")
    if not mapID or not Minimap:IsVisible() then return end
    local fontPath = ChatFontNormal:GetFont()
    HBDPins:RemoveAllMinimapIcons("adeMapMark")

    -- 本地标记与外挂标记的生成流程一致，仅数据来源与 dataIndex 偏移不同
    local function SpawnPin(data, index)
        local x, y = ns.decodeCoord(data.coord)
        local pin = GetMinimapPinFromPool()
        pin.data               = data
        pin.dataIndex          = index
        minimapPinByData[data] = pin    -- 写入查找表
        if not ApplyMinimapPinIcon(pin, data, db) then
            ApplyMinimapPinText(pin, data, db, fontPath, "OUTLINE")
        end
        pin:Show()
        tinsert(minimapActivePins, pin)
        HBDPins:AddMinimapIconMap("adeMapMark", pin, mapID, x, y, true)
    end

    for i, data in ipairs(db.markers) do
        if data.mapID == mapID and data.isVisible ~= false then SpawnPin(data, i) end
    end
    -- 外挂坐标包（小地图，只读；dataIndex 加 100000 与本地标记区分开）
    local ext = ns:GetProviderMarkers()
    for j, data in ipairs(ext) do
        if data.mapID == mapID and data.isVisible ~= false then SpawnPin(data, 100000 + j) end
    end
end

function ns.Plus.UpdateMinimapPinStyle(index)
    if not HBDPins then return end
    local mapID = C_Map.GetBestMapForUnit("player")
    if not mapID then return end
    local targetPin = nil
    for _, pin in ipairs(minimapActivePins) do
        if pin.dataIndex == index then
            targetPin = pin
            break
        end
    end
    if not targetPin then return end
    local data = targetPin.data
    if not data or data.mapID ~= mapID then return end
    local db       = _G["adeMapMarkDB"]
    local fontPath = ChatFontNormal:GetFont()
    if not ApplyMinimapPinIcon(targetPin, data, db) then
        ApplyMinimapPinText(targetPin, data, db, fontPath, "OUTLINE")
    end
end

-- ── B.5 玩家箭头 ─────────────────────────────────────────────────────────────

local SPACER = [[Interface\Common\Spacer]]

local function CreateFakeArrow()
    local arrow = CreateFrame("Frame", "adeMapMark_MinimapArrow", Minimap)
    arrow:SetFrameStrata("HIGH")
    arrow:SetPoint("CENTER")
    arrow:SetSize(10, 10)

    arrow.texture = arrow:CreateTexture(nil, "OVERLAY")
    arrow.texture:SetAtlas("UI-HUD-Minimap-Arrow-Player", true)
    arrow.texture:SetScale(0.9)
    arrow.texture:SetPoint("CENTER")
    arrow.texture:SetTexelSnappingBias(0)
    arrow.texture:SetSnapToPixelGrid(false)

    arrow.facing = "none"
    arrow:SetScript("OnUpdate", function(self)
        if GetCVar("rotateMinimap") == "1" then
            arrow.texture:SetRotation(0)
            return
        end
        local facing = GetPlayerFacing()
        if facing == self.facing then return end
        if facing then
            -- 从禁止区回到正常区：重新隐藏原生箭头
            if self.facing == nil then
                Minimap:SetPlayerTexture(SPACER)
            end
            self.facing = facing
            arrow.texture:SetRotation(facing)
            arrow.texture:Show()
        else
            -- 暴雪禁止区（副本等）：用高清备用贴图还原原生箭头，隐藏插件版
            Minimap:SetPlayerTexture(ICON_DIR .. "MinimapArrow2x.png")
            self.facing = nil
            arrow.texture:Hide()
        end
    end)

    arrow:Show()
    return arrow
end

-- ── B.6 初始化（PLAYER_LOGIN）────────────────────────────────────────────────

local initFrame = CreateFrame("Frame")
initFrame:RegisterEvent("PLAYER_LOGIN")
initFrame:SetScript("OnEvent", function(self)
    self:UnregisterEvent("PLAYER_LOGIN")
    local db = _G["adeMapMarkDB"]
    if not db or not db.settings then return end
    -- 根据开关状态决定是否启用插件版玩家箭头
    if not db.settings.useHandyArrow then return end
    Minimap:SetPlayerTexture(SPACER)
    CreateFakeArrow()
end)

-- ── B.7 小地图选项面板 ───────────────────────────────────────────────────────

function ns.Plus.SetupMinimapOptions(optionsPanel, anchorFrame)
    local db = _G["adeMapMarkDB"]
    if not db or not db.settings then return anchorFrame end

    -- 标记显示开关
    local minimapShowCheck = CreateFrame("CheckButton", "adeMapMark_MinimapShowCheck", optionsPanel, "InterfaceOptionsCheckButtonTemplate")
    minimapShowCheck:SetSize(32, 32)
    minimapShowCheck:SetPoint("TOPLEFT", anchorFrame, "BOTTOMLEFT", 0, -5)
    minimapShowCheck.Text:SetText(L.SETTINGS_MINIMAP)
    minimapShowCheck:SetChecked(db.settings.showMinimapMarkers)
    minimapShowCheck:SetScript("OnClick", function(self)
        db.settings.showMinimapMarkers = self:GetChecked()
        ns.Plus.RefreshMinimapPins()
    end)

    -- 玩家箭头开关
    local arrowCheck = CreateFrame("CheckButton", "adeMapMark_HandyArrowCheck", optionsPanel, "InterfaceOptionsCheckButtonTemplate")
    arrowCheck:SetSize(32, 32)
    arrowCheck:SetPoint("LEFT", minimapShowCheck.Text, "RIGHT", 40, 0)
    arrowCheck.Text:SetText(L.MINIMAP_ARROW_CHECK)
    arrowCheck:SetChecked(db.settings.useHandyArrow)
    arrowCheck:SetScript("OnClick", function(self)
        db.settings.useHandyArrow = self:GetChecked()
        ReloadUI()
    end)

    return minimapShowCheck
end
