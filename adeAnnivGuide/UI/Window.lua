--[==[ adeAnnivGuide / UI/Window.lua — 12.x 原生风格窗口
    模式逐字对齐 adeMapTab_Delve/UI/RosterWindow.lua:96-112（BasicFrameTemplate +
    SetMovable/SetClampedToScreen/EnableMouse + 整框 RegisterForDrag + TitleText）；
    CloseButton 需自接 OnClick（ade_UIKit/Widget/WindowMixin.lua:31 同款——模板不自带脚本）；
    ESC 走 UISpecialFrames；720×600（用户 2026-11-21）。
    修复记录：① 此前漏 SetMovable(true) 致「StartMoving(): Frame is not movable」；
    ② 此前自绘关闭按钮（common-icon-delete）既不合语义又因 Button 未注册点击而失效，
    改用模板原生 CloseButton（X 字形）并显式接 OnClick。 ]==]
local ns = _G.adeAnnivGuide
local Window = {}
ns.Window = Window

local window, listPage, contentPage

local function BuildWindow()
    window = CreateFrame("Frame", "adeAnnivGuideWindow", UIParent, "BasicFrameTemplate")
    window:SetSize(ns.WIN_W, ns.WIN_H)
    window:SetFrameStrata("DIALOG") -- RosterWindow.lua:104 同款，高于世界地图 FULLSCREEN
    window:SetMovable(true)
    window:SetClampedToScreen(true)
    window:EnableMouse(true)
    window:RegisterForDrag("LeftButton")
    window:SetScript("OnDragStart", function(self) self:StartMoving() end)
    window:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        Window.SavePos()
    end)
    window.TitleText:SetText(ns.L["TITLE"])
    window.CloseButton:SetScript("OnClick", function() window:Hide() end)

    -- ESC 关闭
    table.insert(UISpecialFrames, "adeAnnivGuideWindow")

    -- 双页（先建列表页，后建内容页）
    listPage = ns.ListPage.Create(window)
    contentPage = ns.ContentPage.Create(window)
    contentPage:Hide()

    window:SetScript("OnShow", function() Window.RestorePos() end)
    window:Hide()
end

--- 位置存档（UIParent 居中坐标）。
function Window.SavePos()
    if not (ns.db and window) then return end
    ns.db.settings.pos.x = window:GetLeft() + window:GetWidth() / 2 - GetScreenWidth() / 2
    ns.db.settings.pos.y = window:GetBottom() + window:GetHeight() / 2 - GetScreenHeight() / 2
end

function Window.RestorePos()
    if not (ns.db and window) then return end
    local pos = ns.db.settings.pos
    window:ClearAllPoints()
    if pos.x then
        window:SetPoint("CENTER", UIParent, "CENTER", pos.x, pos.y)
    else
        window:SetPoint("CENTER", UIParent, "CENTER")
    end
end

--- 打开窗口并显示主界面。
function Window.ShowList()
    if not window then BuildWindow() end
    contentPage:Hide()
    listPage:Show()
    window:Show()
end

--- 打开窗口并跳到内容界面。
function Window.ShowContent(entry)
    if not window then BuildWindow() end
    listPage:Hide()
    contentPage:Show()
    ns.ContentPage.Open(entry)
    window:Show()
end

function Window.Toggle()
    if window and window:IsShown() then
        window:Hide()
    else
        Window.ShowList()
    end
end
