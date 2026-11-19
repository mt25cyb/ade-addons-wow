local _, addon = ...
addon.Data = addon.Data or {}

-- 仪式场地（DFCN_DelveHelper.lua:137-140）—— 从 Data\DelveZones.lua 拆出（用户 2026-10-30）。
-- 与 Data/DELVES、Data/ABUNDANCE 同款结构：**按资料片分组**，资料片由表的 key 决定。

addon.Data.RITUAL_SITES = {
    midnight = {
        [2395] = { 8615 }, -- 永歌森林 Eversong Woods
        [2437] = { 8614 }, -- 祖阿曼 Zul'Aman
    },
}
-- POI 图集取不到时的兜底图标。
addon.Data.RITUAL_ATLAS_FALLBACK = "Ritual-Sites-Map-Icon"

-- 第二阶段 9.2：仪式场地静态兜底（未激活时 GetAreaPOIInfo 取不到，用此处名称与坐标）。
-- 名称走 locale，不硬编码中文（与「地下堡名称一律本地化」原则一致）。
-- 坐标来自用户 2026-10-29 给定（/way 百分数 → 0~1）。功能不降级：左键切图、右键静态坐标设路点。
addon.Data.RITUAL_STATIC = {
    midnight = {
        [8615] = { nameKey = "RITUAL_DAGGERSPIKE", zoneMapID = 2395, x = 0.376, y = 0.652 }, -- 刺脊营 @ 永歌森林 (37.6, 65.2)
        [8614] = { nameKey = "RITUAL_BROKEN_THRONE", zoneMapID = 2437, x = 0.296, y = 0.778 }, -- 残破神庙 @ 祖阿曼 (29.6, 77.8)
    },
}
-- 仪式场地固定显示顺序：永歌森林(2395) → 祖阿曼(2437)（第二阶段 9.2，按 ZoneIndex 地图顺序）。
addon.Data.RITUAL_SITE_ORDER = {
    midnight = { 2395, 2437 },
}
