------------------------------------------------------------
-- 配置契约 / Tab 注册 / 共享状态 / 公开 Tab 方法。
-- 设计参考 Krowi_Options.lua 的严格校验与错误隔离（不复制其 AceConfig 适配层）。
------------------------------------------------------------
local lib = ResolveBOFNamespace("ade_UIKit")
if not lib then return end

local L = lib.L
local Internal = lib.Internal

lib.Geometry = {
    WindowWidth = 920,          -- 与暴雪 SettingsPanel 同宽；无右栏时 PageWidth 仍为 635（KAF WindowLayout.lua:229-233）
    WindowHeight = 720,
    NavWidth = 199,
    BodyTop = -76, BodyBottom = 46, BodyLeft = 18, BodyRight = -18,
    InnerLeft = 17, InnerTop = -64, InnerRight = -17, InnerBottom = 42,
    NavEnd = 199, PageLeftPad = 16, ControlColumn = 330, NameRight = 342,
    GridLeft = 200, GridColumn = 72, GridColumns = 5,
    RowHeight = 30, RowGap = 2,
    SearchWidth = 175,
}

local configFields = {
    { "name", "string" }, { "saved", "table", "function" }, { "groups", "table" },
    { "sectionName", "function" }, { "elements", "function" },
    { "isNew", "function", "nil" }, { "landing", "function", "nil" },
    { "onSectionShown", "function", "nil" }, { "changedCount", "function", "nil" },
    { "resetSection", "function", "nil" }, { "onCreated", "function", "nil" },
}

local configDefaults = {
    isNew = function() return false end,
    landing = function() return "overview" end,
    onSectionShown = function() end,
    changedCount = function() return 0 end,
    resetSection = function() return false end,
}

local function Protected(func, ...)
    if type(func) ~= "function" then return false end
    local args, count = { ... }, select("#", ...)
    return xpcall(function() return func(unpack(args, 1, count)) end, CallErrorHandler)
end
Internal.Protected = Protected

local function Ask(fallback, func, ...)
    if type(func) ~= "function" then return fallback end
    local ok, result = Protected(func, ...)
    if ok then return result end
    return fallback
end
Internal.Ask = Ask

local function Suggestion(key)
    if type(key) ~= "string" then return nil end
    local lower, found = key:lower(), nil
    for _, field in ipairs(configFields) do
        local known = field[1]:lower()
        if known:sub(1, #lower) == lower or lower:sub(1, #known) == known then
            if found then return nil end
            found = field[1]
        end
    end
    return found
end

local function CheckConfig(config)
    if type(config) ~= "table" then error("ade_UIKit: RegisterTab 需要一个配置表", 3) end
    local name = tostring(config.name)
    local known = {}
    for _, field in ipairs(configFields) do
        known[field[1]] = true
        local kind = type(config[field[1]])
        if kind ~= field[2] and kind ~= field[3] then
            local allowed = field[3] and (field[2] .. " or " .. field[3]) or field[2]
            error(("ade_UIKit: tab %q: config.%s 必须是 %s，实际为 %s"):format(name, field[1], allowed, kind), 3)
        end
    end
    local hasReset, hasCount = config.resetSection ~= nil, config.changedCount ~= nil
    if hasReset ~= hasCount then
        error(("ade_UIKit: tab %q: %s 必须与 %s 同时提供"):format(name,
            hasReset and "changedCount" or "resetSection", hasReset and "resetSection" or "changedCount"), 3)
    end
    local unknown = {}
    for key in next, config do
        if not known[key] then unknown[#unknown + 1] = key end
    end
    if #unknown > 0 then
        table.sort(unknown, function(a, b) return tostring(a) < tostring(b) end)
        local hint = Suggestion(unknown[1])
        error(("ade_UIKit: tab %q: 未知配置键 %s%s"):format(name, tostring(unknown[1]),
            hint and ("；是否想写 " .. hint .. "?") or ""), 3)
    end
    for i, group in ipairs(config.groups) do
        if type(group) ~= "table" or type(group.sections) ~= "table" then
            error(("ade_UIKit: tab %q: groups[%d] 必须是含 sections 表的表"):format(name, i), 3)
        end
    end
end

local function Copy(value)
    if type(value) ~= "table" then return value end
    local result = {}
    for k, v in pairs(value) do result[k] = Copy(v) end
    return result
end
Internal.Copy = Copy

-- 图标三态统一出口：FilePath / FileID / Atlas（项目记忆「图标源三态规范」）。
function Internal.SetIcon(texture, source)
    if type(source) == "table" and source.atlas then
        texture:SetAtlas(source.atlas, true)
    elseif source ~= nil then
        texture:SetTexture(source)
    end
end

function Internal.IconEscape(source, size)
    local s = size or 12
    if type(source) == "table" and source.atlas then return ("|A:%s:%d:%d|a"):format(source.atlas, s, s) end
    return ("|T%s:%d:%d|t"):format(tostring(source), s, s)
end

local function ReadWindow(tab)
    local saved = tab:GetSaved()
    if not saved then return nil end
    saved.Window = saved.Window or {}
    local w = saved.Window
    return {
        Point = Copy(w.Point or { "CENTER", "CENTER", 0, 0 }),
        Size = Copy(w.Size or { lib.Geometry.WindowWidth, lib.Geometry.WindowHeight }),
    }
end
Internal.ReadWindow = ReadWindow

function Internal.WriteShared()
    local shared = Internal.Shared
    if not shared then return end
    for _, tab in ipairs(Internal.Tabs) do
        local saved = tab:GetSaved()
        if saved then
            saved.Window = {
                Point = Copy(shared.Point), Size = Copy(shared.Size),
            }
        end
    end
end

function Internal.SetShared(key, value)
    if not Internal.Shared then return end
    Internal.Shared[key] = value
    Internal.WriteShared()
    lib.Callbacks.Fire("BOF_SHARED_STATE_CHANGED", key, value)
end

local Tab = {}
Tab.__index = Tab
Internal.TabMixin = Tab

function Tab:GetSaved()
    if not self.Saved then
        local saved = self.Config.saved
        if type(saved) == "function" then saved = Ask(nil, saved) end
        if type(saved) == "table" then self.Saved = saved end
    end
    return self.Saved
end

function Tab:GetFrame()
    return Internal.Frame
end

function Tab:IsShown()
    local frame = Internal.Frame
    return frame ~= nil and frame:IsShown() and frame.Tab == self
end

function Tab:Open(sectionId)
    if not Internal.GetFrame then return end
    local frame = Internal.GetFrame(self)
    if frame then frame:ShowTab(self, sectionId) end
end

function Tab:Toggle(sectionId)
    if self:IsShown() then
        Internal.Frame:Hide()
    else
        self:Open(sectionId)
    end
end

function Tab:Refresh()
    local frame = Internal.Frame
    if frame and frame:IsShown() and frame.Tab == self then frame:RefreshPage() end
end

function Tab:Unregister()
    for i, registered in ipairs(Internal.Tabs) do
        if registered == self then tremove(Internal.Tabs, i); break end
    end
    local frame = Internal.Frame
    if frame then frame:RefreshTabs() end
end

local function SortTabs()
    table.sort(Internal.Tabs, function(a, b) return a.Config.name < b.Config.name end)
end

function lib.RegisterTab(config)
    CheckConfig(config)
    local filled = {}
    for _, field in ipairs(configFields) do
        local value = config[field[1]]
        if value == nil then value = configDefaults[field[1]] end
        filled[field[1]] = value
    end
    local registered = setmetatable({ Config = filled }, Tab)
    tinsert(Internal.Tabs, registered)
    SortTabs()
    if Internal.Frame then
        local saved = registered:GetSaved()
        if saved then saved.Window = Copy(Internal.Shared) end
        if filled.onCreated then Protected(filled.onCreated, Internal.Frame) end
        Internal.Frame:RefreshTabs()
    end
    lib.Callbacks.Fire("BOF_TAB_REGISTERED", registered)
    return registered
end
