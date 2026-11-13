-- adeChatMod — 小地图按钮（PrimeTooltip Minimap.lua 一比一复用规格）。
-- 差异：左键显隐快捷条、右键打开设置界面；图标改用 12.1.5 暴雪内置纹理，不复制第三方美术。
-- 通用小地图图标规格见《_docs/plans/ADE-v6-settings-sys-dev-plan.md》§2.8；adeChatMod 适配见《_docs/plans/adeChatMod-dev-plan.md》§5。
local ACM = _G.adeChatMod
if not ACM then return end
local AF = GetFramework("ade_AddonFramework", true)
if not AF then return end
local L = ACM.L or {}

-- math.atan2 在 12.1.5 有效：_1-2_Lua_API.md:69、Blizzard_ArtifactPerks.lua:513。
-- LuaLS 按标准 Lua 5.4 误报弃用，保留 PT 的老客户端兜底写法。
---@diagnostic disable-next-line: deprecated
local atan2 = math.atan2 or function(y, x) return math.atan(y, x) end
local DEFAULT_ANGLE = ACM.DEFAULTS.settings.minimapAngle

local ICON_FALLBACK = "Interface\\ChatFrame\\UI-ChatIcon-ArmoryChat"
local BG = "Interface\\Minimap\\UI-Minimap-Background"
local HIGHLIGHT = "Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight"
local BORDER = "Interface\\Minimap\\MiniMap-TrackingBorder"

-- 按存档角度定位到小地图圆周（PT Minimap.lua:16-23）。
function ACM:ApplyMinimapPosition()
    local b = self.minimapButton
    if not b or not Minimap then return end
    local angle = math.rad(tonumber(self:Get("minimapAngle")) or DEFAULT_ANGLE)
    local radius = math.max(55, ((Minimap.GetWidth and Minimap:GetWidth()) or 140) / 2 + 5)
    b:ClearAllPoints()
    b:SetPoint("CENTER", Minimap, "CENTER", math.cos(angle) * radius, math.sin(angle) * radius)
end

-- 只读同步：供 ApplyAll() 使用，不写存档、不触发刷新，避免递归。
function ACM:SyncMinimapShown()
    local b = self.minimapButton
    if not b then return end
    if self:Get("minimapShown") then
        self:ApplyMinimapPosition()
        b:Show()
    else
        b:Hide()
    end
end

-- 写存档并同步（PT Minimap.lua:25-32）。
function ACM:SetMinimapShown(shown)
    self:Set("minimapShown", shown and true or false)
    self:SyncMinimapShown()
    if self.RefreshOptions then self:RefreshOptions() end
end

function ACM:ToggleMinimap()
    local shown = not self:Get("minimapShown")
    self:SetMinimapShown(shown)
    self:Print(shown and (L.MSG_MINIMAP_SHOWN or "minimap button shown.")
                      or (L.MSG_MINIMAP_HIDDEN or "minimap button hidden. Type /acm minimap to show it again."))
end

function ACM:ResetMinimapPosition()
    self:Set("minimapAngle", DEFAULT_ANGLE)
    self:ApplyMinimapPosition()
end

function ACM:CreateMinimapButton()
    if self.minimapButton or not Minimap then return end
    local b = CreateFrame("Button", "adeChatModMinimapButton", Minimap)
    self.minimapButton = b
    b:SetSize(31, 31)
    b:SetFrameStrata("MEDIUM")
    b:SetFrameLevel((Minimap.GetFrameLevel and Minimap:GetFrameLevel() or 1) + 8)
    b:EnableMouse(true)
    b:RegisterForDrag("LeftButton")
    b:RegisterForClicks("LeftButtonUp", "RightButtonUp")

    -- 拖拽期间才挂 OnUpdate，结束时移除（PT Minimap.lua:50-61）。
    local function Follow()
        local cx, cy = GetCursorPosition()
        local scale = UIParent and UIParent:GetEffectiveScale() or 1
        local mx, my = Minimap:GetCenter()
        if not cx or not cy or not mx or not my or not scale or scale == 0 then return end
        local deg = math.deg(atan2((cy / scale) - my, (cx / scale) - mx))
        ACM:Set("minimapAngle", math.floor((deg % 360) + 0.5))
        ACM:ApplyMinimapPosition()
    end
    b:SetScript("OnDragStart", function(selfButton) selfButton:SetScript("OnUpdate", Follow); Follow() end)
    b:SetScript("OnDragStop", function(selfButton) Follow(); selfButton:SetScript("OnUpdate", nil) end)

    -- 左键显隐快捷条；右键打开设置界面。
    b:SetScript("OnClick", function(_, mouseButton)
        if mouseButton == "LeftButton" then
            ACM:ToggleBar()
        elseif mouseButton == "RightButton" then
            if GameTooltip and GameTooltip:GetOwner() == b then GameTooltip:Hide() end
            ACM:ToggleOptions()
        end
    end)

    b:SetScript("OnEnter", function(selfButton)
        if not GameTooltip then return end
        GameTooltip:SetOwner(selfButton, "ANCHOR_LEFT")
        GameTooltip:ClearLines()
        local ar, ag, ab = AF.Color("accent")
        GameTooltip:AddLine(L.ADDON_TITLE or "adeChatMod", ar, ag, ab)
        GameTooltip:AddLine(L.TT_LEFT or "Left-click: show/hide the channel bar", 1, 1, 1)
        GameTooltip:AddLine(L.TT_RIGHT or "Right-click: open settings", 1, 1, 1)
        GameTooltip:AddLine(L.TT_DRAG or "Drag to reposition", 0.75, 0.75, 0.75)
        GameTooltip:Show()
    end)
    b:SetScript("OnLeave", function() if GameTooltip then GameTooltip:Hide() end end)

    b.background = b:CreateTexture(nil, "BACKGROUND")
    b.background:SetTexture(BG)
    b.background:SetSize(24, 24)
    b.background:SetPoint("CENTER")
    -- 中心图标取自 TOC 的 ## IconTexture / ## IconAtlas（规划 §3.5：统一由 C_AddOns.GetAddOnMetadata 读取，禁止硬编码贴图路径）。
    local iconAtlas = C_AddOns and C_AddOns.GetAddOnMetadata and C_AddOns.GetAddOnMetadata(ACM.name, "IconAtlas")
    local iconTexture = C_AddOns and C_AddOns.GetAddOnMetadata and C_AddOns.GetAddOnMetadata(ACM.name, "IconTexture")
    b.icon = b:CreateTexture(nil, "ARTWORK")
    b.icon:SetSize(20, 20)
    b.icon:SetPoint("CENTER")
    b.icon:SetTexCoord(0, 1, 0, 1)
    if iconAtlas then
        b.icon:SetAtlas(iconAtlas)
    else
        b.icon:SetTexture(iconTexture or ICON_FALLBACK)
    end
    b:SetHighlightTexture(HIGHLIGHT)
    b.border = b:CreateTexture(nil, "OVERLAY")
    b.border:SetTexture(BORDER)
    b.border:SetSize(53, 53)
    b.border:SetPoint("TOPLEFT", 0, 0)

    self:ApplyMinimapPosition()
    self:SyncMinimapShown()
end
