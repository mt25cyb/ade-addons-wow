--[==[ adeMapTab_Delve / Core.lua — ADE v6.5
私有 addon 表入口：零 _G.ADE / 零 AceConsole / 零 AceDB / 无独立设置页（口径：设置只留
世界地图 Tab 内齿轮页，UI/Settings.lua 已删除，不注册 UIKit OptionsStub）。
存档仍用 ADEDB_MAP_TAB_DELVE.profile（扁平键 + Database.Initialize 补嵌套表），
缺失键由 ade_UIKit.DB.MergeDefaults 补全；无 profile 管理（按 v6.5 口径不提供）。
事件顺序沿用 v4/v5：ADDON_LOADED 建库、PLAYER_LOGIN 建界面、PLAYER_ENTERING_WORLD 补快照。 ]==]
local addonName, addon = ...
local L = addon.L  -- Locales\*.lua（先于本文件加载）经 addon.L 导出；本文件 r003 起有本地化文案

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

-- r003：/way 路点命令 —— /way #<mapID> x y <名称>（#mapID 与名称均可选；
-- 省略 #mapID 时用当前地图）。坐标 >1 按百分数折算（/100，路点类插件通例），结果 clamp 0~1。
-- 行为：设置暴雪原生路点并立即追踪（原生无名称通道，名称进聊天反馈）；
-- TomTom 已加载时同步添加同名 TomTom 路点。
local function HandleWayCommand(msg)
    msg = (msg or "")
    local mapID, xStr, yStr, name = msg:match("^#(%d+)%s+([%d%.]+)%s+([%d%.]+)%s*(.*)$")
    if not mapID then
        xStr, yStr, name = msg:match("^([%d%.]+)%s+([%d%.]+)%s*(.*)$")
        if xStr then
            mapID = (WorldMapFrame and WorldMapFrame.GetMapID and WorldMapFrame:GetMapID())
                or (C_Map and C_Map.GetBestMapForUnit and C_Map.GetBestMapForUnit("player"))
        end
    end
    local x, y = tonumber(xStr), tonumber(yStr)
    if not (mapID and x and y) then
        print("|T" .. ICON_DELVE .. ":14:14|t " .. (L["WAY_USAGE"] or "Usage: /way #<mapID> x y <name>"))
        return
    end
    if x > 1 then x = x / 100 end
    if y > 1 then y = y / 100 end
    x = math.min(1, math.max(0, x))
    y = math.min(1, math.max(0, y))
    name = ((name or ""):gsub('^"(.*)"$', "%1")):match("^%s*(.-)%s*$")
    if C_Map.CanSetUserWaypointOnMap and not C_Map.CanSetUserWaypointOnMap(tonumber(mapID)) then
        print("|T" .. ICON_DELVE .. ":14:14|t " .. (L["WAYPOINT_UNAVAILABLE"] or ""))
        return
    end
    local set = false
    if UiMapPoint and UiMapPoint.CreateFromCoordinates and C_Map.SetUserWaypoint then
        local point = UiMapPoint.CreateFromCoordinates(tonumber(mapID), x, y)
        if point then
            C_Map.SetUserWaypoint(point)
            if C_SuperTrack and C_SuperTrack.SetSuperTrackedUserWaypoint then
                C_SuperTrack.SetSuperTrackedUserWaypoint(true)
            end
            set = true
        end
    end
    local tomtom = _G.TomTom
    if tomtom and tomtom.AddWaypoint then
        tomtom:AddWaypoint(tonumber(mapID), x, y, { title = (name ~= "" and name) or nil })
    end
    if set then
        -- 名称的可行落点（原生 user waypoint 无名称通道，已查证；Simple Waypoints 同款处理：
        -- z-ref_retail_Interface_AddOns/SimpleWaypoints/SimpleWaypoints.lua:109-110 名称只进聊天文本）：
        -- TomTom title + 聊天反馈名称，末尾追加原生 Map Pin 链接（GetUserWaypointHyperlink，
        -- wiki _1-1_Main.md:5737；链接文案固定 MAP_PIN_HYPERLINK，可点击查看/分享）。
        local link = C_Map.GetUserWaypointHyperlink and C_Map.GetUserWaypointHyperlink() or nil
        local msg = string.format(L["WAY_SET_CONFIRM"] or "Waypoint set: #%d %.1f, %.1f %s",
            tonumber(mapID), x * 100, y * 100, name):gsub("%s+$", "")
        if link and link ~= "" then
            msg = msg .. " " .. link
        end
        print("|T" .. ICON_DELVE .. ":14:14|t " .. msg)
    end
end

-- /way 命令的当前占用者（通用检测，不针对特定插件——TomTom、MapPinEnhanced、SimpleWaypoints
-- 等的 SlashCmdList key 各不相同，仅查 SlashCmdList["WAY"] 会漏检）。
-- 依据：有效斜杠命令必须伴生 SLASH_<KEY><n> 全局变量（引擎映射即读这些变量），
-- 故遍历全局 SLASH_* 变量、按命令文本匹配即可覆盖全部注册口径；返回其 SlashCmdList key。
-- 仅在 PLAYER_LOGIN 调用一次（所有插件 ADDON_LOADED 之后，pairs(_G) 一次性开销可接受）。
local function FindWayOwner()
    for k, v in pairs(_G) do
        if type(k) == "string" and type(v) == "string"
            and k:sub(1, 6) == "SLASH_" and v:lower() == "/way" then
            return k:match("^SLASH_(.-)%d+$")
        end
    end
    return nil
end

-- /way 注册放在 PLAYER_LOGIN（所有插件加载完毕），并据此决定右键设路点的行为
-- （DelveEntry 右键统一调 addon.MapPanel.WayRunner，不再区分原生/TomTom 修饰键）：
--   WayRunner 每次调用时动态解析 /way 当前归属（FindWayOwner）：
--     任何路点插件占用 → 调对方 handler，等价执行 `/way #<mapID> x y <名称>`（支持名称）；
--     未被占用（或占用者正是本插件）→ 本地 HandleWayCommand（暴雪原生路点，无名称通道，
--     名称仅聊天反馈 + TomTom 同步）。
--   动态解析的原因：实测（用户 2026-11-21 _debug.log）MPE 在 PLAYER_LOGIN 之后才注册 /way，
--   注册时一次性检测会误判为未占用，导致右键永远走本地实现（路点丢名称）。
--   命令注册只在 PLAYER_LOGIN 做（此刻未被占用才注册；之后对方注册会覆盖引擎映射，/way
--   归对方，与本插件命令并存无冲突）；右键走 WayRunner 与命令注册互不干扰。
local function RegisterWayCommand()
    addon.MapPanel.WayRunner = function(msg)
        local key = FindWayOwner()
        if key and key ~= "ADEDELVEWAY" and _G.SlashCmdList and _G.SlashCmdList[key] then
            local fn = _G.SlashCmdList[key]
            if fn then
                fn(msg)
                return
            end
        end
        HandleWayCommand(msg)
    end
    if not FindWayOwner() then
        _G.SLASH_ADEDELVEWAY1 = "/way"
        SlashCmdList["ADEDELVEWAY"] = HandleWayCommand
    end
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
        RegisterWayCommand()
    elseif event == "PLAYER_ENTERING_WORLD" then
        if not initialized then return end
        addon.Roster:Capture()
        addon.MapPanel.RefreshPanel()
    end
end)
