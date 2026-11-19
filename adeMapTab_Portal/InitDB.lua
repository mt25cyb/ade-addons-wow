--[==[ adeMapTab_Portal / InitDB.lua
默认配置唯一来源：v6.5 由 ade_UIKit.DB.MergeDefaults 合并到 ADEDB_MAP_TAB_PORTAL.profile。
只放扁平键：嵌套表（teleportsPreferredHearthstone / collapsedSections / teleportFavorites /
zoneButtonsCharacterFilters / zoneButtonsOffsets / recentTeleports / collapsedSections）
统一由 Core/Database.lua 用主插件公共函数 MapTab.CopyTable 深拷贝后在 profile 上显式建表
（两层互补：MergeDefaults 补缺失键，rawget 补嵌套表，避免共享默认表）。 ]==]
local _, addon = ...

-- 嵌套表的默认值模板（不放进 AceDB defaults，避免 profile metatable 回落拿到共享表）。
-- Core/Database.lua 用主插件公共函数 MapTab.CopyTable 深拷贝后挂到 profile。
addon.nestedDefaults = {
    teleportsPreferredHearthstone = {},   -- 偏好炉石，空表 = 全部已拥有炉石随机
    collapsedSections = {},               -- 分组标题折叠态
    teleportFavorites = {},               -- 收藏
    zoneButtonsCharacterFilters = { hearthstone = true, class = true, race = true, housing = true },
    zoneButtonsOffsets = {},              -- 各布局项独立的偏移
    recentTeleports = {},                 -- 最近使用记录（账号级）
}

addon.defaults = {
    profile = {
        defaultTab = false,                 -- 打开世界地图时自动选中传送标签页
        teleportsWorldMapEnabled = true,    -- 在世界地图启用传送标签页
        portalHideMissing = true,           -- 隐藏尚未学会的传送
        portalShowTooltip = false,          -- 传送按钮显示说明 tooltip
        portalTooltipDestination = true,    -- 在提示中添加传送目的地（依赖「传送按钮显示提示」）
        portalDisableMasque = false,        -- 禁用 Masque 皮肤，改用内置 1px 边框
        showRecentTeleports = false,        -- 列表顶部显示最近使用
        recentTeleportsCount = 6,           -- 最近使用最多显示条数（1~20，RecentHistory 会钳制上限）
        showFavorites = true,               -- 列表显示「收藏」分组（位于最近使用与角色之间）
        zoneButtonsEnabled = true,          -- 地图左上角显示区域传送按钮
        zoneButtonsShowUnknown = false,     -- 区域按钮含未学会的传送
        zoneButtonsShowCharacter = true,   -- 所有地图都显示角色（家宅）分组传送
        zoneButtonsShowContinent = true,   -- 大陆地图（mapType = 2）也显示区域按钮
        zoneButtonsLayout = "topLeftColumn", -- 区域按钮布局预设（ZoneTeleportButtons.LAYOUTS 键）
        portalButtonSquare = false,        -- 区域传送按钮是否方形（false = 圆形，默认）
        portalButtonEdgeShadow = 1,        -- 区域传送按钮暗色边缘虚影厚度（像素，0 = 无；方形/圆形都生效）
    },
}
