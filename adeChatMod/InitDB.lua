-- adeChatMod — 设置默认值（独立文件，规划 §3.4）。
-- 由 Core.lua 的 ACM:InitDB() 在 ADDON_LOADED 时读取，用于初始化/补全存档。
-- 加载顺序：须在引用默认值的模块（如 Minimap.lua 顶部按 DEFAULTS 初始化角度）之前加载（见 TOC）。
-- 规范：每个默认值行尾须以注释标明其对应的设置选项（选项名取自 Locales 的 LABEL_*；规划 §3.4）。
-- b013 起存档分两层（ADE-v6-FrameDesign 配置档方案）：
--   settings = 配置档内容（随 profiles.list[当前档] 切换/导出/导入/重置）；
--   state    = 会话状态（显隐/小地图角度），不随配置档走，固定存 db.state。
local ACM = _G.adeChatMod or {}
_G.adeChatMod = ACM

-- 默认值取自 ChannelBar 原 config 表，统一收进 settings.*。
ACM.DEFAULTS = {
    settings = {
        colorScheme = "COLORFUL",            -- 外观 / 按钮配色（LABEL_COLOR_SCHEME）
        btnSize = 24,                        -- 外观 / 按钮大小（LABEL_BTN_SIZE）
        btnGap = -1,                         -- 外观 / 按钮间距（LABEL_BTN_GAP）
        fontSize = 14,                       -- 外观 / 字号（LABEL_FONT_SIZE）
        worldChannel = "大脚世界频道",         -- 频道 / 世界频道名称（LABEL_WORLD_CHANNEL）
        tradeChannel = "交易",                 -- 频道 / 交易频道名称（LABEL_TRADE_CHANNEL）
        autoJoinWorldChannel = false,        -- 频道 / 自动加入世界频道（LABEL_AUTO_JOIN）
        autoJoinDelay = 5,                   -- 频道 / 自动加入延迟（LABEL_AUTO_JOIN_DELAY）
        attachTarget = "ChatFrame1EditBox",  -- 位置 / 吸附框体（全局名称）（LABEL_ATTACH_TARGET）
        attachPosition = {                   -- 位置 / 快捷条锚点组（以下四字段）
            point = "TOPLEFT",               --   快捷条锚点（LABEL_ATTACH_POINT）
            relativePoint = "BOTTOMLEFT",    --   目标锚点（LABEL_ATTACH_RELATIVE_POINT）
            x = 2,                           --   水平偏移（LABEL_ATTACH_X）
            y = 0,                           --   垂直偏移（LABEL_ATTACH_Y）
        },
        defaultPosition = {                  -- 备用位置 / 偏移组（相对 UIParent BOTTOMLEFT）
            point = "BOTTOMLEFT",            --   备用锚点
            relativePoint = "BOTTOMLEFT",    --   备用相对点
            x = 30,                          --   备用水平偏移（LABEL_FALLBACK_X）
            y = 300,                         --   备用垂直偏移（LABEL_FALLBACK_Y）
        },
        -- 主题色（强调色）：默认黄色；颜色存 {red,green,blue}（项目规则）。设置页「主题色」分区可改。
        themeColor = { red = 1, green = 0.78, blue = 0.20 }, -- 外观 / 主题色（LABEL_THEME_COLOR）
    },
    -- 会话状态（不进配置档；沿用 PT Core.lua:244-247 的口径）
    state = {
        barShown = true,                     -- 小地图按钮 / 显示快捷条（LABEL_BAR_SHOWN）
        minimapShown = true,                 -- 小地图按钮 / 显示小地图按钮（LABEL_MINIMAP_SHOWN）
        minimapAngle = 200,                  -- 小地图按钮 / 按钮圆周角度（拖拽调整，无独立设置控件）
    },
}
