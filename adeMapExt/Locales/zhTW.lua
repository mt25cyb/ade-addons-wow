----------------------------------------------------------------------------
-- adeMapExt zhTW 本地化（繁体中文）
-- 按 GetLocale() 覆盖 enUS 默认值；key 顺序与 enUS.lua 一致
----------------------------------------------------------------------------

local addonName = ...
local ns = _G[addonName]
if not ns or GetLocale() ~= "zhTW" then return end

ns.L.Style = "顯示風格"
ns.L.StyleSingle = "單段式顯示"
ns.L.StyleDouble = "兩段式顯示"
ns.L.PrefixClassColor = "前綴按職業著色"
ns.L.PrefixColor = "前綴顏色"
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
ns.L.StyleTip = "兩段式顯示：前綴居左、值居右；單段式顯示：前綴與值同串混色"

ns.L.Sections = {
	Panel = "地理監視面板",
	Appearance = "外觀",
	Behavior = "行為",
	PanelGroup = "面板",
}

-- 地理監視面板（Panel.lua）運行時與選項文案（自 idTipExt 1.3.0 遷移）
ns.L.Panel = {
	Section = "地理監視面板",
	ShowPanel = "顯示地理監視面板",
	Lock = "鎖定面板位置",
	AutoHide = "戰鬥中自動隱藏",
	Hexadecimal = "位面ID使用十六進制顯示",
	DetailedTooltip = "懸停面板時顯示詳細資訊",
	WorldMapPanel = "在世界地圖顯示",
	WorldMapPosition = "地圖資訊面板位置",
	WorldMapTop = "世界地圖頂部",
	WorldMapBottom = "世界地圖底部",
	WorldMapOffsetY = "Y 軸偏移",
	UpdateInterval = "更新間隔",
	FontSize = "字體大小",
	Alpha = "面板透明度",
	BackgroundColor = "背景顏色",
	BorderColor = "邊框顏色",
	BgAlpha = "背景透明度",
	BorderAlpha = "邊框透明度",
	PrefixClassColor = "前綴按職業著色",
	PrefixColor = "前綴顏色",
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
	InstanceLimitation = "副本內，可能無法檢測",
	NotDetected = "未檢測到（需要有目標/NPC）",
	PhaseMonitor = "地理監視",
	CurrentPhase = "當前位面ID:",
	Format = "格式:",
	HexadecimalFmt = "十六進制",
	DecimalFmt = "十進制",
	Source = "來源:",
	SourceMouseover = "滑鼠指向",
	SourceTarget = "當前目標",
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
	FormatSwitchedHex = "已切換為十六進制顯示",
	FormatSwitchedDec = "已切換為十進制顯示",
	OpenSettings = "開啟設定",
	ButtonClearCache = "清除快取ID",
	ButtonResetPosition = "重置面板位置",
	ButtonOpenSettings = "開啟完整設定",
}
