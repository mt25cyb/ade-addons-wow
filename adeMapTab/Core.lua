--[==[ adeMapTab / Core.lua
纯库插件入口（ADE v6.5）：只校验公共函数库已注册。
本插件刻意不注册设置页、不注册小地图图标、不声明 SavedVariables、不创建任何可见 UI：
落地功能全部由子插件 adeMapTab_Delve / adeMapTab_Portal 承载（迁移计划 §2.4 / §2.5）。

v5 原本依赖 _G.ADE:NewAddon；v6.5 去掉框架依赖，改为私有 addon 表并在此直接初始化：
TOC 已保证 LibStub → LibWorldMapTabs → Public/MapTab.lua 先于本文件加载。 ]==]
local addonName, ns = ...

local addon = ns.addon or {}
ns.addon = addon

function addon:OnInitialize()
    -- 子插件的 ## Dependencies: adeMapTab 保证其晚于本插件加载，
    -- 因此取 LibStub("AdeMapTab-1.0") 时必然已注册（非兜底，仅校验加载顺序）。
    ns.MapTab = LibStub("AdeMapTab-1.0")
    ns.TabLib = LibStub("LibWorldMapTabs")
end

addon:OnInitialize()
