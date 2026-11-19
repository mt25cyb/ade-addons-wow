
-- adeBagPack / Modules / Rule.lua — 分类与排序规则（旧 adeBackpack Rule.lua 原样移植，ns 表机制不变）
local ns = _G.adeBagPack or {}

local ipairs, sort, wipe = ipairs, sort, wipe
local tinsert = table.insert

local Rule = {}
ns.Rule = Rule

local compareStrings = {}
-- 排序键缓存：**按物品实例**（sortKeyCache[bag][slot]），不能用 itemID ——
-- 同一 ID 的两件装备绑定状态可能不同，按 ID 缓存会让「魂绑优先」失效。
local sortKeyCache = {}

function Rule:New(tbl, default)
    local obj = {}
    
    obj.__unknownOrder = default
    for i, v in ipairs(tbl) do
        obj[v] = default and i or true
    end
    
    return obj
end

------ order

-- a12：原 GetJunkZoneKey（垃圾钉放区单维度键）已移除——垃圾改走 Baganator 式
-- 「对称整理」：非垃圾从槽表首游标正向填、垃圾从槽表尾游标反向填，中间留空。
-- 双端游标在 Group:BuildItemSlots 实现（a12 从 Rule:SortItems 的 items 反排迁出：
-- 只重排 items 无法产生物理空格，必须把「物品→目标槽」显式化）。垃圾的排序键
-- 恒末尾由 GetCategoryIndex 固定序号保证（a8），不再需要首位垃圾维度键。

function Rule:GetCustomOrder(item)
    return self.CustomOrder[item:GetItemID()] or self.CustomOrder[item:GetItemName()]
end

function Rule:GetTypeOrder(item)
    return  self.CustomOrder['#'  .. item:GetItemType() .. '##' .. item:GetItemSubType()] or
            self.CustomOrder['##' .. item:GetItemSubType()] or
            self.CustomOrder['#'  .. item:GetItemType()] or
            self.CustomOrder.__unknownOrder
end

-- a13：精确命中版类型规则（不返回 __unknownOrder）。GetTypeOrder 的默认值 999
-- 若直接用于分类序号会让**所有**物品都命中「自定义规则」→ 顺序全乱，故分类序号
-- 只取此处的精确命中值。键格式与 RuleDialog/ComputeRule 完全一致：#主类##子类 /
-- ##子类 / #主类（本地化名称，如 #物品强化##其他）。
function Rule:GetCustomTypeOrder(item)
    return  self.CustomOrder['#'  .. item:GetItemType() .. '##' .. item:GetItemSubType()] or
            self.CustomOrder['##' .. item:GetItemSubType()] or
            self.CustomOrder['#'  .. item:GetItemType()]
end

function Rule:GetEquipLocOrder(item)
    return self.EquipLocOrder[item:GetItemEquipLoc()] or self.EquipLocOrder.__unknownOrder
end

function Rule:GetLevelOrder(item)
    return 9999 - item:GetItemLevel()
end

function Rule:GetQualityOrder(item)
    return 99 - item:GetItemQuality()
end

---- sort keys（方案 §4.2.5-G：多层键链，替代定长拼接串）

-- 各排序键的取值函数。数值键统一为「越小越靠前」：
--   expansionDesc  资料片新→旧（expansionID 越大越新）
--   itemLevelDesc  装等高→低
--   qualityDesc    品质高→低
--   name           名称字符串
--   invSlot        装备部位序（沿用 EquipLocOrder）
--   boundFirst     灵魂绑定优先（已绑定 = 0）
--   equipSet       装备方案创建序（不在任何方案 = 999）
--   tradegoodSubClass  材料按来源专业子类
local keyGetters = {
    expansionDesc = function(item)
        return 99 - (item:GetExpansionID() or 0)
    end,
    itemLevelDesc = function(item)
        return 99999 - (item:GetItemLevel() or 0)
    end,
    qualityDesc = function(item)
        return 99 - (item:GetItemQuality() or 1)
    end,
    name = function(item)
        return item:GetItemName() or ''
    end,
    invSlot = function(item)
        return Rule:GetEquipLocOrder(item) or 99
    end,
    boundFirst = function(item)
        return item:IsBound() and 0 or 1
    end,
    equipSet = function(item)
        return ns.Config:GetEquipmentSetOrder(item) or 999
    end,
    tradegoodSubClass = function(item)
        return item:GetSubClassID() or 0
    end,
}

-- a14：分类序号不再分层。旧实现给 ID/类型规则取数组下标（如 27）、给分类规则取
-- CATEGORY_BASE + 下标（如 1002），导致「把 ID 规则拖到清单末尾」仍在所有分类之前
-- （用户实测 286563 排在类型规则与药水之间）。现四则统一取 CustomOrder 数组下标，
-- 未配置分类排在全部已配置规则之后。仅垃圾仍用固定末尾序号。
local JUNK_INDEX = 100000

-- 按 ns.Categories 顺序找首个命中的分类（Baganator prioritisedSearches 语义）。
-- check 返回 nil（数据未就绪）的分类视为未命中，继续往后匹配。
function Rule:GetCategoryKey(item)
    -- a13：垃圾优先于 Categories 的 miscellaneous/usable 判定。旧顺序里灰色杂项
    -- 先命中那两类（日志 idx=1021/1022）→ 垃圾被排进非垃圾中间；前置后分类键
    -- 与 GetCategoryIndex 的固定末尾序号、对称整理的 IsJunkItem 三者同口径。
    if self:IsJunkItem(item) then
        return 'junk'
    end

    local categories = ns.Categories
    if not categories then
        return 'other'
    end

    for _, category in ipairs(categories) do
        if category.check(item) then
            return category.key
        end
    end

    return 'other'
end

-- 分类序号：优先取「自定义规则」列表里分类条目的顺序（用户可调），
-- 未配置时回退到 Categories 的定义顺序。
function Rule:GetCategoryIndex(item)
    -- a13：垃圾沉底由 GetCategoryKey 前置 IsJunkItem 判定（返回 'junk'）——
    -- Categories 旧顺序里 junk 在 miscellaneous/usable 之后，灰色杂项先命中那两类
    -- （日志 idx=1021/1022）被排进非垃圾中间。下方 catKey=='junk' 分支先于自定义
    -- 规则执行，故关闭对称整理时垃圾也稳定沉底。
    local catKey = self:GetCategoryKey(item)

    -- 垃圾不参与用户分类顺序，固定排在所有规则之后（先于规则判定，避免末尾 ID
    -- 规则把垃圾提前）。
    if catKey == 'junk' then
        return JUNK_INDEX, 'junk'
    end

    -- a14：四类规则统一取 CustomOrder 里的**数组下标**（设置页视觉顺序 == 物理顺序），
    -- 冲突时按「精确优先于宽泛」覆盖，而非取最小下标：
    --   ID / 物品名规则  >  类型规则（#主类##子类 / ##子类 / #主类）  >  分类规则（@category:）
    -- 理由：用户为**特定物品**加的规则拖到清单末尾，是明确要求它排最后；若取最小下标，
    -- 该物品仍命中靠前的宽泛分类（如 286563 命中 @category:consumable 第 4 位）会被
    -- 拉回前面，与用户意图相反。精确规则独占该物品，宽泛规则只对未精确指定的物品生效。
    -- 无命中才回落到「未配置分类」基线。
    local idOrder = self:GetCustomOrder(item)
    local typeOrder = self:GetCustomTypeOrder(item)
    local catOrder = self.CategoryOrder and self.CategoryOrder[catKey]
    local bestOrder, bestKey
    if idOrder then
        bestOrder, bestKey = idOrder, 'custom'
    elseif typeOrder then
        bestOrder, bestKey = typeOrder, 'type'
    elseif catOrder then
        bestOrder, bestKey = catOrder, catKey
    end
    if bestOrder then
        return bestOrder, bestKey
    end

    -- 未在自定义规则里出现的分类（玩家删掉了对应 `@category:` 条目）：
    -- 排在**所有已配置规则之后**，按 Categories 定义顺序依次排开。
    -- 基线取 CustomOrder 长度（而非旧的 CategoryOrderCount），确保大于任何已配置规则下标。
    local categories = ns.Categories or {}
    local p = ns:GetProfile()
    local ruleCount = (p and p.orders and p.orders.CustomOrder) and #p.orders.CustomOrder or 0
    local offset = math.max(ruleCount, self.CategoryOrderCount or 0)
    for index, category in ipairs(categories) do
        if category.key == catKey then
            return offset + index, catKey
        end
    end

    return offset + #categories + 1, 'other'
end

-- 从「自定义规则」列表解析分类条目顺序：`@category:<key>` → **数组原始下标**。
-- a14：此前用「分类条目重新计数」（1..N），会与 ID/类型规则的数组下标撞车
-- （如类型规则在列表第 1、potion 是第 1 个分类 → 两者序号同为 1）。现统一用
-- ipairs 的 index，使四类规则共享同一套序号空间。
-- 返回 (order, count)：count = 自定义分类条目数，供「未配置分类」的序号基线使用。
function Rule:BuildCategoryOrder(list)
    local order = {}
    local prefix = ns.CATEGORY_PREFIX or '@category:'
    local count = 0

    for index, value in ipairs(list or {}) do
        if type(value) == 'string' and value:sub(1, #prefix) == prefix then
            -- a8：兼容旧档残留 junk 条目——不计入分类顺序（Rule:GetCategoryIndex 固定末尾）
            local key = value:sub(#prefix + 1)
            if key ~= 'junk' then
                count = count + 1
                order[key] = index
            end
        end
    end

    return order, count
end

-- 排序键数组：{ 分类序, 键1, 键2, … }。
-- 缓存键必须是 **物品实例（GUID）**，绝不能用 bag+slot：
-- 整理每 tick 都会 Rescan 重建 Item，且物品本身在移动 —— 同一个 bag+slot 位置
-- 在不同 tick 上对应的是**不同物品**。按位置缓存会让新来的物品复用「前任」的
-- 排序键 → 键与物品张冠李戴 → 分类交错、顺序不收敛（「多次整理才完成」的真因）。
-- （同 bag.lua:FindSlot / group.lua:IsSameItem 的 GUID 化理由。）
function Rule:GetSortKeys(item)
    local guid = item.GetGUID and item:GetGUID()
    if guid then
        local cached = sortKeyCache[guid]
        if cached then
            return cached
        end
    end

    -- 单物品排序键计算若出错（数据异常 / getter 缺失 / 某维度取到 nil），兜底为「分类序 + 名称 + GUID」，
    -- 保证不中断整次排序（否则 table.sort 一旦抛错，全组物品都不归位，表现为「整理完全不动」）。
    -- 兜底键仍尊重分类顺序（catIndex 在前），仅丢失次级维度，属安全降级（2026-10-04 加）。
    local keys
    local ok = pcall(function()
        local catIndex, catKey = self:GetCategoryIndex(item)
        local chain = ns.CategorySortKeys and (ns.CategorySortKeys[catKey] or ns.CategorySortKeys.default)
        if not chain then
            chain = {'expansionDesc', 'itemLevelDesc', 'qualityDesc', 'name'}
        end

        -- a12：垃圾维度键移除——垃圾固定末尾由 GetCategoryIndex 保证，
        -- 对称方向由 Group:BuildItemSlots 的双端游标承担（替代原垃圾钉放区）。
        local k = { catIndex }
        for _, name in ipairs(chain) do
            local getter = keyGetters[name]
            tinsert(k, getter and getter(item) or 0)
        end

        -- 统一 tie-breaker（所有分类共用，置于分类链之后）——决定同 itemID 多堆的先后：
        -- ① 堆叠数量降序：满堆在前，观感整齐（如 1000 / 591 两堆，满堆排前面）。
        -- ② GUID：保证**绝对稳定**。同 itemID 的几组若排序键完全相同，Lua table.sort
        --   **不稳定**（等价元素相对顺序无保证）→ 每 tick 重排时它们的顺序可能互换
        --   → 目标位置反复变化 → 整理末段「反复搬移同几组物品」的抖动。追加 GUID 后
        --   不再存在等价元素，排序结果唯一确定，抖动消失。
        tinsert(k, 99999 - (item.GetStackCount and item:GetStackCount() or 1))
        tinsert(k, guid or '')

        keys = k
    end)
    if not ok then
        local catIndex = 0
        pcall(function() catIndex = self:GetCategoryIndex(item) or 0 end)
        keys = { catIndex, item:GetItemName() or '', guid or '' }
        ns:Debug('GetSortKeys 兜底:', item.GetItemID and item:GetItemID() or '?',
            (type(debug) == 'table' and debug.traceback) and debug.traceback() or 'no-debug')
    end

    if guid then
        sortKeyCache[guid] = keys
    end

    return keys
end

-- 排序前置检查：任一物品数据未就绪（classID 等未取到）→ 排序键会缺项导致错乱，
-- 此时调用方应等待下 tick 重建 Item 再排（Baganator CheckItem 返回 nil 同机制）。
function Rule:IsItemsReady(items)
    for _, item in ipairs(items) do
        if not item:IsInfoReady() then
            return false
        end
    end
    return true
end

function Rule:ClearSortKeyCache()
    wipe(sortKeyCache)
end

------ other

local function sortCompare(a, b)
    local ka = Rule:GetSortKeys(a)
    local kb = Rule:GetSortKeys(b)

    for i = 1, #ka < #kb and #ka or #kb do
        local va, vb = ka[i], kb[i]
        if va ~= vb then
            if type(va) == 'number' and type(vb) == 'number' then
                return va < vb
            end
            return tostring(va) < tostring(vb)
        end
    end

    return #ka < #kb
end

-- 垃圾判定（a11）：与 Config.junk.check / 原 GetJunkZoneKey 同口径——
-- Dejunk 接管时问 DejunkApi，否则 Poor 品质；独立于分类（Poor 装备可能已归 weapon，
-- 仍须归入垃圾段），与 Baganator OrderBags.lua:250-268 的 junk plugin/Poor 判定同构。
function Rule:IsJunkItem(item)
    local ext = ns.External
    if ext and ext.IsDejunkActive and ext:IsDejunkActive() then
        return ext:IsJunkSlot(item:GetBag(), item:GetSlot()) == true
    end
    return item:GetItemQuality() == Enum.ItemQuality.Poor
end

-- 纯分类/次级键排序。垃圾对称整理不在此处反排 items —— a12 迁至
-- Group:BuildItemSlots：只有把「物品 → 目标槽」显式化（首/尾双游标），
-- 才能在非垃圾段与垃圾段之间真正留出空格；仅重排 items 后仍靠
-- items[i]↔slots[i] 紧密配对，物理上无法留空（用户实测「垃圾对称整理未生效」）。
function Rule:SortItems(items)
    sort(items, sortCompare)
end

function Rule:BuildRule()
    local profile = ns:GetProfile()
    
    self.CustomOrder   = Rule:New(profile.orders.CustomOrder, 999)
    self.EquipLocOrder = Rule:New(profile.orders.EquipLocOrder, 99)
    -- CategoryOrderCount = 自定义分类条目数，作为「未配置分类」的序号偏移量
    self.CategoryOrder, self.CategoryOrderCount = self:BuildCategoryOrder(profile.orders.CustomOrder)
end

function Rule:OnProfileUpdate()
    wipe(compareStrings)
    -- 排序键实例级缓存：配置/物品数据变化后必须失效
    self:ClearSortKeyCache()
    
    self:BuildRule()
end

function Rule:Init()
    self:BuildRule()
    end
