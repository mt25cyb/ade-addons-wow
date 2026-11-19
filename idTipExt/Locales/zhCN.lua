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

ns.L.Sections = {
	Items = "物品装备",
	Spells = "法术技能",
	Units = "单位与藏品",
	Other = "其它",
}

ns.L.Tooltips = {
	faction = "打开声望面板时，每一行声望条旁边直接标出声望阵营ID",
	questOverlay = "在任务日志详情面板与 NPC 任务对话框上叠加显示任务ID",
	cooldown = "在冷却管理器（Cooldown Manager）条目的提示框上显示冷却ID",
	style = "两段式显示：前缀居左、值居右（AddDoubleLine）；单段式显示：每个 ID 一行左对齐（AddLine）",
	prefixColor = "ID 前缀标签的颜色",
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
