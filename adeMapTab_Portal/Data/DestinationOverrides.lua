local _, addon = ...
local L = addon.L

-- 目的地补充说明表（用户 2026-10-29）。
--
-- 有些传送的目的地读不出来（数据里没有 destination），或者读出来的地图名没有意义
-- （随机、动态、目的地不止一个），这里逐个指定 tooltip 上要显示的目的地文字。
--
-- key 用 Catalog 条目的 spellID（Services/Catalog.lua 的 item.spellID）。
--
-- 字段：
--   name    locale key，作为「地图名称」拼进 传送到「{分组} - {name}」
--   whole   true：整体显示为 传送到「{name}」，不拼分组前缀
--   hide    true：整行都不显示
--   maps    额外匹配的地图 ID —— 区域按钮在这些地图上也出现
--   nameFn  运行时决定文字（住宅区的「去 / 回」、根须漫步的「去 / 回」）
addon.DestinationOverrides = {
	-- ===== 角色分组（首页）=====
	-- 炉石不在这里：条目是动态生成的，靠 entry.isRandomHearthstone 识别。

	-- 住宅区家宅：联盟 / 部落两个条目共用 spellID 1233637（Data/Teleports.lua:78-87），
	-- 用 nameFn 按「在家 / 不在家」切成两段文字。
	[1233637] = {
		nameFn = function(entry)
			if entry.housingFaction and addon.Housing and addon.Housing.CanReturn(entry.housingFaction) then
				return L["DEST_HOUSING_RETURN"]
			end
			return entry.housingFaction == "Horde" and L["DEST_HOUSING_HORDE"] or L["DEST_HOUSING_ALLIANCE"]
		end,
	},
	-- 哈籁恩达尔根须漫步（种族 Harronir）。传送之后技能条上会换成返回法术 1238695，
	-- 用它在不在技能书里判断此刻是「去」还是「回」。
	[1238686] = {
		nameFn = function()
			if C_SpellBook and C_SpellBook.IsSpellInSpellBook and C_SpellBook.IsSpellInSpellBook(1238695) then
				return L["DEST_ROOTWALK_BACK"]
			end
			return L["DEST_ROOTWALK"]
		end,
	},
	[265225] = { name = "DEST_DRILL" }, -- 钻探机（种族：黑铁矮人）
	[312372] = { name = "DEST_CAMP" }, -- 返回营地（种族：狐人）

	-- ===== 玩具 / 道具 =====
	-- 光帷召回道标（玩具 276371）：目的地是瓦尔(2599) 或 奈格塔尔(2600)，
	-- 区域按钮在这两个地图时也要出现，因此额外给 maps。
	[1299515] = { name = "DEST_VOID_CAMP", maps = { 2599, 2600 } },
	[1278093] = { name = "DEST_BOUNTIFUL", whole = true }, -- 钝顿的丰饶旅行方式（玩具 266370）
	[467470] = { name = "DEST_DELVE", whole = true }, -- 地下堡机器人7001型（玩具 230850）
	-- 飞行管理员的哨子（玩具 141605）：数据里这条的 spellID 是 227334
	-- （Data/Teleports.lua:643；用户给的 253937 在数据表里查不到，以数据表为准）。
	[227334] = { name = "DEST_FLIGHT_MASTER" },
	[82674] = { name = "DEST_RANDOM", whole = true }, -- 阿古斯的最后一件圣物（玩具 64457）
	[194812] = { hide = true }, -- 百变之镜（玩具 129929）：不显示目的地整行
	[189838] = { name = "DEST_NAVAL_DOCK" }, -- 海军上将的罗盘（道具 128353）
	[171253] = { name = "DEST_GARRISON" }, -- 要塞炉石（玩具 110560）
	[39937] = { name = "DEST_INN" }, -- 红宝石靴子（道具 28585）：同炉石，绑定旅店
	[139437] = { name = "DEST_BRAWL_CLUB" }, -- 黄铜指虎（道具 95051）联盟版
	[139432] = { name = "DEST_BRAWL_CLUB" }, -- 黄铜指虎（道具 95050）部落版
}
