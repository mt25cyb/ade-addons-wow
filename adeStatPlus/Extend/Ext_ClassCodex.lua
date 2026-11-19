--[==[ 推荐值来源适配器：ClassCodex（§2.4.1 统一契约 / D27）

    ⚠ 实证边界（2026-11-08 核实，与计划 §2.4 原描述不同，见 §十三风险 / §十六）：
      ClassCodex 的 ns 是 TOC vararg 私有表（Core/ClassCodex.lua:1 `local addonName, ns = ...`），
      _G.ClassCodex 仅暴露 RegisterDockHost / UnregisterDockHost / RefreshDock 三个 Dock 函数
      （Core/ClassCodex.lua:2973-2976）。全目录未找到 _G.ClassCodex.GetStatTargets /
      GetStatPriority / ns 本身或 StatDR 的全局出口（子代理全量检索 + 本轮复核）。
      因此无法按计划原设想调用 ns.GetStatTargets / ns.GetStatPriority / ns.StatTargetPercent。

    本适配器的可行取数路径（全部为 ClassCodex 公开全局，不写、不 hook 其帧）：
      · ClassCodexSource            —— Data/db_ugg.lua:1 / db_icyveins.lua:1 定义的全局数据表
      · ClassCodexDB                —— TOC ## SavedVariables（statTargetBin）
      · ClassCodexCharDB            —— TOC ## SavedVariablesPerCharacter（perSpec[specKey].ctx）
    「当前选定」= ctx.source / ctx.contentType / ctx.heroSpec + statTargetBin，全部只读，
    不在本插件内提供组选择器（D27）。解析算法照搬 Shared/SourceData.lua:43-76 的
    contextChain + ResolveCategory 回退链，避免臆造查找规则。

    达标值在 ClassCodex 数据中是 rating，而契约要求百分比(0–100)。因其换算函数
    ns.StatDR.TargetPercent 依赖私有 CONVERSION 表（StatDR.lua:21-101）不可访问，
    本适配器改用「当前 (rating, 面板百分比) 线性外推」：
      targetPct = currentPct * targetRating / currentRating
    这与 ClassCodex StatDR.GoalPercent 用 live pair 自校正换算系数的思路一致
    （StatDR.lua:168-189），但未复刻 DR 分段曲线，属已知近似，实机需校准。 ]==]
-- ADE v6.5：ns 统一走全局私有表
local addonName = ...
local ns = _G.adeStatPlus or {}
_G.adeStatPlus = ns

local SEC = { "crit", "haste", "mastery", "vers" }
local CC_SEC = { "crit", "haste", "mastery", "versatility" }

-- 专精索引 → ClassCodex 数据键 slug，抄自 ClassCodex/Core/ClassCodex.lua:106-120（真实数据，非推测）
local SPEC_KEYS = {
    DEATHKNIGHT = { "blood", "frost", "unholy" },
    DEMONHUNTER = { "havoc", "vengeance", "devourer" },
    DRUID = { "balance", "feral", "guardian", "restoration" },
    EVOKER = { "devastation", "preservation", "augmentation" },
    HUNTER = { "beast-mastery", "marksmanship", "survival" },
    MAGE = { "arcane", "fire", "frost" },
    MONK = { "brewmaster", "mistweaver", "windwalker" },
    PALADIN = { "holy", "protection", "retribution" },
    PRIEST = { "discipline", "holy", "shadow" },
    ROGUE = { "assassination", "outlaw", "subtlety" },
    SHAMAN = { "elemental", "enhancement", "restoration" },
    WARLOCK = { "affliction", "demonology", "destruction" },
    WARRIOR = { "arms", "fury", "protection" },
}

local DEFAULT_PRIORITY = { "icyveins", "ugg" }  -- Shared/SourceData.lua:90
local WILDCARD = "all"

local adapter = {
    key = "ClassCodex",
    label = "ClassCodex",
}

function adapter.IsAvailable()
    if not C_AddOns.IsAddOnLoaded("ClassCodex") then return false end
    return type(_G.ClassCodexSource) == "table"
end

--- 当前专精的 ClassCodex 数据键与「当前选定」上下文。
---@return table|nil ctx  { class, spec, source, contentType, hero, bin, perSpecKey }
local function CurrentSelection()
    local _, classToken = UnitClass("player")
    local specIndex = GetSpecialization()
    if not (classToken and specIndex) then return nil end
    local keys = SPEC_KEYS[classToken]
    if not keys then return nil end
    local spec = keys[specIndex]
    if not spec then return nil end

    local perSpecKey = classToken .. "-" .. spec
    local ps = _G.ClassCodexCharDB and _G.ClassCodexCharDB.perSpec
        and _G.ClassCodexCharDB.perSpec[perSpecKey]
    local ctx = ps and ps.ctx

    -- source：当前选定，未选过时按 ClassCodex 自身默认优先级（SourceData.lua:79-83,90）
    local source = ctx and ctx.source
    if not source or not _G.ClassCodexSource[source] then
        for _, s in ipairs(DEFAULT_PRIORITY) do
            if _G.ClassCodexSource[s] then source = s break end
        end
    end
    if not source then return nil end

    -- contentType：Context.lua:4 DEFAULT_CONTENT = "mplus"，dataContext 原样传入
    local contentType = (ctx and ctx.contentType) or "mplus"
    local lc = contentType:lower()
    local dataContext
    if lc:find("pvp") then dataContext = "pvp"
    elseif lc:find("raid") then dataContext = "raid"
    elseif lc:find("mythic+") or lc:find("m+") or lc:find("dungeon") or lc:find("mplus") then
        dataContext = "mplus"
    else dataContext = WILDCARD end

    -- heroSpec：Context.lua:34-38；未选英雄天赋时用 all 聚合档
    local hero = (ctx and ctx.heroSpec) or (ps and ps.heroTalent) or WILDCARD
    if type(hero) ~= "string" then hero = WILDCARD end

    -- bin：StatTargets.lua:27-31，默认 "top"
    local bin = _G.ClassCodexDB and _G.ClassCodexDB.statTargetBin
    if bin ~= "top" and bin ~= "average" then bin = "top" end

    return {
        class = classToken, spec = spec, source = source,
        dataContext = dataContext, hero = hero, bin = bin,
    }
end

--- 复刻 Shared/SourceData.lua:43-53 的 context 回退链。
local function ContextChain(context)
    local chain = { context }
    local sep = context:find(":", 1, true)
    if sep then chain[#chain + 1] = context:sub(1, sep - 1) end
    if context == "pvp" then chain[#chain + 1] = "pvp:shuffle" end
    local isPvp = context == "pvp" or context:sub(1, 4) == "pvp:"
    if context ~= WILDCARD and not isPvp then chain[#chain + 1] = WILDCARD end
    return chain
end

--- 复刻 Shared/SourceData.lua:56-66 的 ResolveCategory（hero × context 回退）。
local function ResolveCategory(category, hero, context)
    if type(category) ~= "table" then return nil end
    local heroes = (hero == WILDCARD) and { WILDCARD } or { hero, WILDCARD }
    for _, ctx in ipairs(ContextChain(context)) do
        for _, h in ipairs(heroes) do
            local byContext = category[h]
            if byContext and byContext[ctx] ~= nil then return byContext[ctx] end
        end
    end
    return nil
end

--- 取当前选定下的一条 category 数据（statPriority / statTargets）。
local function Category(sel, name)
    local src = _G.ClassCodexSource[sel.source]
    local byClass = src and src.data and src.data[sel.class]
    local sd = byClass and byClass[sel.spec]
    if not sd then return nil end
    return ResolveCategory(sd[name], sel.hero, sel.dataContext)
end

--- 四绿优先级有序数组（高→低）；tiers 按层序扁平化，带 note 的表项取 .stat。
--- 数据实例：db_icyveins.lua:4085 secondary={{"haste"},{"mastery","versatility","crit"}}
---@return table|nil
function adapter.GetPriority(classToken, specID)
    local sel = CurrentSelection()
    if not sel then return nil end
    local sp = Category(sel, "statPriority")
    if type(sp) ~= "table" then return nil end
    local tiers = sp.secondary
    if type(tiers) ~= "table" then return nil end

    local out, seen = {}, {}
    for _, tier in ipairs(tiers) do
        if type(tier) == "table" then
            for _, entry in ipairs(tier) do
                local key = type(entry) == "table" and entry.stat or entry
                if type(key) == "string" then
                    local internal = (key == "versatility") and "vers" or key
                    if not seen[internal] then
                        for _, valid in ipairs(SEC) do
                            if valid == internal then
                                seen[internal] = true
                                out[#out + 1] = internal
                                break
                            end
                        end
                    end
                end
            end
        end
    end
    if #out == 0 then return nil end
    return out
end

--- 四绿达标值（百分比 0–100）；数据实例 db_ugg.lua:247-256
--- statTargets = { all = { mplus = { top = {crit=...,haste=...,mastery=...,versatility=...} } } }
---@return table|nil
function adapter.GetThresholds(classToken, specID)
    local sel = CurrentSelection()
    if not sel then return nil end
    local targets = Category(sel, "statTargets")
    if type(targets) ~= "table" then return nil end

    -- StatTargets.lua:142-153：分档 {top,average} 时按当前 bin 选，否则直接视为扁平表
    local chosen
    if targets.top ~= nil or targets.average ~= nil then
        chosen = targets[sel.bin] or targets.top or targets.average
    else
        chosen = targets
    end
    if type(chosen) ~= "table" then return nil end

    local out = {}
    for _, key in ipairs(SEC) do
        local ccKey = (key == "vers") and "versatility" or key
        local rating = chosen[ccKey]
        if type(rating) == "number" and rating > 0 then
            -- 线性外推：当前 rating → 当前面板百分比，得到目标 rating 对应的百分比。
            -- 任一实时值缺失 / secret 时该键省略（不做 0 兜底，D28）。
            local curRating, curPct = ns.Collector.ReadPlain(key)
            if curRating and curPct and curRating > 0 then
                out[key] = curPct * rating / curRating
            end
        end
    end
    if next(out) == nil then return nil end
    return out
end

ns.Registry.Sources.Register(adapter)
