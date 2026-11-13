-- 文字输入框：底固定灰 + 黑边，聚焦只染边框（不染底/字）。
-- 底本 1248:1296:z-ref_retail_Interface_AddOns/MiliUI_Tooltip/Libs/MiliUIWidgets/Widgets.lua
local AF = ResolveNamespace("ade_AddonFramework")
if not AF then return end
AF.Widget = AF.Widget or {}
local W = {}
AF.Widget.Editbox = W

local function FocusBorder(target, skin)
    target:SetScript("OnEditFocusGained", function() skin:SetBorder(AF.ColorTable("accent")) end)
    target:SetScript("OnEditFocusLost", function() skin:SetBorder(AF.C.EDGE) end)
end

function W.CreateSingle(parent, width, height)
    local eb = CreateFrame("EditBox", nil, parent)
    eb:SetSize(width or 120, height or 20)
    local skin = AF.Stylize(eb, AF.C.WIDGET_FILL, AF.C.EDGE)
    eb.skin = skin
    eb:SetFontObject(AF.fontNormal)
    eb:SetTextInsets(4, 4, 0, 0)
    eb:SetAutoFocus(false)
    eb:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    FocusBorder(eb, skin)
    return eb
end

--- 多行输入：ScrollFrameTemplate + ScrollUtil（12.x 自由布局配对）。
-- 整个外框吃鼠标并把焦点导给 EditBox，避免空白时点不到焦点（1284:1291:…/Widgets.lua）
-- 内容高于框体时按文本真实高度撑开 ScrollChild，滚动条才会激活；opts.scrollbar=false 可关闭滚动条。
-- 滚动条整体下移几像素更美观（2026-11-13 用户要求，MiliUI 同款）；
-- 水平位置保持模板默认不动（2026-11-14 用户反馈：编辑框滚动条原本左右位置是正确的）。
function W.CreateMulti(parent, width, height, opts)
    opts = opts or {}
    local showSB = opts.scrollbar ~= false
    local holder = CreateFrame("Frame", nil, parent)
    holder:SetSize(width or 300, height or 150)
    local skin = AF.Stylize(holder, AF.C.WIDGET_FILL, AF.C.EDGE)
    holder.skin = skin

    -- scrollBarHideIfUnscrollable：内容未超过视口时不显示滚动条（但滚轮滚动始终可用）
    local scroll = CreateFrame("ScrollFrame", nil, holder, "ScrollFrameTemplate",
        { scrollBarHideIfUnscrollable = true })
    scroll:SetPoint("TOPLEFT", 4, -4)
    scroll:SetPoint("BOTTOMRIGHT", -22, 4)

    local eb = CreateFrame("EditBox", nil, scroll)
    eb:SetMultiLine(true)
    eb:SetFontObject(AF.fontNormal)
    eb:SetWidth((width or 300) - 30)
    eb:SetAutoFocus(false)
    eb:SetTextInsets(4, 4, 0, 0)
    eb:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    scroll:SetScrollChild(eb)

    -- 用同字体同宽的测量串撑高 ScrollChild：内容超过视口时滚动条才会出现
    -- ⚠ 必须 Hide：ScrollFrame 是透明底，FontString 无论什么层都会透出来，
    --   与编辑框文字叠成两份「文本错乱」（2026-11-14 用户截图实证）；
    --   隐藏的 FontString 仍可 GetStringHeight（标准测量做法）
    local measure = holder:CreateFontString(nil, "BACKGROUND")
    measure:SetFontObject(AF.fontNormal)
    measure:SetWidth(eb:GetWidth())
    measure:SetPoint("TOPLEFT", 0, 0)
    measure:SetText("")
    measure:Hide()
    local lastH
    local function Resize()
        measure:SetText(eb:GetText() or "")
        local h = measure:GetStringHeight() or height
        local nh = math.max((height or 150) - 8, h)
        -- 仅在高度变化时重设：每敲一字都 SetHeight 会让编辑框内部滚动/光标重排，
        -- 输入光标时隐时现（MiliUI 不重设故无此问题，2026-11-14 用户反馈）
        if nh ~= lastH then lastH = nh; eb:SetHeight(nh) end
    end
    eb:SetScript("OnTextChanged", function(self, userChanged)
        Resize()
        if opts.onTextChanged then opts.onTextChanged(self, userChanged) end
    end)

    if showSB and ScrollUtil and ScrollUtil.InitScrollFrameWithScrollBar and scroll.ScrollBar then
        ScrollUtil.InitScrollFrameWithScrollBar(scroll, scroll.ScrollBar)
        -- 整体下移几像素：只调各锚点的 y，水平保持模板默认
        local pts = {}
        for i = 1, scroll.ScrollBar:GetNumPoints() do
            local a, rel, rtp, x, y = scroll.ScrollBar:GetPoint(i)
            pts[i] = { a, rel, rtp, x, y }
        end
        scroll.ScrollBar:ClearAllPoints()
        for _, p in ipairs(pts) do
            scroll.ScrollBar:SetPoint(p[1], p[2], p[3], p[4], p[5] - 4)
        end
        -- ⚠ ScrollUtil.InitScrollFrameWithScrollBar 会替换 OnScrollRangeChanged，
        --   模板自带的 scrollBarHideIfUnscrollable（keyvalue）因此失效 → 滚动条恒显示。
        --   手工在范围变化时按 GetVerticalScrollRange 显隐：内容未超视口（范围≈0）则隐藏；
        --   范围>0 时自然可滚、滚动条出现（滚轮始终可用，与「未达滑块最小值不显滚动条但滚动固定支持」一致）
        local function UpdateSB()
            scroll.ScrollBar[scroll:GetVerticalScrollRange() > 0.5 and "Show" or "Hide"](scroll.ScrollBar)
        end
        scroll:HookScript("OnScrollRangeChanged", UpdateSB)
        UpdateSB()
    elseif scroll.ScrollBar then
        scroll.ScrollBar:Hide()
    end

    holder:EnableMouse(true)
    holder:SetScript("OnMouseDown", function() eb:SetFocus() end)
    FocusBorder(eb, skin)
    holder.editBox, holder.scroll, holder.measure = eb, scroll, measure
    return holder
end

--- 统一入口：单行 / 多行。
function W.Create(parent, opts)
    opts = opts or {}
    if opts.multiline then
        return W.CreateMulti(parent, opts.width, opts.height, opts)
    end
    local eb = W.CreateSingle(parent, opts.width, opts.height)
    if opts.text then eb:SetText(opts.text) end
    if opts.onTextChanged then
        eb:SetScript("OnTextChanged", function(self, userChanged) opts.onTextChanged(self, userChanged) end)
    end
    return eb
end
