
local band = bit.band
local ipairs = ipairs
-- ripairs（倒序遍历）：原版定义于 tdCore/extra.lua（全局），迁移未搬 → 各使用文件本地定义
--（2026-09-09 实机：pack.lua:203 attempt to call a nil value，ripairs=nil）
local function riter(t, i)
    i = i - 1
    if i > 0 then
        return i, t[i]
    end
end
local function ripairs(t)
    return riter, t, #t + 1
end
local tinsert, tremove, wipe = table.insert, table.remove, wipe

-- adeBagPack / Modules / Group.lua（旧 adeBackpack 移植：ADE 守卫行删除，ns 表机制不变）

local ns = _G.adeBagPack or {}

local Slot = ns.Slot
local Item = ns.Item
local Rule = ns.Rule
local Group = {}
ns.Group = Group

local GroupMeta = { __index = function(_, k) return Group[k] or ns.Base[k] end }

-- 判断槽内的物品是否为指定的**物品实例**：GUID 优先，不可用时回退 itemID。
-- 只比 itemID 会把「同 ID 但不同实例」（多堆、绑定状态不同）误判为已就位 →
-- 直接出队 → 物品实际没归位，表现为整理后仍有残留、需要多次整理。
local function IsSameItem(slot, item)
    -- a12：目标槽可能尚未分配（双端游标 break 后 itemSlots 有洞），防御 nil
    if not slot or not item then return false end
    local itemGUID = item.GetGUID and item:GetGUID()
    local slotGUID = slot.GetGUID and slot:GetGUID()
    if itemGUID and slotGUID then
        return itemGUID == slotGUID
    end
    return slot:GetItemID() == item:GetItemID()
end

function Group:New(parent, family)
    local obj = setmetatable({}, GroupMeta)
    
    obj.family = family
    obj.slots = {}
    obj.items = {}
    -- a12：物品 i 的目标槽（自 Item.lua 排序后建立）。对称整理时目标槽
    -- 不再是 slots[i]（首/尾双游标分配），必须显式记录；非对称模式退化为 slots[i]。
    obj.itemSlots = {}
    obj:SetParent(parent)
    
    obj:InitSlots()
    obj:InitItems()
    
    return obj
end

function Group:GetFamily()
    return self.family
end

---- slots

function Group:InitSlots()
    local bags = self:GetParent():GetBags()
    
    if ns:IsReversePack() then
        for _, bag in ripairs(bags) do
            if ns:GetBagFamily(bag) == self.family then
                for slot = ns:GetBagNumSlots(bag), 1, -1 do
                    tinsert(self.slots, Slot:New(self, bag, slot))
                end
            end
        end
    else
        for _, bag in ipairs(bags) do
            if ns:GetBagFamily(bag) == self.family then
                for slot = 1, ns:GetBagNumSlots(bag) do
                    tinsert(self.slots, Slot:New(self, bag, slot))
                end
            end
        end
    end
    -- a13：FilterSlots 会剔除空槽/已就位槽，诊断需以扫描时的原始槽数显示物理总量
    self.physicalSlotCount = #self.slots
end

function Group:GetSlotCount()
    return #self.slots
end

function Group:GetSlot(index)
    return self.slots[index]
end

-- 本 group 任一槽内是否仍有该 itemID（不判 locked）——供 Bag:HasItemID 聚合，
-- 用于 Pack 阶段区分「物品已离区」与「暂时无合法互换路径」
function Group:HasItemID(itemID)
    for i = 1, self:GetSlotCount() do
        if self:GetSlot(i):GetItemID() == itemID then
            return true
        end
    end
end

---- items

function Group:InitItems()
    for _, slot in ipairs(self.slots) do
        local item = Item:New(self, slot:GetBag(), slot:GetSlot())
        if item then
            tinsert(self.items, item)
        end
    end
end

-- 重新扫描：按**当前实际布局**重建 slots 与 items。
-- 用途：整理过程中移动会改变布局，旧的 items→slots 配对即失效。旧实现只在开始时
-- 扫描一次、后续一直用过期配对，导致后处理的 group 通过「互换」把先处理 group 的
-- 物品换到别处、而先处理者已结束不再归位 → 顺序残留（战团银行需多次整理）。
-- 对齐 Baganator：其 ApplyBagOrdering 每次调用都基于实时 bag 数据重新扫描 + 排序 + 移动。
function Group:Rescan()
    wipe(self.slots)
    wipe(self.items)
    wipe(self.itemSlots)
    self.guidMap = nil
    self:InitSlots()
    self:InitItems()
end

function Group:SortItems()
    Rule:SortItems(self.items)
    self:BuildItemSlots()
end

-- a12：建立「物品 → 目标槽」映射，替代隐式 items[i]↔slots[i]。
-- 对齐 Baganator Sorting/OrderBags.lua:246-328 的双列表 + 首/尾游标：
--   · 非对称整理（symmetricJunk=false）：沿用旧语义，item[i] → slots[i]（槽表方向
--     由 InitSlots 按 desc 生成，故逆序时整体镜像）。
--   · 对称整理（默认开）：非垃圾按排序序从 slots 首游标递增填充，垃圾按排序序从
--     slots 尾游标递减填充；front/back 相遇后未消费的槽保持空 —— 即用户定义的
--     「非垃圾从格1正向、垃圾从格100逆向、中间留空」。
-- 判定口径与 Config.junk.check 同构（Dejunk 优先，否则 Poor）。垃圾内部保持排序序
-- 但目标槽从尾往回分配，故物理上呈反序（与 Baganator SweepBackwards 一致）。
-- desc 不交换两端：槽表已由 InitSlots 反向生成，首/尾槽的物理位置随之镜像，
-- 等价于 Baganator isReverse 交换 groupA/groupB（OrderBags.lua:264-268）。
function Group:BuildItemSlots()
    wipe(self.itemSlots)
    local p = ns:GetProfile()
    local symmetric = p and p.symmetricJunk ~= false

    if not symmetric then
        for i = 1, #self.items do
            self.itemSlots[i] = self.slots[i]
        end
        return
    end

    local normal, junk = {}, {}
    for _, item in ipairs(self.items) do
        if Rule:IsJunkItem(item) then
            junk[#junk + 1] = item
        else
            normal[#normal + 1] = item
        end
    end

    local front, back, n = 1, #self.slots, 0
    for _, item in ipairs(normal) do
        if front > back then break end
        n = n + 1
        self.items[n] = item
        self.itemSlots[n] = self.slots[front]
        front = front + 1
    end
    for _, item in ipairs(junk) do
        if front > back then break end
        n = n + 1
        self.items[n] = item
        self.itemSlots[n] = self.slots[back]
        back = back - 1
    end
    -- 首尾相遇后可能有物品未被分配（空槽数 < 0 不可能，防御性截断）
    for i = #self.items, n + 1, -1 do
        self.items[i] = nil
    end
end

-- 取物品 i 的目标槽（对称模式为双端游标分配，非对称模式 == slots[i]）
function Group:GetTargetSlot(index)
    return self.itemSlots[index] or self.slots[index]
end

function Group:GetItemCount()
    return #self.items
end

function Group:GetItem(index)
    return self.items[index]
end

function Group:GetItems()
    return self.items
end

---- pack

-- 组内物品数据是否全部就绪（classID 等新维度已取到）。
-- 排序前置条件：数据未就绪时排序键缺项会导致顺序错乱，
-- 由 Pack 状态机让出本 tick、下 tick 重建 Item 后再排（方案 §4.2.5-H.3）。
function Group:IsItemsReady()
    for _, item in ipairs(self.items) do
        if not item:IsInfoReady() then
            return false
        end
    end
    return true
end

-- 组内是否有槽处于锁定态（pickup 未落地等瞬时态）。
-- Bag:IsLocked → Group:IsLocked 的底层实现：此前 Group **没有**这个方法，
-- Bag:IsLocked 一调用就报 "attempt to call a nil value"。旧流程里 STATUS_STACKED
-- 不停留、几乎不触发，故未暴露；新增「数据未就绪等待」后状态会停留 → 每 tick 触发。
function Group:IsLocked()
    for _, slot in ipairs(self.slots) do
        if slot:IsLocked() then
            return true
        end
    end
    return false
end

-- 单 tick 每 group 最多搬移次数（2026-09-03 调参：3 → 15）：
-- 15 笔 ≈ 30 次 pickup，单帧可承受（Baganator 单帧批量同数量级）；
-- 600 格银行约 1-2s 完成（3/tick 实测被用户判为「效率不足」，BankStack 同批可达单帧全搬）
local MAX_MOVES_PER_TICK = 15
-- 单 tick 内允许的「暂时无合法互换路径」跳过次数：单对卡死不应拖垮整组，
-- 换下一对继续；超限才让出本 tick（跨 tick 零搬移由 Pack 状态机 stall 兜底）
local MAX_SKIPS_PER_TICK = 8

-- 单次前向扫描整理（对齐 Baganator Sorting/OrderBags.lua 的确定性扫描）：
-- 第 i 个待搬移物品 self.items[i] 的目标槽为 GetTargetSlot(i)（a12 显式映射：对称模式
-- 由首/尾双游标分配，非对称模式 == slots[i]；FilterSlots 已剔除已就位项）。已就位
-- （IsSameItem）跳过；否则经 guidMap 精确定位源槽并搬入。确定性扫描 → 单调收敛，
-- 通常一轮即完成，避免每 tick 随机找槽导致的「多次整理才完成」与随之而来的每轮
-- 全量 bag:Rescan 卡顿。仍受 MAX_MOVES_PER_TICK / 锁定 / 战斗限制；全部目标槽核对
-- 无误才返回 true。
function Group:Pack()
    local moves = 0
    local skipped = 0

    -- 每个 Pack tick 重建本组的实例映射（物品在整理中会被移动，槽内容随之变化）
    self:BuildGUIDMap()

    local count = self:GetItemCount()
    for i = 1, count do
        if moves >= MAX_MOVES_PER_TICK then
            return false, moves -- 达到本 tick 上限，留给下 tick 继续
        end
        if InCombatLockdown() then
            return false, moves
        end

        local tarSlot = self:GetTargetSlot(i)
        if not tarSlot then
            skipped = skipped + 1
            if skipped >= MAX_SKIPS_PER_TICK then
                return false, moves
            end
        elseif tarSlot:IsLocked() then
            -- 目标槽锁定（pickup 未落地等瞬时态）：跳过，不视为完成
            skipped = skipped + 1
            if skipped >= MAX_SKIPS_PER_TICK then
                return false, moves
            end
        else
            local item = self.items[i]
            if not item or IsSameItem(tarSlot, item) then
                -- 已就位（FilterSlots 漏网）跳过
            else
                -- 经 GUID 精确定位物品实例当前所在源槽（同 ID 多堆必须区分，否则顺序不收敛）。
                -- 绝不跨 class：guidMap 仅含本组槽，天然限制在本组（同 family）内，杜绝受限容器搬运。
                -- 定位源槽：优先 GUID（精确区隔同 ID 多实例）；GUID 缺失（特殊物品如钥石，
                -- C_Item.GetItemGUID/DoesItemExist 对其返回空）回退 itemID 扫描本组槽位，
                -- 否则 keystone 等会因 guidMap 无对应键而永不移动（见 _probe.log：keystone
                -- cat=keystone idx=1023 分类正确却停滞原处；同文件 IsSameItem 已有此 itemID 降级）。
                local source
                local guid = item.GetGUID and item:GetGUID()
                if guid then
                    source = self.guidMap[guid]
                else
                    for _, s in ipairs(self.slots) do
                        if s:GetItemID() == item:GetItemID() and not s:IsLocked() then
                            source = s
                            break
                        end
                    end
                end
                if source and source ~= tarSlot and not source:IsLocked() then
                    local success = source:MoveTo(tarSlot)
                    if success then
                        -- 两槽内容已互换 → 重建受影响组的实例映射，保证后续定位精确
                        self:RefreshGUIDFor(source)
                        self:RefreshGUIDFor(tarSlot)
                        moves = moves + 1
                    else
                        -- 移动失败：留在队列里让出本 tick；跨 tick 连续零搬移由 Pack 状态机 stall 兜底
                        return false, moves
                    end
                else
                    -- 找不到可搬源槽（外部变动 / 已搬离本区）：跳过，下一轮 Rescan 修正，绝不静默丢弃
                    skipped = skipped + 1
                    if skipped >= MAX_SKIPS_PER_TICK then
                        return false, moves
                    end
                end
            end
        end
    end

    -- 全部目标槽已核对：统计仍未就位项。有则续推（return false）；全就位则完成（return true）。
    -- 注意：扫描中不改 items/slots 索引，归位判定交给下一 tick 的 FilterSlots / Rescan，
    -- 避免扫描中途改索引导致后续错位（对齐 Baganator「保持索引一致」原则）。
    local pending = 0
    for i = 1, self:GetItemCount() do
        local item = self.items[i]
        if item and not IsSameItem(self:GetTargetSlot(i), item) then
            pending = pending + 1
        end
    end
    return pending == 0, moves
end

function Group:FindSlot(item, tarSlot)
    if not self:CanPutSlot(tarSlot) then
        return
    end
    for _, slot in ripairs(self.slots) do
        if slot:GetItemID() == item:GetItemID() and not slot:IsLocked() then
            return slot
        end
    end
end

-- GUID（物品实例）→ 槽位 映射。用于**精确**定位物品实例：
-- 同一 itemID 可能有多个堆（消耗品/材料）且绑定状态不同 → 只按 itemID 找槽会
-- 移动错误的那一个，导致顺序不收敛（「要多次整理才完成」）。
-- 机制对齐 Baganator Sorting/OrderBags.lua:50-57（SetIndexes 用 GetItemGUID）。
-- 槽内容在整理中会变，故每 tick 重建、每次成功移动后增量重建（RefreshGUIDFor）。
function Group:BuildGUIDMap()
    local guidToSlot = {}
    for _, slot in ipairs(self.slots) do
        local guid = slot.GetGUID and slot:GetGUID()
        if guid then
            guidToSlot[guid] = slot
        end
    end
    self.guidMap = guidToSlot
end

-- 重建指定槽所属 group 的映射（该槽内容已变化）
function Group:RefreshGUIDFor(slot)
    local group = slot and slot.GetParent and slot:GetParent()
    if group and group.BuildGUIDMap then
        group:BuildGUIDMap()
    end
end

function Group:FindSlotByGUID(guid)
    return self.guidMap and self.guidMap[guid]
end

function Group:FilterSlots()
    local p = ns:GetProfile()
    if p and p.symmetricJunk ~= false then
        -- a12：对称整理必须保留**全部物理槽** —— 非垃圾段与垃圾段之间的空格正是
        -- 双端游标未消费区间的产物；旧逻辑把空槽从 slots 尾部剔除、使 items[i] 与
        -- slots[i] 紧密对齐，物理上不可能留空。此处只剔除「已在目标槽」的配对，
        -- itemSlots 存的是槽对象引用（非索引），剔除数组元素不影响其余目标映射。
        for i = #self.items, 1, -1 do
            local item = self.items[i]
            if item and IsSameItem(self.itemSlots[i], item) then
                tremove(self.items, i)
                tremove(self.itemSlots, i)
            end
        end
        return
    end

    -- 非对称模式：沿用旧逻辑（删末尾空槽 + 剔除已就位配对），但同步维护 itemSlots
    for i = self:GetSlotCount(), self:GetItemCount() + 1, -1 do
        if self:GetSlot(i):IsEmpty() then
            tremove(self.slots, i)
        end
    end

    for i, item in ripairs(self.items) do
        -- 同样用 GUID 判定「已就位」，避免同 ID 多实例被误剔除
        if IsSameItem(self:GetTargetSlot(i), item) then
            tremove(self.slots, i)
            tremove(self.items, i)
            tremove(self.itemSlots, i)
        end
    end
end

function Group:IsFull()
    return self:GetItemCount() == self:GetSlotCount()
end

function Group:CanPutItem(item)
    local family = self:GetFamily()
    if family == 0 then
        return true
    end
    return band(family, item:GetFamily()) > 0
end

function Group:CanPutSlot(slot)
    if slot:IsEmpty() then
        return true
    end
    return self:CanPutItem(slot)
end

function Group:ChooseItems(items)
    for i, item in ripairs(items) do
        if self:IsFull() then
            return
        end
        
        if self:CanPutItem(item) then
            tremove(items, i)
            tinsert(self.items, item)
        end
    end
end
