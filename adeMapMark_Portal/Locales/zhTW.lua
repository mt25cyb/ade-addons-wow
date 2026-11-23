-- adeMapMark_Portal - 繁體中文
if GetLocale() ~= "zhTW" then return end
local addonName = ...
local L = _G[addonName].L

L.PROVIDER_TITLE = "傳送點資料包"
L.PROVIDER_SHORT_NAME = "傳送點"

-- 11.x 卡雷什•相位导管（暂用简体，待用户提供繁体译名）
L.CONDUIT_TAZAVESH = "塔扎维什，帷纱集市"
L.CONDUIT_OASIS = "绿洲"
L.CONDUIT_SHAN_DORAH = "珊多拉"
L.CONDUIT_SHADOW_POINT = "暗影营"
L.CONDUIT_SERRATED_PEAKS = "锯刃峰"
L.CONDUIT_ZOSHUUL = "佐舒尔瞭望台"
L.CONDUIT_LUNNALL = "伦娜尔河"
L.CONDUIT_NORTH_SUFAAD = "北苏法德"
L.CONDUIT_NAAKROA = "纳克罗阿"
L.CONDUIT_LAACUNA = "莱阿库纳之隙"
L.CONDUIT_UNTETHERED = "无拘之域"
L.CONDUIT_YAATHRON = "亚斯隆废墟"
L.CONDUIT_HOSAAS = "霍赛斯之眠"
L.CONDUIT_TAZAVESH_KARESH = "塔扎维什，卡雷什"

-- 12.x 瓦尔 & 奈格塔尔（Midnight，暂用简体，待用户提供繁体译名）
L.MIDNIGHT_UMBRAL_BASE = "晦暗大本营"
L.MIDNIGHT_DEVOURING_INGRESS = "贪噬侵临点"
L.MIDNIGHT_VOID_ACROPOLIS = "虚空卫城"
L.MIDNIGHT_STEAM_RAVINE = "蒸雾低地"
L.MIDNIGHT_SPOREFORGE = "孢子熔炉"
L.MIDNIGHT_NEXUS_PORT = "节点港口"
L.MIDNIGHT_EXTRACTION_COAST = "萃取海岸"
