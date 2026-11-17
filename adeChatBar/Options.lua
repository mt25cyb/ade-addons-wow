-- adeChatBar — 设置窗口：基于 ade_UIKit（v6.5）原生 Tab/elements。
-- 按已确认口径裁剪：只保留设置页；不设配置档管理、关于页与主题色选项。
-- 主题色走 ADE 固定色 #EEE4AE（ACB.ACCENT），不由本页修改。
local ACB = _G.adeChatBar
if not ACB then return end
local L = ACB.L or {}

-- 库解析延迟到命令/构建时，避免加载顺序导致顶层 return 后连 slash 都没注册。
local function GetOF()
    local lib = GetBlizzOptionsFrame and GetBlizzOptionsFrame("ade_UIKit", true)
    if lib then return lib end
    return BOF_LIBS and BOF_LIBS["ade_UIKit"]
end

local function CopyValue(v)
    if type(v) ~= "table" then return v end
    local copy = {}
    for key, sub in pairs(v) do copy[key] = CopyValue(sub) end
    return copy
end

local function ChoiceItems(key)
    local items = {}
    for _, value in ipairs(ACB.CHOICES[key] or {}) do
        items[#items + 1] = { value = value, text = ACB.CHOICE_TEXT[value] or tostring(value) }
    end
    return items
end

--- 补上 BOF 行契约：get/set/default 直接从 ACB 的设置读写转发。
local function KeySpec(spec, key)
    spec.key = key
    spec.get = spec.get or function() return ACB:Get(key) end
    spec.set = spec.set or function(value)
        ACB:Set(key, value)
        ACB:ApplyAll()
    end
    if spec.default == nil then spec.default = ACB:GetDefault(key) end
    return spec
end

local sections = {
    appearance = {
        { kind = "note", text = L.NOTE_APPEARANCE or "" },
        KeySpec({ kind = "select", label = L.LABEL_COLOR_SCHEME, items = ChoiceItems("colorScheme") }, "colorScheme"),
        KeySpec({ kind = "range", label = L.LABEL_BTN_SIZE, min = 16, max = 40, step = 1 }, "btnSize"),
        KeySpec({ kind = "range", label = L.LABEL_BTN_GAP, min = -5, max = 12, step = 1 }, "btnGap"),
        KeySpec({ kind = "range", label = L.LABEL_FONT_SIZE, min = 10, max = 20, step = 1 }, "fontSize"),
    },
    channels = {
        { kind = "note", text = L.NOTE_CHANNELS or "" },
        KeySpec({ kind = "input", label = L.LABEL_WORLD_CHANNEL }, "worldChannel"),
        KeySpec({ kind = "input", label = L.LABEL_TRADE_CHANNEL }, "tradeChannel"),
        KeySpec({ kind = "toggle", label = L.LABEL_AUTO_JOIN }, "autoJoinWorldChannel"),
        KeySpec({ kind = "range", label = L.LABEL_AUTO_JOIN_DELAY, min = 0, max = 30, step = 1 }, "autoJoinDelay"),
    },
    position = {
        { kind = "note", text = L.NOTE_POSITION or "" },
        KeySpec({ kind = "input", label = L.LABEL_ATTACH_TARGET }, "attachTarget"),
        KeySpec({ kind = "select", label = L.LABEL_ATTACH_POINT,
            items = ChoiceItems("attachPosition.point") }, "attachPosition.point"),
        KeySpec({ kind = "select", label = L.LABEL_ATTACH_RELATIVE_POINT,
            items = ChoiceItems("attachPosition.relativePoint") }, "attachPosition.relativePoint"),
        KeySpec({ kind = "range", label = L.LABEL_ATTACH_X, min = -400, max = 400, step = 1 }, "attachPosition.x"),
        KeySpec({ kind = "range", label = L.LABEL_ATTACH_Y, min = -400, max = 400, step = 1 }, "attachPosition.y"),
    },
    fallback = {
        { kind = "note", text = L.NOTE_FALLBACK or "" },
        KeySpec({ kind = "range", label = L.LABEL_FALLBACK_X, min = -800, max = 800, step = 10 }, "defaultPosition.x"),
        KeySpec({ kind = "range", label = L.LABEL_FALLBACK_Y, min = 0, max = 1200, step = 10 }, "defaultPosition.y"),
    },
    minimap = {
        { kind = "note", text = L.NOTE_MINIMAP or "" },
        KeySpec({ kind = "toggle", label = L.LABEL_BAR_SHOWN }, "barShown"),
        KeySpec({ kind = "toggle", label = L.LABEL_MINIMAP_SHOWN }, "minimapShown"),
    },
}

local sectionNames = {
    appearance = L.HEADING_APPEARANCE,
    channels = L.HEADING_CHANNELS,
    position = L.HEADING_POSITION,
    fallback = L.HEADING_FALLBACK,
    minimap = L.HEADING_MINIMAP,
}

local sectionKeys = {
    appearance = { "colorScheme", "btnSize", "btnGap", "fontSize" },
    channels = { "worldChannel", "tradeChannel", "autoJoinWorldChannel", "autoJoinDelay" },
    position = { "attachTarget", "attachPosition.point", "attachPosition.relativePoint",
        "attachPosition.x", "attachPosition.y" },
    fallback = { "defaultPosition.x", "defaultPosition.y" },
    minimap = { "barShown", "minimapShown" },
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
            if not SameValue(ACB:Get(key), ACB:GetDefault(key)) then count = count + 1 end
        end
    end
    return count
end

local function ResetSection(id)
    local keys = sectionKeys[id]
    if not keys then return false end
    local changed = false
    for _, key in ipairs(keys) do
        local value = ACB:Get(key)
        local def = ACB:GetDefault(key)
        if not SameValue(value, def) then
            ACB:Set(key, CopyValue(def))
            changed = true
        end
    end
    if changed then ACB:ApplyAll() end
    return changed
end

local tab

local function Build()
    if tab then return tab end
    local lib = GetOF()
    if not lib then return nil end
    tab = lib.RegisterTab({
        name = L.ADDON_TITLE or "adeChatBar",
        saved = ACB.db or {},
        groups = {
            { name = L.GROUP_UI or "UI", sections = { "appearance", "channels" } },
            { name = L.GROUP_LAYOUT or "Layout", sections = { "position", "fallback", "minimap" } },
        },
        sectionName = function(id) return sectionNames[id] or id end,
        elements = function(id) return sections[id] or sections.appearance end,
        landing = function() return "appearance" end,
        changedCount = CountChanged,
        resetSection = ResetSection,
        onCreated = function() end,
    })
    return tab
end

function ACB:RefreshOptions()
    if tab and tab.Refresh then tab:Refresh() end
end

function ACB:ToggleOptions()
    local registered = Build()
    if not registered then
        self:Print("ade_UIKit 未加载：请确认该插件已勾选。")
        return
    end
    registered:Toggle("appearance")
end
