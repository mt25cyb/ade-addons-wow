----------------------------------------------------------------------------
-- idTipExt enUS 本地化（默认语言）
-- 所有客户端先加载本文件填充英文默认值，zhCN / zhTW 按 GetLocale() 覆盖
-- key 顺序与 Core.lua 的文案表骨架 / ns.kinds 定义顺序一致
-- 零依赖：不引 AceLocale，直接填充 Core.lua 的 ns.L
----------------------------------------------------------------------------

local addonName = ...
local ns = _G[addonName]
if not ns then return end

-- ns.kinds 的英文标签已在 Core.lua 定义，默认语言无需覆盖

ns.L.Enabled = "Enabled"
ns.L.Types = "Types"
ns.L.Style = "Display Style"
ns.L.BlankLineBeforeFirst = "Blank Line Before First Info"
ns.L.StyleSingle = "Single-line Segment"
ns.L.StyleDouble = "Two-segment"
ns.L.PrefixColor = "Prefix Color"
ns.L.ShowCaster = "Show Caster"
ns.L.CasterClassColor = "Color Caster Name by Class"
ns.L.PrefixClassColor = "Color Prefixes by Class"
ns.L.WorldMapPanel = "Show on World Map"
ns.L.WorldMapPosition = "Map Info Panel Position"
ns.L.WorldMapTop = "Above World Map"
ns.L.WorldMapBottom = "Below World Map"
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

ns.L.Sections = {
	Items = "Items",
	Spells = "Spells",
	Units = "Units & Collections",
	Other = "Other",
	Panel = "Geo Monitor Panel",
}

ns.L.Tooltips = {
	faction = "Shows the faction ID next to each row in the reputation panel",
	questOverlay = "Shows the quest ID on the quest log details and NPC quest dialog",
	cooldown = "Shows the cooldown ID of Cooldown Manager entries",
	style = "Two-segment: prefix left, value right (AddDoubleLine). Single-line: one segment per ID (AddLine)",
	prefixColor = "Color of the ID prefix label",
}

-- 地理监视面板（GeoWatcher.lua）运行时与选项文案
ns.L.Panel = {
	Section = "Phase Monitor Panel",
	ShowPanel = "Show Phase Monitor Panel",
	Lock = "Lock Panel Position",
	AutoHide = "Auto Hide in Combat",
	Hexadecimal = "Use Hexadecimal Format (Phase ID)",
	DetailedTooltip = "Show Detailed Tooltip on Hover",
	WorldMapPanel = "Show on World Map",
	WorldMapPosition = "Map Info Panel Position",
	WorldMapTop = "Above World Map",
	WorldMapBottom = "Below World Map",
	UpdateInterval = "Update Interval",
	FontSize = "Font Size",
	Alpha = "Panel Opacity",
	BackgroundColor = "Background Color",
	BorderColor = "Border Color",
	BgAlpha = "Background Opacity",
	BorderAlpha = "Border Opacity",
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

-- 坐骑信息子模块（MountInfo.lua）文案
ns.L.MountInfo = {
	ShowMountInfo = "Show Mount Info",
	ShowCollected = "Show Collection Status",
	ShowSource = "Show Mount Source",
	ShowLore = "Show Mount Story",
	BlankLine = "Blank Line Before Mount Info",
	CollectedPrefix = "Collection:",
	Collected = "Collected",
	NotOwned = "Not Owned",
	SourcePrefix = "Source:",
	LorePrefix = "Story:",
}
