--[==[ adeAnnivGuide / UI/ContentPage.lua — 内容界面：返回 + 条目标题 + 富文本滚动区
    12.x 原生风格（用户 2026-11-21）：返回按钮 = UIPanelButtonTemplate；
    文本块 = GameFontHighlight 原生字体对象（不再自设 OUTLINE 字体，参考
    ade_UIKit Kinds.lua Note 行的 SetWidth + GetStringHeight 换行测量模式）；
    富文本内容为空已修复：Blocks.lua 两表合一（详见 Blocks.lua 头注释）。
    图块点击放大（独立遮罩层，点击任意处/ESC 关闭）。 ]==]
local ns = _G.adeAnnivGuide
local ContentPage = {}
ns.ContentPage = ContentPage

local page, scroll, content, titleFS
local textPool, imgPool = {}, {}
local textUsed, imgUsed = 0, 0
local zoomOverlay, zoomTexture, zoomHint

local PAD = 12

--- 滚动容器（ScrollFrameTemplate 自带 MinimalScrollBar，自动维护范围）。
local function CreateAutoScrollFrame(parent)
    --@diagnostic disable-next-line: undefined-global
    local ScrollUtil = ScrollUtil
    local scroll = CreateFrame("ScrollFrame", nil, parent, "ScrollFrameTemplate", {
        scrollBarX = 8,
        scrollBarTopY = -2,
        scrollBarBottomY = 4,
        scrollBarHideIfUnscrollable = true,
    })
    ScrollUtil.InitScrollFrameWithScrollBar(scroll, scroll.ScrollBar)
    local content = CreateFrame("Frame", nil, scroll)
    content:SetSize(1, 1)
    scroll:SetScrollChild(content)
    scroll.content = content
    return scroll, content
end

local function AcquireText(parent)
    textUsed = textUsed + 1
    local fs = textPool[textUsed]
    if not fs then
        fs = parent:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
        fs:SetJustifyH("LEFT")
        textPool[textUsed] = fs
    end
    fs:SetParent(parent)
    return fs
end

local function AcquireImg(parent)
    imgUsed = imgUsed + 1
    local block = imgPool[imgUsed]
    if not block then
        block = CreateFrame("Button", nil, parent)
        block.Texture = block:CreateTexture(nil, "ARTWORK")
        block.Texture:SetAllPoints()
        block:RegisterForClicks("LeftButtonUp")
        imgPool[imgUsed] = block
    end
    block:SetParent(parent)
    return block
end

--- 点击放大遮罩层：独立于窗口的 UIParent 子帧，点击任意处或 ESC 关闭。
local function EnsureZoom()
    if zoomOverlay then return zoomOverlay end
    zoomOverlay = CreateFrame("Button", "adeAnnivGuideZoom", UIParent)
    zoomOverlay:SetFrameStrata("FULLSCREEN")
    zoomOverlay:SetAllPoints(UIParent)
    zoomOverlay:RegisterForClicks("LeftButtonUp", "RightButtonUp")

    local dim = zoomOverlay:CreateTexture(nil, "BACKGROUND")
    dim:SetAllPoints()
    dim:SetColorTexture(0, 0, 0, 0.72)

    zoomTexture = zoomOverlay:CreateTexture(nil, "ARTWORK")

    zoomHint = zoomOverlay:CreateFontString(nil, "OVERLAY", "GameFontDisable")
    zoomHint:SetPoint("BOTTOM", 0, 14)
    zoomHint:SetText(ns.L["ZOOM_HINT"])

    zoomOverlay:SetScript("OnClick", function() zoomOverlay:Hide() end)
    -- ESC 关闭走 UISpecialFrames 原生路径（有名字的帧直接入表）
    table.insert(UISpecialFrames, "adeAnnivGuideZoom")
    zoomOverlay:Hide()
    return zoomOverlay
end

--- 放大查看：按内容区宽高比适配屏幕（宽 ≤ 70% 屏宽、高 ≤ 78% 屏高）。
local function ShowZoom(step)
    EnsureZoom()
    local u, v = step.u, step.v
    local aspect = step.w / step.h
    local screenW, screenH = GetScreenWidth(), GetScreenHeight()
    local maxW, maxH = screenW * 0.70, screenH * 0.78
    local w, h = maxW, maxW / aspect
    if h > maxH then
        h = maxH
        w = h * aspect
    end
    zoomTexture:SetSize(w, h)
    zoomTexture:SetPoint("CENTER")
    zoomTexture:SetTexture(ns.Blocks.ImagePath(step.f))
    ns.Blocks.ApplyCrop(zoomTexture, u, v)
    zoomOverlay:Show()
end

--- 打开条目：重建内容块（池化复用，超出部分隐藏）。
function ContentPage.Open(entry)
    titleFS:SetText(entry.title)
    for i = 1, textUsed do textPool[i]:Hide() end
    for i = 1, imgUsed do imgPool[i]:Hide() end
    textUsed, imgUsed = 0, 0

    local contentW = content:GetWidth()
    local maxW = contentW - PAD
    local y = 0
    local stepNo = 0

    for _, st in ipairs(entry.steps) do
        if st.t == "text" then
            stepNo = stepNo + 1
            local fs = AcquireText(content)
            fs:ClearAllPoints()
            fs:SetPoint("TOPLEFT", content, "TOPLEFT", PAD, -y - 4)
            fs:SetWidth(maxW)
            fs:SetText(ns.Blocks.RichText(stepNo .. ". " .. st.s))
            local h = fs:GetStringHeight()
            fs:SetHeight(h)
            fs:Show()
            y = y + h + 6
        elseif st.t == "img" then
            local scale = math.min(1, maxW / st.w)
            local dw, dh = st.w * scale, st.h * scale
            local block = AcquireImg(content)
            block:ClearAllPoints()
            block:SetSize(dw, dh)
            block:SetPoint("TOPLEFT", content, "TOPLEFT", PAD, -y - 4)
            block.Texture:SetTexture(ns.Blocks.ImagePath(st.f))
            ns.Blocks.ApplyCrop(block.Texture, st.u, st.v)
            block:SetScript("OnClick", function() ShowZoom(st) end)
            block:Show()
            y = y + dh + 6
        end
    end

    content:SetHeight(y + 8)
    -- 打开条目回到顶部（OnScrollRangeChanged 自动驱动滚动条范围）
    scroll:SetVerticalScroll(0)
end

--- 创建内容页；返回页 Frame。
function ContentPage.Create(parent)
    page = CreateFrame("Frame", nil, parent)
    page:SetAllPoints()

    -- 返回按钮（原生模板；原生标题区按 36px 预留）
    local back = CreateFrame("Button", nil, page, "UIPanelButtonTemplate")
    back:SetSize(80, 24)
    back:SetPoint("TOPLEFT", page, "TOPLEFT", 12, -36)
    back:SetText(ns.L["BACK"])
    back:SetScript("OnClick", function() ns.Window.ShowList() end)

    -- 当前条目标题
    titleFS = page:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
    titleFS:SetPoint("LEFT", back, "RIGHT", 12, 0)
    titleFS:SetJustifyH("LEFT")

    -- 内容滚动区（原生内衬框）
    local inset = CreateFrame("Frame", nil, page, "InsetFrameTemplate")
    inset:SetPoint("TOPLEFT", page, "TOPLEFT", 12, -(36 + 24 + 6))
    inset:SetPoint("BOTTOMRIGHT", page, "BOTTOMRIGHT", -28, 12)

    scroll, content = CreateAutoScrollFrame(inset)
    scroll:SetPoint("TOPLEFT", inset, "TOPLEFT", 6, -6)
    scroll:SetPoint("BOTTOMRIGHT", inset, "BOTTOMRIGHT", -6, 6)
    -- 内容宽 = 滚动区宽 668 − 内衬内缩 12 − 滚动条 ~10 − 余量 14 = 632
    content:SetWidth(632)

    return page
end
