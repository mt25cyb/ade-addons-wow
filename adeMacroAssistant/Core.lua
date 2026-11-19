--[==[ adeMacroAssistant / Core.lua — ADE v6.5
私有 addon 表入口：零 _G.ADE / 零 AceLocale / 零 AceConsole。
存档仍用 ADEMA_DB.profile（保留旧结构与旧存档），缺失键由 ade_UIKit.DB.MergeDefaults 补全。
模块调度顺序与 v5 一致；设置页改由 Options.lua 的 UIKit RegisterTab 承担。 ]==]
local addonName = ...
local AM = _G.adeMacroAssistant or {}
_G.adeMacroAssistant = AM
AM.name = addonName or "adeMacroAssistant"

local function GetOF()
    local lib = GetBlizzOptionsFrame and GetBlizzOptionsFrame("ade_UIKit", true)
    if lib then return lib end
    return BOF_LIBS and BOF_LIBS["ade_UIKit"]
end
AM.GetOF = GetOF

-- 名称/版本统一经 UIKit GetAddonMeta 取 TOC 元数据（用户 2026-11-18）。
local addonMeta = GetOF().GetAddonMeta(addonName)
AM.title = addonMeta.title
AM.version = addonMeta.version

function AM:Print(msg)
    if DEFAULT_CHAT_FRAME then
        DEFAULT_CHAT_FRAME:AddMessage(self.title .. ": " .. tostring(msg))
    end
end

local initialized = false
function AM:Init()
    if initialized then return end
    initialized = true

    local db = _G.ADEMA_DB
    if type(db) ~= "table" then db = {}; _G.ADEMA_DB = db end
    if type(db.profile) ~= "table" then db.profile = {} end

    local lib = GetOF()
    if lib and lib.DB and lib.DB.MergeDefaults and self.defaults then
        lib.DB.MergeDefaults(db.profile, self.defaults.profile)
    end
    self.db = db

    -- 一次性迁移：旧 profile 默认未开前缀，按新默认值开启（仅首次）
    local profile = db.profile
    if not profile._version then
        profile._version = 1
        if profile.automacro then profile.automacro.prefixEnabled = true end
    end

    -- 模块调度（同 v4/v5 的 MODULE_KEYS + Init）
    -- MacroSearch 须在 MacroUIResize 之后：前者依赖后者提升的 IsMacroToolkitOverrideActive
    self.MODULE_KEYS = { "AutoMacro", "MacroUIResize", "MacroSearch", "Settings" }
    for _, key in ipairs(self.MODULE_KEYS) do
        local m = self[key]
        if m and m.Init then m.Init() end
    end

    -- 原生「设置 > 插件」的「打开选项」入口页在加载期注册（KAF Stub 同款时点）。
    self:InitOptionsStub()
end

function AM:ApplyAll()
    -- 模块函数均以点号定义（function module.X()），此处必须点调用，冒号会错位传入 self。
    if self.AutoMacro and self.AutoMacro.Refresh then self.AutoMacro.Refresh() end
    if self.MacroUIResize and self.MacroUIResize.ApplySettings then self.MacroUIResize.ApplySettings() end
    if self.MacroSearch and self.MacroSearch.ApplySettings then self.MacroSearch.ApplySettings() end
    if self.RefreshOptions then self:RefreshOptions() end
end

local events = CreateFrame("Frame")
events:RegisterEvent("ADDON_LOADED")
events:SetScript("OnEvent", function(_, event, arg1)
    if event == "ADDON_LOADED" and arg1 == AM.name then
        events:UnregisterEvent("ADDON_LOADED")
        AM:Init()
    end
end)

_G.SLASH_ADEMACROASSISTANT1 = "/adeMacroAssistant"
SlashCmdList["ADEMACROASSISTANT"] = function()
    if AM.Settings then AM.Settings.Toggle() end
end
_G.SLASH_ADEMA1 = "/adema"
_G.SLASH_ADEMA2 = "/adeMA"
SlashCmdList["ADEMA"] = function()
    if AM.Settings then AM.Settings.Toggle() end
end
