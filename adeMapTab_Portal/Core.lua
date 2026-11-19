--[==[ adeMapTab_Portal / Core.lua — ADE v6.5
私有 addon 表入口：零 _G.ADE / 零 AceConsole / 零 AceDB / 无独立设置页（口径：设置只留
世界地图 Tab 内齿轮页，UI/Settings.lua 已删除，不注册 UIKit OptionsStub）。
存档仍用 ADEDB_MAP_TAB_PORTAL.profile（扁平键 + Database.Initialize 补嵌套表 + 3 段旧键迁移），
缺失键由 ade_UIKit.DB.MergeDefaults 补全；无 profile 管理（按 v6.5 口径不提供）。
本子插件不注册小地图图标（用户 2026-11-10：仅 adeMapTab_Delve 配小地图）。

经确认的全局例外（暴雪绑定系统硬要求，v4 PT/Core.lua:23-24、Bindings.xml）：
  · BINDING_NAME_ADEPORTALTAB_TOGGLE_PANEL
  · BINDING_NAME_CLICK ADEPortalTabRandomHearthstoneButton:LeftButton
  · ADEMAPTAB_PORTAL_TOGGLE —— Bindings.xml 的面板开关调用入口
  · ADEPortalTabRandomHearthstoneButton —— SecureActionButton 全局名，保留以免破坏用户已保存的按键绑定
除以上四项外不写任何 _G.X。 ]==]
local addonName, addon = ...

-- 按键绑定显示名放在文件加载期赋值（v4/v5 同款位置）：
-- 暴雪绑定系统解析 Bindings.xml 时就会读取 BINDING_NAME_*，不能等到事件期。
-- 此时 Locales/enUS.lua（TOC 更早）已建立 addon.L，两个键均存在。
_G["BINDING_NAME_ADEPORTALTAB_TOGGLE_PANEL"] = addon.L.teleportsWorldMapBinding
_G["BINDING_NAME_CLICK ADEPortalTabRandomHearthstoneButton:LeftButton"] = addon.L.teleportsRandomHearthstoneBinding

local function GetOF()
    local lib = GetBlizzOptionsFrame and GetBlizzOptionsFrame("ade_UIKit", true)
    if lib then return lib end
    return BOF_LIBS and BOF_LIBS["ade_UIKit"]
end

local initialized = false

local function SetupDatabase()
    local db = _G.ADEDB_MAP_TAB_PORTAL
    if type(db) ~= "table" then db = {}; _G.ADEDB_MAP_TAB_PORTAL = db end
    if type(db.profile) ~= "table" then db.profile = {} end
    local lib = GetOF()
    if lib and lib.DB and lib.DB.MergeDefaults and addon.defaults then
        lib.DB.MergeDefaults(db.profile, addon.defaults.profile)
    end
    addon.db = db.profile
    addon.Database.Initialize()
end

local function RegisterCommands()
    local open = function() addon.MapPanel.Open() end
    _G.SLASH_ADEMAPTABPORTAL1 = "/ademaptabportal"
    _G.SLASH_ADEPORTALTAB1 = "/adeportaltab"
    _G.SLASH_ADEPT1 = "/adept"
    _G.SLASH_ADEMTP1 = "/adeMTP" -- 旧版为基座设置入口；v6.5 无独立设置页，开面板
    SlashCmdList["ADEMAPTABPORTAL"] = open
    SlashCmdList["ADEPORTALTAB"] = open
    SlashCmdList["ADEPT"] = open
    SlashCmdList["ADEMTP"] = open
end

local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("PLAYER_LOGIN")
frame:SetScript("OnEvent", function(_, event, arg1)
    if event == "ADDON_LOADED" and arg1 == addonName then
        if initialized then return end
        initialized = true
        SetupDatabase()
        RegisterCommands()
    elseif event == "PLAYER_LOGIN" then
        addon.Hearthstones.EnsureDefaultName()
        addon.Hearthstones.EnsureButton()
        addon.MapPanel.Initialize()
        addon.MapPanel.Refresh()
        addon.ZoneButtons.Initialize()
    end
end)

-- 经确认的例外：Bindings.xml 的 <Binding> 只能调全局函数（子插件 ns 是私有表）。
_G.ADEMAPTAB_PORTAL_TOGGLE = function()
    addon.MapPanel.Open()
end
