-- adeMacroAssistant / Modules/AutoMacro.lua
-- 按职业自动创建/更新 7 类宏（净化/清除/驱散/打断/战复/疾跑/嘲讽）。
-- 以 SharedMacros 结构为蓝本、用 AutoMacro.lua(12.0) 的现代 API 重写实现；
-- Phase 1：基础版（无前缀）；Phase 2：植入「加前缀」功能（前缀与基名分离，规则变更安全改名防残留）。
local ns = _G.adeMacroAssistant

-- 文件顶部批量缓存全局/API（12.x 要求显式 local 化，禁全局别名）
local pairs, string, tinsert = pairs, string, table.insert
local C_Spell = _G.C_Spell
local C_SpellBook = _G.C_SpellBook
local CreateMacro, EditMacro, DeleteMacro = _G.CreateMacro, _G.EditMacro, _G.DeleteMacro
local GetMacroIndexByName, GetMacroInfo, GetNumMacros = _G.GetMacroIndexByName, _G.GetMacroInfo, _G.GetNumMacros
local InCombatLockdown = _G.InCombatLockdown
local C_Timer = _G.C_Timer
-- ADE v6.5：文案走私有 locale 表（InitDB 已按 GetLocale 选定 ns.L）。
-- 宏类型默认值集中到 InitDB.lua，本模块从 ns.defaults 取用。
local L = ns.L

local ICON = "INV_Misc_Questionmark"

local module = {}
ns.AutoMacro = module

-- 名称变量 -> 法术数组键 + 是否允许宠物法术（interrupt/taunt 含宠物技能回退）
local SPELL_SOURCES = {
    cleanseName      = { key = "AM_CLEANSE_SPELL_ARRAY",            pet = false },
    purgeName        = { key = "AM_PURGE_SPELL_ARRAY",              pet = false },
    interruptName    = { key = "AM_INTERRUPT_SPELL_ARRAY",          pet = true  },
    resurrectionName = { key = "AM_COMBATRESURRECTION_SPELL_ARRAY", pet = false },
    sprintName       = { key = "AM_SPRINT_SPELL_ARRAY",             pet = false },
    tauntName        = { key = "AM_TAUNT_SPELL_ARRAY",              pet = true  },
}

-- 宏类型 -> 依赖的名称变量 + 占位符（宏体中的关键词）映射
local TYPE_DEFS = {
    cleanse      = { sources = { cleanseName = true },      tokens = { CLEANSE_SPELL = "cleanseName" } },
    purge        = { sources = { purgeName = true },        tokens = { PURGE_SPELL = "purgeName" } },
    dispel       = { sources = { cleanseName = true, purgeName = true }, tokens = { CLEANSE_SPELL = "cleanseName", PURGE_SPELL = "purgeName" } },
    interrupt    = { sources = { interruptName = true },    tokens = { INTERRUPT_SPELL = "interruptName" } },
    resurrection = { sources = { resurrectionName = true }, tokens = { RESURRECTION_SPELL = "resurrectionName" } },
    sprint       = { sources = { sprintName = true },       tokens = { SPRINT_SPELL = "sprintName" } },
    taunt        = { sources = { tauntName = true },        tokens = { TAUNT_SPELL = "tauntName" } },
}
module.TYPE_DEFS = TYPE_DEFS

-- ============ 取配置 / 法术名 ============

-- 取 profile 下 automacro 配置（PLAYER_LOGIN 前为 nil）
local function GetCfg()
    return ns.db and ns.db.profile and ns.db.profile.automacro
end

-- 取法术显示名（12.x：C_Spell.GetSpellInfo 返回带 .name 的表；未进缓存时返 nil）
local function GetSpellName(id)
    local info = C_Spell.GetSpellInfo(id)
    if info then
        return info.name
    end
    return nil
end

-- 玩家/宠物是否掌握该 ID 法术（C_SpellBook.IsSpellKnown，宠物第二参数用 pcall 兜底防签名差异）
local function IsKnown(id, pet)
    if pet then
        local ok, known = pcall(C_SpellBook.IsSpellKnown, id, true)
        return ok and known
    end
    return C_SpellBook.IsSpellKnown(id)
end

local function GetPlayerSpell(arr)
    if not arr then return nil end
    for _, id in ipairs(arr) do
        if IsKnown(id, false) then
            return GetSpellName(id)
        end
    end
    return nil
end

local function GetPlayerOrPetSpell(arr)
    if not arr then return nil end
    for _, id in ipairs(arr) do
        if IsKnown(id, false) or IsKnown(id, true) then
            return GetSpellName(id)
        end
    end
    return nil
end

-- 解析各职业法术名（玩家优先、宠物回退），结果供生成与改名复用
local function ResolveNames()
    local names = {}
    for var, src in pairs(SPELL_SOURCES) do
        local arr = ns[src.key]
        names[var] = src.pet and GetPlayerOrPetSpell(arr) or GetPlayerSpell(arr)
    end
    return names
end

-- ============ 文本工具 ============

-- 去除首尾空白（含换行）
local function trim(s)
    if not s then return s end
    return (s:match("^[%s]*(.-)[%s]*$"))
end

-- 宏是否存在（GetMacroIndexByName 返 0 或 nil 视为不存在）
local function MacroExists(name)
    local idx = GetMacroIndexByName(name)
    return idx and idx > 0
end

-- ============ 宏名拼接（加前缀核心） ============

-- 类型默认基名（取自 InitDB 的 ns.defaults.profile.automacro 模板，保留原始默认，不受用户覆盖影响）
local function DefaultName(typeKey)
    local d = ns.defaults.profile.automacro[typeKey]
    return d and d.base or ""
end

-- 有效基名：用户自定义 base 优先；为空回退到类型默认名
local function EffectiveBase(cfg, typeKey)
    local tcfg = cfg[typeKey]
    local base = tcfg and tcfg.base
    if not base or base == "" then
        return DefaultName(typeKey)
    end
    return base
end

-- 前缀是否生效（enabled 且 prefixChar 非空）
local function PrefixActive(cfg)
    return not not (cfg.prefixEnabled and cfg.prefixChar and cfg.prefixChar ~= "")
end

-- 最终宏名 = 前缀字符 + (自定义基名 or 类型默认名)
local function ComposeName(cfg, typeKey)
    local base = EffectiveBase(cfg, typeKey)
    if PrefixActive(cfg) then
        return cfg.prefixChar .. base
    end
    return base
end

-- 规范化前缀字符（去首尾空白；空串等价于停用前缀）
local function NormalizePrefixChar(char)
    if not char then return "" end
    return trim(tostring(char))
end

-- ============ 宏体构建 ============

-- 构建某类型宏体（占位符替换为实际法术名）并返回「体, 已用法术列表」
-- ignoreEnabled=true 时忽略启用开关（供停用/未就绪时仍可取得体以清理残留）
local function BuildBody(typeKey, names, cfg, ignoreEnabled)
    local def = TYPE_DEFS[typeKey]
    local tcfg = cfg[typeKey]
    if not def or not tcfg then return nil end
    if not ignoreEnabled and not tcfg.enabled then return nil end
    local ready = true
    for var in pairs(def.sources) do
        if not names[var] then ready = false; break end
    end
    if not ready then return nil end
    local body = tcfg.body or ""
    local used = ""
    for token, var in pairs(def.tokens) do
        body = string.gsub(body, token, names[var])
        if used ~= "" then used = used .. ", " end
        used = used .. names[var]
    end
    return trim(body), used
end

-- ============ 宏的创建 / 改名 / 删除（所有权模型：每类仅一个宏） ============
-- 关键：改名/更体一律用 EditMacro 按索引原地操作，保留宏索引 -> 已拖到动作条的宏绑定不丢。
-- 原生 MacroFrame 亦如此（EditMacro(index, name, icon) / EditMacro(index, nil, nil, body)），从不删后重建来改名。

-- 找到本插件管理的已有宏（返回索引）：优先用记录的 currentName，再退化为体指纹扫描
local function FindOwnedMacro(cfg, typeKey, body)
    local tcfg = cfg[typeKey]
    if tcfg and tcfg.currentName and MacroExists(tcfg.currentName) then
        return GetMacroIndexByName(tcfg.currentName)
    end
    if body then
        local num = GetNumMacros()
        for i = 1, num or 0 do
            local nm, _, bd = GetMacroInfo(i)
            if nm and bd and trim(bd) == body then return i end
        end
    end
    return nil
end

-- 清理同种宏体的残留（体相同、但索引非 exceptIdx 的宏）；exceptIdx<0 表示全部清理（类型停用时）
-- 仅回收旧前缀/旧命名方案的遗留同体宏；正常改名时 exceptIdx 即当前宏，不会误删动作条上的宏。
local function PurgeStaleByBody(exceptIdx, body)
    if not body then return end
    local num = GetNumMacros()
    if not num or num <= 0 then return end
    local toDelete = {}
    for i = 1, num do
        if i ~= exceptIdx then
            local nm, _, bd = GetMacroInfo(i)
            if nm and bd and trim(bd) == body then
                toDelete[#toDelete + 1] = i
            end
        end
    end
    for _, i in ipairs(toDelete) do
        DeleteMacro(i)
    end
end

-- 确保某类型恰好拥有一个当前拼接名的宏：
-- 优先原地 EditMacro 改名+更体（保留索引 -> 动作条绑定安全）；仅当完全无同体宏时才 CreateMacro 新建。
-- 关键：先对比归属宏的「名/体」与期望值，仅当确有差异才 EditMacro/Print；完全一致则静默跳过
-- （对齐 SharedMacros 的体差异判定，避免无变化时反复刷日志；加前缀使宏名不固定，故先 FindOwnedMacro 定位归属宏再比名+体）。
local function EnsureTypeMacro(cfg, typeKey, body, used)
    local target = ComposeName(cfg, typeKey)
    local ownedIdx = FindOwnedMacro(cfg, typeKey, body)
    local keptIdx

    if ownedIdx and ownedIdx > 0 then
        -- 已有归属宏：对比名/体，仅确有差异才原地改名+更体（索引不变，动作条绑定安全）
        local curName, _, curBody = GetMacroInfo(ownedIdx)
        curBody = curBody and trim(curBody) or ""
        if curName ~= target or curBody ~= body then
            EditMacro(ownedIdx, target, nil, body)
            print(("[ADE] " .. L["MSG_MACRO_UPDATED"]):format(target, used))
        end
        keptIdx = ownedIdx
    elseif MacroExists(target) then
        -- 目标名已存在（旧命名/外部残留，体可能不符）：接管该宏并更体；体已相符则静默跳过
        local tIdx = GetMacroIndexByName(target)
        local _, _, curBody = GetMacroInfo(tIdx)
        curBody = curBody and trim(curBody) or ""
        if curBody ~= body then
            EditMacro(tIdx, target, nil, body)
            print(("[ADE] " .. L["MSG_MACRO_UPDATED"]):format(target, used))
        end
        keptIdx = tIdx
    else
        -- 完全不存在：新建
        CreateMacro(target, ICON, body, nil)
        keptIdx = GetMacroIndexByName(target)
        print(("[ADE] " .. L["MSG_MACRO_CREATED"]):format(target, used))
    end

    -- 回收其余同体宏（旧前缀/旧命名遗留）；exceptIdx 保护当前宏不被误删
    PurgeStaleByBody(keptIdx or -1, body)

    cfg[typeKey].currentName = target
end

-- ============ 对外 API（供设置面板 / 调试调用） ============

-- 设置是否启用前缀（直接改配置后整体刷新；改名/清理由 Refresh 统一处理）
function module.SetPrefixEnabled(value)
    local cfg = GetCfg()
    if not cfg then return end
    cfg.prefixEnabled = not not value
    module.Refresh()
    print("[ADE] " .. (value and L["MSG_PREFIX_ENABLED"] or L["MSG_PREFIX_DISABLED"]))
end

-- 设置前缀字符（自动规范化；为空等价于停用前缀）
function module.SetPrefixChar(char)
    local cfg = GetCfg()
    if not cfg then return end
    cfg.prefixChar = NormalizePrefixChar(char)
    module.Refresh()
    print("[ADE] " .. L["MSG_PREFIX_CHAR_UPDATED"])
end

-- 当前生效的宏名（供设置预览）
function module.EffectiveName(typeKey)
    local cfg = GetCfg()
    if not cfg then return nil end
    return ComposeName(cfg, typeKey)
end

-- 基名输入框当前值（供设置回填）
function module.NameInputValue(typeKey)
    local cfg = GetCfg()
    if not cfg then return nil end
    local tcfg = cfg[typeKey]
    return tcfg and tcfg.base or DefaultName(typeKey)
end

-- 类型默认基名（供设置面板空值回退；取 DEFAULTS 模板原值，不受用户覆盖影响）
function module.DefaultName(typeKey)
    return DefaultName(typeKey)
end

-- ============ 主刷新 / 事件 ============

-- 主刷新：解析各职业法术名 -> 按类型生成/更新宏
function module.DoRefresh()
    local cfg = GetCfg()
    if not cfg or not cfg.enabled then return end
    local names = ResolveNames()
    -- 法术名全部未解析（如缓存未就绪）：无法重建，保留现有宏避免误删
    local anyName = false
    for _ in pairs(names) do anyName = true; break end
    if not anyName then return end
    for typeKey in pairs(TYPE_DEFS) do
        local tcfg = cfg[typeKey]
        if not tcfg then
            -- 无配置：跳过
        elseif not tcfg.enabled then
            -- 类型停用（用户显式）：清理其所有同种体宏（含旧命名/旧前缀残留）
            local body = BuildBody(typeKey, names, cfg, true)
            if body then PurgeStaleByBody(-1, body) end
            tcfg.currentName = nil
        else
            local body, used = BuildBody(typeKey, names, cfg)
            if body and body ~= "" then
                EnsureTypeMacro(cfg, typeKey, body, used)
            else
                -- 法术未就绪：保留现有宏，不删除、不重建（动作条绑定安全）
            end
        end
    end
end

-- 战斗锁守卫：锁定时排队到 PLAYER_REGEN_ENABLED 退战补建
function module.Refresh()
    if InCombatLockdown() then
        if module.frame then
            module.frame:RegisterEvent("PLAYER_REGEN_ENABLED")
        end
        return
    end
    module.DoRefresh()
end

-- 合并突发刷新：短时间内多次触发只真正执行一次（等宏/法术列表稳定，避免「先建后改」双刷）
local refreshTimer
local function CancelRefreshTimer()
    if refreshTimer then refreshTimer:Cancel(); refreshTimer = nil end
end
local function RunRefresh()
    CancelRefreshTimer()
    module.Refresh()
end
local function ScheduleRefresh(delay)
    delay = delay or 0.5
    CancelRefreshTimer()
    refreshTimer = C_Timer.After(delay, RunRefresh)
end

-- 事件帧回调（SetScript 先于 RegisterEvent，符合 12.x 硬约束）
local function OnEvent(self, event)
    if event == "PLAYER_REGEN_ENABLED" then
        self:UnregisterEvent("PLAYER_REGEN_ENABLED")
        module.Refresh()
        return
    end
    if event == "PLAYER_ENTERING_WORLD" then
        -- 登录：宏/法术列表可能尚未就绪，标记待刷；真正刷新推迟到首次 SPELLS_CHANGED 后合并执行
        module.loginPending = true
        -- 兜底：若 SPELLS_CHANGED 迟迟不来（极少见），3s 后也刷一次
        C_Timer.After(3, function()
            if module.loginPending then
                module.loginPending = false
                RunRefresh()
            end
        end)
        return
    end
    if event == "SPELLS_CHANGED" then
        -- 登录突发与游戏中学习新法术：均合并到最后一次事件后 0.5s 再刷一次
        if module.loginPending then module.loginPending = false end
        ScheduleRefresh(0.5)
    end
end

-- 由 Core:OnInitialize 统一调度的模块初始化：建事件帧并注册触发事件
function module.Init()
    local frame = CreateFrame("Frame")
    frame:SetScript("OnEvent", OnEvent)
    frame:RegisterEvent("PLAYER_ENTERING_WORLD")
    frame:RegisterEvent("SPELLS_CHANGED")
    module.frame = frame
end
