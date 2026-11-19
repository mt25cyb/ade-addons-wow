--[==[ adeStatPlus / Core.lua — ADE v6.5（第一批：数据/采集 + 极简面板 + 设置页 + 小地图）
私有 addon 表入口：零 _G.ADE / 零 AceLocale / 零 AceConsole / 零 LSM。
存档仍用 ADEDB_ADESTATPLUS.profile（保留旧结构与旧存档），缺失键由 ade_UIKit.DB.MergeDefaults 补全。
第一批调度：SourceRegistry → Collector → Bars → Panel；Radar/Ring/SortWindow/CharPanel 属第二批，
其专属存档字段（charPanel.* 等）已随默认值合并补全，第二批接入后即生效。 ]==]
local addonName = ...
local SP = _G.adeStatPlus or {}
_G.adeStatPlus = SP
SP.name = addonName or "adeStatPlus"

local function GetOF()
    local lib = GetBlizzOptionsFrame and GetBlizzOptionsFrame("ade_UIKit", true)
    if lib then return lib end
    return BOF_LIBS and BOF_LIBS["ade_UIKit"]
end
SP.GetOF = GetOF

-- 名称/版本/图标统一经 UIKit GetAddonMeta 取 TOC 元数据（用户 2026-11-18）；
-- GetAddOnMetadata 按客户端 locale 返回对应 Title（zhCN 即「[ADE] 属性面板」）。
local meta = GetOF().GetAddonMeta(addonName)
SP.title = meta.title
SP.version = meta.version

function SP:Print(msg)
    if DEFAULT_CHAT_FRAME then
        DEFAULT_CHAT_FRAME:AddMessage(self.title .. ": " .. tostring(msg))
    end
end

local initialized = false
function SP:Init()
    if initialized then return end
    initialized = true

    local db = _G.ADEDB_ADESTATPLUS
    if type(db) ~= "table" then db = {}; _G.ADEDB_ADESTATPLUS = db end
    if type(db.profile) ~= "table" then db.profile = {} end

    local lib = GetOF()
    if lib and lib.DB and lib.DB.MergeDefaults and self.defaults then
        lib.DB.MergeDefaults(db.profile, self.defaults.profile)
    end
    self.db = db

    -- 模块调度（注册表 → 取值 → 条 → 面板；Media 无 Init 无需调度）。
    -- 第二批：SortWindow（L 装配，窗口惰建）→ CharPanel（图形 Radar/Ring 已删除）。
    self.INIT_ORDER = { "SourceRegistry", "Collector", "Bars", "Panel", "SortWindow", "CharPanel" }
    for _, name in ipairs(self.INIT_ORDER) do
        local mod = self[name]
        if mod and mod.Init then mod.Init() end
    end

    -- 原生「设置 > 插件」的「打开选项」入口页在加载期注册（KAF Stub 同款），
    -- 不能等首次打开设置窗口——否则此前原生设置里根本看不到本插件。
    self.Options.Init()

    self:InitMinimap()
end

--- 自绘小地图按钮（零依赖；位置/显隐持久化到 profile.minimap）。
-- 旧基座版仅左键切换面板（D17）；图标走 GetAddonMeta（IconTexture 优先于 IconAtlas）。
function SP:InitMinimap()
    local lib = GetOF()
    local profile = self.db.profile.minimap
    if not (lib and lib.CreateMinimapButton) or self.minimapBtn then return end

    -- 12.x 已移除全局 GetAddOnMetadata，走 C_AddOns（实证 adeChatBar/Minimap.lua:104）。
    -- 图标两态归一走 GetAddonMeta（IconTexture 优先于 IconAtlas），不静默回退。
    self.minimapBtn = lib.CreateMinimapButton({
        name = "adeStatPlusMinimapButton",
        icon = lib.GetAddonMeta(self.name).icon,
        angle = profile.angle,
        getShown = function() return not profile.hide end,
        setShown = function(shown) profile.hide = not shown end,
        onAngleChanged = function(angle) profile.angle = angle end,
        onClick = function(_, mouseButton)
            -- 右键打开设置窗口（用户 2026-11-18）；UIKit MinimapButton 已注册
            -- RightButtonUp 并把键名传入 onClick（MinimapButton.lua:62,102-104）。
            if mouseButton == "RightButton" then
                self.OpenSettings()
            else
                self.Panel.Toggle()
            end
        end,
        tooltip = {
            title = self.title,
            lines = {
                self.L and self.L["MM_LEFT"] or "",
                self.L and self.L["MM_RIGHT"] or "",
            },
        },
    })
end

--- 全量刷新：配置变更时统一走此处，避免部分视图不生效。
local function RefreshAllViews()
    SP.Panel.RefreshAll()
    if SP.Options and SP.Options.SyncDisabled then SP.Options.SyncDisabled() end
    -- 第二批：角色面板条/图形配置变更即时生效（数值变化走 Collector.RegisterRefresh）
    if SP.CharPanel and SP.CharPanel.Refresh then SP.CharPanel.Refresh() end
end
SP.RefreshAllViews = RefreshAllViews

local events = CreateFrame("Frame")
events:RegisterEvent("ADDON_LOADED")
events:SetScript("OnEvent", function(_, event, arg1)
    if event == "ADDON_LOADED" and arg1 == SP.name then
        events:UnregisterEvent("ADDON_LOADED")
        SP:Init()
        RefreshAllViews()
    end
end)

--- 打开设置窗口（Options.lua 提供 tab）。
function SP.OpenSettings()
    if SP.Options and SP.Options.Open then SP.Options.Open() end
end

-- /adsp：面板控制（与旧版一致）；/adeSP：直接打开设置窗口
_G.SLASH_ADESTATPLUS1 = "/adsp"
SlashCmdList["ADESTATPLUS"] = function(input)
    local cmd = (input or ""):lower():match("^%s*(%S*)") or ""
    if cmd == "panel" then
        SP.Panel.Toggle()
    elseif cmd == "sort" then
        SP.SortWindow.Toggle()
    elseif cmd == "config" then
        SP.OpenSettings()
    else
        SP:Print(SP.L["CMD_USAGE"])
    end
end
_G.SLASH_ADESTATHINT1 = "/adeSP"
SlashCmdList["ADESTATHINT"] = function() SP.OpenSettings() end
