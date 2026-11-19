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

ns.L.Sections = {
	Items = "Items",
	Spells = "Spells",
	Units = "Units & Collections",
	Other = "Other",
}

ns.L.Tooltips = {
	faction = "Shows the faction ID next to each row in the reputation panel",
	questOverlay = "Shows the quest ID on the quest log details and NPC quest dialog",
	cooldown = "Shows the cooldown ID of Cooldown Manager entries",
	style = "Two-segment: prefix left, value right (AddDoubleLine). Single-line: one segment per ID (AddLine)",
	prefixColor = "Color of the ID prefix label",
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
