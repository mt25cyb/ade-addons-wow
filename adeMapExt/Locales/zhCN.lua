----------------------------------------------------------------------------
-- adeMapExt zhCN 本地化（简体中文）
-- 按 GetLocale() 覆盖 enUS 默认值；key 顺序与 enUS.lua 一致
----------------------------------------------------------------------------

local addonName = ...
local ns = _G[addonName]
if not ns or GetLocale() ~= "zhCN" then return end

ns.L.Style = "显示风格"
ns.L.StyleSingle = "单段式显示"
ns.L.StyleDouble = "两段式显示"
ns.L.PrefixClassColor = "前缀按职业着色"
ns.L.PrefixColor = "前缀颜色"
ns.L.GrowDirection = "生长方向"
ns.L.GrowUp = "向上生长"
ns.L.GrowDown = "向下生长"
ns.L.MapNameMode = "地图名称显示"
ns.L.MapNameNone = "不显示名称"
ns.L.MapNameInline = "同行显示"
ns.L.MapNameSeparate = "单独一行"
ns.L.PanelWidth = "面板宽度"
ns.L.ShowPhaseID = "显示位面ID"
ns.L.ShowMapID = "显示地图ID"
ns.L.ShowWorldMapID = "显示世界地图ID"
ns.L.ShowInstanceID = "显示副本ID"
ns.L.ShowZoneID = "显示区域ID"
ns.L.StyleTip = "两段式显示：前缀居左、值居右；单段式显示：前缀与值同串混色"

ns.L.Sections = {
	Panel = "地理监视面板",
	Appearance = "外观",
	Behavior = "行为",
	PanelGroup = "面板",
}

-- 地理监视面板（Panel.lua）运行时与选项文案（自 idTipExt 1.3.0 迁移）
ns.L.Panel = {
	Section = "地理监视面板",
	ShowPanel = "显示地理监视面板",
	Lock = "锁定面板位置",
	AutoHide = "战斗中自动隐藏",
	Hexadecimal = "位面ID使用十六进制显示",
	DetailedTooltip = "悬停面板时显示详细信息",
	WorldMapPanel = "在世界地图显示",
	WorldMapPosition = "地图信息面板位置",
	WorldMapTop = "世界地图顶部",
	WorldMapBottom = "世界地图底部",
	UpdateInterval = "更新间隔",
	FontSize = "字体大小",
	Alpha = "面板透明度",
	BackgroundColor = "背景颜色",
	BorderColor = "边框颜色",
	BgAlpha = "背景透明度",
	BorderAlpha = "边框透明度",
	PrefixClassColor = "前缀按职业着色",
	PrefixColor = "前缀颜色",
	Initializing = "初始化中...",
	DragToMove = "拖动移动",
	PhasePrefix = "位面ID:",
	MapPrefix = "地图ID:",
	MapLabel = "地图:",
	WorldMapPrefix = "世界地图ID:",
	WorldMapLabel = "世界地图:",
	InstancePrefix = "副本ID:",
	ZonePrefix = "区域ID:",
	SecretValue = "隐藏（Secret Value 受限）",
	InstanceLimitation = "副本内，可能无法检测",
	NotDetected = "未检测到（需要有目标/NPC）",
	PhaseMonitor = "地理监视",
	CurrentPhase = "当前位面ID:",
	Format = "格式:",
	HexadecimalFmt = "十六进制",
	DecimalFmt = "十进制",
	Source = "来源:",
	SourceMouseover = "鼠标指向",
	SourceTarget = "当前目标",
	SourcePlayer = "玩家自身",
	SourceFocus = "焦点目标",
	SourceCached = "缓存值",
	RightClickHint = "右键打开选项",
	WindowShown = "面板已显示",
	WindowHidden = "面板已隐藏",
	WindowLocked = "面板已锁定",
	WindowUnlocked = "面板已解锁",
	WindowReset = "面板位置已重置",
	CacheCleared = "缓存的位面ID已清除",
	FormatSwitchedHex = "已切换为十六进制显示",
	FormatSwitchedDec = "已切换为十进制显示",
	OpenSettings = "打开设置",
	ButtonClearCache = "清除缓存ID",
	ButtonResetPosition = "重置面板位置",
	ButtonOpenSettings = "打开完整设置",
}
