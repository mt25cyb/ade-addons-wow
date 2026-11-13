----------------------------------------------------------------------------
-- idTipExt zhTW 本地化（繁體中文）
-- 按 GetLocale() 覆蓋 enUS 預設值；key 順序與 enUS.lua / Core.lua 一致
-- 零依賴：不引 AceLocale，直接覆蓋 Core.lua 的 ns.L 與 ns.kinds 標籤
----------------------------------------------------------------------------

local addonName = ...
local ns = _G[addonName]
if not ns or GetLocale() ~= "zhTW" then return end

-- 類型標籤：順序與 Core.lua 的 ns.kinds 定義一致
local kindLabels = {
	spell = "法術ID",
	item = "物品ID",
	itemspell = "物品法術ID",
	unit = "NPC ID",
	quest = "任務ID",
	talent = "天賦ID",
	achievement = "成就ID",
	criteria = "條件ID",
	ability = "技能ID",
	artifactpower = "神器能量ID",
	currency = "貨幣ID",
	enchant = "附魔ID",
	bonus = "加成ID",
	gem = "寶石ID",
	mount = "坐騎ID",
	macro = "巨集ID",
	set = "套裝ID",
	visual = "外觀ID",
	source = "來源ID",
	species = "物種ID",
	icon = "圖示ID",
	areapoi = "區域興趣點ID",
	vignette = "小插曲ID",
	expansion = "資料片ID",
	object = "物體ID",
	traitnode = "特質節點ID",
	traitentry = "特質條目ID",
	traitdef = "特質定義ID",
	unittoken = "施法者",
	faction = "聲望ID",
	questOverlay = "任務ID疊加",
	cooldown = "冷卻ID",
}
for key, label in pairs(kindLabels) do
	ns.kinds[key] = label
end

ns.L.Enabled = "啟用"
ns.L.Types = "類型"
ns.L.Style = "顯示風格"
ns.L.BlankLineBeforeFirst = "首行資訊前加一空行"
ns.L.StyleSingle = "單段式顯示"
ns.L.StyleDouble = "兩段式顯示"
ns.L.PrefixColor = "前綴顏色"
ns.L.ShowCaster = "顯示施法者"
ns.L.CasterClassColor = "施法者名稱依職業著色"
ns.L.PrefixClassColor = "前綴依職業著色"
ns.L.WorldMapPanel = "在世界地圖顯示"
ns.L.WorldMapPosition = "地圖資訊面板位置"
ns.L.WorldMapTop = "世界地圖頂部"
ns.L.WorldMapBottom = "世界地圖底部"
ns.L.GrowDirection = "生長方向"
ns.L.GrowUp = "向上生長"
ns.L.GrowDown = "向下生長"
ns.L.MapNameMode = "地圖名稱顯示"
ns.L.MapNameNone = "不顯示名稱"
ns.L.MapNameInline = "同行顯示"
ns.L.MapNameSeparate = "單獨一行"
ns.L.PanelWidth = "面板寬度"
ns.L.ShowPhaseID = "顯示位面ID"
ns.L.ShowMapID = "顯示地圖ID"
ns.L.ShowWorldMapID = "顯示世界地圖ID"
ns.L.ShowInstanceID = "顯示副本ID"
ns.L.ShowZoneID = "顯示區域ID"

ns.L.Sections = {
	Items = "物品裝備",
	Spells = "法術技能",
	Units = "單位與收藏",
	Other = "其他",
	Panel = "地理監視面板",
}

ns.L.Tooltips = {
	faction = "開啟聲望面板時，每一列聲望條旁邊直接標出聲望陣營ID",
	questOverlay = "在任務日誌詳情面板與 NPC 任務對話框上疊加顯示任務ID",
	cooldown = "在冷卻管理器（Cooldown Manager）條目的提示框上顯示冷卻ID",
	style = "兩段式顯示：前綴居左、值居右（AddDoubleLine）；單段式顯示：每個 ID 一行靠左對齊（AddLine）",
	prefixColor = "ID 前綴標籤的顏色",
}

-- 地理監視面板（GeoWatcher.lua）執行階段與選項文案
ns.L.Panel = {
	Section = "地理監視面板",
	ShowPanel = "顯示地理監視面板",
	Lock = "鎖定面板位置",
	AutoHide = "戰鬥中自動隱藏",
	Hexadecimal = "位面ID使用十六進位顯示",
	DetailedTooltip = "懸停面板時顯示詳細資訊",
	WorldMapPanel = "在世界地圖顯示",
	WorldMapPosition = "地圖資訊面板位置",
	WorldMapTop = "世界地圖頂部",
	WorldMapBottom = "世界地圖底部",
	UpdateInterval = "更新間隔",
	FontSize = "字型大小",
	Alpha = "面板透明度",
	BackgroundColor = "背景顏色",
	BorderColor = "邊框顏色",
	BgAlpha = "背景透明度",
	BorderAlpha = "邊框透明度",
	Initializing = "初始化中...",
	DragToMove = "拖動移動",
	PhasePrefix = "位面ID:",
	MapPrefix = "地圖ID:",
	MapLabel = "地圖:",
	WorldMapPrefix = "世界地圖ID:",
	WorldMapLabel = "世界地圖:",
	InstancePrefix = "副本ID:",
	ZonePrefix = "區域ID:",
	SecretValue = "隱藏（Secret Value 受限）",
	InstanceLimitation = "副本內，可能無法偵測",
	NotDetected = "未偵測到（需要有目標/NPC）",
	PhaseMonitor = "地理監視",
	CurrentPhase = "目前位面ID:",
	Format = "格式:",
	HexadecimalFmt = "十六進位",
	DecimalFmt = "十進位",
	Source = "來源:",
	SourceMouseover = "滑鼠指向",
	SourceTarget = "目前目標",
	SourcePlayer = "玩家自身",
	SourceFocus = "焦點目標",
	SourceCached = "快取值",
	RightClickHint = "右鍵開啟選項",
	WindowShown = "面板已顯示",
	WindowHidden = "面板已隱藏",
	WindowLocked = "面板已鎖定",
	WindowUnlocked = "面板已解鎖",
	WindowReset = "面板位置已重置",
	CacheCleared = "快取的位面ID已清除",
	FormatSwitchedHex = "已切換為十六進位顯示",
	FormatSwitchedDec = "已切換為十進位顯示",
	OpenSettings = "開啟設定",
	ButtonClearCache = "清除快取ID",
	ButtonResetPosition = "重置面板位置",
	ButtonOpenSettings = "開啟完整設定",
}

-- 坐騎資訊子模組（MountInfo.lua）文案
ns.L.MountInfo = {
	ShowMountInfo = "顯示坐騎資訊",
	ShowCollected = "顯示收藏狀態",
	ShowSource = "顯示坐騎來源",
	ShowLore = "顯示坐騎故事",
	BlankLine = "坐騎資訊前加一空行",
	CollectedPrefix = "收藏狀態:",
	Collected = "已收藏",
	NotOwned = "未擁有",
	SourcePrefix = "來源:",
	LorePrefix = "故事:",
}
