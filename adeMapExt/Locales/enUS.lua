----------------------------------------------------------------------------
-- adeMapExt enUS 本地化（默认语言）
-- 所有客户端先加载本文件填充英文默认值，zhCN / zhTW 按 GetLocale() 覆盖
-- 零依赖：直接填充 Core.lua 的 ns.L 骨架
----------------------------------------------------------------------------

local addonName = ...
local ns = _G[addonName]
if not ns then return end

ns.L.Style = "Display Style"
ns.L.StyleSingle = "Single-line Segment"
ns.L.StyleDouble = "Two-segment"
ns.L.PrefixClassColor = "Color Prefixes by Class"
ns.L.PrefixColor = "Prefix Color"
ns.L.GrowDirection = "Growth Direction"
ns.L.GrowUp = "Grow Up"
ns.L.GrowDown = "Grow Down"
ns.L.MapNameMode = "Map Name Display"
ns.L.MapNameNone = "Don't Show Name"
ns.L.MapNameInline = "Same Line"
ns.L.MapNameSeparate = "Separate Line"
ns.L.PanelWidth = "Panel Width"
ns.L.ShowPhaseID = "Show Phase ID"
ns.L.ShowMapID = "Show Map ID"
ns.L.ShowWorldMapID = "Show World Map ID"
ns.L.ShowInstanceID = "Show Instance ID"
ns.L.ShowZoneID = "Show Zone ID"
ns.L.StyleTip = "Two-segment: prefix left, value right. Single-line: one segment per row"

ns.L.Sections = {
	Panel = "Geo Monitor Panel",
	Appearance = "Appearance",
	Behavior = "Behavior",
	PanelGroup = "Panels",
}

-- 地理监视面板（Panel.lua）运行时与选项文案（自 idTipExt 1.3.0 迁移）
ns.L.Panel = {
	Section = "Geo Monitor Panel",
	ShowPanel = "Show Geo Monitor Panel",
	Lock = "Lock Panel Position",
	AutoHide = "Auto Hide in Combat",
	Hexadecimal = "Use Hexadecimal Format (Phase ID)",
	DetailedTooltip = "Show Detailed Tooltip on Hover",
	WorldMapPanel = "Show on World Map",
	WorldMapPosition = "Map Info Panel Position",
	WorldMapTop = "Above World Map",
	WorldMapBottom = "Below World Map",
	WorldMapOffsetY = "Y Offset",
	UpdateInterval = "Update Interval",
	FontSize = "Font Size",
	Alpha = "Panel Opacity",
	BackgroundColor = "Background Color",
	BorderColor = "Border Color",
	BgAlpha = "Background Opacity",
	BorderAlpha = "Border Opacity",
	PrefixClassColor = "Color Prefixes by Class",
	PrefixColor = "Prefix Color",
	Initializing = "Initializing...",
	DragToMove = "Drag to move",
	PhasePrefix = "PhaseID:",
	MapPrefix = "MapID:",
	MapLabel = "Map:",
	WorldMapPrefix = "WorldMapID:",
	WorldMapLabel = "World Map:",
	InstancePrefix = "InstanceID:",
	ZonePrefix = "ZoneID:",
	SecretValue = "Hidden (Secret Value)",
	InstanceLimitation = "In instance, may not detect",
	NotDetected = "Not Detected (Need Target/NPC)",
	PhaseMonitor = "Phase Monitor",
	CurrentPhase = "Current Phase ID:",
	Format = "Format:",
	HexadecimalFmt = "Hexadecimal",
	DecimalFmt = "Decimal",
	Source = "Source:",
	SourceMouseover = "Mouseover",
	SourceTarget = "Target",
	SourcePlayer = "Player",
	SourceFocus = "Focus",
	SourceCached = "Cached",
	RightClickHint = "Right-click for options",
	WindowShown = "Panel shown",
	WindowHidden = "Panel hidden",
	WindowLocked = "Panel locked",
	WindowUnlocked = "Panel unlocked",
	WindowReset = "Panel position has been reset",
	CacheCleared = "Cached phase ID has been cleared",
	FormatSwitchedHex = "Switched to hexadecimal display",
	FormatSwitchedDec = "Switched to decimal display",
	OpenSettings = "Open Settings",
	ButtonClearCache = "Clear Cached ID",
	ButtonResetPosition = "Reset Panel Position",
	ButtonOpenSettings = "Open Settings",
}
