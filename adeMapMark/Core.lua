--[[
adeMapMark - Core（命名空间 / 存档 / 工具层）
定位：ADE v6.5 地图标记插件的公共底座，对外 Provider API 挂在 _G.adeMapMark
体系：ADE v6.5（不依赖 ade_UIKit / Ace；仅 LibStub、HBD、LibWorldMapTabs）
来源：_temp/_map/old_dev/BDmap_ade v1.64.0 的 DB 与工具段
计划：_docs/plans/adeMapMark-dev-plan.md §4.6
]]

local addonName = ...
local AMM = _G.adeMapMark or {}
_G.adeMapMark = AMM
local ns = AMM

ns.addonName = addonName
ns.version = C_AddOns.GetAddOnMetadata(addonName, "Version") or "v6.5-r001"
ns.displayName = C_AddOns.GetAddOnMetadata(addonName, "Title") or "adeMapMark"

-- 本地化表骨架（Locales/*.lua 按 GetLocale() 填充）
ns.L = ns.L or {}

-- 设置面板 panelID 枚举：Settings.xml 的 KeyValue 需在 XML 加载前可见
_G.adeMapMarkPanelID = EnumUtil.MakeEnum("Markers", "Settings")

-- 数据库名（新插件独立存档，不迁移旧档：计划 §〇 决策 4）
local DB_NAME = "adeMapMarkDB"
ns.DB_NAME = DB_NAME

-- 标记默认尺寸（供 Icons/MinimapPin 运行时引用；单位=像素，滑条所见即所得）
-- 文字 10px、图标 22px（用户实测最合适；20 偏小、24 偏大）。
ns.DEFAULT_TEXT_SIZE = 10
ns.DEFAULT_ICON_SIZE = 22

local DEFAULTS = {
    version = 1,
    markers = {},
    settings = {
        lastSize = 22,
        lastTextSize = 10,
        displayMode = "icon",
        lastColor = { r = 0.2, g = 1, b = 0.73, a = 1 },
        useTomTom = true,
        leftClickEditMode = false,
        showMinimapMarkers = true,
        useHandyArrow = false,
        bigNotePos = nil,
        collapsed = { general = true, providers = true },
    },
}
ns.DEFAULTS = DEFAULTS

-- ---------------------------------------------------------------------------
-- 工具：默认值合并 / 存档
-- ---------------------------------------------------------------------------

-- 把 defaults 中有而 target 中缺失的键补齐（不覆盖已有值）
function ns.MergeDefaults(target, defaults)
    if type(target) ~= "table" then return target end
    for k, v in pairs(defaults) do
        if type(v) == "table" then
            if type(target[k]) ~= "table" then target[k] = {} end
            ns.MergeDefaults(target[k], v)
        elseif target[k] == nil then
            target[k] = v
        end
    end
    return target
end

-- 存档初始化（仅清理本插件已废弃字段，不做跨插件迁移）
local function EnsureDB()
    _G[DB_NAME] = _G[DB_NAME] or {}
    local db = _G[DB_NAME]
    db.settings = db.settings or {}
    db.markers = db.markers or {}
    db.settings.liveUpdate = nil
    ns.MergeDefaults(db, DEFAULTS)
    -- 尺寸 schema 迁移（仅执行一次，用 sizePixelSchema 标记）：
    --   r039: 46 → 20；r041: 20 → 24；r042: 24 → 22（用户实测最合适）。
    -- 只重置"等于上一版默认值"的值，尊重用户手动调过的滑条。
    if db.settings.sizePixelSchema ~= 3 then
        if db.settings.lastSize == 24 or (type(db.settings.lastSize) == "number" and db.settings.lastSize > 36) then
            db.settings.lastSize = 22
        end
        for _, m in ipairs(db.markers or {}) do
            if type(m.iconSize) == "number" and (m.iconSize == 24 or m.iconSize > 36) then
                m.iconSize = 22
            end
        end
        db.settings.sizePixelSchema = 3
    end
    return db
end

function ns.db()
    return _G[DB_NAME]
end

-- ---------------------------------------------------------------------------
-- 工具：数值 / 颜色 / 坐标 / 安全
-- ---------------------------------------------------------------------------

function ns.clamp(v, low, high)
    low, high = low or 0, high or 1
    return math.max(low, math.min(high, tonumber(v) or low))
end

local DEFAULT_COLOR = { r = 0.2, g = 1, b = 0.73, a = 1 }

-- 统一颜色表：兼容 r/g/b/a 与 red/green/blue/alpha 两种写法，>1 视为 0~255
function ns.cloneColor(c)
    c = c or DEFAULT_COLOR
    local function pick(a, b, d)
        local v = c[a] or c[b]
        if v == nil then return d end
        v = tonumber(v) or d
        return v
    end
    local r = pick("r", "red", DEFAULT_COLOR.r)
    local g = pick("g", "green", DEFAULT_COLOR.g)
    local b = pick("b", "blue", DEFAULT_COLOR.b)
    local a = pick("a", "alpha", DEFAULT_COLOR.a)
    if r > 1 or g > 1 or b > 1 then r, g, b = r / 255, g / 255, b / 255 end
    if a > 1 then a = a / 255 end
    return { r = ns.clamp(r), g = ns.clamp(g), b = ns.clamp(b), a = ns.clamp(a) }
end

-- 坐标 0~1 → 8 位整型（与 HandyNotes:getCoord 算法一致，计划 §9.1）
function ns.encodeCoord(x, y)
    if not x or not y then return nil end
    local xPart = math.floor(x * 10000 + 0.5)
    local yPart = math.floor(y * 10000 + 0.5)
    return xPart * 10000 + yPart
end

function ns.decodeCoord(coord)
    if not coord then return 0, 0 end
    return math.floor(coord / 10000) / 10000, (coord % 10000) / 10000
end

-- 显示模式：仅决定「图标与文本同时存在」时的呈现；只有其中一种时总是显示那一种。
--   icon = 仅图标（默认，兼容旧行为）；text = 仅文本；both = 图标+文本
-- hasIcon 取 data.icon；hasText 在「无图标」时恒为 true（保留「未命名」文本兜底）。
function ns.GetIconTextVisibility(data)
    if not data then return false, false end
    local hasIcon = data.icon ~= nil and data.icon ~= ""
    local hasText = not hasIcon or (type(data.title) == "string" and data.title:trim() ~= "")
    local mode = "icon"
    local db = _G[DB_NAME]
    if db and db.settings then mode = db.settings.displayMode or "icon" end
    if mode == "text" then
        return not hasText, hasText
    elseif mode == "both" then
        return hasIcon, hasText
    end
    return hasIcon, not hasIcon
end

function ns.hookScript(frame, event, fn)
    if not frame then return end
    frame:HookScript(event, fn)
end

function ns.Print(...)
    local L = ns.L
    local prefix = string.format("|cff00AAFF[%s]|r ", L.ADDON_TAG)
    local parts = {}
    for i = 1, select("#", ...) do
        parts[i] = tostring(select(i, ...))
    end
    print(prefix .. table.concat(parts, " "))
end

function ns.Debug(...)
    if not ns.debugEnabled then return end
    ns.Print("[DEBUG]", ...)
end

-- 安全调用：所有外部 Provider 回调必须经此包裹（计划 §八）
-- 契约：成功直接返回结果（多值），失败返回 nil；调用方不可按 ok, result 解构
function ns.safecall(fn, ...)
    if type(fn) ~= "function" then return nil end
    local ok, a, b, c, d = pcall(fn, ...)
    if not ok then
        ns.Debug("回调执行失败:", tostring(a))
        return nil
    end
    return a, b, c, d
end

-- ---------------------------------------------------------------------------
-- 加载分发（ADE v6.5 约定：统一入口，不用散落的 ADDON_LOADED 判断）
-- ---------------------------------------------------------------------------

local loadFns = {}
local loader = CreateFrame("Frame")
loader:RegisterEvent("ADDON_LOADED")
loader:SetScript("OnEvent", function(_, _, loaded)
    if loaded ~= addonName then return end
    EnsureDB()
    for _, fn in ipairs(loadFns) do
        local ok, err = pcall(fn)
        if not ok then ns.Debug("初始化回调失败:", tostring(err)) end
    end
    loader:UnregisterEvent("ADDON_LOADED")
end)

function ns.RegisterOnAddonLoaded(fn)
    if type(fn) == "function" then loadFns[#loadFns + 1] = fn end
end

-- 已加载（本文件被再次执行等异常情况）时直接跑回调
if C_AddOns.IsAddOnLoaded(addonName) then
    EnsureDB()
    for _, fn in ipairs(loadFns) do pcall(fn) end
    loader:UnregisterEvent("ADDON_LOADED")
end
