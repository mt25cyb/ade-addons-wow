-- adeTooltip — 小地图按钮（复用 adeChatMod / PrimeTooltip 规格）。
-- 左键/右键打开设置界面；图标取自 TOC 元数据，缺省回退暴雪内置纹理。
local ADT = _G.adeTooltip
if not ADT then return end
local AF = GetFramework("ade_AddonFramework", true, "adeTooltip")
if not AF then return end
local L = ADT.L or {}

---@diagnostic disable-next-line: deprecated
local atan2 = math.atan2 or function(y, x) return math.atan(y, x) end
local DEFAULT_ANGLE = ADT.DEFAULTS.settings.minimapAngle

local ICON_FALLBACK = "Interface\\ChatFrame\\UI-ChatIcon-ArmoryChat"
local BG = "Interface\\Minimap\\UI-Minimap-Background"
local HIGHLIGHT = "Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight"
local BORDER = "Interface\\Minimap\\MiniMap-TrackingBorder"

function ADT:ApplyMinimapPosition()
    local b = self.minimapButton
    if not b or not Minimap then return end
    local angle = math.rad(tonumber(self:Get("minimapAngle")) or DEFAULT_ANGLE)
    local radius = math.max(55, ((Minimap.GetWidth and Minimap:GetWidth()) or 140) / 2 + 5)
    b:ClearAllPoints()
    b:SetPoint("CENTER", Minimap, "CENTER", math.cos(angle) * radius, math.sin(angle) * radius)
end

-- 只读同步：供 ApplyAll() 使用，不写存档、不触发刷新，避免递归。
function ADT:SyncMinimapShown()
    local b = self.minimapButton
    if not b then return end
    if self:Get("minimapShown") then
        self:ApplyMinimapPosition()
        b:Show()
    else
        b:Hide()
    end
end

-- 写存档并同步（链路：Checkbox onChange → SetMinimapShown → state → b:Hide）。
function ADT:SetMinimapShown(shown)
    self:Set("minimapShown", shown and true or false)
    self:SyncMinimapShown()
    if self.RefreshOptions then self:RefreshOptions() end
end

function ADT:ToggleMinimap()
    local shown = not self:Get("minimapShown")
    self:SetMinimapShown(shown)
    self:Print(shown and (L.MSG_MINIMAP_SHOWN or "minimap button shown.")
                      or (L.MSG_MINIMAP_HIDDEN or "minimap button hidden. Type /adt minimap to show it again."))
end

function ADT:ResetMinimapPosition()
    self:Set("minimapAngle", DEFAULT_ANGLE)
    self:ApplyMinimapPosition()
end

function ADT:CreateMinimapButton()
    if self.minimapButton or not Minimap then return end
    local b = CreateFrame("Button", "adeTooltipMinimapButton", Minimap)
    self.minimapButton = b
    b:SetSize(31, 31)
    b:SetFrameStrata("MEDIUM")
    b:SetFrameLevel((Minimap.GetFrameLevel and Minimap:GetFrameLevel() or 1) + 8)
    b:EnableMouse(true)
    b:RegisterForDrag("LeftButton")
    b:RegisterForClicks("LeftButtonUp", "RightButtonUp")

    local function Follow()
        local cx, cy = GetCursorPosition()
        local scale = UIParent and UIParent:GetEffectiveScale() or 1
        local mx, my = Minimap:GetCenter()
        if not cx or not cy or not mx or not my or not scale or scale == 0 then return end
        local deg = math.deg(atan2((cy / scale) - my, (cx / scale) - mx))
        ADT:Set("minimapAngle", math.floor((deg % 360) + 0.5))
        ADT:ApplyMinimapPosition()
    end
    b:SetScript("OnDragStart", function(selfButton) selfButton:SetScript("OnUpdate", Follow); Follow() end)
    b:SetScript("OnDragStop", function(selfButton) Follow(); selfButton:SetScript("OnUpdate", nil) end)

    -- 左键/右键均打开设置界面。
    b:SetScript("OnClick", function(_, mouseButton)
        if GameTooltip and GameTooltip:GetOwner() == b then GameTooltip:Hide() end
        ADT:ToggleOptions()
    end)

    b:SetScript("OnEnter", function(selfButton)
        if not GameTooltip then return end
        GameTooltip:SetOwner(selfButton, "ANCHOR_LEFT")
        GameTooltip:ClearLines()
        local ar, ag, ab = AF.Color("accent")
        GameTooltip:AddLine(L.ADDON_TITLE or "adeTooltip", ar, ag, ab)
        GameTooltip:AddLine(L.TAB_SETTINGS or "Settings", 1, 1, 1)
        GameTooltip:AddLine(L.TAB_MINIMAP or "Minimap", 1, 1, 1)
        GameTooltip:Show()
    end)
    b:SetScript("OnLeave", function() if GameTooltip then GameTooltip:Hide() end end)

    b.background = b:CreateTexture(nil, "BACKGROUND")
    b.background:SetTexture(BG)
    b.background:SetSize(24, 24)
    b.background:SetPoint("CENTER")
    local iconAtlas = C_AddOns and C_AddOns.GetAddOnMetadata and C_AddOns.GetAddOnMetadata(ADT.name, "IconAtlas")
    local iconTexture = C_AddOns and C_AddOns.GetAddOnMetadata and C_AddOns.GetAddOnMetadata(ADT.name, "IconTexture")
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
