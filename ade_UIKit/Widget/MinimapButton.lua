------------------------------------------------------------
-- 自绘小地图按钮工厂（零第三方依赖）。
-- 底本：adeChatBar/Minimap.lua:17-121（角度定位/拖拽/点击/tooltip/纹理装配）；
--       ade_apis/Widget/MinimapButton.lua:8-20、50-63（角度换算与 SetIcon/SetAngle 方法）；
--       AF/Widget/MinimapButton.lua:21-60（默认 atlas 与 tooltip）。
-- 本模块只创建按钮与暴露方法，不读写宿主存档；显隐由 opts.getShown / opts.setShown 委托。
------------------------------------------------------------
local lib = ResolveBOFNamespace("ade_UIKit")
if not lib then return end

local DEFAULT_BACKGROUND = "Interface\\Minimap\\UI-Minimap-Background"
local DEFAULT_BORDER = "Interface\\Minimap\\MiniMap-TrackingBorder"
local DEFAULT_HIGHLIGHT = "Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight"
local DEFAULT_ANGLE = 200

local atan2 = math.atan2 or function(y, x) return math.atan(y, x) end

function lib.AngleFromCursor(frame)
    if not GetCursorPosition or not Minimap or not Minimap.GetCenter then return nil end
    local cx, cy = GetCursorPosition()
    local scale = UIParent and UIParent:GetEffectiveScale() or 1
    local mx, my = Minimap:GetCenter()
    if not cx or not cy or not mx or not my or not scale or scale == 0 then return nil end
    local deg = math.floor(math.deg(atan2((cy / scale) - my, (cx / scale) - mx)) % 360 + 0.5)
    return deg
end

function lib.ApplyMinimapPosition(button, angle, radius)
    if not button or not Minimap then return end
    local a = math.rad(tonumber(angle) or DEFAULT_ANGLE)
    local r = radius or math.max(55, ((Minimap.GetWidth and Minimap:GetWidth()) or 140) / 2 + 5)
    button:ClearAllPoints()
    button:SetPoint("CENTER", Minimap, "CENTER", math.cos(a) * r, math.sin(a) * r)
end

function lib.SetMinimapButtonShown(button, shown)
    if not button then return end
    if shown then
        button:ApplyMinimapPosition()
        button:Show()
    else
        button:Hide()
    end
end

--- 创建自绘小地图按钮。
-- opts: name, parent, size, angle, radius, icon, iconSize, background, border, highlight,
--       onClick(btn, mouseButton), onAngleChanged(angle), tooltip, getShown(), setShown(shown), accent={r,g,b}
-- icon 三态：FileID(number) / 贴图路径(string) / {atlas=...}|{texture=...}|{fileID=...}，
-- 推荐 icon = lib.GetAddonMeta(addonName).icon（IconTexture 优先于 IconAtlas，b024）。
function lib.CreateMinimapButton(opts)
    opts = opts or {}
    if not Minimap then return nil end
    local name = opts.name or "AdeUIMinimapButton"
    if _G[name] then return _G[name] end

    local size = opts.size or 31
    local btn = CreateFrame("Button", name, opts.parent or Minimap)
    btn:SetSize(size, size)
    btn:SetFrameStrata("MEDIUM")
    btn:SetFrameLevel((Minimap.GetFrameLevel and Minimap:GetFrameLevel() or 1) + 8)
    btn:EnableMouse(true)
    btn:RegisterForDrag("LeftButton")
    btn:RegisterForClicks("LeftButtonUp", "RightButtonUp")

    btn.angle = tonumber(opts.angle) or DEFAULT_ANGLE
    btn.radius = opts.radius
    btn.onClick = opts.onClick
    btn.onAngleChanged = opts.onAngleChanged
    btn.getShown = opts.getShown
    btn.setShown = opts.setShown
    btn.tooltipSpec = opts.tooltip
    btn.accent = opts.accent or { 238 / 255, 228 / 255, 174 / 255 }

    function btn:SetAngle(angle)
        self.angle = math.floor((tonumber(angle) or DEFAULT_ANGLE) % 360 + 0.5)
        self:ApplyMinimapPosition()
        if self.onAngleChanged then self.onAngleChanged(self.angle) end
    end
    function btn:GetAngle() return self.angle end
    function btn:ApplyMinimapPosition()
        lib.ApplyMinimapPosition(self, self.angle, self.radius)
    end
    function btn:SetIcon(icon, iconOpts)
        return lib.SetButtonIcon(self, icon, iconOpts)
    end
    function btn:SetMinimapShown(shown)
        self:ApplyMinimapPosition()
        if shown then self:Show() else self:Hide() end
        if self.setShown then self.setShown(shown and true or false) end
    end
    function btn:RefreshShown()
        local shown = self.getShown and self.getShown() or true
        lib.SetMinimapButtonShown(self, shown)
    end

    local function Follow()
        local deg = lib.AngleFromCursor(self or btn)
        if deg then btn:SetAngle(deg) end
    end
    btn:SetScript("OnDragStart", function(self) self:SetScript("OnUpdate", Follow); Follow() end)
    btn:SetScript("OnDragStop", function(self) Follow(); self:SetScript("OnUpdate", nil) end)

    btn:SetScript("OnClick", function(self, mouseButton)
        if self.onClick then self.onClick(self, mouseButton) end
    end)

    btn:SetScript("OnEnter", function(self)
        local spec = self.tooltipSpec
        if not GameTooltip or not spec then return end
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:ClearLines()
        if spec.title then
            local a = self.accent
            GameTooltip:AddLine(spec.title, a[1], a[2], a[3])
        end
        for _, line in ipairs(spec.lines or {}) do
            if type(line) == "string" then
                GameTooltip:AddLine(line, 1, 1, 1)
            elseif type(line) == "table" then
                GameTooltip:AddLine(line.text or "", line.r or 1, line.g or 1, line.b or 1)
            end
        end
        GameTooltip:Show()
    end)
    btn:SetScript("OnLeave", function() if GameTooltip then GameTooltip:Hide() end end)

    btn.background = btn:CreateTexture(nil, "BACKGROUND")
    btn.background:SetTexture(opts.background or DEFAULT_BACKGROUND)
    btn.background:SetSize(size - 7, size - 7)
    btn.background:SetPoint("CENTER")

    btn:SetIcon(opts.icon, { size = opts.iconSize or 20 })

    btn:SetHighlightTexture(opts.highlight or DEFAULT_HIGHLIGHT)
    btn.border = btn:CreateTexture(nil, "OVERLAY")
    btn.border:SetTexture(opts.border or DEFAULT_BORDER)
    btn.border:SetSize(53, 53)
    btn.border:SetPoint("TOPLEFT", 0, 0)

    btn:RefreshShown()
    return btn
end
