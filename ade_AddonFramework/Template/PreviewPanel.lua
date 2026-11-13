-- 独立预览面板组件（b010，adeTooltip 开发计划 §九.1 规格）。
-- 用户架构约束（2026-11-13 确认）：预览面板的创建是单独组件，通过开关切换显示在指定位置；
-- 双布局（TabbedFrame）只保留「打开预览」的开关位，不负责创建预览。
-- 组件只负责：外框（Stylize + 主题色边）、内容容器、显隐、锚点、绑定按钮文案同步；
-- 不知道业务内容——内容由宿主 build/refresh 回调提供。
local AF = ResolveNamespace("ade_AddonFramework")
if not AF then return end
AF.Template = AF.Template or {}
local W = {}
AF.Template.PreviewPanel = W  -- 组合模板：独立预览面板

local seq = 0
local DEFAULT_ANCHOR = { point = "TOPRIGHT", relativePoint = "TOPLEFT", x = -8, y = 0 }

--- opts = {
---   width, height,                          -- 尺寸（height 默认 AF.LAYOUT.height）
---   anchor = { point, relativePoint, x, y },-- 停靠（默认主窗左侧：TOPRIGHT→主窗 TOPLEFT -8）
---   build = function(content, panel) end,   -- 首次显示时构建一次；SetBuild 后下次显示重建
---   refresh = function(panel) end,          -- 内容刷新回调（panel:Refresh() 触发）
---   onShow = function(panel) end, onHide = function(panel) end,
--- }
function W.New(opts)
    opts = opts or {}
    seq = seq + 1
    local panel = CreateFrame("Frame", "AF_PreviewPanel" .. seq, UIParent)
    panel:SetSize(opts.width or 340, opts.height or AF.LAYOUT.height)
    local skin = AF.Stylize(panel, AF.C.PANEL, AF.ColorTable("accent"))
    AF.RegisterTheme(panel, function() skin:SetBorder(AF.ColorTable("accent")) end)
    panel.skin = skin

    local content = CreateFrame("Frame", nil, panel)
    content:SetPoint("TOPLEFT", 8, -8)
    content:SetPoint("BOTTOMRIGHT", -8, 8)
    panel.content = content

    -- 原生显隐方法先取出，下面的同名覆盖内部要回调它们（勿递归）
    local rawShow, rawHide = panel.Show, panel.Hide
    local anchor = opts.anchor or DEFAULT_ANCHOR
    local buildFn, refreshFn = opts.build, opts.refresh
    local attached, built = nil, false
    panel.buttons = {}

    local function SyncButtons()
        local shown = panel:IsShown()
        for _, b in ipairs(panel.buttons) do
            b:SetText(AF.L[shown and "AF_PREVIEW_CLOSE" or "AF_PREVIEW_OPEN"])
        end
    end

    local function Place()
        if not attached then return end
        panel:ClearAllPoints()
        panel:SetPoint(anchor.point or "TOPRIGHT", attached,
            anchor.relativePoint or "TOPLEFT", anchor.x or -8, anchor.y or 0)
        panel:SetFrameStrata(attached:GetFrameStrata())
        panel:SetFrameLevel(math.max(attached:GetFrameLevel() - 1, 1))
    end

    --- 绑定主窗生命周期：主窗隐藏 → 预览一并隐藏（按钮文案同步）。
    function panel:AttachTo(frame)
        attached = frame
        frame:HookScript("OnHide", function()
            if panel:IsShown() then panel:Hide() end
        end)
        return self
    end

    --- 运行时改停靠位置（anchor 表同 New；省略字段回退默认）。
    function panel:SetAnchor(cfg)
        anchor = cfg or DEFAULT_ANCHOR
        if self:IsShown() then Place() end
    end

    --- 替换内容构建器：下次显示时重建。
    function panel:SetBuild(fn) buildFn = fn; built = false end
    --- 内容刷新回调（宿主设置变化后调 panel:Refresh() 触发）。
    function panel:SetRefresh(fn) refreshFn = fn end
    function panel:Refresh()
        if built and self:IsShown() and refreshFn then refreshFn(self) end
    end

    function panel:Show()
        if attached then Place() end
        if not built then
            if buildFn then buildFn(content, self) end
            built = true
        end
        rawShow(self)
        if opts.onShow then opts.onShow(self) end
        SyncButtons()
    end

    function panel:Hide()
        rawHide(self)
        if opts.onHide then opts.onHide(self) end
        SyncButtons()
    end

    function panel:Toggle()
        if self:IsShown() then self:Hide() else self:Show() end
    end

    --- 绑定开关按钮：接管 OnClick 为 Toggle，并随显隐切换 AF_PREVIEW_OPEN/CLOSE 文案。
    --- 按钮本体由宿主放在双布局的开关位（标题栏 AddRightButton / 侧栏 AddSidebarFooterButton）。
    function panel:BindButton(btn)
        btn:SetScript("OnClick", function() panel:Toggle() end)
        panel.buttons[#panel.buttons + 1] = btn
        SyncButtons()
        return btn
    end

    panel:Hide()
    return panel
end
