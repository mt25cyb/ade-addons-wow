--[[
adeMapMark_Portal - 11.x 地心之战（The War Within）标记数据库
内容：卡雷什•相位导管 14 点（2371 十三条 + 2472 一条）；coord 沿用 r030 实测值
      （/ammcoord 输出经复核有误，已回滚）；名称引用三语 L 表
说明：图标/颜色/可见性/尺寸由 Core.lua 按库指定赋值，note 为各点特有
]]

local addonName = ...
local Data = _G[addonName].Data
local L = _G[addonName].L

Data.WarWithinMarks = {
	-- 塔扎维什，帷纱集市
	{ mapID = 2472, coord = 46805690, title = L.CONDUIT_TAZAVESH, 		 note = "taxiNodeID:3145" },
	{ mapID = 2371, coord = 65908010, title = L.CONDUIT_TAZAVESH_KARESH, note = "taxiNodeID:3029" },
	-- 卡雷什
	{ mapID = 2371, coord = 75903310, title = L.CONDUIT_OASIS, 			note = "taxiNodeID:3146" },
	{ mapID = 2371, coord = 60202900, title = L.CONDUIT_SHAN_DORAH, 	note = "taxiNodeID:3147" },
	{ mapID = 2371, coord = 45202390, title = L.CONDUIT_SHADOW_POINT, 	note = "taxiNodeID:3155" },
	{ mapID = 2371, coord = 51204860, title = L.CONDUIT_SERRATED_PEAKS, note = "taxiNodeID:3156" },
	{ mapID = 2371, coord = 50403640, title = L.CONDUIT_ZOSHUUL, 		note = "taxiNodeID:3157" },
	{ mapID = 2371, coord = 65404800, title = L.CONDUIT_LUNNALL, 		note = "taxiNodeID:3158" },
	{ mapID = 2371, coord = 77204890, title = L.CONDUIT_NORTH_SUFAAD, 	note = "taxiNodeID:3159" },
	{ mapID = 2371, coord = 58905790, title = L.CONDUIT_NAAKROA, 		note = "taxiNodeID:3160" },
	{ mapID = 2371, coord = 56202150, title = L.CONDUIT_LAACUNA, 		note = "taxiNodeID:3161" },
	{ mapID = 2371, coord = 53902670, title = L.CONDUIT_UNTETHERED, 	note = "taxiNodeID:3162" },
	{ mapID = 2371, coord = 51406710, title = L.CONDUIT_YAATHRON, 		note = "taxiNodeID:3163" },
	{ mapID = 2371, coord = 53806360, title = L.CONDUIT_HOSAAS, 		note = "taxiNodeID:3164" },
}
