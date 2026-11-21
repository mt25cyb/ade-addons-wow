--[==[ adeMapTab_Delve / InitDB.lua
默认配置唯一来源：v6.5 由 ade_UIKit.DB.MergeDefaults 合并到 ADEDB_MAP_TAB_DELVE.profile。
只放扁平键：嵌套表（roster / collapsedExpansions / filters / minimap / recentTeleports）统一由
Core/Database.lua 用主插件公共函数 MapTab.CopyTable 深拷贝后在 profile 上显式建表
（v4 逐行保留的补齐逻辑；UIKit MergeDefaults 会对缺失的嵌套键建默认副本，两层互补）。 ]==]
local _, addon = ...

-- 嵌套表的默认值模板（不放进 AceDB defaults，避免 profile metatable 回落拿到共享表）。
-- Core/Database.lua 用主插件公共函数 MapTab.CopyTable 深拷贝后挂到 profile。
addon.nestedDefaults = {
    roster = {},                                            -- 跨角色快照
    collapsedExpansions = {},                               -- 资料片分组折叠态
    filters = {
        expansion = { -- 资料片过滤
            midnight = true,
            tww = true
        },
        kind = { -- 类型过滤
            delve = true,
            abundance = true,
            ritual = true },
        },
    minimap = { -- 小地图位置存档
        hide = false,
        minimapPos = 220,
        radius = 0
    },
}

addon.defaults = {
    profile = {
        defaultTab = false,             -- 打开世界地图时自动选中地下堡标签页（WQT 已占用时让位）
        showMidnight = true,            -- 显示至暗之夜资料片的地下堡
        showTWW = true,                 -- 显示地心之战资料片的地下堡
        showLabyrinth = true,           -- 显示迷宫
        showRitual = true,              -- 显示仪式场地
        showNemesis = true,             -- 显示宿敌地下堡
        showStoryVariant = true,        -- 条目副标题显示故事变种
        eventActiveFirst = true,        -- 活动中的条目在资料片组内排前
        showAbundance = true,           -- 显示丰饶区域
        showTimeLeft = true,            -- 丰饶条目下显示剩余时间
        entrySortMode = "default",      -- 条目排序：default / map
        rosterShowLastLogin = false,    -- 战团名单显示上次登录时间
        rosterTimeFormat = "ymd",      -- 上次登录时间格式
        rosterTime24 = true,            -- 24 小时制（false 为 12 小时制带 AM/PM）
        rosterGrouping = "realm",       -- 战团名单分组：none / realm / faction
        showTasks = false,              -- 条目右侧显示地下堡行者的召唤任务状态
        showAchievements = false,       -- 条目右侧显示成就进度
        hideCompleted = false,          -- 隐藏成就与召唤都已完成的地下堡
        searchVisible = false,          -- 顶栏搜索框是否展开（面板级状态）
        showMinimapIcon = true,         -- 显示小地图图标
    },
}
