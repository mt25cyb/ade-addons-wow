-- 双布局选项窗口：单选项页 720 宽 680 高 / 多选项页 860 宽 680 高，两种布局内容区等宽 672。
-- ADE-v6-FrameDesign 手绘图（2026-11-13 用户定稿）：
--   单布局：页切换按钮移入标题栏右侧（[预览?][设置][配置管理][关于][X]），顶部页签取消（topInset 66→38）；
--   多布局：页按钮留在左栏；左栏底部为页脚区——复选框固定占最底槽位（如「小地图图标」），
--           按钮从其上方堆叠（如「打开预览」）；
--   预览区（b010 起）：预览面板是独立组件（Template/PreviewPanel），本模板不再创建预览帧，
--           只保留开关位——单布局 titleBar:AddRightButton、多布局 AddSidebarFooterButton；
--           页切换回调 opts.onPageChanged / SetOnPageChanged 供预览联动。
-- 规格 61:82:_docs/plans/ADE-v6-settings-sys-dev-plan.md
local AF = ResolveNamespace("ade_AddonFramework")
if not AF then return end
AF.Template = AF.Template or {}
AF.Options = AF.Options or {}
local W = {}
AF.Template.TabbedFrame = W  -- 组合模板：单/多选项页布局
AF.Options.Frame = W        -- 别名兼容

local seq = 0

local function RegisterEscape(frame)
    if type(_G.UISpecialFrames) ~= "table" then return end
    local name = frame:GetName()
    for _, n in ipairs(_G.UISpecialFrames) do if n == name then return end end
    _G.UISpecialFrames[#_G.UISpecialFrames + 1] = name
end

function W.Create(opts)
    opts = opts or {}
    local layout = opts.layout == "single" and "single" or "multi"
    local frameW = layout == "single" and AF.LAYOUT.singleW or AF.LAYOUT.multiW
    local height = AF.LAYOUT.height
    local contentW = AF.LAYOUT.contentW

    seq = seq + 1
    local frame = CreateFrame("Frame", "AF_OptionsFrame" .. seq, UIParent)
    frame:SetSize(frameW, height)
    frame:SetPoint("CENTER")
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:SetToplevel(true)
    frame:SetClampedToScreen(true)

    -- 主窗边框：1px 细边（NoSnap 已解决过粗），可着主题色（2026-11-13 用户确认边框可随主题）
    local skin = AF.Stylize(frame, AF.C.PANEL, AF.ColorTable("accent"))
    AF.RegisterTheme(frame, function() skin:SetBorder(AF.ColorTable("accent")) end)
    frame.skin = skin
    -- 记录创建时的活动主题（来自插件门面）；后续 AddPage/ShowPage/页脚在门面包裹作用域之外被插件直接调用，
    -- 重建控件时据此沿用本插件主题（否则落全局默认主题，导致标题栏页签按钮/侧栏页脚不跟色）。
    frame._afTheme = AF._activeTheme

    frame.titleBar = AF.Widget.TitleBar.Create(frame, {
        title = opts.title or "ade_AddonFramework",
        icon = opts.icon or "Interface\\AddOns\\ade_AddonFramework\\assets\\ade_128.tga",
        rightInset = 26 + 44, -- X 关闭钮安全区 + 保底按钮余量；有右按钮后由 AddRightButton 重算
        onMoved = opts.onMoved,
    })

    local close = AF.Widget.Icon.CreateButton(frame, {
        size = 18,
        atlas = "common-icon-redx",
        tooltip = AF.L["AF_CLOSE"],
        onClick = function() frame:Hide() end,
    })
    close:SetPoint("TOPRIGHT", -6, -5)
    close:SetFrameLevel(frame.titleBar:GetFrameLevel() + 2)
    frame.closeButton = close

    -- b010：内嵌预览面板已抽离为独立组件（Template/PreviewPanel.New + AttachTo + BindButton）。
    -- 此处不再创建预览帧；宿主把开关按钮放进标题栏/侧栏页脚后 BindButton 即可。

    local contentX, topInset
    if layout == "multi" then
        local sidebar = CreateFrame("Frame", nil, frame)
        sidebar:SetPoint("TOPLEFT", 10, -38)
        sidebar:SetPoint("BOTTOMLEFT", 10, 10)
        sidebar:SetWidth(AF.LAYOUT.sidebarW)
        frame.sidebar = sidebar
        contentX, topInset = 10 + AF.LAYOUT.sidebarW + 14, 38
        -- 侧栏与内容区之间的纵向分隔条：用调暗的主题色（主窗外边框是全亮 accent，
        -- 分隔线若同亮度会与边框混在一起；accentDim = accent×0.75）
        local vdiv = AF.Fill(frame, AF.C.EDGE, "ARTWORK", 0)
        AF.Tint(vdiv, "accentDim")
        vdiv:ClearAllPoints()
        vdiv:SetWidth(AF.Pixel(frame))
        vdiv:SetPoint("TOPLEFT", contentX - 7, -38)
        vdiv:SetPoint("BOTTOMLEFT", contentX - 7, 10)
        frame.sidebarDivider = vdiv

        -- 左栏页脚区（ADE-v6-FrameDesign）：复选框固定最底槽位（如「小地图图标」），
        -- 按钮从复选框上方堆叠（如「打开预览」）。约定：复选框至多一个。
        frame.footerBtnH = 0
        function frame:AddSidebarFooterCheckbox(label, get, set)
            local cb = AF.Widget.Checkbox.Create(sidebar, {
                label = label,
                checked = get and get() or false,
                onChange = set,
            })
            cb:SetPoint("BOTTOMLEFT", sidebar, "BOTTOMLEFT", 0, 0)
            return cb
        end
        function frame:AddSidebarFooterButton(text, onClick)
            local b = AF.Widget.Button.Create(sidebar, {
                text = text, width = AF.LAYOUT.sidebarW, height = 20, onClick = onClick,
            })
            AF.Widget.Button.FitButton(b, AF.LAYOUT.sidebarW, 20)
            b:SetPoint("BOTTOMLEFT", sidebar, "BOTTOMLEFT", 0, 30 + frame.footerBtnH)
            frame.footerBtnH = frame.footerBtnH + 26
            return b
        end
    else
        contentX, topInset = (frameW - contentW) / 2, 38 -- 页按钮在标题栏，内容区顶距与多布局一致
    end

    local holder = CreateFrame("Frame", nil, frame)
    holder:SetPoint("TOPLEFT", contentX, -topInset)
    holder:SetPoint("BOTTOMRIGHT", -(frameW - contentX - contentW), 10)
    frame.holder = holder

    local scroll = AF.Widget.Scroll.Create(holder, { width = contentW, height = height - topInset - 10 })
    scroll:SetAllPoints()
    frame.scroll = scroll
    frame.content = scroll.content

    frame.pages, frame.pageOrder, frame.page = {}, {}, nil
    frame.layout = layout

    function frame:AddPage(id, label, build)
        local holderPage = CreateFrame("Frame", nil, self.content)
        holderPage:SetAllPoints()
        holderPage:Hide()
        local page = { id = id, label = label, build = build, holder = holderPage, content = holderPage }
        self.pages[id] = page
        self.pageOrder[#self.pageOrder + 1] = id

        if self.sidebar then
            local b = AF.Widget.Button.Create(self.sidebar, {
                text = label, width = AF.LAYOUT.sidebarW, height = 22,
                onClick = function() self:ShowPage(id) end,
            })
            AF.Widget.Button.FitButton(b, AF.LAYOUT.sidebarW, 22)
            b:SetPoint("TOPLEFT", 0, -((#self.pageOrder - 1) * 26))
            page.tab = b
        else
            -- 单布局：页按钮入标题栏右侧（先加的保持最左，Visual 顺序 = AddPage 顺序）。
            -- FitButton 按译文撑宽：译文比基准宽的语系自动让位（Button.lua §十.2）。
            -- 主题色随控件层级自动传递（Stylize 给每个控件记 parent 链主题），无需在此手动置活动主题。
            local b = AF.Widget.Button.Create(frame.titleBar, {
                text = label, width = 88, height = 20,
                onClick = function() self:ShowPage(id) end,
            })
            AF.Widget.Button.FitButton(b, 56, 20)
            frame.titleBar:AddRightButton(b, 20)
            page.tab = b
        end
        if #self.pageOrder == 1 then self:ShowPage(id) end
        return page
    end

    function frame:ShowPage(id)
        local page = self.pages[id]
        if not page then return end
        for _, pid in ipairs(self.pageOrder) do
            local p = self.pages[pid]
            p.holder:SetShown(pid == id)
            if p.tab then AF.Widget.Button.SetVariant(p.tab, pid == id and "primary" or "normal") end
        end
        self.page = id
        if not page.built and page.build then
            page.build(page.content, page)
            page.built = true
            self.scroll:SetContentHeight(math.max(page.content:GetHeight() or 1, 1))
        end
        if self.onPageChanged then self.onPageChanged(id, page) end
    end

    -- 页切换回调：供预览组件等外部联动（adeTooltip 开发计划 §九.3）。
    frame.onPageChanged = opts.onPageChanged
    function frame:SetOnPageChanged(fn) self.onPageChanged = fn end

    frame:SetScript("OnShow", function(self) if self.page then self:ShowPage(self.page) end end)
    RegisterEscape(frame)
    frame:Hide()
    return frame
end
