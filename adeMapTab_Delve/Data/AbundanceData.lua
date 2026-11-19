local _, addon = ...
local Data = addon.Data

-- 第二阶段 9.3：丰饶收获区域静态表。
--
-- 结构与 Data/DELVES 一致：**按资料片分组**（四个区域都在 Midnight，见 DevPlan §9.3.1）。
-- 资料片由表的 key 决定，不再单独写 `EXPANSION` 字段——这样从根本上杜绝了把它标成
-- tww 导致条目落到错误分组的可能（2026-10-30 修过一次这个坑）。
--
-- 名称走 locale（不硬编码中文，符合开发要求）；专业走 Data.PROFESSION 的**专业 ID**；
-- 所属地图名走 API（C_Map），不落静态表。
--
-- wpX / wpY（0-100）是**静态兜底坐标**：非「丰饶收获」状态时地图不渲染该 POI
-- （普通组 8415-8418 在地图上无图标，见 §9.3.3），`GetAreaPOIInfo` 取不到结果，
-- 右键设路径点会因缺坐标而失败 —— 所以每个区域都必须带兜底坐标（用户 2026-10-30）。
--
-- 坐标来源：DevPlan §9.3.1；其中 8526 @2405（0.3885/0.5336）与 8525 @2437
-- （0.316049/0.261134）已由用户实机 dump 实证。

addon.Data.ABUNDANCE = {
    midnight = {
        {   mapID = 2395, poi = 8528, nameKey = "ABUNDANCE_WATHANAN_CRYPTS",
            professions = {
                Data.PROFESSION.TAILORING,
                Data.PROFESSION.ENCHANTING,
                Data.PROFESSION.JEWELCRAFTING,
            },
            wpX = 56.8, wpY = 65.8,
        }, -- 瓦萨南墓穴 Watha'nan Crypts（裁缝 / 附魔 / 珠宝）
        {   mapID = 2437, poi = 8525, nameKey = "ABUNDANCE_LOAKNIT_DEN",
            professions = {
                Data.PROFESSION.SKINNING,
                Data.PROFESSION.LEATHERWORKING,
                Data.PROFESSION.COOKING,
            },
            wpX = 31.6, wpY = 26.0,
        }, -- 神愈兽穴 Loaknit Den（剥皮 / 制皮 / 烹饪）
        {   mapID = 2413, poi = 8527, nameKey = "ABUNDANCE_FLOARET_GROTTO",
            professions = {
                Data.PROFESSION.HERBALISM,
                Data.PROFESSION.ALCHEMY,
                Data.PROFESSION.INSCRIPTION,
            },
            wpX = 66.0, wpY = 61.6,
        }, -- 花朵洞窟 Floaret Grotto（采药 / 炼金 / 铭文）
        {   mapID = 2405, poi = 8526, nameKey = "ABUNDANCE_VOIDBURROW",
            professions = {
                Data.PROFESSION.MINING,
                Data.PROFESSION.ENGINEERING,
                Data.PROFESSION.BLACKSMITHING,
            },
            wpX = 38.8, wpY = 53.2,
        }, -- 盎然虚空之窟 Abundant Voidburrow（采矿 / 工程 / 锻造）
    },
}
