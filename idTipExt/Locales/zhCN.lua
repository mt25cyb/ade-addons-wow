----------------------------------------------------------------------------
-- idTipExt zhCN 本地化（简体中文）
-- 按 GetLocale() 覆盖 enUS 默认值；key 顺序与 enUS.lua / Core.lua 一致
-- 零依赖：不引 AceLocale，直接覆盖 Core.lua 的 ns.L 与 ns.kinds 标签
----------------------------------------------------------------------------

local addonName = ...
local ns = _G[addonName]
if not ns or GetLocale() ~= "zhCN" then return end

-- 类型标签：顺序与 Core.lua 的 ns.kinds 定义一致
local kindLabels = {
	spell = "法术ID",
	item = "物品ID",
	itemspell = "物品法术ID",
	unit = "NPC ID",
	quest = "任务ID",
	talent = "天赋ID",
	achievement = "成就ID",
	criteria = "条件ID",
	ability = "技能ID",
	artifactpower = "神器能量ID",
	currency = "货币ID",
	enchant = "附魔ID",
	bonus = "加成ID",
	gem = "宝石ID",
	mount = "坐骑ID",
	macro = "宏ID",
	set = "套装ID",
	visual = "外观ID",
	source = "来源ID",
	species = "物种ID",
	icon = "图标ID",
	areapoi = "区域兴趣点ID",
	vignette = "小插曲ID",
	expansion = "资料片ID",
	object = "物体ID",
	traitnode = "特质节点ID",
	traitentry = "特质条目ID",
	traitdef = "特质定义ID",
	unittoken = "施法者",
	faction = "声望ID",
	questOverlay = "任务ID叠加",
	cooldown = "冷却ID",
}
for key, label in pairs(kindLabels) do
	ns.kinds[key] = label
end

ns.L.Enabled = "启用"
ns.L.Types = "类型"
ns.L.Style = "显示风格"
ns.L.BlankLineBeforeFirst = "首行信息前加一空行"
ns.L.StyleSingle = "单段式显示"
ns.L.StyleDouble = "两段式显示"
ns.L.PrefixColor = "前缀颜色"
ns.L.ShowCaster = "显示施法者"
ns.L.CasterClassColor = "施法者名称按职业着色"
ns.L.PrefixClassColor = "前缀按职业着色"
ns.L.WorldMapPanel = "在世界地图显示"
ns.L.WorldMapPosition = "地图信息面板位置"
ns.L.WorldMapTop = "世界地图顶部"
ns.L.WorldMapBottom = "世界地图底部"
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

ns.L.Sections = {
	Items = "物品装备",
	Spells = "法术技能",
	Units = "单位与藏品",
	Other = "其它",
	Panel = "地理监视面板",
}

ns.L.Tooltips = {
	faction = "打开声望面板时，每一行声望条旁边直接标出声望阵营ID",
	questOverlay = "在任务日志详情面板与 NPC 任务对话框上叠加显示任务ID",
	cooldown = "在冷却管理器（Cooldown Manager）条目的提示框上显示冷却ID",
	style = "两段式显示：前缀居左、值居右（AddDoubleLine）；单段式显示：每个 ID 一行左对齐（AddLine）",
	prefixColor = "ID 前缀标签的颜色",
}

-- 地理监视面板（GeoWatcher.lua）运行时与选项文案
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

-- 坐骑信息子模块（MountInfo.lua）文案
ns.L.MountInfo = {
	ShowMountInfo = "显示坐骑信息",
	ShowCollected = "显示收藏状态",
	ShowSource = "显示坐骑来源",
	ShowLore = "显示坐骑故事",
	BlankLine = "坐骑信息前加一空行",
	CollectedPrefix = "收藏状态:",
	Collected = "已收藏",
	NotOwned = "未拥有",
	SourcePrefix = "来源:",
	LorePrefix = "故事:",
}
