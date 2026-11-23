--[[
adeMapMark_Portal - 12.x 至暗之夜（Midnight）标记数据库
内容：瓦尔 & 奈格塔尔 8 点；coord 沿用 r030 实测值（/ammcoord 输出经复核有误，已回滚）
结构：与 Data_Portal_WarWithin 一致（mapID/coord/title/note），名称取三语 L 表
]]

local addonName = ...
local Data = _G[addonName].Data
local L = _G[addonName].L

Data.MidnightMarks = {
	-- 瓦尔 (12.x)
	{ mapID = 2599, coord = 60761592, title = L.MIDNIGHT_UMBRAL_BASE,       note = "taxiNodeID:3267" },
	{ mapID = 2599, coord = 30276791, title = L.MIDNIGHT_DEVOURING_INGRESS, note = "taxiNodeID:3268" },
	{ mapID = 2599, coord = 46457154, title = L.MIDNIGHT_VOID_ACROPOLIS,    note = "taxiNodeID:3269" },
	{ mapID = 2599, coord = 64626928, title = L.MIDNIGHT_STEAM_RAVINE,      note = "taxiNodeID:3270" },
	-- 奈格塔尔 (12.x)
	{ mapID = 2600, coord = 77264289, title = L.MIDNIGHT_UMBRAL_BASE,      note = "taxiNodeID:3277" },
	{ mapID = 2600, coord = 55034698, title = L.MIDNIGHT_SPOREFORGE,       note = "taxiNodeID:3278" },
	{ mapID = 2600, coord = 32274604, title = L.MIDNIGHT_NEXUS_PORT,       note = "taxiNodeID:3279" },
	{ mapID = 2600, coord = 46678290, title = L.MIDNIGHT_EXTRACTION_COAST, note = "taxiNodeID:3280" },
}
