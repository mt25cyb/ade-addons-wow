local _, addon = ...
addon.Data = addon.Data or {}

-- 区域地图种子表与大陆表提取自 DelveCompanion：
-- Data/Config.lua:159-162（DELVE_CONTINENTS）、:166-184（DELVE_MAPS）。
-- 这两个数组同时决定列表顺序：外层（地区）倒序遍历，内层（地下堡）正序遍历。
-- 新资料片由运行时自发现补全（Services/DelveScanner.lua），此表只作为扫描起点。

addon.Data.CONTINENTS = {
    midnight = 2537, -- 至暗之夜大陆
    tww = 2274, -- 卡兹阿加大陆
}

addon.Data.DELVE_MAPS = {
    midnight = {
        2393, -- 银月城 Silvermoon City
        2424, -- 奎尔丹纳斯岛 Isle of Quel'Danas
        2395, -- 永歌森林 Eversong Woods
        2437, -- 祖阿曼 Zul'Aman
        2413, -- 哈籁恩达尔 Harandar
        2405, -- 虚影风暴 Voidstorm
        2512, -- 盘卷蛇岛 The Coiled Isle
    },
    tww = {
        2248, -- 多恩岛 Isle of Dorn
        2214, -- 喧鸣深窟 The Ringing Deeps
        2215, -- 陨圣峪 Hallowfall
        2255, -- 艾基-卡赫特 Azj-Kahet
        2346, -- 安德麦 Undermine
        2371, -- 卡雷什 K'aresh
    },
}

-- 显示顺序：Midnight 在上、The War Within 在下。
addon.Data.EXPANSION_ORDER = { "midnight", "tww" }

addon.Data.EXPANSION_NAME_KEY = {
    midnight = "EXPANSION_MIDNIGHT",
    tww = "EXPANSION_TWW",
}

-- 迷宫（Kindo'jan）不属于 DELVES_CONFIG，来源 DFCN_DelveHelper.lua:142-144：
-- 只在地图 2395（永歌森林）注册 POI 9035/9036；之前对所有 zone 扫同一组 POI，
-- 导致同名迷宫在永歌森林 / 祖阿曼各出现一次（2026-10-27 修正）。
-- 仪式场地的相关表已拆到 Data\RitualData.lua（用户 2026-10-30）。
-- 与 Data/DELVES、Data/ABUNDANCE 同款结构：**按资料片分组**（用户 2026-10-30 要求），
-- 资料片由表的 key 决定，不再另设 LABYRINTH_EXPANSION / EXPANSION 之类的字段。
addon.Data.LABYRINTHS = {
    midnight = {
        [2395] = { 9035, 9036 }, -- 永歌森林 Eversong Woods
    },
}
