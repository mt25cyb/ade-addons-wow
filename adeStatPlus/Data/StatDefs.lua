--[==[ 属性注册表（静态数据）
    每个条目：key / group / labelKey / abbrKey / color / read / readSplit。
    read 返回 **(value, percent)** 两个彼此独立的数据通道：
      · value   = 面板值（角色面板该属性显示的主数值，纯数字、不带 %）
      · percent = 角色面板 tooltip 中显示的百分比（带 %）
    两者各自可为 nil（该属性没有这类数据）或 secret 原值，绝不互相复用。
    实证：IStats/Stats.lua:208-222 把 armor 与 armorPct 拆成两个独立显示项，
    前者 UnitArmor 第 3 返回、后者 C_PaperDollInfo.GetArmorEffectiveness×100，
    正对应用户举例「值 230 / 百分比 20.72%」。

    逐属性映射（value / percent），全部基于 _temp/_stats 实证 API：
      主属性·耐力  UnitStat effective        / 无（角色面板无百分比）
      四绿        GetCombatRating(CR_*)     / GetCritChance·GetHaste·GetMasteryEffect·全能双源
      护甲        UnitArmor 第 3 返回       / GetArmorEffectiveness×100
      闪避·吸血   GetCombatRating(CR_*)     / GetAvoidance·GetLifesteal
      防护四属性  无（角色面板只有几率）    / 对应 Chance
      等级·装等   数值                     / 无
      耐久       无                       / 逐槽总耐久百分比
      移速       无                       / 额定奔跑速度 /7×100（D56，依 Stats）
    「不需要评级」落地：删除旧 columns.rating 与 format.kind(number/percent/both) 组合格式。
    移速取值（D56）：依 _temp/_stats/Stats/Stats.lua:392-397 只取 `GetUnitSpeed("player")`
    的**第 2 返回值 run**（额定奔跑速度），基准 7 由 :361-371 significandDivisor=0.0699999
    与 :390 的 `speedValue / 7 * 100` 实证；旧实现误取第 1 返回值 current（实际瞬时速度）。

    secret 纪律（§2.3）：判定用 12.x 裸全局 issecretvalue / canaccessvalue；
    算术前必须过关卡，原值只交给 FontString / StatusBar 由客户端渲染。 ]==]
-- ADE v6.5：ns 统一走全局私有表
local addonName = ...
local ns = _G.adeStatPlus or {}
_G.adeStatPlus = ns

local UnitStat, UnitLevel, UnitArmor = UnitStat, UnitLevel, UnitArmor
local GetSpecialization, GetSpecializationInfo = GetSpecialization, GetSpecializationInfo
local GetCombatRating, GetCombatRatingBonus = GetCombatRating, GetCombatRatingBonus
local GetInventoryItemDurability = GetInventoryItemDurability
local C_PaperDollInfo = C_PaperDollInfo

local EQUIP_SLOTS = { 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18 }
local BASE_MOVEMENT_SPEED = 7

-- 运行期经 ns.Collector 取判定函数（Collector.lua 在本文件之后加载，故不能顶层固化其引用）。
local function IsSecret(value)
    return ns.Collector.IsSecret(value)
end

-- 把「多源相加 / 按基准换算」这类算术收口在此：任一操作数为 secret 时直接返回原值，
-- 由 Collector 标记 secret 并交给 FontString / StatusBar 由客户端渲染。
-- 用变参而非表传参，避免 secret 值进入表后被迭代 / 作键（12.x 限制）。
local function Combine(apply, ...)
    for i = 1, select("#", ...) do
        local v = select(i, ...)
        if IsSecret(v) then return v end
    end
    -- apply 内的算术只在此处、即全部操作数已通过 secret 关卡后执行。
    -- 静态分析器无法跨越函数边界推断该运行时守卫，故对调用点做局部抑制。
    return apply()
end

-- 默认属性色：**全部取自 Stats 插件 AceDB 真默认值**（实证 _temp/_stats/Stats/Stats.lua:64-80，
-- z-ref_addons_retail/Stats/Stats.lua 同）。其 EnsureColors() 补齐表(:169-187) 对 speed/armor
-- 有 0.01 差异，这里以 AceDB 真默认表为准（新 profile 实际生效的那份）。
-- Stats 没有单独色键的项，按同组/同类继承并注明依据，不臆造新色值。
local C_ILVL      = { 1.00, 1.00, 1.00 }  -- Stats colors.ilvl；等级·耐久继承（同为其它说明类）
local C_MAIN      = { 0.46, 0.76, 0.77 }  -- Stats colors.main：力/敏/智共用；耐力继承主属性
local C_CRIT      = { 0.77, 0.29, 0.28 }  -- Stats colors.crit
local C_HASTE     = { 0.34, 0.77, 0.40 }  -- Stats colors.haste
local C_MASTERY   = { 0.77, 0.77, 0.25 }  -- Stats colors.mastery
local C_VERS      = { 0.32, 0.42, 0.77 }  -- Stats colors.vers
local C_LEECH     = { 0.81, 0.39, 0.99 }  -- Stats colors.leech
local C_AVOIDANCE = { 0.99, 0.62, 0.19 }  -- Stats colors.avoidance
local C_SPEED     = { 1.00, 1.00, 0.40 }  -- Stats colors.speed
local C_BLOCK     = { 0.75, 0.75, 0.75 }  -- Stats colors.block
local C_PARRY     = { 0.65, 0.85, 0.85 }  -- Stats colors.parry；醉拳继承防护组 parry
local C_DODGE     = { 0.85, 0.85, 0.65 }  -- Stats colors.dodge
local C_ARMOR     = { 0.60, 0.60, 0.90 }  -- Stats colors.armor

local function PrimaryStatIndex()
    -- GetSpecializationInfo 第 6 返回为 LE_UNIT_STAT_* statID（1 力 / 2 敏 / 4 智）
    local spec = GetSpecialization()
    if not spec then return nil end
    return select(6, GetSpecializationInfo(spec))
end

local function ReadPrimary(statIndex)
    return (select(2, UnitStat("player", statIndex))), nil
end

local function ReadDurability()
    local totalCur, totalMax = 0, 0
    for _, slot in ipairs(EQUIP_SLOTS) do
        local cur, max = GetInventoryItemDurability(slot)
        if cur and max and max > 0 then
            totalCur = totalCur + cur
            totalMax = totalMax + max
        end
    end
    if totalMax == 0 then return nil, nil end
    return nil, totalCur / totalMax * 100
end

--- 护甲减伤百分比（tooltip 数据）。C 侧 API 不接受 secret 实参，故先判定再调用。
local function ReadArmorPercent()
    local _, effective = UnitArmor("player")
    if IsSecret(effective) then return effective end
    ---@diagnostic disable-next-line: secret-argument
    local dr = C_PaperDollInfo.GetArmorEffectiveness(effective, UnitLevel("player"))
    ---@diagnostic disable-next-line: secret-arithmetic
    return Combine(function() return dr * 100 end, dr)
end

local StatDefs = {}
local function Define(def)
    StatDefs[def.key] = def
end

-- ── 主要属性：只有面板值，没有百分比 ────────────────────────────────────────────
Define { key = "strength", group = "primary", labelKey = "STAT_STRENGTH", abbrKey = "ABBR_STRENGTH",
    color = C_MAIN, read = function() return ReadPrimary(1) end }
Define { key = "agility", group = "primary", labelKey = "STAT_AGILITY", abbrKey = "ABBR_AGILITY",
    color = C_MAIN, read = function() return ReadPrimary(2) end }
Define { key = "intellect", group = "primary", labelKey = "STAT_INTELLECT", abbrKey = "ABBR_INTELLECT",
    color = C_MAIN, read = function() return ReadPrimary(4) end }
Define { key = "stamina", group = "primary", labelKey = "STAT_STAMINA", abbrKey = "ABBR_STAMINA",
    color = C_MAIN, read = function() return ReadPrimary(3) end }

-- ── 次级属性：面板值 = CombatRating，百分比 = tooltip 几率 ───────────────────────
Define { key = "crit", group = "secondary", labelKey = "STAT_CRIT", abbrKey = "ABBR_CRIT",
    color = C_CRIT, read = function()
        -- 三源择优：法系(primaryStat 4)取法术爆击、远程物理(2)取远程爆击，其余取近战爆击。
        -- 依据 MightStats/Core.lua:75-91 与 StatDisplay/StatDisplay.lua:1140-1188。
        -- 12.x 三个函数均无参数（Blizzard_APIDocumentation arguments=[]）；参考插件传 school
        -- 是旧 API 遗留写法，额外实参在 12.x 无效。
        local statID = PrimaryStatIndex()
        local chance
        if statID == 4 then
            chance = GetSpellCritChance()
        elseif statID == 2 then
            chance = GetRangedCritChance()
        else
            chance = GetCritChance()
        end
        return GetCombatRating(CR_CRIT_MELEE), chance
    end }
Define { key = "haste", group = "secondary", labelKey = "STAT_HASTE", abbrKey = "ABBR_HASTE",
    color = C_HASTE, read = function()
        return GetCombatRating(CR_HASTE_MELEE), GetHaste()
    end }
Define { key = "mastery", group = "secondary", labelKey = "STAT_MASTERY", abbrKey = "ABBR_MASTERY",
    color = C_MASTERY, read = function()
        return GetCombatRating(CR_MASTERY), GetMasteryEffect()
    end }
Define { key = "vers", group = "secondary", labelKey = "STAT_VERS", abbrKey = "ABBR_VERS",
    color = C_VERS, read = function()
        local rating = GetCombatRating(CR_VERSATILITY_DAMAGE_DONE)
        local a = GetCombatRatingBonus(CR_VERSATILITY_DAMAGE_DONE)
        local b = GetVersatilityBonus(CR_VERSATILITY_DAMAGE_DONE)
        ---@diagnostic disable-next-line: secret-arithmetic
        local dmg = Combine(function() return a + b end, a, b)
        return rating, dmg
    end,
    -- 全能分显：伤害加成 / 减伤，两者都是百分比
    readSplit = function()
        local a = GetCombatRatingBonus(CR_VERSATILITY_DAMAGE_DONE)
        local b = GetVersatilityBonus(CR_VERSATILITY_DAMAGE_DONE)
        local c = GetCombatRatingBonus(CR_VERSATILITY_DAMAGE_TAKEN)
        local d = GetVersatilityBonus(CR_VERSATILITY_DAMAGE_TAKEN)
        ---@diagnostic disable-next-line: secret-arithmetic
        local dmg = Combine(function() return a + b end, a, b)
        ---@diagnostic disable-next-line: secret-arithmetic
        local red = Combine(function() return c + d end, c, d)
        return dmg, red
    end }

-- ── 第三属性 ────────────────────────────────────────────────────────────────────
Define { key = "armor", group = "tertiary", labelKey = "STAT_ARMOR", abbrKey = "ABBR_ARMOR",
    color = C_ARMOR, read = function()
        -- 面板值 = UnitArmor 第 3 返回；百分比 = 减伤率（独立通道，不复用面板值）
        local _, _, armor = UnitArmor("player")
        return armor, ReadArmorPercent()
    end }
Define { key = "avoidance", group = "tertiary", labelKey = "STAT_AVOIDANCE", abbrKey = "ABBR_AVOIDANCE",
    color = C_AVOIDANCE, read = function()
        return GetCombatRating(CR_AVOIDANCE), GetAvoidance()
    end }
Define { key = "leech", group = "tertiary", labelKey = "STAT_LEECH", abbrKey = "ABBR_LEECH",
    color = C_LEECH, read = function()
        return GetCombatRating(CR_LIFESTEAL), GetLifesteal()
    end }

-- ── 防护属性：角色面板只有几率，没有独立面板值 ───────────────────────────────────
Define { key = "parry", group = "defensive", labelKey = "STAT_PARRY", abbrKey = "ABBR_PARRY",
    color = C_PARRY, read = function() return nil, GetParryChance() end }
Define { key = "block", group = "defensive", labelKey = "STAT_BLOCK", abbrKey = "ABBR_BLOCK",
    color = C_BLOCK, read = function() return nil, GetBlockChance() end }
Define { key = "dodge", group = "defensive", labelKey = "STAT_DODGE", abbrKey = "ABBR_DODGE",
    color = C_DODGE, read = function() return nil, GetDodgeChance() end }
-- 醉拳不再硬编码「仅酒仙」显示限制（D54：去除此显示限制）；
-- 是否显示交给设置页「自动隐藏属性」选项按当前专精判断（FallbackVisible 用 specID 268）。
Define { key = "stagger", group = "defensive", labelKey = "STAT_STAGGER", abbrKey = "ABBR_STAGGER",
    color = C_PARRY,
    read = function() return nil, C_PaperDollInfo.GetStaggerPercentage("player") end }

-- ── 其他属性 ────────────────────────────────────────────────────────────────────
Define { key = "level", group = "others", labelKey = "STAT_LEVEL", abbrKey = "ABBR_LEVEL",
    color = C_ILVL, read = function() return UnitLevel("player"), nil end }
Define { key = "ilvl", group = "others", labelKey = "STAT_ILVL", abbrKey = "ABBR_ILVL",
    color = C_ILVL, read = function() return select(2, GetAverageItemLevel()), nil end }
Define { key = "durability", group = "others", labelKey = "STAT_DURABILITY", abbrKey = "ABBR_DURABILITY",
    color = C_ILVL, read = ReadDurability }
Define { key = "speed", group = "others", labelKey = "STAT_SPEED", abbrKey = "ABBR_SPEED",
    color = C_SPEED, read = function()
        -- 依 Stats/Stats.lua:392-397：只取第 2 返回值 run（额定奔跑速度），
        -- 基准 7（:361-371, :390）。第 1 返回值 current 是瞬时速度，会把坐骑/滑翔
        -- 变化时钉在实时值上，故不采用。
        local _, run = GetUnitSpeed("player")
        ---@diagnostic disable-next-line: secret-arithmetic
        return nil, Combine(function() return run / BASE_MOVEMENT_SPEED * 100 end, run)
    end }

ns.StatDefs = StatDefs
ns.PrimaryStatIndex = PrimaryStatIndex

-- 组标题 locale key（Panel / SortWindow 共用）
ns.GROUP_LABEL_KEYS = {
    primary = "GRP_PRIMARY",
    secondary = "GRP_SECONDARY",
    tertiary = "GRP_TERTIARY",
    defensive = "GRP_DEFENSIVE",
    others = "GRP_OTHERS",
}

-- 组内成员默认顺序（用户 2026-11-09 定稿；实际顺序以 profile.order.* 为准）
ns.GROUP_MEMBERS = {
    primary = { "strength", "agility", "intellect", "stamina" },
    secondary = { "crit", "haste", "mastery", "vers" },
    tertiary = { "armor", "avoidance", "leech" },
    defensive = { "dodge", "parry", "block", "stagger" },
}

-- 颜色统一取 RGB：StatDefs 内置默认色用 {r,g,b} 数组，ColorPicker 回调给 {r=,g=,b=,a=}
-- 命名表（widget/ColorSwatch.lua:13）。两种形态在此收口，避免各处 color[1] 取到 nil。
---@param color table
---@return number r
---@return number g
---@return number b
function ns.ColorRGB(color)
    return color[1] or color.r or 1, color[2] or color.g or 1, color[3] or color.b or 1
end
