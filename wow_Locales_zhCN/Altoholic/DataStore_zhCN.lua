-- DataStore 2026.10.14 (zhCN 汉化 / Ade)
local addonName = ...
local L = AddonFactory:SetLocale(addonName, "zhCN")
if not L then return end


-- [ADE] 补全缺失 key
L["Disabled"] = "禁用"
L["Enabled"] = "启用"
L["Memory used for %d |4character:characters;:"] = "内存占用 %d |4character:characters;:"
