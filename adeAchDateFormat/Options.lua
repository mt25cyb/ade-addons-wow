-- adeAchDateFormat — 设置页：基于 ade_UIKit 的 RegisterTab（BOF 原生行）。
-- 按当前库能力裁剪为两个分区：日期格式 / 生效范围；不设配置档页、关于页与颜色选项。
local ADF = _G.adeAchDateFormat
if not ADF then return end
local L = ADF.L or {}
local UIKit = ADF.UIKit or (_G.ResolveBOFNamespace and _G.ResolveBOFNamespace("ade_UIKit"))

local function GetOF()
    return ADF.UIKit or (GetBlizzOptionsFrame and GetBlizzOptionsFrame("ade_UIKit", true))
end

local presetItems
local function PresetItems()
    if presetItems then return presetItems end
    presetItems = {}
    if ADF.UIKit and ADF.UIKit.DATE_PRESET_COUNT then
        for i = 1, ADF.UIKit.DATE_PRESET_COUNT do
            presetItems[i] = { value = tostring(i), text = L["PRESET_" .. i] or tostring(i) }
        end
    end
    presetItems[#presetItems + 1] = { value = "custom", text = L.PRESET_CUSTOM or "Custom" }
    return presetItems
end

--- 统一补上 UIKit 行的 get/set/default 契约（key 为函数参数，避免闭包捕获错误）。
local function KeySpec(spec, key)
    spec.key = key
    spec.get = spec.get or function() return ADF:Get(key) end
    spec.set = spec.set or function(value)
        ADF:Set(key, value)
        ADF:ApplyAll()
    end
    if spec.default == nil then spec.default = ADF:GetDefault(key) end
    return spec
end

local sections = {
    format = {
        { kind = "note", text = L.NOTE_FORMAT or "" },
        KeySpec({ kind = "select", label = L.LABEL_PRESET, items = PresetItems() }, "dateFormat.preset"),
        KeySpec({ kind = "toggle", label = L.LABEL_HIDE_TIME }, "dateFormat.hideTime"),
        KeySpec({ kind = "input", label = L.LABEL_CUSTOM }, "dateFormat.custom"),
        { kind = "note", text = L.NOTE_FORMAT_TOKENS or "" },
    },
    scope = {
        { kind = "note", text = L.NOTE_SCOPE or "" },
        KeySpec({ kind = "toggle", label = L.LABEL_ENABLE_NATIVE }, "enableNative"),
        -- 外部插件支持选项统一口径（b006，规范 _docs/External-Addon-Support-Convention.md）：
        -- 目标插件未加载 → disabled 禁用 + desc 动态提示；已加载 → 恢复可用并显示功能说明。
        KeySpec({
            kind = "toggle", label = L.LABEL_ENABLE_KROWI,
            disabled = function() return not UIKit.IsAddOnLoaded("Krowi_AchievementFilter") end,
            desc = UIKit.IsAddOnLoaded("Krowi_AchievementFilter") and L.DESC_ENABLE_KROWI or L.DESC_NEED_KROWI,
        }, "enableKrowi"),
        KeySpec({
            kind = "toggle", label = L.LABEL_ENABLE_PRAT,
            disabled = function() return not UIKit.IsAddOnLoaded("Prat-3.0") end,
            desc = UIKit.IsAddOnLoaded("Prat-3.0") and L.DESC_ENABLE_PRAT or L.DESC_NEED_PRAT,
        }, "enablePrat"),
        { kind = "note", text = L.NOTE_Z_CONFLICT or "" },
    },
}

local sectionNames = {
    format = L.HEADING_DATE_FORMAT,
    scope = L.HEADING_SCOPE,
}

local sectionKeys = {
    format = { "dateFormat.preset", "dateFormat.hideTime", "dateFormat.custom" },
    scope = { "enableNative", "enableKrowi", "enablePrat" },
}

local function SameValue(a, b)
    if type(a) ~= "table" or type(b) ~= "table" then return a == b end
    for key, value in pairs(a) do if not SameValue(value, b[key]) then return false end end
    for key in pairs(b) do if a[key] == nil then return false end end
    return true
end

local function CountChanged()
    local count = 0
    for _, keys in pairs(sectionKeys) do
        for _, key in ipairs(keys) do
            if not SameValue(ADF:Get(key), ADF:GetDefault(key)) then count = count + 1 end
        end
    end
    return count
end

local function ResetSection(id)
    local keys = sectionKeys[id]
    if not keys then return false end
    local changed = false
    for _, key in ipairs(keys) do
        local value, def = ADF:Get(key), ADF:GetDefault(key)
        if not SameValue(value, def) then
            local copy = type(def) == "table" and ADF.UIKit.DB.DeepCopy(def) or def
            ADF:Set(key, copy)
            changed = true
        end
    end
    if changed then ADF:ApplyAll() end
    return changed
end

local tab

local function Build()
    if tab then return tab end
    local lib = GetOF()
    if not lib then return nil end
    tab = lib.RegisterTab({
        name = ADF.title,
        saved = ADF.db or {},
        groups = {
            { name = L.GROUP_FORMAT or "Date format", sections = { "format" } },
            { name = L.GROUP_SCOPE or "Scope", sections = { "scope" } },
        },
        sectionName = function(id) return sectionNames[id] or id end,
        elements = function(id) return sections[id] or sections.format end,
        landing = function() return "format" end,
        changedCount = CountChanged,
        resetSection = ResetSection,
        onCreated = function() end,
    })
    if lib.RegisterOptionsStub then
        lib.RegisterOptionsStub({
            title = ADF.title,
            version = ADF.version,
            tab = tab,
        })
    end
    return tab
end

--- 加载期注册 tab 与 stub 页（Core ADDON_LOADED 调用；KAF Stub 同款时点）。
--- ade_UIKit 为 ## Dependencies 硬依赖，失败直接 error 暴露，不做静默降级。
function ADF:InitOptionsStub()
    if not Build() then
        error("adeAchDateFormat: 加载期注册设置页失败（ade_UIKit RegisterTab 不可用）")
    end
end

function ADF:RefreshOptions()
    if tab and tab.Refresh then tab:Refresh() end
end

function ADF:ToggleOptions()
    local registered = Build()
    if not registered then
        self:Print("ade_UIKit 未加载：请确认该库已勾选。")
        return
    end
    registered:Toggle("format")
end
