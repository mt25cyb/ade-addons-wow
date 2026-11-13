-- DataStore_Auctions 2026.10.14 (zhCN 汉化 / Ade)
local addonName = ...
local L = AddonFactory:SetLocale(addonName, "zhCN")
if not L then return end


-- [ADE] 补全缺失 key
L["CLEAR_EXPIRED_ITEMS_DISABLED"] = "过期物品会保留在数据库中，直到玩家下次访问拍卖行。"
L["CLEAR_EXPIRED_ITEMS_ENABLED"] = "过期物品会从数据库中自动删除。"
L["CLEAR_EXPIRED_ITEMS_LABEL"] = "自动清理过期拍卖与竞标"
L["CLEAR_EXPIRED_ITEMS_TITLE"] = "清理拍卖行物品"
L["LAST_VISIT_SLIDER_TOOLTIP"] = "当拍卖行超过此天数未被访问时发出警告"
L["LAST_VISIT_CHECK_DISABLED"] = "不会检查上次访问拍卖行的时间。"
L["LAST_VISIT_CHECK_ENABLED"] = "将检查每个角色上次访问拍卖行的时间。超过此天数的角色会向客户端插件发送通知。"
L["LAST_VISIT_CHECK_LABEL"] = "上次访问拍卖行"
L["LAST_VISIT_CHECK_TITLE"] = "检查上次访问时间"
