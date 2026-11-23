--[==[ adeMapTab_Portal / Data/TeleportAnnouncer.lua — 传送通报「补充」数据源
功能来源：TeleportAnnouncer v1.9.0（z-ref_retail_Interface_AddOns/TeleportAnnouncer/），
原作者：电视卫士(SGSwdzgr), KeiraMetz；MIT，声明随实质性副本保留如下。
v6.5-r004 起本文件**不再是播报的完整数据源**：232 条白名单与 232×2 双语目的地名表
已消除——播报信息由 Services/Catalog.lua 从主表（Teleports / Hearthstones /
DestinationOverrides）按 spellID 索引派生。这里只保留两类非重复数据：
① 原表未收录的传送（老道具/旧版本法术，68 条，含本地化目的地名）；
② 播报专属过滤标记（keystone / heartstone，主表没有对应字段）。
新增传送只要写进 Data/Teleports.lua 即自动可播报，无需维护本文件。

原插件 MIT 许可声明（依其 LICENSE 要求随实质性副本保留）：
    MIT License

    Copyright (c) 2025 KeiraMetz

    Permission is hereby granted, free of charge, to any person obtaining a copy
    of this software and associated documentation files (the "Software"), to deal
    in the Software without restriction, including without limitation the rights
    to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
    copies of the Software, and to permit persons to whom the Software is
    furnished to do so, subject to the following conditions:

    The above copyright notice and this permission notice shall be included in all
    copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
    SOFTWARE.
]==]
local _, addon = ...
local TA = addon.TeleportAnnouncer

-- 原表（TeleportData + HearthstoneData）尚未收录的传送：键 = 施法事件 spellID，
-- 值 = { keystone?, heartstone?, item? } + enUS / zhCN 目的地名（非 zhCN 回退 enUS）。
-- 字段语义与旧白名单一致：keystone 供「仅大秘境」过滤、heartstone 供「忽略炉石」过滤、
-- item 是播报时优先展示的物品 ID（无则不展示物品链接）。
addon.TeleportAnnouncerExtras = {
    [26373] = { item = 21711, enUS = "Moonglade", zhCN = "月光林地" },
    [46149] = { item = 35230, enUS = "Shattrath City", zhCN = "沙塔斯城" },
    [63826] = { item = 45705, enUS = "Icecrown", zhCN = "冰冠冰川" },
    [85609] = { item = 61379, enUS = "Eastern Plaguelands", zhCN = "东瘟疫之地" },
    [96333] = { item = 68808, enUS = "Stormwind City", zhCN = "暴风城" },
    [96334] = { item = 68809, enUS = "Orgrimmar", zhCN = "奥格瑞玛" },
    [136252] = { item = 91866, enUS = "The Exodar", zhCN = "埃索达" },
    [136253] = { item = 91863, enUS = "Silvermoon City", zhCN = "银月城" },
    [136254] = { item = 91865, enUS = "Darnassus", zhCN = "达纳苏斯" },
    [136255] = { item = 91864, enUS = "Ironforge", zhCN = "铁炉堡" },
    [136256] = { item = 91862, enUS = "Undercity", zhCN = "幽暗城" },
    [136257] = { item = 91861, enUS = "Thunder Bluff", zhCN = "雷霆崖" },
    [136258] = { item = 91860, enUS = "Stormwind City", zhCN = "暴风城" },
    [136259] = { item = 91850, enUS = "Orgrimmar", zhCN = "奥格瑞玛" },
    [147420] = { item = 136849, enUS = "a natural location", zhCN = "随机一座森林" },
    [151895] = { item = 107441, enUS = "Bloodmaul Slag Mines", zhCN = "血槌炉渣矿井" },
    [176766] = { item = 119183, enUS = "Ashran", zhCN = "阿什兰" },
    [193669] = { enUS = "Azsuna", zhCN = "阿苏纳" },
    [196079] = { item = 169298, enUS = "Frostwolf Keep", zhCN = "霜狼要塞" },
    [196080] = { item = 169297, enUS = "Dun Baldar", zhCN = "丹巴达尔" },
    [197107] = { item = 132120, enUS = "Stormwind City", zhCN = "暴风城" },
    [216138] = { item = 138448, enUS = "Dalaran - Broken Isles", zhCN = "达拉然（破碎群岛）" },
    [220989] = { item = 139599, enUS = "Dalaran - Broken Isles", zhCN = "达拉然（破碎群岛）" },
    [223352] = { item = 140319, enUS = "Dalaran - Broken Isles", zhCN = "达拉然（破碎群岛）" },
    [223805] = { enUS = "an attuned Ley Line point in the Broken Isles", zhCN = "破碎群岛的魔网结点" },
    [225428] = { item = 141013, enUS = "Val'sharah", zhCN = "瓦尔莎拉" },
    [225434] = { item = 141014, enUS = "Suramar", zhCN = "苏拉玛" },
    [225435] = { item = 141015, enUS = "Val'sharah", zhCN = "瓦尔莎拉" },
    [225436] = { item = 141016, enUS = "Azsuna", zhCN = "阿苏纳" },
    [225440] = { item = 141017, enUS = "Highmountain", zhCN = "至高岭" },
    [239570] = { item = 146796, enUS = "Dalaran - Broken Isles", zhCN = "达拉然（破碎群岛）" },
    [240913] = { item = 147354, enUS = "Dalaran - Broken Isles", zhCN = "达拉然（破碎群岛）" },
    [244018] = { item = 147878, enUS = "Stormwind City", zhCN = "暴风城" },
    [253937] = { enUS = "the nearest Flight Master", zhCN = "最近的鸟点" },
    [254667] = { item = 153226, enUS = "Antoran Wastes", zhCN = "安托兰废土" },
    [267381] = { item = 159224, enUS = "Zuldazar", zhCN = "祖达萨" },
    [267619] = { item = 159671, enUS = "Silithus", zhCN = "希利苏斯" },
    [278512] = { item = 162515, enUS = "Kul Tiras or Zandalar", zhCN = "库尔提拉斯或赞达拉" },
    [291981] = { item = 167075, enUS = "Mechagon", zhCN = "麦卡贡" },
    [308841] = { item = 172203, enUS = "Ghostlands", zhCN = "幽魂之地" },
    [311643] = { item = 173373, enUS = "Tirisfal Glades", zhCN = "提瑞斯法林地" },
    [311678] = { item = 173430, enUS = "Borean Tundra", zhCN = "北风苔原" },
    [311681] = { item = 173523, enUS = "Tirisfal Glades", zhCN = "提瑞斯法林地" },
    [311703] = { item = 173526, enUS = "Western Plaguelands", zhCN = "西瘟疫之地" },
    [311704] = { item = 173527, enUS = "Duskwood", zhCN = "暮色森林" },
    [311705] = { item = 173528, enUS = "The Cape of Stranglethorn", zhCN = "荆棘谷海角" },
    [311709] = { item = 173530, enUS = "Duskwood", zhCN = "暮色森林" },
    [311711] = { item = 173531, enUS = "Blasted Lands", zhCN = "诅咒之地" },
    [311712] = { item = 173532, enUS = "Elwynn Forest", zhCN = "艾尔文森林" },
    [311749] = { item = 173537, enUS = "Western Plaguelands", zhCN = "西瘟疫之地" },
    [311798] = { item = 173698, enUS = "Blasted Lands", zhCN = "诅咒之地" },
    [311800] = { item = 173699, enUS = "Blasted Lands", zhCN = "诅咒之地" },
    [311897] = { item = 173716, enUS = "Moonglade", zhCN = "月光林地" },
    [335671] = { item = 181163, enUS = "Maldraxxus", zhCN = "玛卓克萨斯" },
    [346167] = { item = 184500, enUS = "Bastion", zhCN = "晋升堡垒" },
    [346168] = { item = 184504, enUS = "Oribos", zhCN = "奥利波斯" },
    [346170] = { item = 184503, enUS = "Ardenweald", zhCN = "炽蓝仙野" },
    [346171] = { item = 184502, enUS = "Maldraxxus", zhCN = "玛卓克萨斯" },
    [346173] = { item = 184501, enUS = "Revendreth", zhCN = "雷文德斯" },
    [367891] = { item = 189827, enUS = "Random location", zhCN = "随机地点" },
    [368788] = { item = 191029, enUS = "Tirisfal Glades", zhCN = "提瑞斯法林地" },
    [390783] = { item = 200613, enUS = "Ohn'ahran Plains", zhCN = "欧恩哈拉平原" },
    [395792] = { item = 201957, enUS = "Orgrimmar", zhCN = "奥格瑞玛" },
    [406714] = { item = 204802, enUS = "The Forbidden Reach", zhCN = "禁忌离岛" },
    [418549] = { item = 208206, enUS = "The Vindicaar", zhCN = "维迪卡尔" },
    [450410] = { item = 223988, enUS = "Dalaran - Broken Isles", zhCN = "达拉然（破碎群岛）" },
    [460271] = { item = 227669, enUS = "Silithus", zhCN = "希利苏斯" },
    [1254557] = { keystone = true, enUS = "Skyreach", zhCN = "通天峰" },
}

-- 播报过滤标记。原白名单里 77 条 keystone + 2 条 heartstone 是「仅大秘境 / 忽略炉石」
-- 两个开关的判据；主表的 section/字段无法可靠推导（散布在 40~130 各分组），故只把这些
-- 布尔标记搬来，不再复制法术名/目的地名。extras 里带 keystone 的条目已自带标记。
-- 注意：这里不限制「哪些法术会被播报」——那个集合完全由主表 + extras 决定。
addon.TeleportAnnounceFlags = {
    keystone = {
        [131204] = true, [131205] = true, [131206] = true, [131222] = true,
        [131225] = true, [131228] = true, [131229] = true, [131231] = true,
        [131232] = true, [159895] = true, [159896] = true, [159897] = true,
        [159898] = true, [159899] = true, [159900] = true, [159901] = true,
        [159902] = true, [354462] = true, [354463] = true, [354464] = true,
        [354465] = true, [354466] = true, [354467] = true, [354468] = true,
        [354469] = true, [367416] = true, [373262] = true, [373274] = true,
        [393222] = true, [393256] = true, [393262] = true, [393267] = true,
        [393273] = true, [393276] = true, [393279] = true, [393283] = true,
        [393764] = true, [393766] = true, [410071] = true, [410074] = true,
        [410078] = true, [410080] = true, [424142] = true, [424153] = true,
        [424163] = true, [424167] = true, [424187] = true, [424197] = true,
        [445269] = true, [445414] = true, [445416] = true, [445417] = true,
        [445418] = true, [445424] = true, [445440] = true, [445441] = true,
        [445443] = true, [445444] = true, [464256] = true, [467553] = true,
        [467555] = true, [1216786] = true, [1237215] = true, [1254400] = true,
        [1254551] = true, [1254555] = true, [1254559] = true, [1254563] = true,
        [1254572] = true, [1286801] = true, [1286804] = true, [1286807] = true,
        [1286809] = true, [1286812] = true, [1286828] = true, [1286831] = true,
    },
    heartstone = {
        [171253] = true, -- 要塞炉石（item 110560）
        [222695] = true, -- 达拉然炉石（item 140192）
    },
}

TA.teleportItems = {}
local teleportItemsGeneration = 0
function TA:buildTeleportItems()
    teleportItemsGeneration = teleportItemsGeneration + 1
    local generation = teleportItemsGeneration
    table.wipe(TA.teleportItems)
    for inventorySlotID = INVSLOT_FIRST_EQUIPPED, INVSLOT_LAST_EQUIPPED do
        local itemID = GetInventoryItemID("player", inventorySlotID)
        if itemID then
            local item = Item:CreateFromItemID(itemID)
            item:ContinueOnItemLoad(function()
                if generation ~= teleportItemsGeneration or GetInventoryItemID("player", inventorySlotID) ~= itemID then return end
                local _, spellID = C_Item.GetItemSpell(itemID)
                if spellID and addon.Catalog.AnnounceInfo(spellID) then
                    TA.teleportItems[spellID] = GetInventoryItemLink("player", inventorySlotID)
                end
            end)
        end
    end
end
