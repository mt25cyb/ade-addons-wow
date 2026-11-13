-- DataStore_Characters 2026.10.14 (zhCN 汉化 / Ade)
local addonName = ...
local L = AddonFactory:SetLocale(addonName, "zhCN")
if not L then return end


-- [ADE] 补全缺失 key
L["HIDE_PLAYTIME_DISABLED"] = "将显示真实游戏时间。"
L["HIDE_PLAYTIME_ENABLED"] = "将显示为零天的游戏时间。"
L["HIDE_PLAYTIME_TEXT"] = "隐藏真实游戏时间。"
L["HIDE_PLAYTIME_TITLE"] = "隐藏真实游戏时间"
L["REQUEST_PLAYTIME_DISABLED"] = "登录时不会查询游戏时间。将向客户端插件发送上次已知值。"
L["REQUEST_PLAYTIME_ENABLED"] = "每次登录时都会查询游戏时间。"
L["REQUEST_PLAYTIME_TEXT"] = "登录时请求游戏时间。"
L["REQUEST_PLAYTIME_TITLE"] = "请求游戏时间"
