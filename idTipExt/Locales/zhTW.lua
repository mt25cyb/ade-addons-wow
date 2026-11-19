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

ns.L.Sections = {
	Items = "物品裝備",
	Spells = "法術技能",
	Units = "單位與收藏",
	Other = "其他",
}

ns.L.Tooltips = {
	faction = "開啟聲望面板時，每一列聲望條旁邊直接標出聲望陣營ID",
	questOverlay = "在任務日誌詳情面板與 NPC 任務對話框上疊加顯示任務ID",
	cooldown = "在冷卻管理器（Cooldown Manager）條目的提示框上顯示冷卻ID",
	style = "兩段式顯示：前綴居左、值居右（AddDoubleLine）；單段式顯示：每個 ID 一行靠左對齊（AddLine）",
	prefixColor = "ID 前綴標籤的顏色",
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
