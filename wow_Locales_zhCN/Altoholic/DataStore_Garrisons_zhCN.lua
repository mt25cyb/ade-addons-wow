-- DataStore_Garrisons 2026.10.14 (zhCN 汉化 / Ade)
local addonName = ...
local L = AddonFactory:SetLocale(addonName, "zhCN")
if not L then return end


-- [ADE] 补全缺失 key
L["REPORT_LEVEL_LABEL"] = "在 %s%s 处报告"
L["REPORT_LEVEL_TOOLTIP"] = "当未收集资源的等级高于此值时发出报告"
L["REPORT_UNCOLLECTED_DISABLED"] = "不会报告任何内容。"
L["REPORT_UNCOLLECTED_ENABLED"] = "登录时，未收集资源超过 400 的小号将报告到聊天框。"
L["REPORT_UNCOLLECTED_LABEL"] = "报告未收集资源"
L["REPORT_UNCOLLECTED_TITLE"] = "报告未收集资源"
L["UNCOLLECTED_RESOURCES_ALERT"] = "%s 有 %s 个未收集资源"
