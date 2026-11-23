--[[
adeMapMark_Portal - 开发辅助：世界坐标 → 地图 coord dump
命令：/ammcoord —— 按当前数据表结构逐行 print 可直接粘贴的条目
字段顺序：taxiNodeID, ContinentID, Pos_0, Pos_1, Pos_2（Pos_2 高度不参与）
计算：C_Map.GetMapPosFromWorldPos(continentID, CreateVector2D(Pos_1, Pos_0), mapID)
用完可从 TOC 移除并删除本文件
]]

-- 卡雷什导管已有的三语名称键（Locales/*.lua）；3029 没有对应键，输出字面名称
local CONDUIT_KEYS = {
    [3145] = "CONDUIT_TAZAVESH",
    [3146] = "CONDUIT_OASIS",
    [3147] = "CONDUIT_SHAN_DORAH",
    [3155] = "CONDUIT_SHADOW_POINT",
    [3156] = "CONDUIT_SERRATED_PEAKS",
    [3157] = "CONDUIT_ZOSHUUL",
    [3158] = "CONDUIT_LUNNALL",
    [3159] = "CONDUIT_NORTH_SUFAAD",
    [3160] = "CONDUIT_NAAKROA",
    [3161] = "CONDUIT_LAACUNA",
    [3162] = "CONDUIT_UNTETHERED",
    [3163] = "CONDUIT_YAATHRON",
    [3164] = "CONDUIT_HOSAAS",
}

local GROUPS = {
    {
        header = "-- 瓦尔 (mapID: 2599)", style = "plain",
        points = {
            { name = "晦暗大本营", taxiNodeID = 3267, continentID = 3047, p0 = -3848.8200683594, p1 = 445.94400024414, mapID = 2599 },
            { name = "贪噬侵临点", taxiNodeID = 3268, continentID = 3047, p0 = -4169.9799804688, p1 = 727.62200927734, mapID = 2599 },
            { name = "虚空卫城", taxiNodeID = 3269, continentID = 3047, p0 = -4192.1499023438, p1 = 577.01898193359, mapID = 2599 },
            { name = "蒸雾低地", taxiNodeID = 3270, continentID = 3047, p0 = -4177.2099609375, p1 = 410.61801147461, mapID = 2599 },
        },
    },
    {
        header = "-- 奈格塔尔 (mapID: 2600)", style = "plain",
        points = {
            { name = "晦暗大本营", taxiNodeID = 3277, continentID = 3075, p0 = -2180, p1 = -1709, mapID = 2600 },
            { name = "孢子熔炉", taxiNodeID = 3278, continentID = 3075, p0 = -1519.3499755859, p1 = -2468.3500976562, mapID = 2600 },
            { name = "节点港口", taxiNodeID = 3279, continentID = 3075, p0 = -1586, p1 = -1917, mapID = 2600 },
            { name = "萃取海岸", taxiNodeID = 3280, continentID = 3075, p0 = -1571, p1 = -1352, mapID = 2600 },
        },
    },
    {
        header = "-- 塔扎维什，帷纱集市 (mapID: 2472)", style = "conduit",
        points = {
            { name = "塔扎维什，帷纱集市", taxiNodeID = 3145, continentID = 2738, p0 = -1206.6500244141, p1 = -217.3390045166, mapID = 2472 },
        },
    },
    {
        header = "-- 卡雷什 (mapID: 2371)", style = "conduit",
        points = {
            { name = "塔扎维什，卡雷什", taxiNodeID = 3029, continentID = 2738, p0 = -636.35101318359, p1 = 6.26562976837, mapID = 2371 },
            { name = "绿洲", taxiNodeID = 3146, continentID = 2738, p0 = 1391.8199462891, p1 = -1040.1800537109, mapID = 2371 },
            { name = "珊多拉", taxiNodeID = 3147, continentID = 2738, p0 = 1611.4300537109, p1 = 249.98599243164, mapID = 2371 },
            { name = "暗影营", taxiNodeID = 3155, continentID = 2738, p0 = 1891.1999511719, p1 = 1497.5100097656, mapID = 2371 },
            { name = "锯刃峰", taxiNodeID = 3156, continentID = 2738, p0 = 529.13201904297, p1 = 999.41101074219, mapID = 2371 },
            { name = "佐舒尔瞭望台", taxiNodeID = 3157, continentID = 2738, p0 = 1201.5500488281, p1 = 1062.0100097656, mapID = 2371 },
            { name = "伦娜尔河", taxiNodeID = 3158, continentID = 2738, p0 = 562.82098388672, p1 = -170.86500549316, mapID = 2371 },
            { name = "北苏法德", taxiNodeID = 3159, continentID = 2738, p0 = 509.88198852539, p1 = -1143.6999511719, mapID = 2371 },
            { name = "纳克罗阿", taxiNodeID = 3160, continentID = 2738, p0 = 25.08849906921, p1 = 365.99499511719, mapID = 2371 },
            { name = "莱阿库纳之隙", taxiNodeID = 3161, continentID = 2738, p0 = 2027.4699707031, p1 = 596.68402099609, mapID = 2371 },
            { name = "无拘之域", taxiNodeID = 3162, continentID = 2738, p0 = 1733.5600585938, p1 = 771.22100830078, mapID = 2371 },
            { name = "亚斯隆废墟", taxiNodeID = 3163, continentID = 2738, p0 = -482.05599975586, p1 = 985.00897216797, mapID = 2371 },
            { name = "霍赛斯之眠", taxiNodeID = 3164, continentID = 2738, p0 = -289.4049987793, p1 = 787.75500488281, mapID = 2371 },
        },
    },
}

local function ToCoord(pt)
    local _, pos = C_Map.GetMapPosFromWorldPos(pt.continentID, CreateVector2D(pt.p1, pt.p0), pt.mapID)
    if not pos then return nil end
    return math.floor(pos.x * 10000 + 0.5) * 10000 + math.floor(pos.y * 10000 + 0.5)
end

SLASH_AMMCOORD1 = "/ammcoord"
SlashCmdList["AMMCOORD"] = function()
    for _, group in ipairs(GROUPS) do
        print(group.header)
        for _, pt in ipairs(group.points) do
            local coord = ToCoord(pt)
            if not coord then
                print(string.format("-- FAILED: %s (taxi:%d, mapID:%d)", pt.name, pt.taxiNodeID, pt.mapID))
            elseif group.style == "conduit" then
                local key = CONDUIT_KEYS[pt.taxiNodeID]
                local title = key and ("L." .. key) or ('"' .. pt.name .. '"')
                print(string.format('{ mapID = %d, coord = %d, title = %s, note = "taxi:%d" },', pt.mapID, coord, title, pt.taxiNodeID))
            else
                print(string.format('{ mapID = %d, coord = %d, title = "%s" },', pt.mapID, coord, pt.name))
            end
        end
    end
end
