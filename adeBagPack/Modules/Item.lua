
local type, tonumber = type, tonumber
local GetItemFamily = C_Item.GetItemFamily -- 12.1.0 收口（旧全局已移除，方案 §4.2.1）；item.lua 内直引 2 处
local GetItemInfo = C_Item.GetItemInfo
local GetContainerItemInfo = C_Container.GetContainerItemInfo
local GetContainerItemQuestInfo = C_Container.GetContainerItemQuestInfo
local IsItemDataCachedByID = C_Item.IsItemDataCachedByID
local RequestLoadItemDataByID = C_Item.RequestLoadItemDataByID
local ItemLocation = ItemLocation

-- adeBagPack / Modules / Item.lua（旧 adeBackpack 移植：ADE 守卫行删除，ns 表机制不变）


local ns = _G.adeBagPack or {}

local Item = {}
ns.Item = Item

local ItemMeta = { __index = function(_, k) return Item[k] or ns.Base[k] end }

function Item:New(parent, bag, slot)
    local itemID = ns:GetBagSlotID(bag, slot)
    if not itemID then
        return
    end
    
    local obj = setmetatable({}, ItemMeta)
    
    local itemName, itemType, itemSubType, itemEquipLoc, itemQuality, itemLevel, itemTexture = ns:GetItemInfo(itemID)
    
    if not itemName or not itemLevel then
        ns:Debug(itemID, ns:GetItemInfo(itemID))
    end
    
    obj:SetParent(parent)
    obj.bag = bag
    obj.slot = slot
    obj.itemID = itemID

    -- 物品实例唯一标识：同一 itemID 的多个堆 / 不同绑定状态靠它区分。
    -- Baganator 用同一机制保证排序稳定（Sorting/OrderBags.lua:50-57 的 SetIndexes，
    -- 注释即说明"keep an index so that the order is consistent after sort
    -- application and resorting"）。tdPack 此前只按 itemID 找源槽，同 ID 多实例时
    -- 会移动错误的那一个 → 顺序不收敛（表现为「要多次整理才完成」）。
    -- API：C_Item.GetItemGUID / DoesItemExist（ItemDocumentation.lua:479/109 `[已核]`）
    local location = ItemLocation:CreateFromBagAndSlot(bag, slot)
    if C_Item.DoesItemExist(location) then
        obj.itemGUID = C_Item.GetItemGUID(location)
    end
    obj.itemName = itemName
    obj.itemType = itemType
    obj.itemSubType = itemSubType
    obj.itemEquipLoc = itemEquipLoc
    obj.itemQuality = itemQuality
    obj.itemLevel = itemLevel
    obj.itemTexture = itemTexture
    
    -- 分类/排序新维度（方案 §4.2.5-H.3）：
    -- classID / subClassID / expansionID = C_Item.GetItemInfo 第 12 / 13 / 15 列
    -- （官方 ItemDocumentation.lua:627/628/630 `[已核]`）。数据未缓存时先请求加载，
    -- 本帧取不到 → IsInfoReady() 为 false，排序层按下 tick 重试处理（同 Baganator
    -- CheckItem 返回 nil 的做法）。战斗宠物的 itemID 是 'battlepet:...' 字符串，
    -- 无这些列，直接套用 Enum.ItemClass.Battlepet。
    if type(itemID) == 'number' then
        if IsItemDataCachedByID(itemID) then
            local _, _, _, _, _, _, _, _, _, _, _, classID, subClassID, _, expansionID = GetItemInfo(itemID)
            obj.classID = classID
            obj.subClassID = subClassID
            obj.expansionID = expansionID
        else
            RequestLoadItemDataByID(itemID)
        end
    else
        obj.classID = Enum.ItemClass.Battlepet
        obj.subClassID = 0
        obj.expansionID = 0
    end
    
    -- 绑定状态 / 未开锁战利品：C_Container.GetContainerItemInfo 记录字段
    -- （官方 ContainerDocumentation.lua:775 `hasLoot`、:780 `isBound` `[已核]`）。
    -- 「未开锁物品」判定 = hasLoot and not isBound（Baganator
    -- SpecialisedSplitting.lua:98 同款）。
    local info = GetContainerItemInfo(bag, slot)
    if info then
        obj.isBound = info.isBound
        obj.hasLoot = info.hasLoot
        obj.stackCount = info.stackCount
    end

    -- 关联任务信息：C_Container.GetContainerItemQuestInfo 返回 isQuestItem /
    -- questID / isActive（容器层，不依赖物品数据缓存）。
    -- 用于「触发任务物品」分类：questID 存在且 isActive 为否 = 该物品将触发一个任务
    -- （尚未接取的起始物品），与已在进行中的任务物品区分。
    local qInfo = GetContainerItemQuestInfo(bag, slot)
    if qInfo then
        obj.questID = qInfo.questID
        obj.isQuestActive = qInfo.isActive
    end

    return obj
end

-- 物品实例唯一标识的读取器（New 时已从 C_Item.GetItemGUID 取到 obj.itemGUID）。
-- 必须显式提供：Bag:FindSlot / Group:IsSameItem / Rule:GetSortKeys 都以
-- `item.GetGUID and item:GetGUID()` 做 nil 保护调用 —— 方法一旦缺失，这些调用会
-- **静默回退到 itemID 匹配**，同 ID 多实例（多堆 / 绑定状态不同）就会移动错误的
-- 那一堆，表现为「顺序不收敛、要多次整理才完成」。
function Item:GetGUID()
    return self.itemGUID
end

-- 槽内堆叠数量（New 时快照，Rescan 重建时刷新）。
-- 用途：排序 tie-breaker —— 同 itemID 的多堆按「满堆优先」排列。
function Item:GetStackCount()
    return self.stackCount or 1
end

function Item:GetFamily()
    local itemID = self:GetItemID()
    
    ns:Debug(itemID, GetItemFamily(itemID))
    
    return type(itemID) == 'string' and 0 or GetItemFamily(itemID) or 0
end

function Item:GetItemID()
    return self.itemID or 0
end

function Item:GetItemName()
    return self.itemName or ''
end

function Item:GetItemType()
    return self.itemType or ''
end

function Item:GetItemSubType()
    return self.itemSubType or ''
end

function Item:GetItemLevel()
    return self.itemLevel or 0
end

function Item:GetItemQuality()
    return self.itemQuality or 1
end

function Item:GetItemTexture()
    return self.itemTexture or ''
end

function Item:GetItemEquipLoc()
    return self.itemEquipLoc or ''
end

function Item:GetBag()
    return self.bag
end

function Item:GetSlot()
    return self.slot
end

function Item:GetClassID()
    return self.classID
end

function Item:GetSubClassID()
    return self.subClassID
end

function Item:GetExpansionID()
    return self.expansionID or 0
end

function Item:IsBound()
    return self.isBound and true or false
end

function Item:HasLoot()
    return self.hasLoot and true or false
end

-- 关联任务信息（Modules/Config.lua 的 queststarter 分类用）。
-- 返回 questID（关联任务 ID，无则 nil）、isActive（该任务是否已在日志进行中）。
function Item:GetQuestInfo()
    return self.questID, self.isQuestActive
end

-- 是否为装备（武器 / 护甲大类）。
function Item:IsEquipment()
    local c = self:GetClassID()
    return c == Enum.ItemClass.Weapon or c == Enum.ItemClass.Armor
end

-- （计划 §1.3 裁剪：GetSellPrice/GetQuantity/IsArtifactRelic/IsWarbandEquipment/
--   IsRefundable/IsEquipmentSet/IsSuitable+BuildSuitableTable —— 纯垃圾处理方法，
--   adeBagPack 不含垃圾功能；装备方案分类改走 Config:GetEquipmentSetOrder 直接判定。）

-- 数据就绪：分类与排序依赖的新维度（classID 等）必须取到，否则排序键缺项会导致
-- 排序错乱。未就绪时排序层让出本 tick，下 tick 重建 Item 再排（方案 §4.2.5-H.3）。
--
-- 除 classID 外还要求 IsItemDataCachedByID：玩具箱 / 钥石 / 可用法术等分类判定
-- 依赖各自的缓存，基础数据未缓存时它们会返回 nil，物品将被误判进兜底分类
-- → 本次整理顺序不对、下次整理又变（表现为「要多次整理才稳定」）。
function Item:IsInfoReady()
    if self.classID == nil then
        return false
    end
    if type(self.itemID) == 'number' and not C_Item.IsItemDataCachedByID(self.itemID) then
        return false
    end
    return true
end
