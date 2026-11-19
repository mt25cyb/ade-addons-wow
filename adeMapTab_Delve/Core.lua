--[==[ adeMapTab_Delve / Core.lua — ADE v6.5
私有 addon 表入口：零 _G.ADE / 零 AceConsole / 零 AceDB / 无独立设置页（口径：设置只留
世界地图 Tab 内齿轮页，UI/Settings.lua 已删除，不注册 UIKit OptionsStub）。
存档仍用 ADEDB_MAP_TAB_DELVE.profile（扁平键 + Database.Initialize 补嵌套表），
缺失键由 ade_UIKit.DB.MergeDefaults 补全；无 profile 管理（按 v6.5 口径不提供）。
事件顺序沿用 v4/v5：ADDON_LOADED 建库、PLAYER_LOGIN 建界面、PLAYER_ENTERING_WORLD 补快照。 ]==]
local addonName, addon = ...

local function GetOF()
    local lib = GetBlizzOptionsFrame and GetBlizzOptionsFrame("ade_UIKit", true)
    if lib then return lib end
    return BOF_LIBS and BOF_LIBS["ade_UIKit"]
end

local initialized = false

local function SetupDatabase()
    local db = _G.ADEDB_MAP_TAB_DELVE
    if type(db) ~= "table" then db = {}; _G.ADEDB_MAP_TAB_DELVE = db end
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
    _G.SLASH_ADEMAPTABDELVE1 = "/ademaptabdelve"
    _G.SLASH_ADEDELVETAB1 = "/adedelvetab"
    _G.SLASH_ADEDT1 = "/adedt"
    _G.SLASH_ADEMTD1 = "/adeMTD" -- 旧版为基座设置入口；v6.5 无独立设置页，开面板
    SlashCmdList["ADEMAPTABDELVE"] = open
    SlashCmdList["ADEDELVETAB"] = open
    SlashCmdList["ADEDT"] = open
    SlashCmdList["ADEMTD"] = open
end

local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("PLAYER_LOGIN")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:SetScript("OnEvent", function(_, event, arg1)
    if event == "ADDON_LOADED" and arg1 == addonName then
        if initialized then return end
        initialized = true
        SetupDatabase()
        addon.MinimapIcon:Init()
        RegisterCommands()
        -- 12.x 强制：先 SetScript 再 RegisterEvent（原 EventFrame 逻辑并入本 frame）。
        addon.EventFrame = frame
    elseif event == "PLAYER_LOGIN" then
        addon.Roster:Capture()
        addon.MapPanel.Initialize()
    elseif event == "PLAYER_ENTERING_WORLD" then
        if not initialized then return end
        addon.Roster:Capture()
        addon.MapPanel.RefreshPanel()
    end
end)
