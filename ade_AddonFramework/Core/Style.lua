-- 固定黑白灰色阶 + WHITE8x8 纯色纹理绘制后端（12.x 一律不用 backdrop 模板方法）。
-- 色值依据：109:115、190:211、479:481、1301:1313:z-ref_retail_Interface_AddOns/MiliUI_Tooltip/Libs/MiliUIWidgets/Widgets.lua
local AF = ResolveNamespace("ade_AddonFramework")
if not AF then return end

-- 固定常量：永不随主题色变化（规则 §5.3）
AF.C = {
    WIDGET_FILL   = { 0.115, 0.115, 0.115, 1 },
    CHECKBOX_FILL = { 0.28, 0.28, 0.28, 1 },
    CARD_FILL     = { 0.15, 0.15, 0.15, 1 },
    PANEL         = { 0.1, 0.1, 0.1, 0.9 },
    DD_BORDER     = { 0.22, 0.22, 0.22, 1 },
    BTN_HOVER     = { 0.23, 0.23, 0.23, 1 },
    EDGE          = { 0, 0, 0, 1 },
    DIVIDER       = { 0.4, 0.4, 0.4, 1 }, -- 内容区横向分隔条：固定灰白（不随主题色）
    TEXT_MAIN     = { 1, 1, 1, 1 },
    TEXT_MUTED    = { 0.8, 0.8, 0.8, 1 },
    TEXT_DIM      = { 0.6, 0.6, 0.6, 1 },
    TEXT_DISABLED = { 0.4, 0.4, 0.4, 1 },
}

--- 创建一张铺满 parent 的纯色纹理。填充与边框相接，同样关掉像素贴齐（PixelPerfect.lua:44 注释口径）。
function AF.Fill(parent, color, layer, sublevel)
    local t = parent:CreateTexture(nil, layer or "BACKGROUND", nil, sublevel or 0)
    t:SetTexture(AF.WHITE)
    t:SetAllPoints()
    AF.NoSnap(t)
    if color then t:SetVertexColor(color[1], color[2], color[3], color[4] or 1) end
    return t
end

--- 四条 1px 边（不用 backdrop）。返回带 SetColor / SetShown / Refresh 的边对象。
function AF.Edges(parent, color, layer)
    local px = AF.Pixel(parent)
    local edges = {}
    local function Make(pointA, pointB, horizontal)
        local t = parent:CreateTexture(nil, layer or "BORDER", nil, 1)
        t:SetTexture(AF.WHITE)
        AF.NoSnap(t)
        t:SetPoint(pointA, parent, pointA, 0, 0)
        t:SetPoint(pointB, parent, pointB, 0, 0)
        if horizontal then t:SetHeight(px) else t:SetWidth(px) end
        edges[#edges + 1] = t
        return t
    end
    Make("TOPLEFT", "TOPRIGHT", true)
    Make("BOTTOMLEFT", "BOTTOMRIGHT", true)
    Make("TOPLEFT", "BOTTOMLEFT", false)
    Make("TOPRIGHT", "BOTTOMRIGHT", false)

    function edges:SetColor(c)
        for _, t in ipairs(self) do t:SetVertexColor(c[1], c[2], c[3], c[4] or 1) end
    end
    function edges:SetShown(on)
        for _, t in ipairs(self) do t:SetShown(on) end
    end
    function edges:Refresh()
        local p = AF.Pixel(parent)
        if math.abs(p - px) < 1e-5 then return end
        px = p
        for i, t in ipairs(self) do
            if i <= 2 then t:SetHeight(p) else t:SetWidth(p) end
        end
    end
    if color then edges:SetColor(color) end
    return edges
end

--- 统一的「底 + 1px 边」皮肤，替代 W.Stylize。
function AF.Stylize(frame, fill, border)
    local skin = {}
    skin.fill = AF.Fill(frame, fill or AF.C.WIDGET_FILL, "BACKGROUND", 0)
    skin.edges = AF.Edges(frame, border or AF.C.EDGE, "BORDER")
    function skin:SetFill(c) self.fill:SetVertexColor(c[1], c[2], c[3], c[4] or 1) end
    function skin:SetBorder(c) self.edges:SetColor(c) end
    function skin:SetShown(on) self.fill:SetShown(on); self.edges:SetShown(on) end
    function skin:Refresh() self.edges:Refresh() end
    frame._afSkin = skin
    -- UI 缩放 / 祖先缩放改变后，1px 边会整条消失（Widgets.lua:117-143 实证）
    if frame.HookScript then frame:HookScript("OnShow", function() skin:Refresh() end) end
    return skin
end

--- 固定色：黑白灰，不进主题派生公式。
function AF.Fixed(tex, key, alpha)
    local c = AF.C[key] or AF.C.WIDGET_FILL
    tex:SetVertexColor(c[1], c[2], c[3], alpha or c[4] or 1)
    return tex
end

-- 随主题刷新的纹理登记（弱键，避免窗口销毁后仍被遍历）
AF.__tinted = setmetatable({}, { __mode = "k" })

--- 着色部位专用：仅勾 / 滑块 / 下拉箭头 / 标题类 / hover 边框允许调用本函数。
-- 同时支持 Texture（SetVertexColor）与 FontString（SetTextColor）。
function AF.Tint(target, key, alpha)
    AF.__tinted[target] = { key = key or "accent", alpha = alpha }
    local r, g, b, a = AF.Color(key or "accent", alpha)
    if target.SetVertexColor then
        target:SetVertexColor(r, g, b, a)
    elseif target.SetTextColor then
        target:SetTextColor(r, g, b, a)
    end
    return target
end

--- hover / 选中 / 聚焦只改边框，底色不动（规则 §5.3）。
function AF.HoverBorder(frame, skin)
    if not skin then return end
    frame:HookScript("OnEnter", function() skin:SetBorder(AF.ColorTable("accent")) end)
    frame:HookScript("OnLeave", function() skin:SetBorder(AF.C.EDGE) end)
end
