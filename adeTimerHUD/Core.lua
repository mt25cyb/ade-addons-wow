-- adeTimerHUD / Core.lua — 入口：加载期 slash 注册 + ADDON_LOADED 装配 + 模块调度
-- 范式实证 adeChatBar/Core.lua:9-13(GetOF)、:135-145(EnsureSettings)、:191-205(加载期 slash)。
-- slash 必须在加载期注册（吸取 adeStatesTimer 教训：Init 链中断会让命令失效）。
local addonName = ...
local ns = _G.adeTimerHUD or {}
_G.adeTimerHUD = ns
ns.name = addonName

local function GetOF()
    local lib = GetBlizzOptionsFrame and GetBlizzOptionsFrame("ade_UIKit", true)
    if lib then return lib end
    return BOF_LIBS and BOF_LIBS["ade_UIKit"]
end
ns.GetOF = GetOF

-- 对齐 adeBagPack/Core.lua:23-32：ade_UIKit 为 Dependencies 硬依赖，
-- 加载期硬校验并缓存到 ns.UIKit（Options.GetOF 优先消费，避免登录时序导致入口缺失）。
local lib = GetOF()
if not lib then
    error("adeTimerHUD: ade_UIKit 未就绪（检查 Dependencies 与加载顺序）")
end
ns.UIKit = lib
if lib.GetAddonMeta then
    local meta = lib.GetAddonMeta(addonName)
    ns.title = meta.title
    ns.version = meta.version
end

local L = ns.L or {}
ns.L = L

function ns:Print(msg)
    if DEFAULT_CHAT_FRAME then
        DEFAULT_CHAT_FRAME:AddMessage(self.title .. ": " .. tostring(msg))
    end
end

--- 补全 settings 默认值（UIKit DB.MergeDefaults 实证 adeStatPlus/Core.lua:39-42）
local function EnsureSettings()
    local db = _G.ADEDB_TIMERHUD
    if type(db) ~= "table" then db = {}; _G.ADEDB_TIMERHUD = db end
    if type(db.settings) ~= "table" then db.settings = {} end
    local lib = GetOF()
    if lib and lib.DB and lib.DB.MergeDefaults and ns.defaults then
        lib.DB.MergeDefaults(db.settings, ns.defaults.settings)
    end
    -- r006：用户明确不考虑老存档——无 MigrateSettings；仅由 MergeDefaults 补全缺失键
    ns.db = db
end

local initialized = false
function ns:Init()
    if initialized then return end
    initialized = true
    EnsureSettings()
    ns.Clock.Init()
    -- 加载期注册 tab 与「设置 > 插件」Stub（adeBagPack/Core 同款时点、硬失败暴露）
    if ns.InitOptionsStub then ns.InitOptionsStub() end
end

-- ADDON_LOADED 在加载期注册，ade_UIKit 依赖保证其已就绪
local events = CreateFrame("Frame")
events:RegisterEvent("ADDON_LOADED")
events:SetScript("OnEvent", function(self, event, name)
    if name ~= addonName then return end
    ns:Init()
    self:UnregisterEvent("ADDON_LOADED")
end)

-- 斜杠命令加载期注册（命令入口自驱 Init，避免依赖链中断）
_G.SLASH_ADETIMERHUD1 = "/ath"
_G.SLASH_ADETIMERHUD2 = "/adeTimerHUD"
SlashCmdList["ADETIMERHUD"] = function(msg)
    if not ns.db then ns:Init() end
    local cmd = (msg or ""):lower():match("^%s*(%S*)") or ""
    if cmd == "" or cmd == "options" or cmd == "config" then
        ns.OpenSettings()
    elseif cmd == "reset" then
        ns.Clock.ResetPosition()
        ns:Print(L.MSG_RESET_POSITION or "Clock position and size reset.")
    else
        ns:Print(L.CMD_HELP or "Commands: /ath, /ath options, /ath reset")
    end
end
