-- adeAchDateFormat — 核心：存档、设置读写、刷新调度、slash 入口。
-- 日期格式化统一委托 ade_UIKit 的 FormatDate；本插件只持有设置与 hook。
local addonName = ...
local ADF = _G.adeAchDateFormat or {}
_G.adeAchDateFormat = ADF
ADF.name = addonName or "adeAchDateFormat"

-- ade_UIKit 为 ## Dependencies 硬依赖，直接取用；缺失即报错暴露，不静默降级。
local OF = GetBlizzOptionsFrame("ade_UIKit", true)
ADF.UIKit = OF
-- 名称/版本统一经 UIKit GetAddonMeta 取 TOC 元数据（用户 2026-11-18）。
local addonMeta = OF.GetAddonMeta(addonName)
ADF.title = addonMeta.title
ADF.version = addonMeta.version
ADF.ACCENT = OF.ColorHex(238 / 255, 228 / 255, 174 / 255)

local refreshers = {}
local GetPath, SetPath

local function InitPaths()
    if not OF then return end
    GetPath, SetPath = OF.GetPath, OF.SetPath
end

function ADF:Get(key)
    if not self.db or not GetPath then return nil end
    return GetPath(self.db.settings, key)
end

function ADF:Set(key, value)
    if not self.db or not SetPath then return end
    SetPath(self.db.settings, key, value)
end

function ADF:GetDefault(key)
    if not GetPath then return nil end
    return GetPath(self.DEFAULTS.settings, key)
end

function ADF:InitDB()
    if type(_G.adeAchDateFormatDB) ~= "table" then _G.adeAchDateFormatDB = {} end
    local db = _G.adeAchDateFormatDB
    if type(db.settings) ~= "table" then db.settings = {} end
    self.db = db
    if OF and OF.DB and OF.DB.MergeDefaults then
        OF.DB.MergeDefaults(db.settings, self.DEFAULTS.settings)
    else
        for key, value in pairs(self.DEFAULTS.settings) do
            if db.settings[key] == nil then db.settings[key] = value end
        end
    end
    db.version = self.version
    return db
end

function ADF:ResetSettings()
    if not self.db then return end
    self.db.settings = {}
    if OF and OF.DB and OF.DB.MergeDefaults then
        OF.DB.MergeDefaults(self.db.settings, self.DEFAULTS.settings)
    end
    self:ApplyAll()
end

--- 注册设置变更后的重绘回调（NativeHooks / Ext_Krowi_AF / Ext_Prat 各自注册）。
function ADF.RegisterRefresh(fn)
    if type(fn) == "function" then refreshers[#refreshers + 1] = fn end
end

function ADF:ApplyAll()
    for _, fn in ipairs(refreshers) do
        local ok, err = pcall(fn)
        if not ok and DEFAULT_CHAT_FRAME then
            DEFAULT_CHAT_FRAME:AddMessage("|cffff5555" .. self.title .. " refresh error:|r " .. tostring(err))
        end
    end
    if self.RefreshOptions then self:RefreshOptions() end
end

function ADF:Print(msg)
    if DEFAULT_CHAT_FRAME then
        DEFAULT_CHAT_FRAME:AddMessage(self.title .. ": " .. tostring(msg))
    end
end

local events = CreateFrame("Frame")
events:RegisterEvent("ADDON_LOADED")
events:RegisterEvent("PLAYER_LOGIN")
events:SetScript("OnEvent", function(_, event, arg1)
    if event == "ADDON_LOADED" and arg1 == ADF.name then
        InitPaths()
        ADF:InitDB()
        -- 原生「设置 > 插件」的「打开选项」入口页在加载期注册（KAF Stub 同款时点）。
        ADF:InitOptionsStub()
        events:UnregisterEvent("ADDON_LOADED")
    elseif event == "PLAYER_LOGIN" then
        if not ADF.db then
            InitPaths()
            ADF:InitDB()
        end
        ADF:ApplyAll()
        events:UnregisterEvent("PLAYER_LOGIN")
    end
end)

_G.SLASH_ADEACHDATEFORMAT1 = "/aadf"
_G.SLASH_ADEACHDATEFORMAT2 = "/adeachdateformat"
SlashCmdList["ADEACHDATEFORMAT"] = function(msg)
    local cmd = (msg or ""):lower():match("^%s*(%S*)") or ""
    if cmd == "" or cmd == "options" or cmd == "config" then
        ADF:ToggleOptions()
    elseif cmd == "reset" then
        ADF:ResetSettings()
        ADF:Print(L.MSG_RESET or "settings reset to defaults.")
    else
        ADF:Print(L.CMD_HELP or "commands: /aadf, /aadf reset")
    end
end
