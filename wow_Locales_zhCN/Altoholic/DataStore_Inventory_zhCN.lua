-- DataStore_Inventory 2026.10.14 (zhCN 汉化 / Ade)
local addonName = ...
local L = AddonFactory:SetLocale(addonName, "zhCN")
if not L then return end

L["Heroic"] = "英雄"
L["Trash Mobs"] = "小怪"


-- [ADE] 补全缺失 key
L["CLEAR_INVENTORY_TEXT"] = "自动清理公会成员的装备"
L["CLEAR_INVENTORY_DISABLED"] = "公会成员的装备会保留在数据库中，即使离线也可见。"
L["CLEAR_INVENTORY_ENABLED"] = "为节省内存，本地公会成员的背包会在每次登录时清空。"
L["CLEAR_INVENTORY_TITLE"] = "清理公会成员装备"
L["BROADCAST_AIL_TEXT"] = "登录时向公会广播我的平均物品等级"
L["BROADCAST_AIL_DISABLED"] = "完全不发送任何内容。"
L["BROADCAST_AIL_ENABLED"] = "登录时，你小号的平均物品等级会发送到公会频道。"
L["BROADCAST_AIL_TITLE"] = "广播平均物品等级"
L["EQUIP_REQ_TEXT"] = "当有人查看我某个小号的装备时收到通知。"
L["EQUIP_REQ_DISABLED"] = "完全不会显示任何内容。"
L["EQUIP_REQ_ENABLED"] = "聊天消息会告知你哪位公会成员正在查看哪个小号。"
L["EQUIP_REQ_TITLE"] = "装备请求通知"
L["%s is inspecting %s"] = "%s 正在查看 %s"
