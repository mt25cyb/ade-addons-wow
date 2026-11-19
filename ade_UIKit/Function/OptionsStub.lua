------------------------------------------------------------
-- 原生选项界面「打开选项」入口页（b023）
-- 蓝本：Krowi_AchievementFilter/Options/Window/Stub.lua:10-45
--   Settings.RegisterCanvasLayoutCategory(frame, title)
--   Settings.RegisterAddOnCategory(category)
-- 每个使用独立设置窗口的 ADE v6.5 插件在原生「设置 > 插件」里留一个 stub 页，
-- 说明选项在插件自己的窗口里，并提供「打开选项」按钮调用宿主 tab:Open()。
-- 刻意不代暴雪关设置面板（KAF Stub.lua:6-9 的 taint 教训）：本页按钮只 Show 自己的窗口，
-- 面板保持打开，窗口 HIGH 层级浮在其上。
------------------------------------------------------------
local lib = ResolveBOFNamespace("ade_UIKit")
if not lib then return end

local L = lib.L

--- 在原生选项界面注册一个「打开选项」入口页。
---@param spec table {
---   title = string,              分类名（通常传插件显示名）
---   version = string|nil,        版本号，显示在标题下方
---   hint = string|nil,           说明文字（默认「选项在插件自己的窗口中」）
---   ways = string|nil,           补充提示（默认「也可用 /命令 打开」；传 false 则不显示）
---   buttonText = string|nil,     按钮文案（默认 L["BOF_OPEN_OPTIONS"]）
---   tab = table,                 RegisterTab 返回的 Tab 对象，点击调用 tab:Open(sectionId)
---   sectionId = string|nil,      传给 tab:Open 的分区 id（默认 nil → 落地分区）
--- }
---@return table|nil category Settings category，便于 Settings.OpenToCategory(cat:GetID())
function lib.RegisterOptionsStub(spec)
    if type(spec) ~= "table" or type(spec.tab) ~= "table" or type(spec.tab.Open) ~= "function" then
        return nil
    end
    if not (Settings and Settings.RegisterCanvasLayoutCategory and Settings.RegisterAddOnCategory) then
        return nil
    end

    local frame = CreateFrame("Frame")
    local title = frame:CreateFontString(nil, "ARTWORK", "GameFontNormalHuge")
    title:SetPoint("TOPLEFT", 16, -16)
    title:SetText(spec.title or lib.MAJOR)

    local anchor = title
    if spec.version then
        local version = frame:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
        version:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -6)
        version:SetText(tostring(spec.version))
        anchor = version
    end

    local text = frame:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    text:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, -20)
    text:SetPoint("RIGHT", -16, 0)
    text:SetJustifyH("LEFT")
    text:SetText(spec.hint or L["BOF_OPTIONS_STUB_HINT"])

    local button = CreateFrame("Button", nil, frame, "UIPanelButtonNoTooltipTemplate")
    button:SetSize(180, 26)
    button:SetPoint("TOPLEFT", text, "BOTTOMLEFT", 0, -16)
    button:SetText(spec.buttonText or L["BOF_OPEN_OPTIONS"])
    button:SetScript("OnClick", function()
        spec.tab:Open(spec.sectionId)
    end)

    if spec.ways ~= false then
        local ways = frame:CreateFontString(nil, "ARTWORK", "GameFontDisable")
        ways:SetPoint("TOPLEFT", button, "BOTTOMLEFT", 0, -16)
        ways:SetPoint("RIGHT", -16, 0)
        ways:SetJustifyH("LEFT")
        ways:SetText(spec.ways or L["BOF_OPTIONS_STUB_WAYS"])
    end

    local category = Settings.RegisterCanvasLayoutCategory(frame, spec.title or lib.MAJOR)
    Settings.RegisterAddOnCategory(category)
    return category
end
