-- 标题栏：底色画在 window 自身（外框才会包住标题栏），拖曳只由左侧 drag 子框承担。
-- 视觉底本 835:950:z-ref_retail_Interface_AddOns/MiliUI_Tooltip/Libs/MiliUIWidgets/Widgets.lua
local AF = ResolveNamespace("ade_AddonFramework")
if not AF then return end
AF.Widget = AF.Widget or {}
local W = {}
AF.Widget.TitleBar = W

function W.Create(window, opts)
    opts = opts or {}
    local height = opts.height or 28
    local rightInset = opts.rightInset or 0

    local bar = CreateFrame("Frame", nil, window)
    bar:SetHeight(height)
    bar:SetPoint("TOPLEFT", 0, 0)
    bar:SetPoint("TOPRIGHT", 0, 0)

    -- header 底色属于 window 自身，位于外框之内
    local bg = AF.Fill(window, AF.C.CARD_FILL, "BACKGROUND", 1)
    bg:ClearAllPoints()
    bg:SetPoint("TOPLEFT", window, "TOPLEFT", 1, -1)
    bg:SetPoint("TOPRIGHT", window, "TOPRIGHT", -1, -1)
    bg:SetHeight(height - 1)

    local divider = AF.Fill(window, AF.C.DIVIDER, "ARTWORK", 1)
    divider:ClearAllPoints()
    divider:SetHeight(AF.Pixel(window))
    divider:SetPoint("TOPLEFT", window, "TOPLEFT", 1, -height)
    divider:SetPoint("TOPRIGHT", window, "TOPRIGHT", -1, -height)

    local icon
    if opts.icon then
        icon = bar:CreateTexture(nil, "ARTWORK")
        AF.ResolveIcon(icon, opts.icon, opts.icon)
        icon:SetSize(height - 10, height - 10)
        icon:SetPoint("LEFT", 8, 0)
    end

    local title = bar:CreateFontString(nil, "OVERLAY")
    title:SetFontObject(AF.fontTitle)
    -- 图标与名称之间留一点间距（用户要求）
    title:SetPoint("LEFT", icon and (height + 4) or 10, 0)
    title:SetText(opts.title or "")

    -- 可拖区域避开右上按钮区
    local drag = CreateFrame("Frame", nil, bar)
    drag:SetPoint("TOPLEFT", 0, 0)
    drag:SetPoint("BOTTOMRIGHT", bar, "BOTTOMRIGHT", -rightInset, 0)
    drag:EnableMouse(true)
    local dragging
    drag:SetScript("OnMouseDown", function(_, button)
        if button ~= "LeftButton" or not window:IsMovable() then return end
        window:StartMoving(); dragging = true
    end)
    drag:SetScript("OnMouseUp", function()
        if not dragging then return end
        dragging = false
        window:StopMovingOrSizing()
        if opts.onMoved then opts.onMoved(window) end
    end)

    bar.bg, bar.divider, bar.title, bar.drag = bg, divider, title, drag
    function bar:SetTitle(text) title:SetText(text or "") end

    -- 标题栏右侧按钮区（ADE-v6-FrameDesign，2026-11-13：单布局页切换按钮移入标题栏）。
    -- 倒序锚定（2026-11-14 用户定稿）：以最右一颗的右缘为基准（距 X 关闭钮 26px 安全区），
    -- 第一颗按钮向左让位——每加一颗，整体随总占宽左移；Visual 顺序 = AddPage 顺序，
    -- 最后一颗永远紧贴 X 左侧，不会随页数增多溢出窗口右缘。
    -- （旧实现只按第一颗自身宽度定位、后续链式向右排而不回移，按钮一多直接压出窗外。）
    bar.rightButtons = {}
    local function RearrangeRightButtons()
        local n = #bar.rightButtons
        if n == 0 then return end
        local offset, total = 26, 0
        for i = 1, n do
            local w = bar.rightButtons[i]:GetWidth() or 88
            total = total + w + 6
            if i > 1 then offset = offset + w + 6 end
        end
        local first = bar.rightButtons[1]
        first:ClearAllPoints()
        first:SetPoint("TOPRIGHT", bar, "TOPRIGHT", -offset, -4)
        for i = 2, n do
            local b = bar.rightButtons[i]
            b:ClearAllPoints()
            b:SetPoint("TOPLEFT", bar.rightButtons[i - 1], "TOPRIGHT", 6, 0)
        end
        drag:ClearAllPoints()
        drag:SetPoint("TOPLEFT", 0, 0)
        drag:SetPoint("BOTTOMRIGHT", bar, "BOTTOMRIGHT", -(total + 26), 0)
    end
    function bar:AddRightButton(btn, height)
        height = height or 20
        btn:SetParent(bar)
        btn:SetSize(btn:GetWidth() or 88, height)
        btn:SetFrameLevel(bar:GetFrameLevel() + 3)
        bar.rightButtons[#bar.rightButtons + 1] = btn
        RearrangeRightButtons()
        return btn
    end
    return bar
end
