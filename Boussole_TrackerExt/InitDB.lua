-- Boussole_TrackerExt — 设置默认值（独立文件，依 ADE 系列样式）。
-- 由 Core.lua 的 InitSettings() 在 ADDON_LOADED 时读取，用于初始化/补全存档。
-- 加载顺序：须在引用默认值的模块（Options.lua 顶部按 DEFAULTS 初始化设置控件）之前加载（见 TOC）。
-- 规范：每个默认值行尾须以注释标明其对应的设置选项（选项名取自 Locales 的 SETTINGS_*）。
-- 存档为扁平 settings.* 表（本插件不接入 ADE 配置档方案）；颜色存 {red,green,blue}（项目规则）。
local _, ns = ...
local Addon = ns.Addon

Addon.DEFAULTS = {
	settings = {
		enabled = true,                       -- 追踪目标来源 / 主开关（SETTINGS_ENABLE_SOURCE）
		trackUserWaypoint = true,             -- 追踪目标来源 / 用户航点（SETTINGS_USER_WAYPOINT）

		pointerStay = true,                   -- 贴边指针 / 指针保持在罗盘上（SETTINGS_POINTER_STAY）
		stayAtlas = "NPE_ArrowUp",            -- 贴边指针 / 贴边箭头样式（SETTINGS_STAY_ATLAS）
		hideFar = false,                      -- 贴边指针 / 隐藏其他大陆指针（SETTINGS_HIDE_FAR）
		useCurrentMap = true,                 -- 贴边指针 / 使用地图转换（SETTINGS_USE_CURRENT_MAP）

		scaleMultiplier = 1.0,                -- 追踪强调 / 放大比例（SETTINGS_SCALE）
		highlightColor = { red = 1, green = 0.85, blue = 0.35 }, -- 追踪强调 / 高亮颜色（SETTINGS_HIGHLIGHT_COLOR）
		glowAlpha = 0.6,                      -- 追踪强调 / 光晕透明度（SETTINGS_GLOW_ALPHA）
		useRewardIcon = true,                 -- 追踪强调 / 世界任务奖励图标（SETTINGS_REWARD_ICON）

		showScale = false,                    -- 罗盘版式 / 显示刻度数字（SETTINGS_SHOW_SCALE）

	},
}
