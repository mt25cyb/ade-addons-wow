------------------------------------------------------------
-- 主窗构建。复刻 KAF Libs/Krowi_Options/WindowFrame.lua:106-185，删除右侧描述区。
-- 仅保留 Nav + Page 两列；宽度固定 920（KAF 的 gameWidth，WindowLayout.lua:26）。
------------------------------------------------------------
local lib = ResolveBOFNamespace("ade_UIKit")
if not lib then return end

local Internal = lib.Internal
local build, mixins, geometry = Internal.Build, Internal.Mixins, Internal.Geometry
local Text = build.Text

-- ESC 代理：KAF Gui/FramesForClosing.lua 的加载期注册模式。
-- 窗口用普通 Show，面板管理器不知道它打开；ESC 由 CloseSpecialWindows 隐藏代理帧，代理的 OnHide 关真实窗。
local escapeProxy = CreateFrame("Frame", "AdeBlizzOptionsFrame_SpecialFrame")
if not tContains(UISpecialFrames, escapeProxy:GetName()) then
    tinsert(UISpecialFrames, escapeProxy:GetName())
end
escapeProxy:SetScript("OnHide", function()
    local frame = Internal.Frame
    if frame and frame:IsShown() then frame:Hide() end
end)

local function PanelButton(parent, width, hidden)
    local button = CreateFrame("Button", nil, parent, "UIPanelButtonNoTooltipTemplate")
    button:SetSize(width, 22)
    if hidden then button:Hide() end
    return button
end

function build.Window()
    local frame = CreateFrame("Frame", lib.WindowName, UIParent, "SettingsFrameTemplate")
    frame:Hide() -- 子控件建好前隐藏，搜索框不抢键盘
    frame:SetSize(geometry.WindowWidth, geometry.WindowHeight)
    frame:SetPoint("CENTER")
    frame:SetFrameStrata("HIGH")
    frame:SetToplevel(true)
    frame:EnableMouse(true)
    frame:SetMovable(true)
    frame:SetResizable(true)
    frame:SetClampedToScreen(true)

    frame.PageTitle = Text(frame, "ARTWORK", "GameFontHighlightHuge", "LEFT")
    frame.PageTitle:SetWordWrap(false)
    frame.ChangedText = Text(frame, "ARTWORK", "GameFontDisableSmall", "RIGHT")
    frame.ReloadText = Text(frame, "ARTWORK", "GameFontHighlight", "LEFT")
    frame.Divider = frame:CreateTexture(nil, "ARTWORK")
    frame.Divider:SetAtlas("Options_HorizontalDivider", true)
    frame.ReloadBackground = build.Color(frame, "BACKGROUND", 1, 0.82, 0, 0.08, 2)
    frame.ReloadBackground:Hide()

    -- KAF WindowFrame.lua:124-145：搜索的范围（全部 Tab）与广度（描述）两个复选框及其小字标签。
    frame.SearchAllLabel = Text(frame, "ARTWORK", "GameFontNormalSmall", "LEFT")
    frame.SearchAllLabel:Hide()
    frame.SearchBroadLabel = Text(frame, "ARTWORK", "GameFontNormalSmall", "LEFT")
    frame.SearchAll = build.CheckButton(frame)
    frame.SearchAll:Hide()
    frame.SearchBroad = build.CheckButton(frame)

    frame.Body = CreateFrame("Frame", nil, frame)
    frame.InnerFrame = CreateFrame("Frame", nil, frame)
    frame.InnerFrame:SetPoint("TOPLEFT", geometry.InnerLeft, geometry.InnerTop)
    frame.InnerFrame:SetPoint("BOTTOMRIGHT", geometry.InnerRight, geometry.InnerBottom)

    frame.SearchBox = CreateFrame("EditBox", nil, frame, "SearchBoxTemplate")
    frame.SearchBox:SetAutoFocus(false)
    frame.SearchBox:SetMaxLetters(60)
    frame.SearchBox:SetSize(geometry.SearchWidth, 22)

    for _, list in ipairs({ "Nav", "Page" }) do
        frame[list .. "ScrollBox"] = CreateFrame("Frame", nil, frame, "WowScrollBoxList")
        frame[list .. "ScrollBar"] = CreateFrame("EventFrame", nil, frame, "MinimalScrollBar")
    end

    frame.DefaultsButton = PanelButton(frame, 96)
    frame.CancelButton = PanelButton(frame, 80, true)
    frame.ReloadButton = PanelButton(frame, 110, true)
    frame.CloseButton = PanelButton(frame, 96)
    frame.CloseButton:SetPoint("BOTTOMRIGHT", -26, 16)

    local resize = CreateFrame("Button", nil, frame)
    resize:SetSize(16, 16)
    resize:SetPoint("BOTTOMRIGHT", -4, 4)
    resize:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
    resize:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")
    resize:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight", "ADD")
    frame.ResizeButton = resize

    build.Finish(frame, mixins.Window, {
        OnLoad = "OnLoad", OnShow = "OnShow", OnHide = "OnHide", OnEvent = "OnEvent",
        OnSizeChanged = "OnSizeChanged", OnDragStart = "OnDragStart", OnDragStop = "OnDragStop",
    })

    frame:HookScript("OnShow", function()
        if not escapeProxy:IsShown() then escapeProxy:Show() end
    end)
    frame:HookScript("OnHide", function()
        if not frame:IsShown() and escapeProxy:IsShown() then escapeProxy:Hide() end
    end)
    Internal.EscapeProxy = escapeProxy
    return frame
end

-- 首次打开才建窗；与 KAF Krowi_Options.lua:429-445 同构（错误隔离后仍保证只有一个窗口）。
function Internal.GetFrame(opening)
    if not Internal.Frame then
        (opening or Internal.Tabs[1]):GetSaved()
        if not Internal.Shared then
            Internal.Shared = Internal.ReadWindow(opening or Internal.Tabs[1]) or {}
        end
        local frame = Internal.Build.Window()
        Internal.Frame = frame
        frame.Tooltip = lib.Tooltip
        frame:Init(Internal.Shared or {})
        Internal.WriteShared()
        local tabs = {}
        for i, registered in ipairs(Internal.Tabs) do tabs[i] = registered end
        for _, registered in ipairs(tabs) do
            if registered.Config.onCreated then
                xpcall(function() registered.Config.onCreated(frame) end, CallErrorHandler)
            end
        end
        frame:RefreshTabs()
    end
    return Internal.Frame
end
