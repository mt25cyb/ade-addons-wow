-- adeChatBar — 设置默认值（唯一默认值权威源）。
-- 由 Core.lua 的 ACB:InitDB() 在 ADDON_LOADED 时读取，用于初始化/补全存档。
-- 存档分两层：settings = 设置项；state = 会话状态（显隐/小地图角度），随登录保留。
-- 频道名缩写功能已移除，本次不保留其任何存档键。
local ACB = _G.adeChatBar or {}
_G.adeChatBar = ACB

ACB.DEFAULTS = {
    settings = {
        colorScheme = "COLORFUL",            -- 外观 / 按钮配色
        btnSize = 24,                        -- 外观 / 按钮大小
        btnGap = -1,                         -- 外观 / 按钮间距
        fontSize = 14,                       -- 外观 / 字号
        worldChannel = "大脚世界频道",         -- 频道 / 世界频道名称
        tradeChannel = "交易",                 -- 频道 / 交易频道名称
        autoJoinWorldChannel = false,        -- 频道 / 自动加入世界频道
        autoJoinDelay = 5,                   -- 频道 / 自动加入延迟
        attachTarget = "ChatFrame1EditBox",  -- 位置 / 吸附框体（全局名称）
        attachPosition = {
            point = "TOPLEFT",
            relativePoint = "BOTTOMLEFT",
            x = 2,
            y = 0,
        },
        defaultPosition = {
            point = "BOTTOMLEFT",
            relativePoint = "BOTTOMLEFT",
            x = 30,
            y = 300,
        },
    },
    state = {
        barShown = true,
        minimapShown = true,
        minimapAngle = 200,
    },
}
