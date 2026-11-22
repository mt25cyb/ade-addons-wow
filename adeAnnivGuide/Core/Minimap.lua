--[==[ adeAnnivGuide / Core/Minimap.lua — 自绘小地图按钮（零依赖内联）
    逻辑逐字对齐 ade_UIKit/Widget/MinimapButton.lua:18-143（其底本 adeChatBar/Minimap.lua）：
    角度定位 / OnUpdate 拖拽跟随 / 点击 / GameTooltip / 背景-图标-边框-高亮四层纹理装配。
    本插件无库依赖，按需精简：仅贴图路径图标、仅左键（拖拽注册同键，拖动不误触点击）；
    存档读写仍由宿主 Main 委托（本模块不碰 settings）。 ]==]
local ns = _G.adeAnnivGuide

local DEFAULT_BACKGROUND = "Interface\\Minimap\\UI-Minimap-Background"
local DEFAULT_BORDER = "Interface\\Minimap\\MiniMap-TrackingBorder"
local DEFAULT_HIGHLIGHT = "Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight"
local DEFAULT_ANGLE = 200

local atan2 = math.atan2 or function(y, x) return math.atan(y, x) end

local function AngleFromCursor()
    if not GetCursorPosition or not Minimap then return nil end
    local cx, cy = GetCursorPosition()
    local scale = UIParent and UIParent:GetEffectiveScale() or 1
    local mx, my = Minimap:GetCenter()
    if not cx or not cy or not mx or not my or scale == 0 then return nil end
    return math.floor(math.deg(atan2((cy / scale) - my, (cx / scale) - mx)) % 360 + 0.5)
end

local function ApplyPosition(btn)
    if not Minimap then return end
    local a = math.rad(btn.angle or DEFAULT_ANGLE)
    local r = math.max(55, ((Minimap.GetWidth and Minimap:GetWidth()) or 140) / 2 + 5)
    btn:ClearAllPoints()
    btn:SetPoint("CENTER", Minimap, "CENTER", math.cos(a) * r, math.sin(a) * r)
end

--- 创建小地图按钮。
-- opts: name / icon（贴图路径）/ angle / onClick(btn, mouseButton) /
--       onAngleChanged(angle) / tooltip = { title, lines }。
function ns.CreateMinimapButton(opts)
    opts = opts or {}
    if not Minimap then return nil end
    local name = opts.name or "adeAnnivGuideMinimapButton"
    if _G[name] then return _G[name] end

    local btn = CreateFrame("Button", name, Minimap)
    btn:SetSize(31, 31)
    btn:SetFrameStrata("MEDIUM")
    btn:SetFrameLevel((Minimap.GetFrameLevel and Minimap:GetFrameLevel() or 1) + 8)
    btn:EnableMouse(true)
    btn:RegisterForDrag("LeftButton")
    btn:RegisterForClicks("LeftButtonUp")

    btn.angle = math.floor((tonumber(opts.angle) or DEFAULT_ANGLE) % 360 + 0.5)
    btn.onClick = opts.onClick
    btn.onAngleChanged = opts.onAngleChanged
    btn.accent = { ns.THEME.r, ns.THEME.g, ns.THEME.b }

    local function SetAngle(angle)
        btn.angle = math.floor((tonumber(angle) or DEFAULT_ANGLE) % 360 + 0.5)
        ApplyPosition(btn)
        if btn.onAngleChanged then btn.onAngleChanged(btn.angle) end
    end

    local function Follow()
        local deg = AngleFromCursor()
        if deg then SetAngle(deg) end
    end
    btn:SetScript("OnDragStart", function()
        btn:SetScript("OnUpdate", Follow)
        Follow()
    end)
    btn:SetScript("OnDragStop", function()
        Follow()
        btn:SetScript("OnUpdate", nil)
    end)

    btn:SetScript("OnClick", function(_, mouseButton)
        if btn.onClick then btn.onClick(btn, mouseButton) end
    end)

    btn:SetScript("OnEnter", function(self)
        if not GameTooltip or not opts.tooltip then return end
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:ClearLines()
        if opts.tooltip.title then
            GameTooltip:AddLine(opts.tooltip.title, btn.accent[1], btn.accent[2], btn.accent[3])
        end
        for _, line in ipairs(opts.tooltip.lines or {}) do
            if type(line) == "string" then
                GameTooltip:AddLine(line, 1, 1, 1)
            end
        end
        GameTooltip:Show()
    end)
    btn:SetScript("OnLeave", function()
        if GameTooltip then GameTooltip:Hide() end
    end)

    btn.background = btn:CreateTexture(nil, "BACKGROUND")
    btn.background:SetTexture(DEFAULT_BACKGROUND)
    btn.background:SetSize(24, 24)
    btn.background:SetPoint("CENTER")

    btn.icon = btn:CreateTexture(nil, "ARTWORK")
    btn.icon:SetTexture(opts.icon)
    btn.icon:SetSize(20, 20)
    btn.icon:SetPoint("CENTER")

    btn:SetHighlightTexture(DEFAULT_HIGHLIGHT)
    btn.border = btn:CreateTexture(nil, "OVERLAY")
    btn.border:SetTexture(DEFAULT_BORDER)
    btn.border:SetSize(53, 53)
    btn.border:SetPoint("TOPLEFT", 0, 0)

    ApplyPosition(btn)
    btn:Show()
    return btn
end
