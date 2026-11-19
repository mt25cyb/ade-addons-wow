local _, addon = ...

-- 区域传送按钮的**补充**索引：只放 Data/Teleports.lua 表达不了的东西。
-- Teleports.lua 一条传送只能写一个 destination，而德鲁伊梦境行走有多个落点，
-- 这里列出其余落点（来源：WeakAura「ZachLT3 + Eathox Map Teleports 11.0.7.1」，见 _docs/_WA-Profile.txt）。
-- 英雄之路副本传送（57 条）与法师传送门（25 条）Teleports.lua 已完整覆盖，不在此重复。
addon.ZoneTeleportExtraMaps = {
	{ spellID = 193753, maps = { 2239, 747, 641, 69, 116, 198, 47, 26, 80 } }, -- 梦境行走
}
