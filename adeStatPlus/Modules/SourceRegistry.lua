--[==[ 推荐值来源中央注册表（开发计划 §2.4.2 / D26 / D29）
    Extend/Ext_*.lua 在加载期向本表 Register；所有消费点只经本表读取，
    UI / 渲染代码禁止出现 `if source == "GearInsight" then ...` 之类来源特例分支。

    契约（§2.4.1）：适配器 table 必须含
      key(string) / label(string) / IsAvailable() / GetPriority(classToken, specID) / GetThresholds(classToken, specID)
    specID 为 GetSpecializationInfo 的第 1 返回值（数字），各适配器自行转换成自身数据源的专精键；「当前选定」的多组数据在适配器内解析，消费者不自选。
    GetPriority 返回四绿优先级有序数组；GetThresholds 返回百分比(0–100)表；
    单能力缺失返回 nil（D28 降级）。 ]==]
-- ADE v6.5：ns 统一走全局私有表（Core/InitDB 同一表）
local addonName = ...
local ns = _G.adeStatPlus or {}
_G.adeStatPlus = ns

local Registry = ns.Registry or {}
ns.Registry = Registry

local Sources = {}
Registry.Sources = Sources

local adapters = {}
local order = {}

-- Core.lua 的 INIT_ORDER 以 ns["SourceRegistry"] 取模块；注册表同时挂在 ns.Registry.Sources（消费点）与本别名（生命周期驱动），指向同一张表。
ns.SourceRegistry = Sources

--- 注册一个数据源适配器（加载期调用；重复 key 拒绝，类型校验）。
---@param adapter table
function Sources.Register(adapter)
    if type(adapter) ~= "table" then
        error("adeStatPlus.Sources.Register: adapter must be a table")
    end
    local key = adapter.key
    if type(key) ~= "string" or key == "" or key == "none" then
        error("adeStatPlus.Sources.Register: invalid adapter key")
    end
    if adapters[key] then
        error(("adeStatPlus.Sources.Register: duplicate key %q"):format(key))
    end
    if type(adapter.label) ~= "string"
        or type(adapter.IsAvailable) ~= "function"
        or type(adapter.GetPriority) ~= "function"
        or type(adapter.GetThresholds) ~= "function" then
        error(("adeStatPlus.Sources.Register: adapter %q violates the interface contract"):format(key))
    end
    adapters[key] = adapter
    order[#order + 1] = adapter
end

--- 已「安装且可用」的适配器列表（供来源下拉，D29；不含「无」，不写死列表）。
---@return table
function Sources.ListAvailable()
    local list = {}
    for _, adapter in ipairs(order) do
        if adapter.IsAvailable() then
            list[#list + 1] = adapter
        end
    end
    return list
end

--- 按 key 取适配器（不可用 / 不存在返回 nil）。
---@param key string
---@return table|nil
function Sources.Get(key)
    local adapter = adapters[key]
    if not adapter then return nil end
    if not adapter.IsAvailable() then return nil end
    return adapter
end

--- 当前选中的适配器；recommendSource = "none" / 未安装 / 已卸载时返回 nil。
--- nil 时由调用方触发 D24 灰禁用与功能降级，不在此造兜底数据。
---@return table|nil
function Sources.GetActive()
    local key = ns.db and ns.db.profile.recommendSource
    if not key or key == "none" then return nil end
    return Sources.Get(key)
end

--- 当前专精上下文（供消费者传给适配器；各适配器自行解析「当前选定」）。
---@return string classToken
---@return number? specID
local function CurrentSpec()
    local _, classToken = UnitClass("player")
    local specIndex = GetSpecialization()
    if not specIndex then return classToken, nil end
    local specID = GetSpecializationInfo(specIndex)
    return classToken, specID
end
Sources.CurrentSpec = CurrentSpec

--- 四绿优先级有序数组；源缺优先级能力 / 无来源时返回 nil（D28）。
---@return table|nil
function Sources.GetPriority()
    local adapter = Sources.GetActive()
    if not adapter then return nil end
    local classToken, specID = CurrentSpec()
    if not specID then return nil end
    return adapter.GetPriority(classToken, specID)
end

--- 四绿达标值（百分比 0–100）；源缺阀值能力 / 无来源时返回 nil（D28）。
---@return table|nil
function Sources.GetThresholds()
    local adapter = Sources.GetActive()
    if not adapter then return nil end
    local classToken, specID = CurrentSpec()
    if not specID then return nil end
    return adapter.GetThresholds(classToken, specID)
end

--- 当前来源是否具备优先级能力（供排序窗口决定「依来源」是否真正生效 / 提示）。
---@return boolean
function Sources.HasPriority()
    return Sources.GetPriority() ~= nil
end

function Sources.Init()
    -- 注册发生在 TOC 加载期的 Extend/*.lua 中；此处只校验加载顺序未被破坏。
    if #order == 0 then
        error("adeStatPlus: no source adapters registered; check TOC file list")
    end
end
