--[==[ 取值聚合与 Secret Values 关卡（§2.2 / §2.3）
    唯一取值入口 ns.Collector.Read(key)。StatDefs.read() 返回两个独立通道：
      entry.value   = 面板值（纯数字）
      entry.percent = 角色面板 tooltip 百分比
    二者各自独立判定 secret / 是否为可运算数字，任一可为 nil（该属性无此数据）。
    12.x 战斗中属性 API 可能返回 secret：禁止比较 / 算术 / 作表键 / 裸格式化；
    判定用 12.x 裸全局 issecretvalue / canaccessvalue（实证 MightStats/Core.lua:58-61、
    StatVerdict/Core/SV_Constants.lua:23-25）。secret 原值只交给 FontString:SetText /
    StatusBar:SetValue 由客户端渲染；需要算术的场合走 ReadPlain，取不到返回 nil，不 or 0 兜底。

    事件注册顺序按 12.x 硬要求：SetScript("OnEvent") 先于 RegisterEvent。
    高频事件用 C_Timer.After + pending 标记合并刷新（wow-event-system.mdc）。
    实证事件集：IStats/Stats.lua:27-34、Noodle_StatBars/Noodle_StatBars.lua:1065-1069、
    StatCompass/UI.lua:946。 ]==]
-- ADE v6.5：ns 统一走全局私有表
local addonName = ...
local ns = _G.adeStatPlus or {}
_G.adeStatPlus = ns

local Collector = {}
ns.Collector = Collector

local type, select = type, select
local CreateFrame, C_Timer = CreateFrame, C_Timer

local eventFrame
local refreshers = {}
local snapshot = {}
local pending = false

local EVENTS = {
    "PLAYER_ENTERING_WORLD",
    "UNIT_STATS",
    "COMBAT_RATING_UPDATE",
    "MASTERY_UPDATE",
    "UNIT_SPELL_HASTE",
    "UNIT_AURA",
    "PLAYER_EQUIPMENT_CHANGED",
    "PLAYER_AVG_ITEM_LEVEL_UPDATE",
    "UPDATE_INVENTORY_DURABILITY",
    "ACTIVE_PLAYER_SPECIALIZATION_CHANGED",
}

--- 判定一个值在 Lua 侧是否不可见（secret）。
---@param value any
---@return boolean
function Collector.IsSecret(value)
    if type(issecretvalue) == "function" and issecretvalue(value) then return true end
    if type(canaccessvalue) == "function" and not canaccessvalue(value) then return true end
    return false
end

--- 读取单个属性，返回快照表。value / percent 两个通道各自判定，绝不互相回退。
---@param key string
---@return table|nil entry
function Collector.Read(key)
    local def = ns.StatDefs[key]
    if not def then return nil end

    local value, percent = def.read()
    local entry = snapshot[key]
    if not entry then
        entry = {}
        snapshot[key] = entry
    end
    entry.key = key
    entry.def = def
    entry.value = value
    entry.percent = percent

    -- 每个通道独立：secret 与否、是否为可运算的 number，都不牵连另一通道
    entry.valueSecret = Collector.IsSecret(value)
    entry.percentSecret = Collector.IsSecret(percent)
    entry.secret = entry.valueSecret or entry.percentSecret
    entry.valuePlain = (not entry.valueSecret)
        and ((value == nil) or type(value) == "number")
    entry.percentPlain = (not entry.percentSecret)
        and ((percent == nil) or type(percent) == "number")
    entry.plain = entry.valuePlain and entry.percentPlain

    -- 上次已知非 secret 数值缓存（用户 2026-11-18，参考 _temp/Stats 旧版战斗策略）：
    -- 12.x 战斗中属性 API 大量返回 secret，直通原值会让整行退化成裸浮点；
    -- 显示层面沿用「最近一次已确认可读的数值」渲染完整格式，secret 原值本身
    -- 仍绝不参与运算 / 拼接 / 比较——缓存的是战斗外已确认的 plain number。
    if not entry.valueSecret and type(value) == "number" then
        entry.lastValue = value
    end
    if not entry.percentSecret and type(percent) == "number" then
        entry.lastPercent = percent
    end
    return entry
end

--- 安全数值读取：只返回已确认非 secret 的数字；无数据 / secret 时该通道为 nil。
---@param key string
---@return number? value 面板值
---@return number? percent tooltip 百分比
function Collector.ReadPlain(key)
    local entry = Collector.Read(key)
    if not entry then return nil, nil end
    local value = entry.valuePlain and entry.value or nil
    local percent = entry.percentPlain and entry.percent or nil
    return value, percent
end

--- 读取四绿百分比（供图形视图 / 进度条用）；无百分比的键直接省略。
---@param keys table
---@return table
function Collector.ReadSecondaryValues(keys)
    local out = {}
    for _, key in ipairs(keys) do
        local _, percent = Collector.ReadPlain(key)
        if percent then out[key] = percent end
    end
    return out
end

--- 订阅刷新（Panel / Bars / Radar / Ring / CharPanel）。
---@param fn function
function Collector.RegisterRefresh(fn)
    refreshers[#refreshers + 1] = fn
end

local function DoRefresh()
    for _, fn in ipairs(refreshers) do fn() end
end

--- 请求一次合并刷新（高频事件只触发一次）。
function Collector.RequestUpdate()
    if pending then return end
    pending = true
    C_Timer.After(0.05, function()
        pending = false
        DoRefresh()
    end)
end

--- 立即刷新（配置变更、profile 切换等）。
function Collector.Refresh()
    DoRefresh()
end

local function OnEvent(self, event, unit)
    if event == "UNIT_STATS" or event == "UNIT_AURA" or event == "UNIT_SPELL_HASTE" then
        if unit ~= "player" then return end
    end
    Collector.RequestUpdate()
end

function Collector.Init()
    eventFrame = CreateFrame("Frame")
    eventFrame:SetScript("OnEvent", OnEvent)
    for _, event in ipairs(EVENTS) do
        eventFrame:RegisterEvent(event)
    end
end
