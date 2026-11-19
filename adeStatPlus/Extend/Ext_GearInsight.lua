--[==[ 推荐值来源适配器：GearInsight（§2.4.1 统一契约 / D25）
    GearInsight 是全局表，对外函数全部随主插件 TOC 加载（实证）：
      core/DataLoader.lua:134  GearInsight.SpecKeyByID(specID) -> "CLASS/SPEC"
      core/BisData.lua:5828     BisData:GetSpecData(class, spec, heroTalent)
      core/BisPlan.lua:1525     GearInsight.SpecStatWeights(specData) -> 权重表
      main/Sources.lua:599      GearInsight.FillerStatPct(specData) -> 当前 _statMode 档的
                                targetStatPercents*（百分比，已含「当前选定」语义）
    「当前选定」由 GearInsight 自己维护：FillerStatPct 内部读 GearInsight._statMode
    （raid / mplusHigh / mplusFarm / mplusCommon，PanelBuild.lua:377-405）并叠加「我的方案」
    占比（Sources.lua:610-614），本适配器不自选档位（D25）。
    权重表键名含 versatility，映射为本插件 vers；只保留四绿，按值降序成优先级数组。 ]==]
-- ADE v6.5：ns 统一走全局私有表
local addonName = ...
local ns = _G.adeStatPlus or {}
_G.adeStatPlus = ns

local SEC = { "crit", "haste", "mastery", "vers" }
local GI_SEC = { "crit", "haste", "mastery", "versatility" }

local adapter = {
    key = "GearInsight",
    label = "GearInsight",
}

--- 可用性：插件已加载且所需对外函数齐备（决定下拉是否出现，D29）。
function adapter.IsAvailable()
    if not C_AddOns.IsAddOnLoaded("GearInsight") then return false end
    local GI = _G.GearInsight
    return type(GI) == "table"
        and type(GI.BisData) == "table"
        and type(GI.SpecKeyByID) == "function"
        and type(GI.SpecStatWeights) == "function"
        and type(GI.FillerStatPct) == "function"
end

--- 取当前专精的 specData；GearInsight 无专精条目时返回 nil（能力降级，D28）。
---@param specID number
---@return table|nil
local function GetSpecData(specID)
    local GI = _G.GearInsight
    local specKey = GI.SpecKeyByID(specID)
    if not specKey then return nil end
    local class, spec = specKey:match("^([^/]+)/([^/]+)")
    if not (class and spec) then return nil end
    -- heroTalent 传空串：GetSpecData 会按 "CLASS/SPEC/" 前缀回退到该专精任意英雄天赋条目
    -- （BisData.lua:5835-5843），与 GearInsight 自身「装备跨英雄天赋相同」的口径一致。
    return GI.BisData:GetSpecData(class, spec, "")
end

--- 四绿优先级有序数组（高→低）；无权重数据返回 nil。
---@param classToken string
---@param specID number
---@return table|nil
function adapter.GetPriority(classToken, specID)
    local specData = GetSpecData(specID)
    if not specData then return nil end
    local weights = _G.GearInsight.SpecStatWeights(specData)
    if type(weights) ~= "table" then return nil end

    local present = {}
    for _, key in ipairs(GI_SEC) do
        local v = weights[key]
        if type(v) == "number" then
            present[#present + 1] = { key = key, value = v }
        end
    end
    if #present == 0 then return nil end
    table.sort(present, function(a, b) return a.value > b.value end)

    local out = {}
    for _, item in ipairs(present) do
        out[#out + 1] = (item.key == "versatility") and "vers" or item.key
    end
    return out
end

--- 四绿达标值（百分比 0–100）；无达标值数据返回 nil。
--- 直接取 FillerStatPct 的返回值，即 GearInsight 当前显示的那套 targetStatPercents*。
---@param classToken string
---@param specID number
---@return table|nil
function adapter.GetThresholds(classToken, specID)
    local specData = GetSpecData(specID)
    if not specData then return nil end
    local pct = _G.GearInsight.FillerStatPct(specData)
    if type(pct) ~= "table" then return nil end

    local out = {}
    for _, key in ipairs(SEC) do
        local srcKey = (key == "vers") and "versatility" or key
        local v = pct[srcKey]
        if type(v) == "number" then out[key] = v end
    end
    if next(out) == nil then return nil end
    return out
end

ns.Registry.Sources.Register(adapter)
