--[==[ adeAnnivGuide / Core/Main.lua — 入口：存档初始化 / 自绘小地图按钮 / 斜杠命令
    无库依赖（用户 2026-11-21：去 ade_UIKit，仅小地图按钮为入口）；
    小地图按钮走 Core/Minimap.lua 自绘实现；TOC 元数据走 C_AddOns（12.x 无全局 GetAddOnMetadata）。 ]==]
local addonName = ...
local ns = _G.adeAnnivGuide
ns.name = addonName or "adeAnnivGuide"

function ns:Print(msg)
    if DEFAULT_CHAT_FRAME then
        DEFAULT_CHAT_FRAME:AddMessage(self.title .. ": " .. tostring(msg))
    end
end

--- 自绘小地图按钮（Core/Minimap.lua；角度/显隐持久化到 settings.minimap）。
function ns:InitMinimap()
    if self.minimapBtn then return end
    local settings = self.db.settings

    self.minimapBtn = ns.CreateMinimapButton({
        name = "adeAnnivGuideMinimapButton",
        -- 图标走 TOC IconTexture 元数据，禁止硬编码贴图路径（wow-addon-dev.mdc §5.6）
        icon = C_AddOns.GetAddOnMetadata(self.name, "IconTexture"),
        angle = settings.minimap.angle,
        onAngleChanged = function(angle) settings.minimap.angle = angle end,
        onClick = function() ns.Window.Toggle() end,
        tooltip = {
            title = self.title,
            lines = { self.L["MM_LEFT"] },
        },
    })
    -- 显隐持久化（无库版 setShown 委托内联：创建后按存档决定显隐）
    if settings.minimap.hide then
        self.minimapBtn:Hide()
    end
end

local initialized = false
function ns:Init()
    if initialized then return end
    initialized = true

    -- 存档（settings.* 结构）
    local db = _G.ADEDB_ADEANNIVGUIDE
    if type(db) ~= "table" then db = {}; _G.ADEDB_ADEANNIVGUIDE = db end
    if type(db.settings) ~= "table" then db.settings = {} end
    if type(db.settings.pos) ~= "table" then db.settings.pos = {} end
    if type(db.settings.minimap) ~= "table" then db.settings.minimap = {} end
    self.db = db

    self:InitMinimap()
end

-- 本地化装配（Locales/*.lua 已按 enUS → zhCN → zhTW 顺序加载）
ns.L = ns.Loc[GetLocale()] or ns.Loc.enUS

-- 标题/版本走 TOC 元数据（C_AddOns，12.x 已无全局 GetAddOnMetadata）
ns.title = C_AddOns.GetAddOnMetadata(ns.name, "Title")
ns.version = C_AddOns.GetAddOnMetadata(ns.name, "Version")

local events = CreateFrame("Frame")
events:RegisterEvent("ADDON_LOADED")
events:SetScript("OnEvent", function(_, event, arg1)
    if event == "ADDON_LOADED" and arg1 == ns.name then
        events:UnregisterEvent("ADDON_LOADED")
        ns:Init()
    end
end)

-- /adeanniv：开关攻略窗口
_G.SLASH_ADEANNIVGUIDE1 = "/adeanniv"
SlashCmdList["ADEANNIVGUIDE"] = function(input)
    local cmd = (input or ""):lower():match("^%s*(%S*)") or ""
    if cmd == "" then
        ns.Window.Toggle()
    else
        ns:Print(ns.L["CMD_HINT"])
    end
end
