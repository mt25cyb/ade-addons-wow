
-- adeBagPack / Modules / Config.lua（旧 adeBackpack 移植：ADE 守卫行删除，L 走 ABP.L）

local ns = _G.adeBagPack or {}

local L = ns.L

-- V4 模块表：V3 经 tdPack.Config 构造，迁移后需显式建表（否则 function ns.Config:.. 索引 nil 报错）
ns.Config = ns.Config or {}

-- 12.1.0 适配（方案 §4.2.1 / §2.2）：
-- 1) GetItemSubClassInfo / LE_ITEM_CLASS_* / LE_ITEM_WEAPON_FISHINGPOLE 已移除 →
--    C_Item.GetItemSubClassInfo(Enum.ItemClass.X, Enum.ItemWeaponSubclass.X)；
--    Enum.ItemClass 取值与字段名 [已核] z-ref ItemConstantsDocumentation.lua:206-226。
-- 2) AUCTION_CATEGORY_*（MoP 拍卖类名全局）12.1 是否仍导出 [待实测]（客户端 C 侧，
--    UI 源码零引用）；缺失时回退 C_Item.GetItemClassInfo(classID)（与 GetItemInfo
--    返回的 itemType 同源，保证 DefaultCustomOrder 分类标签能命中物品主类名）。
-- 注：这些名字同时充当顺序规则标签，必须与物品主类名一致才能分组生效。

local function AuctionClass(legacy, classID)
    return legacy or C_Item.GetItemClassInfo(classID)
end

local Weapons, Armor, Containers, Consumables, Glyphs, TradeGoods, Recipes, Gems, Miscellaneous, Quest, BattlePet =
    AuctionClass(AUCTION_CATEGORY_WEAPONS, Enum.ItemClass.Weapon),
    AuctionClass(AUCTION_CATEGORY_ARMOR, Enum.ItemClass.Armor),
    AuctionClass(AUCTION_CATEGORY_CONTAINERS, Enum.ItemClass.Container),
    AuctionClass(AUCTION_CATEGORY_CONSUMABLES, Enum.ItemClass.Consumable),
    AuctionClass(AUCTION_CATEGORY_GLYPHS, Enum.ItemClass.Glyph),
    AuctionClass(AUCTION_CATEGORY_TRADE_GOODS, Enum.ItemClass.Tradegoods),
    AuctionClass(AUCTION_CATEGORY_RECIPES, Enum.ItemClass.Recipe),
    AuctionClass(AUCTION_CATEGORY_GEMS, Enum.ItemClass.Gem),
    AuctionClass(AUCTION_CATEGORY_MISCELLANEOUS, Enum.ItemClass.Miscellaneous),
    AuctionClass(AUCTION_CATEGORY_QUEST_ITEMS, Enum.ItemClass.Questitem),
    AuctionClass(AUCTION_CATEGORY_BATTLE_PETS, Enum.ItemClass.Battlepet)

local FishingPoles = C_Item.GetItemSubClassInfo(Enum.ItemClass.Weapon, Enum.ItemWeaponSubclass.Fishingpole)
local Devices = C_Item.GetItemSubClassInfo(Enum.ItemClass.Tradegoods, 3)

ns.DefaultCustomOrder = {
    HEARTHSTONE_ITEM_ID,                    -- 炉石
    -- 140192 达拉然炉石：经用户实机确认 2026-09-03 已玩具化（与 141605/110560/64488
    -- 相同，使用即入玩具箱、不占包）→ 与其余旧置顶项一并降级注释：
    -- 旧版 8.2 常用置顶项 —— 2026-09-03 逐项核实后统一降级注释：
    -- 141605,                                 -- 飞行管理员的哨子（军团，已玩具化不占包）
    -- 110560,                                 -- 要塞炉石（德拉诺，已玩具化不占包）
    -- 64488,                                  -- 旅店老板的女儿（考古玩具）
    -- 79104,                                  -- 水壶 [待验证：ID↔名称未核实]
    -- 2901,                                   -- 矿工锄（经典旧世专业工具，现役专业已用专精装备）
    -- 5956,                                   -- 铁匠锤（同上）
    -- 7005,                                   -- 剥皮刀（同上）
    -- 20815,                                  -- 珠宝制作工具
    -- 39505,                                  -- 学者的书写工具
    -- 147707,                                 -- 改装的邪能焦镜（军团消耗品；abyVesion 原误写 147717，已修正）
    -- 138111,                                 -- 雷铸爪钩枪（军团风暴峡湾任务道具，ID 有效）
    -- 141652,                                 -- [待验证：abyVesion 注释「苏拉玛侦测」，ID↔名称未核实]
    -- 118922,                                 -- [待验证：abyVesion 注释「疯狂低语水晶」，ID↔名称未核实]
    '#'  .. TradeGoods .. '##' .. Devices,  -- #商品##装置
    '##' .. FishingPoles,                   -- ##鱼竿
    '#'  .. BattlePet,                      -- #战斗宠物
    '#'  .. Weapons,                        -- #武器
    '#'  .. Armor,                          -- #护甲
    '#'  .. Containers,                     -- #容器
    '#'  .. Gems,                           -- #珠宝
    '#'  .. Glyphs,                         -- #雕文
    '#'  .. Recipes,                        -- #配方
    '#'  .. TradeGoods,                     -- #商品
    '#'  .. Consumables,                    -- #消耗品
    '#'  .. Miscellaneous,                  -- #其它
    '#'  .. Quest,                          -- #任务
}

-- 新分类体系（方案 §4.2.5，2026-09-03 落地）：
-- 清单与顺序照搬 Baganator Retail 预设（CategoryViews/Constants.lua:166-323 定义 +
-- :359 的 v2 默认顺序），按用户 2026-09-03 确认的 12 点定制；
-- **判定函数全部自实现**，逻辑对齐 Syndicator/Search/CheckItem.lua（行号见各条注释
-- `[已核]`），不引入 Syndicator 依赖（决策 D10-b）。
--
-- 每项字段：
--   key    唯一标识（与 Baganator 的 default_xxx 对齐，便于以后对照）
--   name   本地化键（L[name]）
--   check  function(item) -> true / false / nil
--          nil = 物品数据未就绪，调用方应让出本 tick、下 tick 重试
--
-- 匹配语义：按数组顺序**首个命中**的分类胜出（同 Baganator prioritisedSearches）。
local C = Enum.ItemClass

-- 装备方案映射：itemID → 方案序号（创建序）。方案列表在一次整理内不变，故缓存；
-- 整理开始时由 Pack 调 ResetEquipmentSetCache() 失效，保证方案增删能被感知。
local equipmentSetMap = nil

local function GetEquipmentSetItemMap()
    if equipmentSetMap then
        return equipmentSetMap
    end

    equipmentSetMap = {}
    local ids = C_EquipmentSet.GetEquipmentSetIDs()
    for order, setID in ipairs(ids or {}) do
        local itemIDs = C_EquipmentSet.GetItemIDs(setID)
        for _, itemID in ipairs(itemIDs or {}) do
            if itemID and not equipmentSetMap[itemID] then
                equipmentSetMap[itemID] = order -- 首次命中的方案为准（创建序）
            end
        end
    end
    return equipmentSetMap
end

function ns.Config:ResetEquipmentSetCache()
    equipmentSetMap = nil
end

-- 物品所属装备方案的创建序（不在任何方案 → nil）。
-- 装备段排序键链 `equipSet` 用之（用户定：多方案按创建序、无方案装备排在其后）。
function ns.Config:GetEquipmentSetOrder(item)
    return GetEquipmentSetItemMap()[item:GetItemID()]
end

-- 需要额外数据（缓存/玩具箱/钥石）才能判定的分类：先确保数据已缓存，否则返回 nil
-- 让调用方下 tick 重试（同 Syndicator ToyCheck :814-821 的做法）
local function NeedItemData(item)
    local itemID = item:GetItemID()
    if type(itemID) ~= 'number' then
        return nil
    end
    if not C_Item.IsItemDataCachedByID(itemID) then
        C_Item.RequestLoadItemDataByID(itemID)
        return nil
    end
    return itemID
end

-- 分类判定缓存（按 itemID）：玩具箱 / 钥石 / 可用法术各有**独立的数据加载**，
-- 首次查询可能未就绪（返回 nil）。若因此把物品判进兜底分类，本次整理后数据到达、
-- 下次整理分类又变 → 表现为「要多次整理才稳定」。
-- 结果一旦确定即缓存：既避免每 tick 重复调用，也保证同一次整理内判定一致。
-- ⚠️ 必须定义在 NeedItemData 之后：Lua 的 local 前向引用为 nil（同 §7.1 坑）。
local itemFlags = {}

local function GetItemFlag(item, flag, compute)
    local itemID = item:GetItemID()
    if type(itemID) ~= 'number' then
        return false
    end

    local entry = itemFlags[itemID]
    if entry and entry[flag] ~= nil then
        return entry[flag]
    end

    if not C_Item.IsItemDataCachedByID(itemID) then
        C_Item.RequestLoadItemDataByID(itemID)
        return nil -- 数据未就绪 → 调用方下 tick 重试
    end

    local value = compute(itemID) and true or false
    itemFlags[itemID] = itemFlags[itemID] or {}
    itemFlags[itemID][flag] = value
    return value
end

-- 物品是否「可使用 / 可打开」：C_Item.GetItemSpell 有值即视为可用
-- （ItemDocumentation.lua:948 `[已核]`）。
local function IsUsableItem(item)
    return GetItemFlag(item, 'usable', function(itemID)
        return C_Item.GetItemSpell(itemID) ~= nil
    end)
end

-- 住宅木料专属名称关键词：中/英已覆盖（后续新增语言直接在此追加，如法语 'Bois'、德语 'Holz'）。
-- 仅收录专属词（Lumber / 木料），不收宽泛的 Wood/Timber，避免误收名字碰巧含它们的非住宅物。
local LUMBER_KEYWORDS = { '木料', 'Lumber' }

ns.Categories = {
    -- 具名特殊物品：必须排在所有「按 classID 判定」的通用类目之前。
    -- 钥石真实 itemClass = Reagent(5) / subclass 1（2026-10-04 /adebp debug 实测：
    -- id=180653 → classID=5 subclassID=1），与 Baganator CategoryGrouping.lua `5, 1, -- Keystone` 一致。
    -- 若本分类排在下方 'reagent'（classID==5）之后，GetCategoryKey 会先命中 'reagent'，钥石被当成材料
    -- → 不参与钥石分组/整理。故置于表最前（仅晚于 hearthstone 的 itemID 精确判定）。
    -- 判定用 class/subclass（不依赖 C_Item.IsItemKeystoneByID）：后者标 AllowedWhenUntainted，
    -- 在整理触发链（tainted 上下文）调用会受限 → 返回非预期 → 钥石误归入 reagent、不归位
    -- （Baganator/BankStack 用 class/subclass 故正常）。class/subclass 为物品基础属性，数据就绪即可靠。
    -- 注：早年注释误记为「被 key/questitem 抢走」，实测真凶是 reagent（钥石本就属 Reagent 类）。
    { key = 'hearthstone', name = 'Hearthstone', check = function(item)
        return item:GetItemID() == HEARTHSTONE_ITEM_ID
    end },
    { key = 'keystone', name = 'KeyStone', check = function(item)
        -- Reagent(5)/subclass 1 = 钥石（对齐 Baganator；实测 id=180653 如此）
        return item:GetClassID() == C.Reagent and item:GetSubClassID() == 1
    end },
    -- 药水/合剂：Consumable 子类 1/2/3 = 药水/药剂/合剂（CheckItem.lua:123-126）
    { key = 'potion', name = 'Potion', check = function(item)
        return item:GetClassID() == C.Consumable
            and (item:GetSubClassID() == 1 or item:GetSubClassID() == 2 or item:GetSubClassID() == 3)
    end },
    -- 食物：Consumable 子类 5 = 食物和饮料（CheckItem.lua:118-121）
    { key = 'food', name = 'Food', check = function(item)
        return item:GetClassID() == C.Consumable and item:GetSubClassID() == 5
    end },
    -- 其余消耗品（Baganator consumable，CheckItem.lua 用 classID 直接判定）
    { key = 'consumable', name = 'Consumable', check = function(item)
        return item:GetClassID() == C.Consumable
    end },

    -- 装备分区：装备方案（独立一段）→ 武器 → 护甲
    { key = 'equipment_sets', name = 'Equipment sets', check = function(item)
        local map = GetEquipmentSetItemMap()
        return map[item:GetItemID()] ~= nil
    end },
    { key = 'weapon', name = 'Weapon', check = function(item)
        return item:GetClassID() == C.Weapon
    end },
    { key = 'armor', name = 'Armor', check = function(item)
        return item:GetClassID() == C.Armor
    end },

    { key = 'gem', name = 'Gem', check = function(item)
        return item:GetClassID() == C.Gem
    end },
    { key = 'itemenhancement', name = 'Item enhancement', check = function(item)
        return item:GetClassID() == C.ItemEnhancement
    end },

    -- 制造分区：材料 → 商品 → 专业 → 配方 → 住宅
    { key = 'reagent', name = 'Reagent', check = function(item)
        return item:GetClassID() == C.Reagent
    end },
    -- 12.x 独立「住宅制作材料」分类：把住宅染料（主类 Housing）与住宅木料合并为同一组，
    -- 置于 tradegoods 之前（优先级更高），避免木料混进通用制作材料。
    -- 住宅木料（奥雷巴木料/多恩冷杉木料等）主类 Tradegoods、子类=其它(11)：实测 itemID 242691
    -- = classID 7 / subclassID 11，与通用制作材料无法靠单一 class/subclass 区分，故再加专属
    -- 名称闸门——英文名几乎都叫 Xxx Lumber，中文为「木料」；去掉宽泛的 Wood/Timber 以防误收
    -- 名字碰巧含它们的非住宅物。取消上版的独立 lumber 类（2026-10-04 改）。
    { key = 'housing', name = 'Housing', check = function(item)
        if item:GetClassID() == C.Housing then
            return true
        end
        -- 住宅木料：主类 Tradegoods + 子类 其它(11) 双重收窄，再用专属名称判定
        if item:GetClassID() == C.Tradegoods and item:GetSubClassID() == 11 then
            local name = item:GetItemName() or ''
            for _, kw in ipairs(LUMBER_KEYWORDS) do
                if name:find(kw) then
                    return true
                end
            end
        end
        return false
    end },
    { key = 'tradegoods', name = 'Trade goods', check = function(item)
        return item:GetClassID() == C.Tradegoods
    end },
    { key = 'profession', name = 'Profession', check = function(item)
        return item:GetClassID() == C.Profession
    end },
    { key = 'recipe', name = 'Recipe', check = function(item)
        return item:GetClassID() == C.Recipe
    end },
    { key = 'container', name = 'Container', check = function(item)
        return item:GetClassID() == C.Container
    end },
    { key = 'key', name = 'Key', check = function(item)
        return item:GetClassID() == C.Key
    end },
    -- 需要开锁的物品（未开锁状态）：hasLoot and not isBound
    -- （Baganator SpecialisedSplitting.lua:98 同款；已开锁后 hasLoot=false → 落到后面分类）
    { key = 'locked', name = 'Locked item', check = function(item)
        return item:HasLoot() and not item:IsBound()
    end },
    { key = 'battlepet', name = 'Battle pet', check = function(item)
        return item:GetClassID() == C.Battlepet
    end },
    -- 玩具：C_ToyBox.GetToyInfo（CheckItem.lua:814-821）
    { key = 'toy', name = 'Toy', check = function(item)
        return GetItemFlag(item, 'toy', function(itemID)
            return C_ToyBox.GetToyInfo(itemID) ~= nil
        end)
    end },
    -- 触发任务物品：该物品「将触发一个任务」（尚未接取的起始物品）。
    -- 判定 = GetContainerItemQuestInfo 返回 questID 且 isActive 为否（Baganator
    -- ItemButton.lua:723-725 同款字段）。放在 questitem 之前，使其比普通任务物品更靠前。
    { key = 'queststarter', name = 'Quest-starting item', check = function(item)
        local questID, isActive = item:GetQuestInfo()
        return questID and questID > 0 and not isActive
    end },
    { key = 'questitem', name = 'Quest item', check = function(item)
        return item:GetClassID() == C.Questitem
    end },
    -- 其他/杂项：杂项类且**不可使用**（可用的归入下一类 usable）
    { key = 'miscellaneous', name = 'Miscellaneous', check = function(item)
        if item:GetClassID() ~= C.Miscellaneous then
            return false
        end
        local usable = IsUsableItem(item)
        if usable == nil then
            return -- 数据未就绪 → 下 tick 重试
        end
        return not usable
    end },
    -- 可打开 / 可使用的其他物品：物品带可用法术（GetItemSpell 有值）。
    -- Baganator 同义判定走 tooltip 扫 ITEM_OPENABLE（CheckItem.lua:752-766），
    -- 此处用更轻的 C_Item.GetItemSpell（ItemDocumentation.lua:948 `[已核]`）。
    { key = 'usable', name = 'Usable', check = function(item)
        return IsUsableItem(item)
    end },
    -- 垃圾：品质 Poor（CheckItem.lua:559-569 同款）。
    -- P3.5：junkSource="dejunk" 时判定接管（DejunkApi:IsJunk(bag,slot)）；External 未就绪回退内置。
    { key = 'junk', name = 'Junk', check = function(item)
        local ext = ns.External
        if ext and ext:IsDejunkActive() then
            return ext:IsJunkSlot(item:GetBag(), item:GetSlot())
        end
        return item:GetItemQuality() == Enum.ItemQuality.Poor
    end },
    -- 其余（其他 / 可打开可使用的其他物品）→ 兜底分类，永远命中
    { key = 'other', name = 'Other', check = function(item)
        return true
    end },
}

-- 分区（section）：仅用于组织展示与顺序，成员指向 Categories 的 key
ns.CategorySections = {
    { key = 'equipment', name = 'Equipment', children = {'equipment_sets', 'weapon', 'armor'} },
    { key = 'crafting',  name = 'Crafting',  children = {'reagent', 'tradegoods', 'profession', 'recipe', 'housing'} },
}

-- 组内排序键链（方案 §4.2.5-G）：分类 → 键1 → 键2 → …，逐级比较，层级无上限。
-- 键名由 rule.lua 的 keyGetters 提供。
ns.CategorySortKeys = {
    -- 默认：资料片（新→旧）→ 装等（高→低）→ 品质（高→低）→ 名称
    default = {'expansionDesc', 'itemLevelDesc', 'qualityDesc', 'name'},
    -- 装备特例（用户定 3/4 点）：部位 → 资料片 → 魂绑优先 → 装等 → 品质 → 名称
    weapon = {'invSlot', 'expansionDesc', 'boundFirst', 'itemLevelDesc', 'qualityDesc', 'name'},
    armor  = {'invSlot', 'expansionDesc', 'boundFirst', 'itemLevelDesc', 'qualityDesc', 'name'},
    -- 装备方案段：按方案创建序 → 部位 → 资料片 → 装等
    equipment_sets = {'equipSet', 'invSlot', 'expansionDesc', 'itemLevelDesc', 'name'},
    -- 战斗宠物（用户定 10 点）：资料片 → 名称 → 等级
    battlepet = {'expansionDesc', 'name', 'itemLevelDesc'},
    -- 材料：按来源专业子类分组 → 资料片 → 名称
    reagent = {'tradegoodSubClass', 'expansionDesc', 'name'},
    tradegoods = {'tradegoodSubClass', 'expansionDesc', 'name'},
    housing = {'tradegoodSubClass', 'expansionDesc', 'name'},
}

-- 「自定义规则」（Orders.CustomOrder）的新默认内容（2026-09-03）：
-- 旧默认值是一维的 `#主类##子类` 条目，与新的分类排序体系**不是同一套东西**，
-- 导致设置面板显示项与实际生效的默认顺序对不上。现改为**分类条目**
-- （`@category:<key>`，key 对应 ns.Categories），顺序即整理顺序，
-- 用户可在面板内上下调整 / 增删（玩法与「装备位置规则」一致）。
-- 旧格式条目（纯 itemID / `#主类##子类` / 物品名）仍被识别为**置顶规则**，保持兼容。
ns.DefaultCategoryOrder = {
    '@category:potion',
    '@category:food',
    '@category:consumable',
    '@category:equipment_sets',
    '@category:weapon',
    '@category:armor',
    '@category:gem',
    '@category:itemenhancement',
    '@category:reagent',
    '@category:tradegoods',
    '@category:profession',
    '@category:recipe',
    '@category:housing',
    '@category:container',
    '@category:key',
    '@category:locked',
    '@category:battlepet',
    '@category:toy',
    '@category:queststarter',
    '@category:questitem',
    '@category:miscellaneous',
    '@category:usable',
    '@category:hearthstone',
    '@category:keystone',
    -- a8：junk 从用户可调顺序中剔除——整理时由 Rule:GetCategoryIndex 固定排末尾
    '@category:other',
}

-- 分类条目前缀：Orders.CustomOrder 中以该前缀开头的项视为「分类顺序条目」
ns.CATEGORY_PREFIX = '@category:'

-- 「自定义规则」列表项的显示文本：分类条目 → 分类名（本地化），其余原样返回。
-- 否则面板上会直接显示 `@category:potion` 这类内部串。
function ns:GetRuleText(value)
    if type(value) ~= 'string' then
        return tostring(value)
    end

    local prefix = ns.CATEGORY_PREFIX
    if value:sub(1, #prefix) == prefix then
        local key = value:sub(#prefix + 1)
        for _, category in ipairs(ns.Categories or {}) do
            if category.key == key then
                return L[category.name] or category.name
            end
        end
    end

    return value
end

ns.DefaultEquipLocOrder = {
    'INVTYPE_2HWEAPON',         --双手
    'INVTYPE_WEAPON',           --单手
    'INVTYPE_WEAPONMAINHAND',   --主手
    'INVTYPE_WEAPONOFFHAND',    --副手
    'INVTYPE_SHIELD',           --副手
    'INVTYPE_HOLDABLE',         --副手物品
    'INVTYPE_RANGED',           --远程
    -- 'INVTYPE_RANGEDRIGHT',      --远程
    -- 'INVTYPE_THROWN',           --投掷

    'INVTYPE_HEAD',             --头部
    'INVTYPE_SHOULDER',         --肩部
    'INVTYPE_CHEST',            --胸部
    'INVTYPE_ROBE',             --胸部
    'INVTYPE_HAND',             --手
    'INVTYPE_LEGS',             --腿部

    'INVTYPE_WRIST',            --手腕
    'INVTYPE_WAIST',            --腰部
    'INVTYPE_FEET',             --脚
    'INVTYPE_CLOAK',            --背部

    'INVTYPE_NECK',             --颈部
    'INVTYPE_FINGER',           --手指
    'INVTYPE_TRINKET',          --饰品

    'INVTYPE_BODY',             --衬衣
    'INVTYPE_TABARD',           --战袍

    --  这些应该不需要了
    --  'INVTYPE_RELIC',                --圣物
    --  'INVTYPE_WEAPONMAINHAND_PET',   --主要攻击
    --  'INVTYPE_AMMO',                 --弹药
    --  'INVTYPE_BAG',                  --背包
    --  'INVTYPE_QUIVER',               --箭袋
}
