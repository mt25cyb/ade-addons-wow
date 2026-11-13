-- 小地图按钮：角度存档、拖动阈值。底本 z-ref_retail_Interface_AddOns/MiliUI_BossTimeline/Libs/MiliUIMinimapButton.lua
local AF = ResolveNamespace("ade_AddonFramework")
if not AF then return end
AF.Widget = AF.Widget or {}
local W = {}
AF.Widget.MinimapButton = W

function W.Create(opts)
    opts = opts or {}
    if not Minimap then return nil end
    local b = CreateFrame("Button", "AF_MinimapButton_" .. tostring(opts.key or "default"), Minimap)
    b:SetSize(31, 31)
    b:SetFrameStrata("MEDIUM")
    local border = b:CreateTexture(nil, "OVERLAY")
    border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
    border:SetSize(54, 54)
    border:SetPoint("CENTER", 11, -11)
    local icon = b:CreateTexture(nil, "ARTWORK")
    icon:SetSize(20, 20)
    icon:SetPoint("CENTER")
    AF.ResolveIcon(icon, opts.icon or { atlas = "GM-icon-settings" }, opts)
    b.icon = icon

    local angle = opts.angle or 225
    local function Place()
        local r = math.rad(angle)
        local radius = (Minimap:GetWidth() / 2) + 5
        b:SetPoint("CENTER", Minimap, "CENTER", math.cos(r) * radius, math.sin(r) * radius)
    end
    Place()

    local dragging, startX, startY
    b:SetScript("OnMouseDown", function(_, button)
        if button ~= "LeftButton" then return end
        startX, startY = GetCursorPosition(); dragging = false
    end)
    b:SetScript("OnUpdate", function()
        if not startX then return end
        local x, y = GetCursorPosition()
        if not dragging and (math.abs(x - startX) + math.abs(y - startY)) > 4 then dragging = true end
        if dragging then
            local cx, cy = Minimap:GetCenter()
            local dx, dy = x / (UIParent:GetEffectiveScale() or 1) - cx, y / (UIParent:GetEffectiveScale() or 1) - cy
            angle = math.deg(math.atan2 and math.atan2(dy, dx) or math.atan(dy / (dx == 0 and 1 or dx)))
            Place()
        end
    end)
    b:SetScript("OnMouseUp", function(_, button)
        if button == "LeftButton" and not dragging and opts.onClick then opts.onClick(button) end
        startX, startY, dragging = nil, nil, false
        if opts.onAngleChanged then opts.onAngleChanged(angle) end
    end)
    if opts.tooltip then
        b:SetScript("OnEnter", function()
            GameTooltip:SetOwner(b, "ANCHOR_LEFT")
            GameTooltip:SetText(opts.tooltip, 1, 1, 1, 1, true)
            GameTooltip:Show()
        end)
        b:SetScript("OnLeave", function() GameTooltip:Hide() end)
    end
    return b
end
