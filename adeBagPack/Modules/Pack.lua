
-- adeBagPack / Modules / Pack.lua（旧 adeBackpack 移植：ADE 守卫行删除，L 走 ABP.L、frame 用原生 CreateFrame）

local ns = _G.adeBagPack or {}

local ipairs, wipe = ipairs, wipe
-- ripairs（倒序遍历）：原版定义于 tdCore/extra.lua（全局），迁移未搬 → 各使用文件本地定义
--（2026-09-09 实机：pack.lua:203 attempt to call a nil value，452x）
local function riter(t, i)
    i = i - 1
    if i > 0 then
        return i, t[i]
    end
end
local function ripairs(t)
    return riter, t, #t + 1
end
local tinsert, tremove = table.insert, table.remove

-- 迁移原语（12.1.0 已核：C_Container.SplitContainerItem / GetContainerItemInfo 记录式、
-- C_Bank.IsItemAllowedInBankType、ItemLocation:CreateFromBagAndSlot 均 Mainline 存在）
local C_Container = C_Container
local GetContainerItemInfo = C_Container.GetContainerItemInfo
local GetItemInfo = C_Item.GetItemInfo
--[===[ 战团银行存入（bag2abank / bank2abank）功能暂禁用（2026-10-04，CHANGELOG 01.15）
-- 原因：12.x 无「精确单件存入战团银行」的 API。唯一公开入口 C_Bank.AutoDepositItemsIntoBank 是
-- 批量黑盒（一次把背包/银行里允许入战团物品全部存入，无法指定单件、无法精确合堆），与「目标容器
-- 已含同 id 才并入」的迁移语义不符，且银行→战团覆盖不可靠。故暂禁用此方向，相关代码保留待重做。
local C_Bank = C_Bank
local AutoDeposit = (C_Bank and C_Bank.AutoDepositItemsIntoBank) or nil
--]===]
-- 禁用后不再引用 AutoDeposit；保留变量定义仅为代码完整性（永不赋值使用）。
local AutoDeposit = nil
local SplitContainerItem = C_Container.SplitContainerItem
local ItemLocation = ItemLocation

local Bag = ns.Bag
local Slot = ns.Slot
local Rule = ns.Rule
local Pack = {}
ns.Pack = Pack

local frame = CreateFrame("Frame")
frame:Hide()
local L = ns.L

local STATUS_FREE       = 0
local STATUS_READY      = 1
local STATUS_STACKING   = 2
local STATUS_STACKED    = 3
local STATUS_PACKING    = 4
local STATUS_PACKED     = 5
local STATUS_FINISH     = 6
local STATUS_CANCEL     = 7
local STATUS_TRANSFER   = 8
local STATUS_TRANSFERED = 9

-- 合堆单槽连续失败上限（≈6 tick × 0.05s = 300ms，设计值，方案 §4.2.3-3，实机调参）
local MAX_STACK_MOVE_FAILS = 6
-- 合堆单 tick 最多并堆对数（2026-09-03 调参 5 → 12，用户判旧值效率不足）
local MAX_STACK_MOVES_PER_TICK = 12
-- 整理（Packing）连续零搬移 tick 上限：超阈值中止并提示，替代 group 层静默跳对/清空
-- （跳对 = 物品永久留原处的「整理遗漏」，2026-09-03 实测反馈修复）
local MAX_PACK_STALL_TICKS = 120
-- 等待槽位解锁的宽松上限（30s）。物品越多，移动越密集，服务器确认造成的
-- **锁定等待**越长（战团银行 490 格尤其明显）；这种「零搬移」是正常等待，
-- 不能按真停滞处理，否则大容器会被误判中止、需点多次才整理完。
local MAX_PACK_WAIT_TICKS = 600
-- 收敛轮数上限：一轮「全部 group 完成」后按当前布局重新扫描 + 排序，若仍有未归位的
-- 配对则再走一轮（对齐 Baganator 每次调用都基于实时数据重新扫描）。设上限防死循环。
local MAX_REPACK_ROUNDS = 5
-- 迁移（Transfer）单 tick 最多搬移笔数
local MAX_TRANSFER_MOVES_PER_TICK = 15

Pack.isBankOpened = nil
Pack.status = STATUS_FREE
Pack.slots = {}
Pack.bags = {}

function Pack:SetTarget(target)
    self.target = target
end

function Pack:GetTarget()
    return self.target or 'bag'
end

-- 迁移动作（2026-09-03 重构：替代旧 save/load，见 main.lua Actions）。
-- 语义：源容器里「目标容器已含同 itemID」的堆 全部并入/存入目标容器。
-- 安全：战团方向按目标 bankType 前置校验（IsItemAllowedInBankType）；区内普通
-- 整理的「互换式 MoveTo」绝不用在跨容器搬移上 —— Transfer 只落「空格/同 id
-- 未满堆」两种目标格（BankStack DoMove 同款规划约束）。
local transferDefs = {
    bag2bank   = { source = 'bag',        target = 'bank' },
    --[==[ 存入战团银行方向暂禁用（2026-10-04，CHANGELOG 01.15）：无精确单件 API
    bag2abank  = { source = 'bag',        target = 'accountbank' },
    bank2abank = { source = 'bank',       target = 'accountbank' },  -- 银行 → 战团银行
    --]==]
    bank2bag   = { source = 'bank',       target = 'bag' },
    abank2bag  = { source = 'accountbank', target = 'bag' },
    abank2bank = { source = 'accountbank', target = 'bank' },        -- 战团银行 → 银行
}

function Pack:SetTransfer(direction)
    assert(not direction or transferDefs[direction], 'unknown transfer direction')
    self.transfer = direction
end

function Pack:GetTransfer()
    return self.transfer
end

function Pack:IsLocked()
    for _, bag in ipairs(self.bags) do
        if bag:IsLocked() then
            return true
        end
    end
end

function Pack:FindSlot(item, tarSlot)
    -- 分区原则：只在物品所属 Bag 内找槽（跨 class 容器搬运是 ERR/乱象之源；
    -- ns:FindSlot 转发入口保留兼容）
    local itemBag = item:GetParent() and item:GetParent():GetParent()
    if itemBag then
        return itemBag:FindSlot(item, tarSlot)
    end
end

function Pack:Start(target)
    if target and target ~= "" then
        self:SetTarget(target)
    end
    if self.status ~= STATUS_FREE then
        ns:ShowMessage(L['Packing now'], 1, 0, 0)
        return
    end
    
    if UnitIsDead('player') then
        ns:ShowMessage(L['Player is dead'], 1, 0, 0)
        return
    end
    
    if InCombatLockdown() then
        ns:ShowMessage(L['Player in combat'], 1, 0, 0)
        return
    end
    
    if GetCursorInfo() then
        ns:ShowMessage(L['Please drop the item, money or skills.'], 1, 0, 0)
        return
    end
    
    -- 银行 / 战团银行整理需银行窗口已打开；迁移四向均涉及银行
    local target = self:GetTarget()
    if (target == 'bank' or target == 'accountbank' or self:GetTransfer()) and not self.isBankOpened then
        ns:ShowMessage(L['Open the bank first.'], 1, 0, 0)
        return
    end
    
    self:SetStatus(STATUS_READY)
    Pack:StartUpdate()
end

function Pack:Stop()
    Pack:StopUpdate()
    
    wipe(self.bags)
    wipe(self.slots)
    self.target = nil
    self.transfer = nil
    self.pendingDeposit = nil
    self.packStall = nil
    self.bagReadyTotal = nil
    self.bagReadyTicks = nil
    self.bagWaitTicks = nil
    self.itemsWaitTicks = nil
    self.repackRounds = nil
    if self.transferCandidates then
        wipe(self.transferCandidates)
    end
    if self.transferFree then
        wipe(self.transferFree)
    end
    if self.transferStacks then
        wipe(self.transferStacks)
    end
    self:SetStatus(STATUS_FREE)
end

function Pack:ShowMessage(text, r, g, b)
    ns:ShowMessage('|cff45afd3adePack: |r' .. text, r, g, b)
end

------ stack

-- 合堆（半堆并堆）范围与整理目标一致（分区原则）：
--   bag：随身合堆（0-4 背包 + 5 材料袋，半堆合并合法）
--   bank：银行整理时可并入背包与角色银行（不跨战团——战团收纳有硬限制，
--         BankStack CanItemGoInBank 实锤；跨 bankType 并堆会被游戏拒收）
--   accountbank：战团银行只区内并堆（不拉入背包物品，防受限搬运）
--   reagent：材料袋区内
local stackBags = {
    bag = {0, 1, 2, 3, 4, 5},
    bank = {0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11},
    accountbank = {12, 13, 14, 15, 16},
    reagent = {Enum.BagIndex.ReagentBag},
}

local function GetStackBags(target)
    return stackBags[target] or stackBags.bag
end

function Pack:StackReady()
    for _, bag in ipairs(GetStackBags(self:GetTarget())) do
        for slot = 1, ns:GetBagNumSlots(bag) do
            if not ns:IsBagSlotEmpty(bag, slot) and not ns:IsBagSlotFull(bag, slot) then
                tinsert(self.slots, Slot:New(nil, bag, slot))
            end
        end
    end
end

function Pack:Stack()
    local stackingSlots = {}
    local complete = true
    local movesDone = 0
    
    for i, slot in ripairs(self.slots) do
        if slot:IsLocked() then
            complete = false
        else
            if not slot:IsEmpty() and not slot:IsFull() then
                local itemID = slot:GetItemID()
                if stackingSlots[itemID] then
                    local ok = slot:MoveTo(stackingSlots[itemID])

                    stackingSlots[itemID] = nil
                    if ok then
                        slot.moveFails = nil
                        complete = false
                        movesDone = movesDone + 1
                        if movesDone >= MAX_STACK_MOVES_PER_TICK then
                            break -- 本 tick 并堆已满额，其余槽保留下 tick 继续
                        end
                    else
                        -- 移动未完成（锁定/光标残留回滚）：槽保留在 self.slots，下 tick
                        -- 自然重试；连续失败达上限则中止，防无限空转（原缺陷修正，
                        -- 方案 §4.2.3-2/3）
                        slot.moveFails = (slot.moveFails or 0) + 1
                        if slot.moveFails >= MAX_STACK_MOVE_FAILS then
                            self:SetStatus(STATUS_CANCEL)
                            ns:ShowMessage(L['Stack retries exceeded, pack canceled.'], 1, 0, 0)
                            return false
                        end
                        complete = false
                    end
                else
                    stackingSlots[itemID] = slot
                end
            else
                tremove(self.slots, i)
            end
        end
    end
    return complete
end

function Pack:StackFinish()
    wipe(self.slots)
end

function Pack:PackReady()
    wipe(self.bags)
    
    -- 整理目标（ns:Pack 参数 / 菜单设置；Stop 统一清理）：
    --   bag         随身（背包 0-4 + 材料袋自整；银行开着且带 save/load 时接入角色银行换格）
    --   bank        角色银行 6-11（需银行打开，区内重排）
    --   accountbank 战团银行 12-16（需银行打开，区内重排）
    --   reagent     材料袋 5（袋内自整）
    local target = self:GetTarget()
    
    -- 分区原则：各 class 区内重排、互不换格。战团银行拒收魂绑/任务等物品，跨
    -- bankType 搬运是 ERR_INTERNAL_BAG_ERROR 之源（BankStack CanItemGoInBank 前置
    -- 校验实锤）；材料袋收材料走暴雪 reagent 特判、不走 family 位（CanItemGoInBag），
    -- 故只做袋内自整。背包↔角色银行换格仅经 save/load 规则显式触发。
    if target == 'reagent' then
        local reagent = Bag:New('reagent')
        tinsert(self.bags, reagent)
        return reagent:Sort()
    end
    
    if target == 'bank' then
        local bank = Bag:New('bank')
        tinsert(self.bags, bank)
        return bank:Sort()
    end
    
    if target == 'accountbank' then
        local accountbank = Bag:New('accountbank')
        tinsert(self.bags, accountbank)
        return accountbank:Sort()
    end
    
    -- 默认目标 bag：背包整理 + 材料袋自整（2026-09-03：银行不再于默认整理时自动
    -- 接入 —— 存取改由独立迁移动作显式触发，旧 save/load 链已删除）
    local bag = Bag:New('bag')
    tinsert(self.bags, bag)
    bag:Sort()

    local reagent = Bag:New('reagent')
    tinsert(self.bags, reagent)
    reagent:Sort()
end

function Pack:Pack()
    local complete = true
    local totalMoves = 0
    for _, bag in ipairs(self.bags) do
        local done, moves = bag:Pack()
        totalMoves = totalMoves + (moves or 0)
        if not done then
            complete = false
        end
    end
    return complete, totalMoves
end

function Pack:PackFinish()
    wipe(self.bags)
end

------ transfer

-- 迁移执行器（2026-09-03 新增，替代旧 save/load 两个功能）：
--   语义（用户定义）：把「目标容器里已含同 itemID」的源堆 并入/存入目标容器。
--   四向：bag2bank / bag2abank / bank2bag / abank2bag。
--   约束（对齐 BankStack DoMove）：目标只落「同 id 未满堆 / 空格」两种格。
--   光标 pickup 语义下这是唯一不会打乱目标区、且不被游戏拒收的搬法
--   （互换式 MoveTo 只用于区内排序，绝不用于跨容器迁移）。
--   入战团方向按 IsItemAllowedInBankType(Account) 前置校验（防御：能出现在
--   战团里的物品必然已通过该校验，候选天然过滤；校验仅防边缘漂移）。
--   容量不足（无空格且无半堆可并）时物品合法留在源容器 —— 不是遗漏。

local bankTypeForTarget = {
    accountbank = Enum.BankType.Account,
}

local function TransferAllowedToBank(pack, slot)
    local bankType = bankTypeForTarget[pack.transferTgtClass]
    if not bankType then
        return true
    end
    local itemID = slot:GetItemID()
    local cache = pack.transferAllowedCache
    if not cache then
        cache = {}
        pack.transferAllowedCache = cache
    end
    if cache[itemID] == nil then
        local loc = ItemLocation:CreateFromBagAndSlot(slot:GetBag(), slot:GetSlot())
        cache[itemID] = C_Bank.IsItemAllowedInBankType and C_Bank.IsItemAllowedInBankType(bankType, loc) or true
    end
    return cache[itemID]
end

--[===[ 战团存入相关 helper：找背包同 id/空格（已禁用，待功能重做时恢复）。
-- 原用于 bank2abank：把银行候选先移回背包再 AutoDeposit。功能禁用期间不再调用。
function Pack:FindBagDestForItem(itemID)
    local bagList = Bag:GetClassBags('bag')
    for _, bag in ipairs(bagList) do
        local n = ns:GetBagNumSlots(bag)
        for s = 1, n do
            local slot = Slot:FromBagSlot(bag, s)
            if not slot:IsEmpty() and slot:GetItemID() == itemID
                and slot:GetCount() < slot:GetStackMax() and not slot:IsLocked() then
                return slot
            end
        end
    end
    for _, bag in ipairs(bagList) do
        local n = ns:GetBagNumSlots(bag)
        for s = 1, n do
            local slot = Slot:FromBagSlot(bag, s)
            if slot:IsEmpty() and not slot:IsLocked() then
                return slot
            end
        end
    end
    return nil
end
--]===]

-- src 槽物品并入/放入 dst（dst 已保证：空格 或 同 id 未满堆，此处仍复核）。
-- 返回 ok, remain（remain>0 = 拆分并入后源槽仍有剩余半堆，需要再处理）
local function TransferMerge(pack, src, dst)
    --[==[ 战团目标（bag2abank/bank2abank）已禁用；保留防御性早退，正常不触发。
    if pack.transferTgtClass == 'accountbank' then
        return false
    end
    --]==]
    if dst:IsLocked() or src:IsLocked() then
        return false
    end
    local srcID = src:GetItemID()
    if not srcID then
        return false
    end
    -- 目标复核（漂移防护）：非空格必须是同 id
    local dstID = dst:GetItemID()
    if dstID and dstID ~= srcID then
        return false
    end

    local srcInfo = GetContainerItemInfo(src:GetBag(), src:GetSlot())
    local dstInfo = GetContainerItemInfo(dst:GetBag(), dst:GetSlot())
    local sCount = srcInfo and srcInfo.stackCount or 0
    local dCount = dstInfo and dstInfo.stackCount or 0
    if sCount <= 0 then
        return false
    end
    -- select(8, C_Item.GetItemInfo) = maxStack（main.lua 同款，[已核]）
    local _, _, _, _, _, _, _, maxStack = GetItemInfo(srcID)
    if not maxStack then
        return false, nil, 'no item info'
    end
    local space = maxStack - dCount
    if space <= 0 then
        return false, nil, 'dst full'
    end

    if sCount <= space then
        -- 整堆并入/放入
        ns:PickupBagSlot(src:GetBag(), src:GetSlot())
        ns:PickupBagSlot(dst:GetBag(), dst:GetSlot())
        if GetCursorInfo() then
            -- 未落位（目标突变/被拒）：放回源槽重试
            ns:PickupBagSlot(src:GetBag(), src:GetSlot())
            return false, nil, 'rollback'
        end
        return true, 0
    else
        -- 拆分：拆出 space 个补满 dst（C_Container.SplitContainerItem [已核 Mainline]）
        SplitContainerItem(src:GetBag(), src:GetSlot(), space)
        if not GetCursorInfo() then
            return false, nil, 'split failed'
        end
        ns:PickupBagSlot(dst:GetBag(), dst:GetSlot())
        if GetCursorInfo() then
            -- 回滚：把拆出部分放回源槽（源槽剩余同 id → pickup 互换自动合并）
            ns:PickupBagSlot(src:GetBag(), src:GetSlot())
            return false, nil, 'split rollback'
        end
        return true, sCount - space
    end
end

function Pack:TransferSetup()
    local def = transferDefs[self:GetTransfer()]
    if not def then
        self:SetStatus(STATUS_CANCEL)
        return
    end

    self.transferCandidates = {}
    self.transferFree = {}
    self.transferStacks = {} -- itemID → 未满堆槽数组
    self.transferIds = {}
    self.transferAllowedCache = nil
    self.transferSrcClass = def.source
    self.transferTgtClass = def.target

    -- 目标区扫描：id 集合 + 未满堆槽 + 空格槽
    for _, bag in ipairs(Bag:GetClassBags(def.target)) do
        for slotIndex = 1, ns:GetBagNumSlots(bag) do
            local itemID = ns:GetBagSlotID(bag, slotIndex)
            if itemID then
                self.transferIds[itemID] = true
                if not ns:IsBagSlotFull(bag, slotIndex) and not ns:IsBagSlotLocked(bag, slotIndex) then
                    local stacks = self.transferStacks[itemID]
                    if not stacks then
                        stacks = {}
                        self.transferStacks[itemID] = stacks
                    end
                    tinsert(stacks, Slot:New(nil, bag, slotIndex))
                end
            else
                tinsert(self.transferFree, Slot:New(nil, bag, slotIndex))
            end
        end
    end

    -- 源区候选：目标已含同 id 的非空格
    for _, bag in ipairs(Bag:GetClassBags(def.source)) do
        for slotIndex = 1, ns:GetBagNumSlots(bag) do
            local itemID = ns:GetBagSlotID(bag, slotIndex)
            if itemID and self.transferIds[itemID] and not ns:IsBagSlotLocked(bag, slotIndex) then
                tinsert(self.transferCandidates, { slot = Slot:New(nil, bag, slotIndex) })
            end
        end
    end
end

function Pack:Transfer()
    local candidates = self.transferCandidates
    local free = self.transferFree
    local stacks = self.transferStacks
    local moved = 0

    --[==[ 战团银行存入（bag2abank/bank2abank）已禁用，pendingDeposit 收尾逻辑不再使用。
    -- 保留作死代码注释，待功能重做时恢复。
    if self.pendingDeposit then
        local p = self.pendingDeposit
        if (p.tries or 0) >= 8 then
            self.pendingDeposit = nil
            return true, moved  -- 视为完成
        else
            p.tries = (p.tries or 0) + 1
            return false, moved
        end
    end
    --]==]

    while #candidates > 0 do
        if moved >= MAX_TRANSFER_MOVES_PER_TICK then
            return false, moved
        end
        if InCombatLockdown() then
            return false, moved
        end
        if GetCursorInfo() then
            return false, moved -- 上笔光标残留：等下一 tick 由 TransferMerge 兜底清理
        end

        local cand = candidates[#candidates]
        tremove(candidates)
        local slot = cand.slot

        if slot:IsLocked() then
            tinsert(candidates, 1, cand) -- 等帧重试
            return false, moved
        end
        if slot:IsEmpty() then
            -- 源已空（外部/本会话已搬走）：丢弃
        else
            -- 入战团方向校验（防御；正常不触发 —— 战团已含同 id 即代表可入）
            if not TransferAllowedToBank(self, slot) then
                -- 不允许入战团的源堆：留在源容器
                --（下一句不可达的防御分支；保留防漂移）
            else
                -- 目标为战团银行：该功能（bag2abank / bank2abank）因 12.x 无精确单件 API 暂禁用（CHANGELOG 01.15）。
                if self.transferTgtClass == 'accountbank' then
                    --[==[ 原实现（暂禁用，待重做）：先把银行候选移回背包，再 C_Bank.AutoDepositItemsIntoBank 批量存入。
                    if self.transferSrcClass == 'bank' then
                        local hasBank = false
                        for _, c in ipairs(candidates) do
                            local b = c.slot:GetBag()
                            if b >= 6 and b <= 11 then hasBank = true; break end
                        end
                        if hasBank then
                            local b = slot:GetBag()
                            if b >= 6 and b <= 11 then
                                local dest = self:FindBagDestForItem(slot:GetItemID())
                                if dest and not slot:IsLocked() and not dest:IsLocked() then
                                    ns:PickupBagSlot(slot:GetBag(), slot:GetSlot())
                                    ns:PickupBagSlot(dest:GetBag(), dest:GetSlot())
                                end
                                tinsert(candidates, 1, cand)
                            end
                            return false, moved
                        end
                    end
                    if AutoDeposit then
                        pcall(AutoDeposit, Enum.BankType.Account)
                    end
                    self.pendingDeposit = { tries = 0 }
                    return false, moved
                    --]==]
                    ns:ShowMessage('[adePack] 存入战团银行功能暂禁用（无精确单件 API）', 1, 0, 0)
                    return true, moved
                end

                local itemID = slot:GetItemID()

                -- 1) 同 id 未满堆
                local dest
                local tlist = stacks[itemID]
                while tlist and #tlist > 0 do
                    local d = tlist[1]
                    if d:IsLocked() or d:IsEmpty() or d:IsFull() then
                        tremove(tlist, 1)
                    else
                        dest = d
                        break
                    end
                end

                -- 2) 空格
                if not dest then
                    while #free > 0 do
                        local f = free[#free]
                        tremove(free)
                        if not f:IsLocked() and f:IsEmpty() then
                            dest = f
                            break
                        end
                    end
                end

                if not dest then
                    -- 无半堆位也无空格：该候选受容量限制留在源（非遗漏），继续其它候选
                else
                    local ok, remain = TransferMerge(self, slot, dest)
                    if not ok then
                        tinsert(candidates, 1, cand) -- 下 tick 重试（TransferMerge 内部已回滚）
                        return false, moved
                    end
                    moved = moved + 1
                    -- 更新目标状态：dest 槽变满/被占 → 从对应表移除
                    if dest then
                        if dest:IsFull() then
                            local tlist2 = stacks[itemID]
                            if tlist2 then
                                for i = #tlist2, 1, -1 do
                                    if tlist2[i] == dest then
                                        tremove(tlist2, i)
                                        break
                                    end
                                end
                            end
                        end
                    end
                    if remain and remain > 0 then
                        -- 拆分后源槽仍有剩余半堆：重新入队继续搬
                        tinsert(candidates, 1, cand)
                    end
                end
            end
        end
    end
    return true, moved
end

------ status

function Pack:SetStatus(status)
    self.status = status
end

function Pack:StatusReady()
    if self:IsLocked() then
        return
    end
    
    if self:GetTransfer() then
        -- 迁移模式：不做区内排序合堆，直接进入目标规划 + 逐 tick 搬移
        self:TransferSetup()
        self:SetStatus(STATUS_TRANSFER)
        return
    end
    
    self:StackReady()
    self:SetStatus(STATUS_STACKING)
end

function Pack:StatusStacking()
    if not self:Stack() then
        return
    end
    
    self:SetStatus(STATUS_STACKED)
    self:StackFinish()
end

-- 银行数据就绪等待（2026-09-03 实测修复）：角色/战团银行各 tab 数据由服务器下发，
-- 未展开或未就绪时 GetContainerNumSlots = 0 → Group:InitSlots 扫不到槽、Item:New
-- 拿不到 itemID → 该页物品根本不进 items，整理「完成」却整页留在原处（用户所见
-- 「战团银行要整理多次才干净」）。此处等目标区槽位总数出现且连续稳定后再扫描。
-- 随身背包恒有槽位，无需等待（不增加普通背包整理耗时）。
local MAX_BAGREADY_TICKS = 40    -- 最长等待（40 × 0.05s = 2s）
local BAGREADY_STABLE_TICKS = 6  -- 连续 6 tick 槽位总数不变视为数据稳定
-- 物品数据（classID/expansionID 等）异步就绪的最长等待；超时则按现有数据整理，
-- 避免个别物品数据长期不到导致整理卡死（方案 §4.2.5-H.3）
-- 物品数据（classID/expansionID、玩具箱/钥石/可用法术）就绪的最长等待。
-- 对齐 Baganator：`ItemsPreparation.lua:31-42` 用计数等待，所有未缓存物品全部
-- 加载完才继续，**不设超时**；`Core/Utilities.lua:65-79` 还每 0.4s 重新请求以防
-- 请求丢失。超时过早会用残缺分类排序 → 本次顺序不对、下次数据到了又变
-- （即「要多次整理才完成」）。故此处给到 30s 兜底——正常加载远快于此，
-- 该值只在数据异常时才可能触发，避免永久卡住。
-- 等待期间每 tick 重建 Item，Item:New 会对未缓存项重新 RequestLoadItemDataByID
-- （等效于 Baganator 的轮询重试）。
local MAX_ITEMSREADY_TICKS = 600
-- 等待超过该 tick 数（1s）时提示一次，避免用户以为整理卡住
local ITEMS_WAIT_NOTICE_TICKS = 20

-- 本轮整理涉及的所有 Bag，其物品数据是否全部就绪（排序前置条件）
function Pack:IsItemsReady()
    for _, bag in ipairs(self.bags) do
        if not bag:IsItemsReady() then
            return false
        end
    end
    return true
end

-- 进入 PACKING 的公共收口：重置实例级缓存 → 扫描 → 数据未就绪则下 tick 重建。
-- 排序键依赖 GetItemInfo 的异步数据，缺项会导致顺序错乱，绝不带残缺数据排序。
function Pack:BeginPacking()
    ns.Config:ResetEquipmentSetCache()
    -- a8：每次整理从 profile 重建分类顺序（不只是清缓存）——设置页调整/添加顺序后
    -- 即使 UI 回调链未触发 OnProfileUpdate，整理也会按当前数组执行（回归修复）。
    Rule:OnProfileUpdate()

    self:PackReady()

    if not self:IsItemsReady() then
        wipe(self.bags)
        self.itemsWaitTicks = (self.itemsWaitTicks or 0) + 1

        if self.itemsWaitTicks == ITEMS_WAIT_NOTICE_TICKS then
            ns:ShowMessage(L['Loading item data, please wait.'])
        end

        if self.itemsWaitTicks < MAX_ITEMSREADY_TICKS then
            return
        end
        -- 超时兜底：按现有数据整理
        self:PackReady()
    end

    self.itemsWaitTicks = nil
    self:SetStatus(STATUS_PACKING)
end

function Pack:GetClassSlotTotal(bagClass)
    local total = 0
    for _, bag in ipairs(Bag:GetClassBags(bagClass) or {}) do
        total = total + (ns:GetBagNumSlots(bag) or 0)
    end
    return total
end

-- 仅银行类目标（含迁移）需要等待：其槽位依赖服务器数据下发
function Pack:NeedWaitBagReady()
    if self:GetTransfer() then
        return true
    end
    local target = self:GetTarget()
    return target == 'bank' or target == 'accountbank'
end

function Pack:IsBagReady()
    if self:GetTransfer() then
        local def = transferDefs[self:GetTransfer()]
        if not def then
            return true
        end
        return self:GetClassSlotTotal(def.source) > 0 and self:GetClassSlotTotal(def.target) > 0
    end
    return self:GetClassSlotTotal(self:GetTarget()) > 0
end

function Pack:StatusStacked()
    if self:IsLocked() then
        return
    end
    
    if self:NeedWaitBagReady() then
        if self:IsBagReady() then
            local total = self:GetClassSlotTotal(self:GetTarget())
            if self.bagReadyTotal == total then
                self.bagReadyTicks = (self.bagReadyTicks or 0) + 1
            else
                self.bagReadyTotal = total
                self.bagReadyTicks = 0
            end
            
            if self.bagReadyTicks >= BAGREADY_STABLE_TICKS then
                self:BeginPacking()
                return
            end
        else
            self.bagReadyTotal = nil
            self.bagReadyTicks = nil
        end
        
        self.bagWaitTicks = (self.bagWaitTicks or 0) + 1
        if self.bagWaitTicks >= MAX_BAGREADY_TICKS then
            self:SetStatus(STATUS_CANCEL)
            ns:ShowMessage(L['Bank data not ready, pack canceled.'], 1, 0, 0)
        end
        return
    end
    
    self:BeginPacking()
end

function Pack:StatusPacking()
    local complete, moves = self:Pack()
    if not complete then
        -- stall 检测：连续 tick 零搬移（目标槽长期锁定 / 无法落位）→ 中止并提示，
        -- 绝不静默跳对漏物（2026-09-03 修复：跳对即「物品留在原处」）
        if not moves or moves == 0 then
            -- 区分「等待槽位解锁」与「真停滞」（2026-09-04 修复）：
            -- 有槽处于锁定 = 正在等服务器确认，属正常等待 → 用宽松阈值；
            -- 无任何锁定却始终无法落位 = 真卡死 → 用短阈值及时中止。
            local waitingUnlock = self:IsLocked()
            local limit = waitingUnlock and MAX_PACK_WAIT_TICKS or MAX_PACK_STALL_TICKS

            self.packStall = (self.packStall or 0) + 1
            if self.packStall >= limit then
                self:SetStatus(STATUS_CANCEL)
                ns:ShowMessage(
                    waitingUnlock and L['Packing wait timeout, canceled.'] or L['Packing stalled, canceled.'],
                    1, 0, 0)
            end
        else
            self.packStall = nil
        end
        return
    end

    -- 「全部 group 完成」后的**收敛校验**（2026-09-04 重构，对齐 Baganator）：
    -- 移动是互换语义，后处理的 group 会把先处理 group 的物品换到别处，而先处理者已
    -- 结束、不再归位 → 顺序残留。故此处按**当前实际布局**重新扫描 + 排序，若仍有未
    -- 归位的配对，则保持 PACKING 再走一轮，直到收敛或达上限。
    if (self.repackRounds or 0) < MAX_REPACK_ROUNDS then
        local pending = self:RescanAndCountPending()
        if pending > 0 then
            self.repackRounds = (self.repackRounds or 0) + 1
            self.packStall = nil
            return
        end
    end

    self.packStall = nil
    self.repackRounds = nil
    self:SetStatus(STATUS_PACKED)
    self:PackFinish()
end

-- 重新扫描全部 Bag（按当前实际布局重建 slots/items 并重新排序），返回**仍未归位**的
-- 配对总数（Group:FilterSlots 会剔除已就位，故剩余的即待移动项）
function Pack:RescanAndCountPending()
    local pending = 0

    for _, bag in ipairs(self.bags) do
        bag:Rescan()
        for _, group in bag:IterateGroups() do
            pending = pending + group:GetItemCount()
        end
    end

    return pending
end

function Pack:StatusPacked()
    self:SetStatus(STATUS_FINISH)
end

function Pack:StatusTransfer()
    local complete, moved = self:Transfer()
    if not complete then
        if not moved or moved == 0 then
            self.packStall = (self.packStall or 0) + 1
            if self.packStall >= MAX_PACK_STALL_TICKS then
                self:SetStatus(STATUS_CANCEL)
                ns:ShowMessage(L['Transfer stalled, canceled.'], 1, 0, 0)
            end
        else
            self.packStall = nil
        end
        return
    end
    
    self.packStall = nil
    self:SetStatus(STATUS_TRANSFERED)
end

function Pack:StatusTransfered()
    self:SetStatus(STATUS_FINISH)
end

function Pack:StatusFinish()
    local transfer = self:GetTransfer()
    self:Stop()
    if transfer then
        ns:ShowMessage(L['Transfer finish.'], 0, 1, 0)
    else
        ns:ShowMessage(L['Pack finish.'], 0, 1, 0)
    end
end

function Pack:StatusCancel()
    self:Stop()
end

Pack.statusProc = {
    [STATUS_READY]       = Pack.StatusReady,
    [STATUS_STACKING]    = Pack.StatusStacking,
    [STATUS_STACKED]     = Pack.StatusStacked,
    [STATUS_PACKING]     = Pack.StatusPacking,
    [STATUS_PACKED]      = Pack.StatusPacked,
    [STATUS_FINISH]      = Pack.StatusFinish,
    [STATUS_CANCEL]      = Pack.StatusCancel,
    [STATUS_TRANSFER]    = Pack.StatusTransfer,
    [STATUS_TRANSFERED]  = Pack.StatusTransfered,
}

function Pack:Update(elapsed)
    local proc = self.statusProc[self.status]
    if proc then
        proc(self)
    end
end

function Pack:OnEvent(event, ...)
    if self[event] then
        self[event](self, event, ...)
    end
end

------ event

-- 银行开合检测（方案 §4.2.2，PIM 主路径）：
-- 12.1 角色银行开合由 PLAYER_INTERACTION_MANAGER_FRAME_SHOW/HIDE（payload id =
-- Enum.PlayerInteractionType.Banker）驱动（BankStack core.lua:84-110 实锤）。
-- BANKFRAME_OPENED/CLOSED 12.1 是否仍触发 [待实测] → 保留为 pcall 候选注册（静默降级）。
-- 战团银行（AccountBanker）与公会银行（GuildBanker）接入属阶段二（L1，决策 D4/D8）。

local BANKER_ID = Enum.PlayerInteractionType.Banker

function Pack:PLAYER_INTERACTION_MANAGER_FRAME_SHOW(event, id)
    if id == BANKER_ID then
        self.isBankOpened = true
    end
end

function Pack:PLAYER_INTERACTION_MANAGER_FRAME_HIDE(event, id)
    if id == BANKER_ID then
        if self.isBankOpened and self.status ~= STATUS_FREE then
            self:SetStatus(STATUS_CANCEL)
            ns:ShowMessage(L['Leave bank, pack cancel.'], 1, 0, 0)
        end
        self.isBankOpened = nil
    end
end

function Pack:BANKFRAME_OPENED()
    self.isBankOpened = true
end

function Pack:BANKFRAME_CLOSED()
    if self.isBankOpened and self.status ~= STATUS_FREE then
        self:SetStatus(STATUS_CANCEL)
        ns:ShowMessage(L['Leave bank, pack cancel.'], 1, 0, 0)
    end
    self.isBankOpened = nil
end

function Pack:PLAYER_REGEN_DISABLED()
    if self.status ~= STATUS_FREE then
        self:SetStatus(STATUS_CANCEL)
        ns:ShowMessage(L['Player enter combat, pack cancel.'], 1, 0, 0)
    end
end

function Pack:Init()
    -- 12.x 纪律：SetScript 必须先于 RegisterEvent
    frame:SetScript("OnUpdate", function(_, elapsed) Pack:Update(elapsed) end)
    frame:SetScript("OnEvent", function(_, event, ...) Pack:OnEvent(event, ...) end)
    frame:RegisterEvent('PLAYER_INTERACTION_MANAGER_FRAME_SHOW')
    frame:RegisterEvent('PLAYER_INTERACTION_MANAGER_FRAME_HIDE')
    -- BANKFRAME_* 兼容候选：12.1 是否仍触发 [待实测]；注册报错则静默降级
    pcall(frame.RegisterEvent, frame, 'BANKFRAME_OPENED')
    pcall(frame.RegisterEvent, frame, 'BANKFRAME_CLOSED')
    frame:RegisterEvent('PLAYER_REGEN_DISABLED')
end


function Pack:StartUpdate()
    frame:Show()
end

function Pack:StopUpdate()
    frame:Hide()
end
