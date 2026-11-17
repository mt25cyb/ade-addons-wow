-- adeChatBar — 小地图按钮（PrimeTooltip Minimap.lua 规格）。
-- 左键显隐快捷条、右键打开 BOF 设置界面；主题色固定 ADE #EEE4AE，无 AF 依赖。
local ACB = _G.adeChatBar
if not ACB then return end
local L = ACB.L or {}

---@diagnostic disable-next-line: deprecated
local atan2 = math.atan2 or function(y, x) return math.atan(y, x) end
local DEFAULT_ANGLE = ACB.DEFAULTS.state.minimapAngle
local ACCENT = { 238 / 255, 228 / 255, 174 / 255 }

local ICON_FALLBACK = "Interface\\ChatFrame\\UI-ChatIcon-ArmoryChat"
local BG = "Interface\\Minimap\\UI-Minimap-Background"
local HIGHLIGHT = "Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight"
local BORDER = "Interface\\Minimap\\MiniMap-TrackingBorder"

function ACB:ApplyMinimapPosition()
    local b = self.minimapButton
    if not b or not Minimap then return end
    local angle = math.rad(tonumber(self:Get("minimapAngle")) or DEFAULT_ANGLE)
    local radius = math.max(55, ((Minimap.GetWidth and Minimap:GetWidth()) or 140) / 2 + 5)
    b:ClearAllPoints()
    b:SetPoint("CENTER", Minimap, "CENTER", math.cos(angle) * radius, math.sin(angle) * radius)
end

function ACB:SyncMinimapShown()
    local b = self.minimapButton
    if not b then return end
    if self:Get("minimapShown") then
        self:ApplyMinimapPosition()
        b:Show()
    else
        b:Hide()
    end
end

function ACB:SetMinimapShown(shown)
    self:Set("minimapShown", shown and true or false)
    self:SyncMinimapShown()
    if self.RefreshOptions then self:RefreshOptions() end
end

function ACB:ToggleMinimap()
    local shown = not self:Get("minimapShown")
    self:SetMinimapShown(shown)
    self:Print(shown and (L.MSG_MINIMAP_SHOWN or "minimap button shown.")
                      or (L.MSG_MINIMAP_HIDDEN or "minimap button hidden."))
end

function ACB:ResetMinimapPosition()
    self:Set("minimapAngle", DEFAULT_ANGLE)
    self:ApplyMinimapPosition()
end

function ACB:CreateMinimapButton()
    if self.minimapButton or not Minimap then return end
    local b = CreateFrame("Button", "adeChatBarMinimapButton", Minimap)
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
        ACB:Set("minimapAngle", math.floor((deg % 360) + 0.5))
        ACB:ApplyMinimapPosition()
    end
    b:SetScript("OnDragStart", function(selfButton) selfButton:SetScript("OnUpdate", Follow); Follow() end)
    b:SetScript("OnDragStop", function(selfButton) Follow(); selfButton:SetScript("OnUpdate", nil) end)

    b:SetScript("OnClick", function(_, mouseButton)
        if mouseButton == "LeftButton" then
            ACB:ToggleBar()
        elseif mouseButton == "RightButton" then
            if GameTooltip and GameTooltip:GetOwner() == b then GameTooltip:Hide() end
            ACB:ToggleOptions()
        end
    end)

    b:SetScript("OnEnter", function(selfButton)
        if not GameTooltip then return end
        GameTooltip:SetOwner(selfButton, "ANCHOR_LEFT")
        GameTooltip:ClearLines()
        GameTooltip:AddLine(L.ADDON_TITLE or "adeChatBar", ACCENT[1], ACCENT[2], ACCENT[3])
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
    local iconAtlas = C_AddOns and C_AddOns.GetAddOnMetadata and C_AddOns.GetAddOnMetadata(ACB.name, "IconAtlas")
    local iconTexture = C_AddOns and C_AddOns.GetAddOnMetadata and C_AddOns.GetAddOnMetadata(ACB.name, "IconTexture")
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
