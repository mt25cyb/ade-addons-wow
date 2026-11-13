-- 自由布局滚动容器：ScrollFrameTemplate + ScrollUtil.InitScrollFrameWithScrollBar。
-- 12.x 手动布局配对依据：Blizzard_SharedXML/SecureUIPanelTemplates.lua、Scroll/ScrollUtil.lua（项目记忆 70424312）。
local AF = ResolveNamespace("ade_AddonFramework")
if not AF then return end
AF.Widget = AF.Widget or {}
local W = {}
AF.Widget.Scroll = W

function W.Create(parent, opts)
    opts = opts or {}
    local frame = CreateFrame("Frame", nil, parent)
    frame:SetSize(opts.width or 200, opts.height or 200)

    -- 滚动条贴容器右缘（2026-11-14 用户反馈：主窗滚动条偏左，右侧贴边控件会与滚动条重叠）；
    -- 内容宽 = 容器 - 24，给滚动条留位，内容不再压到滚动条上。
    local scroll = CreateFrame("ScrollFrame", nil, frame, "ScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", 0, 0)
    scroll:SetPoint("BOTTOMRIGHT", -2, 0)

    local content = CreateFrame("Frame", nil, scroll)
    content:SetWidth(math.max((opts.width or 200) - 24, 1))
    content:SetHeight(1)
    scroll:SetScrollChild(content)
    if ScrollUtil and ScrollUtil.InitScrollFrameWithScrollBar and scroll.ScrollBar then
        ScrollUtil.InitScrollFrameWithScrollBar(scroll, scroll.ScrollBar)
    end

    frame:SetScript("OnSizeChanged", function(self, w)
        content:SetWidth(math.max(w - 24, 1))
    end)

    frame.scroll, frame.content = scroll, content
    function frame:SetContentHeight(h) content:SetHeight(math.max(h or 1, 1)) end
    function frame:ScrollTo(v) scroll:SetVerticalScroll(v or 0) end
    return frame
end
