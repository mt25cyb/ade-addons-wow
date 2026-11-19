--[==[ adeMacroAssistant / Settings.lua — ADE v6.5 设置兼容层
保留 v5 ns.Settings 的对外契约（Init / Toggle / UpdateValues），供 MacroSearch 调用；
AceGUI 控件页已全部移除。
导入/导出：本文件只负责 payload（schemaVersion + automacro）的构造、校验与写回；
字符串编解码走 ade_UIKit 的 lib.ShareString（CBOR→压缩→Base64，MiliUI_Tooltip 同款），
UI 由 Options.lua 的 execute 按钮 + multiline 行承载。 ]==]
local AM = _G.adeMacroAssistant
if not AM then return end
local L = AM.L or {}

local module = {}
AM.Settings = module

module.TYPE_ORDER = { "cleanse", "purge", "dispel", "interrupt", "resurrection", "sprint", "taunt" }
module.TYPE_LABELS = {
    cleanse = "SPELLTYPE_CLEANSE", purge = "SPELLTYPE_PURGE", dispel = "SPELLTYPE_DISPEL",
    interrupt = "SPELLTYPE_INTERRUPT", resurrection = "SPELLTYPE_RESURRECTION",
    sprint = "SPELLTYPE_SPRINT", taunt = "SPELLTYPE_TAUNT",
}
module.SCHEMA_VERSION = 1
module.WIRE_PREFIX = "ADEMA!"

-- ===================== payload 构造 / 校验 / 写回 =====================

local function BuildAutomacro(profile)
    local automacro = {}
    for _, v in ipairs(module.TYPE_ORDER) do
        local cfg = profile and profile.automacro and profile.automacro[v]
        if cfg then
            automacro[v] = {
                enabled = cfg.enabled and true or false,
                base = type(cfg.base) == "string" and cfg.base or "",
                body = type(cfg.body) == "string" and cfg.body or "",
            }
        end
    end
    return automacro
end

--- 生成导出 payload（纯表，交给 UIKit 编成字符串）。
function module.BuildExport()
    return { schemaVersion = module.SCHEMA_VERSION, automacro = BuildAutomacro(AM.db and AM.db.profile) }
end

--- 校验导入 payload。返回 true/false，遵循 UIKit ShareString.Decode 的 validate 契约。
function module.ValidatePayload(data)
    if type(data) ~= "table" then return false end
    if type(data.schemaVersion) ~= "number" or data.schemaVersion > module.SCHEMA_VERSION then return false end
    if type(data.automacro) ~= "table" then return false end
    for _, v in ipairs(module.TYPE_ORDER) do
        local cfg = data.automacro[v]
        if cfg ~= nil then
            if type(cfg) ~= "table" then return false end
            if cfg.enabled ~= nil and type(cfg.enabled) ~= "boolean" then return false end
            if cfg.base ~= nil and type(cfg.base) ~= "string" then return false end
            if cfg.body ~= nil and type(cfg.body) ~= "string" then return false end
        end
    end
    return true
end

--- 把已校验 payload 写回当前 profile（只覆盖 automacro 的 7 类，其余不动）。
function module.ApplyPayload(data)
    if not module.ValidatePayload(data) then return false end
    local profile = AM.db and AM.db.profile
    if not profile then return false end
    profile.automacro = profile.automacro or {}
    for _, v in ipairs(module.TYPE_ORDER) do
        local incoming = data.automacro[v]
        local cfg = profile.automacro[v]
        if incoming and cfg then
            if incoming.enabled ~= nil then cfg.enabled = incoming.enabled end
            if incoming.base ~= nil then cfg.base = incoming.base end
            if incoming.body ~= nil then cfg.body = incoming.body end
        end
    end
    if AM.AutoMacro and AM.AutoMacro.Refresh then AM.AutoMacro.Refresh() end
    module.UpdateValues()
    return true
end

-- ===================== 对外契约 =====================
function module.Init() end

function module.Toggle()
    if AM.ToggleOptions then AM:ToggleOptions() end
end

function module.UpdateValues()
    if AM.RefreshOptions then AM:RefreshOptions() end
end
