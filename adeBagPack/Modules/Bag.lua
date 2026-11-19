
-- adeBagPack / Modules / Bag.lua（旧 adeBackpack 移植：ADE 守卫行删除，ns 表机制不变）
-- ripairs（倒序遍历）：原版定义于 tdCore/extra.lua（全局），adeBagPack 无 tdCore →
-- 本地定义（Group.lua/Pack.lua 同款 riter；2026-09-09 实机 ripairs=nil 教训）。
local assert, ipairs, pairs = assert, ipairs, pairs
local tinsert, tremove, wipe = table.insert, table.remove, wipe
local function ripairs(t)
    local iter = function(tt, i)
        i = i - 1
        if i > 0 then return i, tt[i] end
    end
    return iter, t, #t + 1
end

local ns = _G.adeBagPack or {}


local Bag = {}
ns.Bag = Bag

local BagMeta = { __index = function(_, k) return Bag[k] or ns.Base[k] end }

-- 容器 id 基线（12.1 Mainline，2026-09-03 核实）：
--   0-4    背包（角色）
--   5      材料袋（Enum.BagIndex.ReagentBag，11.0+ 独立栏位，占用了旧银行 tab 的 5）
--   6-11   角色银行 tabs（Enum.BagIndex.CharacterBankTab_1..6；
--           12.1 角色银行 = 6 页×98 格，旧 BANK_CONTAINER(-1) 本体已并入 tab 模型，
--           mainline 不再独立寻址 —— 参照 BankStack core.lua bank_bags）
--   12-16  战团银行 tabs（Enum.BagIndex.AccountBankTab_1..5）
-- 旧「材料银行 -3」容器模型在 mainline 已弃用（BankStack has_reagent_bank=false 实锤）
--
-- 分区原则（2026-09-03 实测修复）：背包 / 角色银行 / 战团银行 / 材料袋各自成 class，
-- 区内整理、互不换格 —— 战团银行拒收魂绑/任务等物品，跨 bankType 搬运会被游戏拒绝
-- （ERR_INTERNAL_BAG_ERROR 之源，BankStack CanItemGoInBank 按 bankType 前置校验实锤）；
-- 材料袋收材料走暴雪 reagent 特判、不走 family 位（BankStack CanItemGoInBag），
-- 故仅做袋内自整。背包↔角色银行的存/取换格仅经用户规则（save/load）显式触发。
local bagClasses = {
    bag = {0, 1, 2, 3, 4},
    bank = {6, 7, 8, 9, 10, 11},
    accountbank = {12, 13, 14, 15, 16},
    reagent = {Enum.BagIndex.ReagentBag},
}

function Bag:New(bagClass)
    assert(bagClasses[bagClass])
    
    local obj = setmetatable({}, BagMeta)
    
    obj.bags = bagClasses[bagClass]
    obj.bagClass = bagClass
    obj.groups = {}
    
    obj:InitGroups()
    
    return obj
end

function Bag:InitGroups()
    local initedGroups = {}
    for _, bag in ipairs(self.bags) do
        local bagFamily = ns:GetBagFamily(bag)
        if bagFamily and not initedGroups[bagFamily] then
            initedGroups[bagFamily] = true
            
            local group = ns.Group:New(self, bagFamily)
            if bagFamily == 0 then
                self.groups[0] = group
            else
                tinsert(self.groups, group)
            end
        end
    end
end

function Bag:GetBags()
    return self.bags
end

-- class → 容器 id 列表（Transfer 迁移等直接扫描用）
function Bag:GetClassBags(bagClass)
    return bagClasses[bagClass]
end

function Bag:IterateGroups()
    return pairs(self.groups)
end

function Bag:IterateTradeGroups()
    return ipairs(self.groups)
end

function Bag:GetNormalGroup()
    return self.groups[0]
end

function Bag:IsLocked()
    for _, group in self:IterateGroups() do
        if group:IsLocked() then
            return true
        end
    end
end

-- 本 Bag 内所有 group 的物品数据是否就绪（排序前置条件，见 Group:IsItemsReady）
function Bag:IsItemsReady()
    for _, group in self:IterateGroups() do
        if not group:IsItemsReady() then
            return false
        end
    end
    return true
end

-- 重新扫描：按**当前实际布局**重建各组的 slots/items，并重新排序 + 过滤（生成新的
-- items→slots 配对）。用于一轮移动后做收敛校验 —— 移动会改变布局，旧配对即失效。
-- 对齐 Baganator：其 ApplyBagOrdering 每次调用都基于实时 bag 数据重新扫描 + 排序 + 移动。
function Bag:Rescan()
    for _, group in self:IterateGroups() do
        group:Rescan()
    end
    self:Sort()
end

function Bag:Pack()
    local complete = true
    local totalMoves = 0

    -- 为所有组建立实例映射：FindSlot 会跨组查找源槽，各组映射都需就绪
    for _, group in self:IterateGroups() do
        group:BuildGUIDMap()
    end

    for _, group in self:IterateGroups() do
        local success, moves = group:Pack()
        totalMoves = totalMoves + (moves or 0)
        if not success then
            ns:Debug('group pack not complete')
            complete = false
        end
    end
    return complete, totalMoves
end

function Bag:FindSlot(item, tarSlot)
    -- 优先按 GUID 精确定位**物品实例**：同一 itemID 的多个堆 / 不同绑定状态必须
    -- 区分，否则会移动错误的那一堆 → 顺序不收敛（表现为「要多次整理才完成」）。
    -- 对齐 Baganator Sorting/OrderBags.lua:50-57 的 GetItemGUID 索引做法。
    local guid = item.GetGUID and item:GetGUID()
    if guid then
        for _, group in self:IterateGroups() do
            local slot = group:FindSlotByGUID(guid)
            if slot then
                return slot
            end
        end
    end

    -- 回退：按 itemID 匹配（GUID 不可用或未命中时）
    for _, group in self:IterateGroups() do
        local slot = group:FindSlot(item, tarSlot)
        if slot then
            return slot
        end
    end
end

-- 物品是否仍在本 Bag（遍历各 group 的槽，不判 locked）——用于 Pack 阶段区分
-- 「已搬离本区」与「暂时无合法互换路径」，避免静默出队造成永久漏物
function Bag:HasItemID(itemID)
    for _, group in self:IterateGroups() do
        if group:HasItemID(itemID) then
            return true
        end
    end
end

function Bag:Sort()
    -- reagent（纯材料袋）无普通格 group → normal 可为 nil（纯 family 组防御）
    local normal = self:GetNormalGroup()
    for _, group in self:IterateTradeGroups() do
        if normal then
            group:ChooseItems(normal:GetItems())
        end
    end
    for _, group in self:IterateGroups() do
        group:SortItems()
        group:FilterSlots()
    end
end

function Bag:GetSwapItems_removed_2026_09_03()
    -- 旧 save/load 链已随迁移动作（Transfer）删除；此桩防止误调用
    error('Bag:GetSwapItems removed (save/load deprecated, use Transfer)')
end
