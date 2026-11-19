local _, addon = ...
addon.Data = addon.Data or {}

-- 地下堡静态表：整体提取自 DelveCompanion Data/Config.lua:206-684（DELVES_CONFIG）。
-- 只包含 API 拿不到的字段：uiMapID、areaPoiID、成就 ID、宿敌的赛季/首领/兜底坐标。
-- 名称、所在地区、丰裕状态、实时坐标一律走 API（见 Services/DelveScanner.lua）。
--
-- kind:
--   "normal"  普通地下堡（每周可能轮转为丰裕）
--   "nemesis" 宿敌地下堡（无丰裕）
--
-- 宿敌字段：
--   season     赛季序号
--   bossKey    首领名的本地化键（Locales）
--   wpMapID    兜底路点所在地图
--   wpX / wpY  兜底坐标（0-100）

addon.Data.DELVES = {
    midnight = {
        -- 银月城 Silvermoon City
        { uiMapID = 2577, poiRegular = 8425, poiBountiful = 8426, achChest = 61894, achStory = 61726, kind = "normal" }, -- 学府骚动 Collegiate Calamity
        { uiMapID = 2525, poiRegular = 8439, poiBountiful = 8440, achChest = 61895, achStory = 61728, kind = "normal" }, -- 黑暗回廊 The Darkway
        -- 奎尔丹纳斯岛 Isle of Quel'Danas
        { uiMapID = 2545, poiRegular = 8427, poiBountiful = 8428, achChest = 61893, achStory = 61725, kind = "normal" }, -- 幻日广场 Parhelion Plaza
        -- 永歌森林 Eversong Woods
        { uiMapID = 2502, poiRegular = 8437, poiBountiful = 8438, achChest = 61892, achStory = 61727, kind = "normal" }, -- 聚影领地 The Shadow Enclave
        -- 祖阿曼 Zul'Aman
        { uiMapID = 2503, poiRegular = 8441, poiBountiful = 8442, achChest = 61896, achStory = 61730, kind = "normal" }, -- 暮光地穴 Twilight Crypts
        { uiMapID = 2535, poiRegular = 8443, poiBountiful = 8444, achChest = 61863, achStory = 61729, kind = "normal" }, -- 阿塔阿曼 Atal'Aman
        -- 哈籁恩达尔 Harandar
        { uiMapID = 2510, poiRegular = 8433, poiBountiful = 8434, achChest = 61897, achStory = 61724, kind = "normal" }, -- 憎怨斗坑 The Grudge Pit
        { uiMapID = 2505, poiRegular = 8435, poiBountiful = 8436, achChest = 61898, achStory = 61731, kind = "normal" }, -- 回忆深沟 Gulf of Memory
        -- 虚影风暴 Voidstorm
        { uiMapID = 2528, poiRegular = 8429, poiBountiful = 8430, achChest = 61899, achStory = 61732, kind = "normal" }, -- 戮日圣殿 Sunkiller Sanctum
        { uiMapID = 2506, poiRegular = 8431, poiBountiful = 8432, achChest = 61900, achStory = 61733, kind = "normal" }, -- 影卫营   Shadowguard Point
        {
            uiMapID = 2507, poiRegular = 8445, poiBountiful = nil, achChest = nil, achStory = nil,
            achNemesis = 61799, kind = "nemesis", season = 1, bossKey = "NEMESIS_BOSS_NULLAEUS",
            wpMapID = 2405, wpX = 61.2, wpY = 71.8,
        }, -- 磨难高地 Torment's Rise | 首领: 努雷乌斯 Nullaeus
        -- 盘卷蛇岛 The Coiled Isle
        { uiMapID = 2635, poiRegular = 8761, poiBountiful = 8760, achChest = 63170, achStory = 63437, kind = "normal" }, -- 纳拉多尔岛 Gnarldor Isle
        { uiMapID = 2633, poiRegular = 8764, poiBountiful = 8763, achChest = 63171, achStory = 63436, kind = "normal" }, -- 荣耀之环   The Ring of Glory
        {
            uiMapID = 2634, poiRegular = 8779, poiBountiful = nil, achChest = nil, achStory = nil,
            achNemesis = 63333, kind = "nemesis", season = 2, bossKey = "NEMESIS_BOSS_AZTAREC",
            wpMapID = 2512, wpX = 51.2, wpY = 30.3,
        }, -- 毒瀑深渊 Venomfall Deeps（当前赛季） | 首领: 阿兹塔雷克 Azta'rec
    },
    tww = {
        -- 多恩岛 Isle of Dorn
        { uiMapID = 2269, poiRegular = 7863, poiBountiful = 7787, achChest = 40806, achStory = 40527, kind = "normal" }, -- 地匍矿洞      Earthcrawl Mines
        { uiMapID = 2249, poiRegular = 7864, poiBountiful = 7779, achChest = 40803, achStory = 40525, kind = "normal" }, -- 真菌之愚      Fungal Folly
        { uiMapID = 2250, poiRegular = 7865, poiBountiful = 7781, achChest = 40807, achStory = 40526, kind = "normal" }, -- 克莱格瓦之眠  Kriegval's Rest
        -- 喧鸣深窟 The Ringing Deeps
        { uiMapID = 2251, poiRegular = 7866, poiBountiful = 7782, achChest = 40816, achStory = 40528, kind = "normal" }, -- 水能堡        The Waterworks
        { uiMapID = 2302, poiRegular = 7867, poiBountiful = 7788, achChest = 40812, achStory = 40529, kind = "normal" }, -- 恐惧陷坑      Dread Pit
        { uiMapID = 2396, poiRegular = 8143, poiBountiful = 8181, achChest = 41100, achStory = 41098, kind = "normal" }, -- 九号挖掘场    Excavation Site 9
        -- 陨圣峪 Hallowfall
        { uiMapID = 2277, poiRegular = 7868, poiBountiful = 7785, achChest = 40809, achStory = 40530, kind = "normal" }, -- 夜幕圣所      Nightfall Sanctum
        { uiMapID = 2312, poiRegular = 7869, poiBountiful = 7780, achChest = 40808, achStory = 40531, kind = "normal" }, -- 丝菌师洞穴    Mycomancer Cavern
        { uiMapID = 2300, poiRegular = 7870, poiBountiful = 7783, achChest = 40813, achStory = 40532, kind = "normal" }, -- 无底沉穴      The Sinkhole
        { uiMapID = 2310, poiRegular = 7871, poiBountiful = 7789, achChest = 40810, achStory = 40533, kind = "normal" }, -- 飞掠裂口      The Skittering Breach
        -- 艾基-卡赫特 Azj-Kahet
        { uiMapID = 2299, poiRegular = 7872, poiBountiful = 7786, achChest = 40815, achStory = 40534, kind = "normal" }, -- 幽暗要塞      The Underkeep
        { uiMapID = 2259, poiRegular = 7873, poiBountiful = 7784, achChest = 40811, achStory = 40535, kind = "normal" }, -- 塔克-雷桑深渊 Tak-Rethan Abyss
        { uiMapID = 2313, poiRegular = 7874, poiBountiful = 7790, achChest = 40814, achStory = 40536, kind = "normal" }, -- 螺旋织纹      Spiral Weave
        {
            uiMapID = 2348, poiRegular = 7875, poiBountiful = nil, achChest = nil, achStory = nil,
            achNemesis = 40433, kind = "nemesis", season = 1, bossKey = "NEMESIS_BOSS_ZEKVIR",
            wpMapID = 2213, wpX = 6.28, wpY = 33.85,
        }, -- 泽克维尔的巢穴 Zekvir's Lair | 首领: 泽克维尔 Zekvir | 真实所在是 千丝之城 City of Threads (2213)
        -- 安德麦 Undermine
        { uiMapID = 2420, poiRegular = 8140, poiBountiful = 8246, achChest = 41101, achStory = 41099, kind = "normal" }, -- 闸板陋巷      Sidestreet Sluice
        {
            uiMapID = 2425, poiRegular = 8142, poiBountiful = nil, achChest = nil, achStory = nil,
            achNemesis = 41210, kind = "nemesis", season = 2, bossKey = "NEMESIS_BOSS_UNDERPIN",
            wpMapID = 2346, wpX = 53.87, wpY = 9.30,
        }, -- 破拆穹顶 Demolition Dome | 首领: 幽坑太保 The Underpin
        -- 卡雷什 K'aresh
        { uiMapID = 2452, poiRegular = 8274, poiBountiful = 8273, achChest = 42679, achStory = 42771, kind = "normal" }, -- 档案馆突袭    Archival Assault
        {
            uiMapID = 2484, poiRegular = 8323, poiBountiful = nil, achChest = nil, achStory = nil,
            achNemesis = 42190, kind = "nemesis", season = 3, bossKey = "NEMESIS_BOSS_KYVEZA",
            wpMapID = 2472, wpX = 38.4, wpY = 51.1,
        }, -- 虚空之锋庇护所 Voidrazor Sanctuary | 首领: 节点女亲王凯威扎 Nexus-Princess Ky'veza | 真实所在是 塔扎维什 Tazavesh (2472)
    },
}

-- 当前赛季（原 CURRENT_NEMESIS_FALLBACK，用户 2026-10-30 要求改名并注明由来）：
-- **赛季号无法通过 API 获取**，所以直接在这里定义「当前赛季」信息。按资料片登记各自
-- 进行到的赛季号；宿敌的「是否为当前赛季」判断以此为准（Services/Stats.lua）。
-- tww 已是过去资料片，赛季号不再变化（其最后一位宿敌 Ky'veza 为第 3 赛季）。
addon.Data.CURRENT_SEASON = { midnight = 2, tww = 3 }
-- 当前资料片：与 CURRENT_SEASON 配对使用，替代原先写在 fallback 里的 expansion 字段。
addon.Data.CURRENT_EXPANSION = "midnight"

-- 地下堡行者的召唤 Delver's Call：每地下堡的 questID。
-- 结构与 DELVES / ABUNDANCE 同款：**按资料片分组**（用户 2026-10-30）。
-- 来源：
--   - 至暗之夜：EverythingDelves Core/Data.lua:234-245（E.DelversCall）。
--   - 地心之战：手动补充
addon.Data.DELVERS_CALL_QUESTS = {
    midnight = {
        [2525] = 93385, -- 黑暗回廊 The Darkway
        [2577] = 93384, -- 学府骚动 Collegiate Calamity
        [2545] = 93386, -- 幻日广场 Parhelion Plaza
        [2502] = 93372, -- 聚影领地 The Shadow Enclave
        [2503] = 93410, -- 暮光地穴 Twilight Crypt
        [2535] = 93409, -- 阿塔阿曼 Atal'Aman
        [2505] = 93416, -- 回忆深沟 The Gulf of Memory
        [2510] = 93421, -- 憎怨斗坑 The Grudge Pit
        [2506] = 93428, -- 影卫营   Shadowguard Point
        [2528] = 93427, -- 戮日圣殿 Sunkiller Sanctum
    },
    tww = {
        [2249] = 83758, -- 真菌之愚      Fungal Folly
        [2250] = 83759, -- 克莱格瓦之眠  Kriegval's Rest
        [2269] = 85648, -- 地匍矿洞      Earthcrawl Mines
        [2251] = 85649, -- 水能堡        The Waterworks
        [2302] = 83766, -- 恐惧陷坑      Dread Pit
        [2277] = 85664, -- 夜幕圣所      Nightfall Sanctum
        [2300] = 83767, -- 无底沉穴      The Sinkhole
        [2310] = 83768, -- 飞掠裂口      The Skittering Breach
        [2312] = 83769, -- 丝菌师洞穴    Mycomancer Cavern
        [2259] = 83771, -- 塔克-雷桑深渊 Tak-Rethan Abyss
        [2299] = 85667, -- 幽暗要塞      The Underkeep
        [2313] = 85666, -- 螺旋织纹      Spiral Weave    还有一个 questID 是 83770，等校验
    },
}
