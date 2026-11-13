-- 双布局选项窗口：单选项页 720 宽 680 高 / 多选项页 860 宽 680 高，两种布局内容区等宽 672。
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

    frame.titleBar = AF.Widget.TitleBar.Create(frame, {
        title = opts.title or "ade_AddonFramework",
        icon = opts.icon or "Interface\\AddOns\\ade_AddonFramework\\assets\\ade_128.tga",
        rightInset = 70,
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
    else
        contentX, topInset = (frameW - contentW) / 2, 66 -- 顶部一行页签占位
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

        local function MakeTab(tabParent, isSide)
            local b = AF.Widget.Button.Create(tabParent, {
                text = label, width = isSide and AF.LAYOUT.sidebarW or 100, height = 22,
                onClick = function() self:ShowPage(id) end,
            })
            AF.Widget.Button.FitButton(b, isSide and AF.LAYOUT.sidebarW or 100, 22)
            return b
        end
        if self.sidebar then
            local b = MakeTab(self.sidebar, true)
            b:SetPoint("TOPLEFT", 0, -((#self.pageOrder - 1) * 26))
            page.tab = b
        else
            local b = MakeTab(frame, false)
            b:SetPoint("TOPLEFT", contentX + ((#self.pageOrder - 1) * 104), -36)
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
    end

    frame:SetScript("OnShow", function(self) if self.page then self:ShowPage(self.page) end end)
    RegisterEscape(frame)
    frame:Hide()
    return frame
end
