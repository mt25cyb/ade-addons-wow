
local InCombatLockdown = InCombatLockdown
local GetCursorInfo = GetCursorInfo -- 光标卫生（方案 §4.2.3-1）
local ClearCursor = ClearCursor
local ItemLocation = ItemLocation

-- adeBagPack / Modules / Slot.lua（旧 adeBackpack 移植：ADE 守卫行删除，ns 表机制不变）


local ns = _G.adeBagPack or {}

local Slot = {}
ns.Slot = Slot

local SlotMeta = { __index = function(_, k) return Slot[k] or ns.Base[k] end }

function Slot:New(parent, bag, slot)
    local obj = setmetatable({}, SlotMeta)
    
    obj:SetParent(parent)
    obj.bag = bag
    obj.slot = slot
    
    return obj
end

function Slot:GetBag()
    return self.bag
end

function Slot:GetSlot()
    return self.slot
end

function Slot:GetItemID()
    return ns:GetBagSlotID(self.bag, self.slot)
end

-- 槽内物品的**实例**唯一标识（实时查询：整理过程中槽内容会变，不能缓存）。
-- 用于按 GUID 精确定位物品实例，区分同一 itemID 的多个堆。
function Slot:GetGUID()
    local location = ItemLocation:CreateFromBagAndSlot(self.bag, self.slot)
    if C_Item.DoesItemExist(location) then
        return C_Item.GetItemGUID(location)
    end
end

function Slot:GetFamily()
    return ns:GetBagSlotFamily(self.bag, self.slot)
end

function Slot:IsEmpty()
    return ns:IsBagSlotEmpty(self.bag, self.slot)
end

function Slot:IsFull()
    return ns:IsBagSlotFull(self.bag, self.slot)
end

function Slot:IsLocked()
    return ns:IsBagSlotLocked(self.bag, self.slot)
end

function Slot:MoveTo(slot)
    if self:IsEmpty() then
        if slot:IsEmpty() then
            return true
        else
            return slot:MoveTo(self)
        end
    end
    
    if InCombatLockdown() then
        return false, 'player in combat'
    end
    
    if self:IsLocked() or slot:IsLocked() then
        return false, 'some slot is locked'
    end

    -- 光标卫生（方案 §4.2.3-1）：执行 pickup 前光标必须为空。残留 = 上一笔本槽
    -- pickup 未完成（半途失败/未落地）→ ClearCursor 放回来源槽后返回 false，等待
    -- 下一 tick 自然重试（Baganator 每笔后 ClearCursor 同效；绝不带光标继续 pickup）。
    -- 会话入口 Pack:Start() 已确认光标为空，此残留只可能来自本会话上一笔移动。
    if GetCursorInfo() then
        ClearCursor()
        return false, 'cursor busy, cleared'
    end

    ns:PickupBagSlot(self.bag, self.slot)
    ns:PickupBagSlot(slot.bag, slot.slot)

    -- 落位后光标残留 ≠ 失败（2026-09-03 根因修复）：WoW pickup 语义下目标槽非空时
    -- 走「互换」——源物品已落入目标槽，目标原物品被拿到光标上；合堆场景则是目标堆
    -- 被填满、源槽剩余部分留在光标。两者都是**已完成的正确搬移**，只需把光标内容
    -- 落回此时已空的源槽即可（合堆时即"剩余半堆留在源槽"，正是 Stack 期望的结果）。
    -- 旧实现直接 ClearCursor 并判失败 —— 光标物品被随机塞回某个空槽，items↔slots
    -- 配对快照被打乱（「越整越乱」之源），且合堆永远失败最终触发 retries exceeded。
    if GetCursorInfo() then
        ns:PickupBagSlot(self.bag, self.slot)

        if GetCursorInfo() then
            -- 落回源槽被游戏拒绝（family 不兼容 / 受限容器等）：完整回滚 ——
            -- 目标原物品换回目标槽 → 源物品放回源槽，恢复到调用前状态再判失败
            ns:PickupBagSlot(slot.bag, slot.slot)
            ns:PickupBagSlot(self.bag, self.slot)
            if GetCursorInfo() then
                ClearCursor()
            end
            return false, 'move rejected, rolled back'
        end
    end

    return true
end
