-- BattlePetBreedID v1.42.0 · zhCN 中英对照词条主档（E 类：源码级自建多语言改造）
-- key = 英文原文逐字对齐（含 \124c 等源码字面转义）；value = zhCN 译文。
-- 本文件是唯一权威；插件内语言文件 BPBIDLocale.lua 的 zhCN 表由此生成。
-- 范围说明：
--   * BattlePetBreedID.lua 仅含 Debug 串（需 /run BPBID_Options.Debug = true 才显示），不包不译；
--   * ERR*/NEW/??? 为逻辑返回值（RetrieveBreedName 依赖 "ERR" 前缀比较），禁止翻译；
--   * "Battle Pet BreedID"（插件名）、slash 命令字面量保留英文。

return {
	---------------- BreedTooltips.lua：品种 tooltip ----------------
	["\124cFFD4A017Current Breed:\124r "] = "\124cFFD4A017当前品种：\124r ",
	[" or "] = " 或 ",
	["\124cFFD4A017Collected:\124r "] = "\124cFFD4A017已收集：\124r ",
	["\124cFFD4A017Possible Breed"] = "\124cFFD4A017可能的品种",
	["s:\124r All"] = "：\124r 全部",
	["s:\124r Unknown"] = "：\124r 未知",
	["s:\124r "] = "：\124r ",
	[":\124r "] = "：\124r ",
	[" and "] = " 和 ",
	[", and "] = " 和 ",
	[", "] = "、",
	["\124cFFD4A017Base Stats:\124r "] = "\124cFFD4A017基础属性：\124r ",
	["\124cFFD4A017Breed "] = "\124cFFD4A017品种 ",
	["*:\124r "] = "*：\124r ",
	["* at 25:\124r "] = "* 25级：\124r ",
	[" at 25:\124r "] = " 25级：\124r ",
	["L"] = "Lv",

	---------------- OptionsPanel.lua：设置面板 ----------------
	["version "] = "版本 ",
	["created by "] = "作者：",
	["Battle Pet BreedID displays the BreedID of pets in your journal, in battle, in chat links, and in item tooltips."] =
		"Battle Pet BreedID 在宠物手册、战斗中、聊天链接和物品提示中显示宠物的品种 ID。",
	["Number (3)"] = "数字 (3)",
	["Dual numbers (3/13)"] = "双数字 (3/13)",
	["Letters (B/B)"] = "字母 (B/B)",
	["The number system was created by Blizzard developers and is used internally (it was discovered via the Web API). As such, it is fairly arbitrary (why does it start at 3?), but it was all we had at first. However, some people have learned the system by numbers, and a few older resources and addons use it."] =
		"数字系统由暴雪开发者创建、在内部使用（通过 Web API 被玩家发现）。因此这套编号相当随意（为什么从 3 开始？），但这曾是我们最初仅有的一套体系。不过有些玩家已经习惯用数字记忆这套系统，少数较早的资料和插件也在使用它。",
	["Same as numbers but for people who like a reminder that we cannot figure out the sex of pets in-game. Male pets are the first number (3 - 12) and female pets are the second number (13 - 22). Remember that not all pets can be both sexes. For example, all (?) Elemental type pets are exclusively male."] =
		"与数字系统相同，但额外提醒玩家：游戏中无法确定宠物性别。雄性宠物用第一个数字（3-12），雌性宠物用第二个数字（13-22）。注意并非所有宠物都有两种性别——例如所有（?）元素类宠物只有雄性。",
	["The letter system was developed as a way to more quickly tell breeds apart from each other. Each letter represents one half of the stat contribution that makes up a breed. A few examples: S/S (#5) is a pure Speed breed. S/B (#11) is half Speed with the other half Balanced between all three stats. H/P (#7) is half Health and half Power."] =
		"字母系统是为了更快区分各品种而设计的。每个字母代表构成该品种的属性贡献的一半。几个例子：S/S（#5）是纯速度品种；S/B（#11）是半速度、另一半在三项属性间均衡分配；H/P（#7）是半生命、半力量。",
	["Show BreedIDs in the Name line..."] = "在名称行显示品种 ID……",
	["In Battle (on primary pets)"] = "战斗中（双方主要宠物）",
	["On in-battle tooltips"] = "战斗内提示的标题",
	["In Item tooltips"] = "物品提示中",
	["In Chat Link tooltips"] = "聊天链接提示中",
	["In the Pet Journal scrolling frame"] = "宠物手册滚动列表中",
	["Color Pet Journal scrolling frame by rarity."] = "按品质为宠物手册滚动列表着色",
	["In the Pet Journal description tooltip"] = "宠物手册说明提示中",
	["Color Pet Journal tooltip headers by rarity"] = "按品质为宠物手册提示标题着色",
	["Enable Battle Pet BreedID Tooltips"] = "启用品种 ID 提示",
	["Show Battle Pet BreedID Tooltips..."] = "显示品种 ID 提示……",
	["In Battle"] = "战斗中",
	["On Items"] = "物品上",
	["On Chat Links"] = "聊天链接上",
	["In the Pet Journal"] = "宠物手册中",
	["In Tooltips, show..."] = "在提示中显示……",
	["Current pet's breed"] = "当前宠物的品种",
	["Current pet's possible breeds"] = "当前宠物的可能品种",
	["Current's pet collected breeds"] = "当前宠物的已收集品种",
	["Pet species' base stats"] = "该物种的基础属性",
	["Current breed's base stats"] = "当前品种的基础属性",
	["All breed's base stats"] = "全部品种的基础属性",
	["Current breed's stats at level 25"] = "当前品种 25 级属性",
	["Always assume pet will be Rare at level 25"] = "25 级时始终按精良品质计算",
	["All breeds' stats at level 25"] = "全部品种 25 级属性",
	["Fix Bugs:"] = "修复 Bug：",
	["Defaults"] = "默认",
}
