local _, ns = ...
ns.Locales.zhCN = {
	ADDON_NAME = "罗盘追踪扩展",

	SECTIONS_SOURCE = "追踪目标来源",
	SECTIONS_EDGE = "贴边指针",
	SECTIONS_EMPHASIS = "追踪强调",
	SECTIONS_LAYOUT = "罗盘版式",

	SETTINGS_ENABLE_SOURCE = "追踪地图 / 任务追踪窗目标",
	SETTINGS_ENABLE_SOURCE_TIP = "显示超级追踪目标（任务、航点、地图标记、事件），与 CompassHUD 显示的目标一致；无超级追踪时显示主插件选定的图钉，两者冲突以超级追踪为准。",
	SETTINGS_USER_WAYPOINT = "追踪用户航点",
	SETTINGS_USER_WAYPOINT_TIP = "地图手放航点处于超级追踪时显示到罗盘上。",

	SETTINGS_POINTER_STAY = "指针保持在罗盘上",
	SETTINGS_POINTER_STAY_TIP = "追踪目标超出罗盘可视范围时，追踪扩展信息保持在边缘显示，并在其外侧显示方向箭头。",
	SETTINGS_STAY_ATLAS = "贴边箭头样式",
	STAY_ATLAS_NPE = "标准箭头",
	STAY_ATLAS_NAV = "导航追踪箭头",
	STAY_ATLAS_BAG = "三角箭头",
	SETTINGS_HIDE_FAR = "隐藏指向其他大陆的指针",
	SETTINGS_HIDE_FAR_TIP = "目标位于其他大陆时隐藏追踪指示。",
	SETTINGS_USE_CURRENT_MAP = "使用地图转换",
	SETTINGS_USE_CURRENT_MAP_TIP = "目标在其他地图时，指向系统建议的转换点（传送门、入口）而非原始坐标。",

	SETTINGS_SCALE = "追踪目标放大比例",
	SETTINGS_HIGHLIGHT_COLOR = "高亮颜色",
	SETTINGS_GLOW_ALPHA = "光晕透明度",
	SETTINGS_REWARD_ICON = "使用世界任务奖励图标",
	SETTINGS_REWARD_ICON_TIP = "世界任务 / 奖励目标使用奖励物品或货币图标（CompassHUD 默认开启），关闭则用对应任务分类的指针图标。",
	SETTINGS_SHOW_SCALE = "显示罗盘刻度数字",
	SETTINGS_SHOW_SCALE_TIP = "仿 CompassHUD 在罗盘上叠加 30° 间隔的方位读数（复用主插件刻度投影，宿主本身只显示刻度线）。",

	INCOMPATIBLE = "Compass 内部结构不兼容，增强层已禁用。",
	USER_WAYPOINT = "用户航点",
	AREA_PIN = "地图标记",
	STATUS_LINE = "|cffabd473Compass TrackerExt|r 状态：API %s，罗盘 %s，内部层 %s，导航 %s",
}
