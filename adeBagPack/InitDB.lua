--[==[ adeBagPack / InitDB.lua
默认配置（旧 adeBackpack InitDB 裁剪版，计划 §二决策 1/7）：
- 沿用 ADEDB_BACKPACK 旧存档结构（profiles/profileKeys/char/realm/global 不迁移），
  缺失键由 ade_UIKit DB.MergeDefaults 补全（statPlus 同款口径）。
- 删除：出售/摧毁/修理全套键（sellJunk/destroy*/safeMode*/junkAllow/Deny/attachLists/
  include*/qualityFilter/autoRepair*）——旧键残留无害（不读不写，不主动清理）。
- 新增：external 分组（外部插件支持，P3.5 External.lua 消费，计划 §二决策 7）。
]==]
local ns = _G.adeBagPack or {}

-- 配置默认值（分层 profile）
ns.defaults = {
    profile = {
        showmessage = true,               -- 显示整理消息
        messageframe = 2,                 -- 1=聊天框 2=UIErrors
        useBlizzardSort = false,          -- 启用暴雪原生整理（右键菜单/兜底）
        overrideNativeSort = true,        -- 接管原生背包整理按钮（false=保留原生按钮行为）
        nativeSortButton = true,          -- a16：在原生背包界面外挂一个自建整理按钮（独立于原生接管）
        desc = true,                      -- 默认逆序整理
        symmetricJunk = true,             -- a11：垃圾对称整理（替代 junkZone 垃圾钉放区）
        orders = { CustomOrder = {}, EquipLocOrder = {} },
        minimap = { hide = false, minimapPos = 220, radius = 0 },  -- P3 Minimap 消费
        external = {                      -- 外部插件支持（计划 §二决策 7；P3.5 External.lua 消费）
            junkSource = "builtin",       -- 垃圾判定来源：builtin | dejunk
            infoSource = "builtin",       -- 物品信息来源：builtin | itemera
            baganatorSort = false,        -- 注册为 Baganator 容器排序
            baganatorButton = true,       -- Baganator 视图内注入整理按钮（RegisterRegion）
        },
    },
    global = {},
}
