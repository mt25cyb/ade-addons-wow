-- adeBagPack / Debug.lua — /adebp debug 诊断工具
-- （旧 adeBackpack Core.lua:189-404 原样移植，ns→ABP；12.1 容器 API 收口 C_Container/C_Item）
local ABP = _G.adeBagPack

function ABP.DebugScan(ids)
    local C_Container = C_Container
    local C_Item = C_Item
    local tremove = table.remove
    local ClassName = function(c) return c and C_Item.GetItemClassInfo(c) or '?' end
    local SubName   = function(c, sc) return (c and sc) and C_Item.GetItemSubClassInfo(c, sc) or '?' end

    -- 最小 item stub：仅提供 Rule 分类/排序管线所需方法。
    -- 银行内物品 C_Item.GetItemInfo 返回 nil，故 classID/subClassID 改取
    -- GetItemInfoInstant（银行物品也能取到），名称优先 GetItemName。
    local function MakeStub(id, bag, slot)
        local _, _, _, _, _, cIns, scIns = C_Item.GetItemInfoInstant(id)
        -- a14：type/subType 必须取到——Rule:GetCustomTypeOrder 会调 GetItemType/
        -- GetItemSubType，旧 stub 缺这两个方法导致 idx=ERR:Rule.lua:51 且排序键兜底为 0。
        -- a15：equipLoc（第 9 列）必须取到——armor/weapon 的 SORTKEY 首维是 invSlot，
        -- 旧 stub 恒 nil → invSlot=99，日志里 16 件护甲部位全同值、boundFirst 看似交错，
        -- 无法据日志逐项核对装备部位排序（真实整理走 Item.lua，不受影响）。
        local name, _, quality, iLevel, _, itemType, itemSubType, stackCount, equipLoc, _, _, classID, subClassID, _, expansionID
            = C_Item.GetItemInfo(id)
        classID = classID or cIns
        subClassID = subClassID or scIns
        name = name or (C_Item.GetItemName and C_Item.GetItemName(id))
        local spell = C_Item.GetItemSpell and C_Item.GetItemSpell(id)
        local loot, bound
        if bag and slot then
            local info = C_Container.GetContainerItemInfo(bag, slot)
            if info then loot, bound = info.hasLoot, info.isBound end
        end
        -- b046 修复：补 GetQuestInfo（queststarter 分类 check 必调；旧 stub 缺此方法
        -- → 扫到任务起始物品即 attempt to call nil，全背包诊断中断）。容器层快照同 Item.lua:92-97。
        local questID, questActive
        if bag and slot then
            local qInfo = C_Container.GetContainerItemQuestInfo and C_Container.GetContainerItemQuestInfo(bag, slot)
            if qInfo then
                questID, questActive = qInfo.questID, qInfo.isActive
            end
        end
        return {
            GetItemID      = function() return id end,
            GetItemType    = function() return itemType or '' end,
            GetItemSubType = function() return itemSubType or '' end,
            GetClassID     = function() return classID end,
            GetSubClassID  = function() return subClassID end,
            GetItemQuality = function() return quality end,
            GetItemLevel   = function() return iLevel end,
            GetExpansionID = function() return expansionID end,
            GetItemName    = function() return name end,
            GetItemSpell   = function() return spell end,
            GetStackCount  = function() return stackCount or 1 end,
            GetItemEquipLoc= function() return equipLoc or '' end,
            HasLoot        = function() return loot end,
            IsBound        = function() return bound end,
            GetQuestInfo   = function() return questID, questActive end,
            -- a15：用真实 GUID 让 tie-break（满堆优先 + GUID）也进入诊断排序键，
            -- 与真实 Item 一致；按 GUID 缓存故不与真实整理互相污染。
            GetGUID        = function()
                if not bag or not slot then return nil end
                local loc = ItemLocation:CreateFromBagAndSlot(bag, slot)
                return C_Item.DoesItemExist(loc) and C_Item.GetItemGUID(loc) or nil
            end,
        }
    end

    local function Report(id, bag, slot, classID, subClassID)
        local isKS = C_Item.IsItemKeystoneByID and C_Item.IsItemKeystoneByID(id)
        local fam  = C_Item.GetItemFamily and C_Item.GetItemFamily(id) or '?'
        local catKey, catIdx, sortErr = '?', '?', nil
        if ABP.Rule and ABP.Rule.GetCategoryKey then
            local stub = MakeStub(id, bag, slot)
            local function trace(e)
                return (type(debug) == 'table' and debug.traceback) and debug.traceback(tostring(e), 3) or tostring(e)
            end
            -- b046：GetCategoryKey 也包 pcall——诊断工具自身不崩，报 ERR:栈
            local okKey, vKey = xpcall(function() return ABP.Rule:GetCategoryKey(stub) end, trace)
            catKey = okKey and tostring(vKey) or ('ERR:' .. tostring(vKey))
            local ok, v = xpcall(function() return ABP.Rule:GetCategoryIndex(stub) end, trace)
            catIdx = ok and tostring(v) or ('ERR:' .. tostring(v))
            -- b046 修：成功时显示排序键前 4 值（诊断用途），失败才报 ERR——
            -- 原写法 `ok and nil or tostring(v)` 在成功时也强制走 or 分支，把键表地址当错误打印。
            ok, v = xpcall(function() return ABP.Rule:GetSortKeys(stub) end, trace)
            if ok and type(v) == 'table' then
                sortErr = table.concat({ tostring(v[1]), tostring(v[2]), tostring(v[3]), tostring(v[4]) }, ',')
            elseif not ok then
                sortErr = 'ERR:' .. tostring(v)
            end
        end
        local realGUID
        if bag and slot then
            local locG = ItemLocation:CreateFromBagAndSlot(bag, slot)
            if C_Item.DoesItemExist(locG) then
                realGUID = C_Item.GetItemGUID(locG)
            end
        end
        local loc = (bag and slot) and (bag .. ':' .. slot) or ('id=' .. id)
        -- P3.5：infoSource="itemera" 时附加资料片/专业文本（显示用；External 未就绪返回 nil）
        local extra = ''
        local ext = ABP.External
        if ext then
            local expText = ext.GetExpansionText and ext:GetExpansionText(id)
            if expText then extra = extra .. ' era=' .. expText end
            local profText = ext.GetProfessionText and ext:GetProfessionText(id)
            if profText then extra = extra .. ' prof=' .. profText end
        end
        print(('[adeBP] %s id=%d class=%d(%s) sub=%d(%s) fam=%s cat=%s idx=%s%s%s%s%s'):format(
            loc, id, classID or -1, ClassName(classID), subClassID or -1, SubName(classID, subClassID),
            tostring(fam), tostring(catKey), tostring(catIdx),
            isKS and ' [KEYSTONE]' or '', sortErr and (' SORTKEY=' .. sortErr) or '',
            realGUID and (' GUID=' .. tostring(realGUID)) or ' GUID=nil', extra))
    end

    -- 指定 itemID 查询：/adebp debug 180653 [180665 ...]
    if ids and #ids > 0 then
        print('[adeBP] debug: 查询指定 itemID = ' .. table.concat(ids, ','))
        for _, s in ipairs(ids) do
            local id = tonumber(s)
            if id then
                Report(id, nil, nil, select(6, C_Item.GetItemInfoInstant(id)), select(7, C_Item.GetItemInfoInstant(id)))
            end
        end
    end

    -- 无参数：全背包逐槽报告 + 模拟整理（旧 Core.lua:264-369）
    if not ids or #ids == 0 then
        print('[adeBP] debug: 全背包扫描')
        for b = 0, 4 do
            local famC = select(2, C_Container.GetContainerNumFreeSlots(b)) or 0
            local n = C_Container.GetContainerNumSlots(b)
            print(('[adeBP] 诊断 bag%d: famC=%s GetBagFamily=%s GetBagNumSlots=%s GetContainerNumSlots=%s'):format(
                b, tostring(famC), tostring(ABP:GetBagFamily(b)), tostring(ABP:GetBagNumSlots(b)), tostring(n)))
            if n and n > 0 then
                for s = 1, n do
                    local id = ABP:GetBagSlotID(b, s)
                    if id and type(id) == 'number' then
                        local _, _, _, _, _, cIns, scIns = C_Item.GetItemInfoInstant(id)
                        Report(id, b, s, cIns, scIns)
                    end
                end
            end
        end
        if ABP.DebugSimulateSort then
            ABP.DebugSimulateSort()
        end
    end
end

-- a12：模拟真实整理——直接走 Bag:New → Bag:Sort（含 Group:BuildItemSlots 双端游标
-- 与 FilterSlots），输出「物理槽 / 待搬移 / 当前槽→目标槽」。旧版手工模拟
-- Rule:SortItems + 同位置删除，在对称模式下会把「目标槽==当前槽」误判为已归位，
-- 永远输出 0/0，无法判断双端布局是否生效（用户实测困惑点）。
function ABP.DebugSimulateSort()
    local ok, err = pcall(function()
        local p = ABP:GetProfile()
        local rev = ABP:IsReversePack()
        local symmetric = p and p.symmetricJunk ~= false

        local function at(obj)
            if not obj then return '?' end
            return obj:GetBag() .. ':' .. obj:GetSlot()
        end

        local bag = ABP.Bag:New('bag')
        bag:Sort()

        local totalPending, totalSlots = 0, 0
        for _, group in bag:IterateGroups() do
            -- a13：FilterSlots 会剔除空槽/已就位槽，#slots 可能归零；显示扫描时的物理总量
            local pending, slotCount = #group.items, (group.physicalSlotCount or #group.slots)
            totalPending = totalPending + pending
            totalSlots = totalSlots + slotCount
            print(('[adeBP] 模拟整理 desc=%s symmetricJunk=%s family=%s：物理槽=%d 待搬移=%d'):format(
                tostring(rev), tostring(symmetric), tostring(group:GetFamily() or 0), slotCount, pending))

            local head, tail = {}, {}
            for i = 1, math.min(6, pending) do
                local item = group.items[i]
                local okc, cat = pcall(ABP.Rule.GetCategoryKey, ABP.Rule, item)
                head[#head + 1] = ('%s:%s→%s'):format(
                    okc and tostring(cat) or '?', at(item), at(group.itemSlots[i]))
            end
            for i = math.max(1, pending - 5), pending do
                local item = group.items[i]
                local okc, cat = pcall(ABP.Rule.GetCategoryKey, ABP.Rule, item)
                local mark = ABP.Rule:IsJunkItem(item) and 'J' or '-'
                tail[#tail + 1] = ('%s%s:%s→%s'):format(
                    mark, okc and tostring(cat) or '?', at(item), at(group.itemSlots[i]))
            end
            print(('[adeBP]   待搬移头6: %s'):format(table.concat(head, ' ')))
            print(('[adeBP]   待搬移尾6(J=垃圾): %s'):format(table.concat(tail, ' ')))
        end
        print(('[adeBP] 模拟整理汇总 desc=%s symmetricJunk=%s：物理槽=%d 待搬移=%d%s'):format(
            tostring(rev), tostring(symmetric), totalSlots, totalPending,
            totalPending == 0 and '（全部已归位）' or ''))
    end)
    if not ok then
        print('[adeBP] 模拟整理失败: ' .. tostring(err))
    end
end

