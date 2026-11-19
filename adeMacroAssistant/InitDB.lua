--[==[ adeMacroAssistant / InitDB.lua
默认配置（集中管理，经 v5 框架 ADE:NewDB 装配到 ns.db）。

作为「单一真源」（single source of truth）：本文件**先于**各代码文件加载，自动宏宏体 /
宏界面布局等默认值都在此内联定义；其他模块（AutoMacro / MacroUIResize 等）改为从
ns.defaults 取用，不再由 InitDB 反向引用各模块的常量表（如旧 DEFAULTS / LAYOUT_DEFAULTS /
DEFAULT_TEXT）。

ns.defaults.profile 结构必须与 v4 完全一致（automacro/macroresize/macrosearch/uiScale/minimap），
否则旧存档不兼容。 ]==]
local addonName = ...
local AM = _G.adeMacroAssistant or {}
_G.adeMacroAssistant = AM
local ns = AM
local tinsert = table.insert

-- ADE v6.5：按客户端语言选定私有 locale 表（三个 locale 文件已先于本文件加载）。
ns.L = ns.Loc and (ns.Loc[GetLocale()] or ns.Loc.enUS) or {}
local L = ns.L

-- 事件总线（自建，替代 v4 的 ADE.RegisterCallback / ADE.Fire）
-- 用法：ns.Bus.Sub("EVENT", fn) 订阅 / ns.Bus.Fire("EVENT", ...) 发布。
local subscribers = {}
ns.Bus = {
    Fire = function(_, event, ...)
        local t = subscribers[event]
        if not t then return end
        for _, fn in ipairs(t) do fn(...) end
    end,
    Sub = function(_, event, fn)
        subscribers[event] = subscribers[event] or {}
        tinsert(subscribers[event], fn)
    end,
}

-- 局部深拷贝（v5 无 ADE:CopyTable）：供 InitDB 默认值与 Settings 重置复用。
local function CopyTable(t)
    if type(t) ~= "table" then return t end
    local c = {}
    for k, v in pairs(t) do
        c[k] = CopyTable(v)
    end
    return c
end
ns.CopyTable = CopyTable

-- 重置子树：清空 node 后按 defaults 重建（与 AceDB 默认值同构），移除多余字段。
-- v5 无 ADE:ResetSubtree，故在此定义并挂 ns 复用。
local function ResetSubtree(node, defaults)
    wipe(node)
    for k, v in pairs(defaults) do
        node[k] = CopyTable(v)
    end
end
ns.ResetSubtree = ResetSubtree

-- 默认配置：全部在此内联（单一真源），不反向引用任何模块常量表。
-- 宏基名（base）取 locale（L["DEFAULT_NAME_*"]），保证显示名随语言切换。
-- 注意：db.profile 在 PLAYER_LOGIN 前为 nil，需 profile 的模块逻辑须挂 PLAYER_LOGIN 回调。
ns.defaults = {
    profile = {
        macroresize = {
            enabled = true,
            layoutMode = "vertical",   -- "vertical" | "horizontal"（默认垂直＝原生布局走向）
            -- addTextY 只作用于垂直布局，故统一存在顶层；cols / rows 按布局分开独立保存，
            -- 切换布局时读到的是该布局自己的一组值（用户 2026-10-31）。
            addTextY = 40,             -- 文本区额外高度默认（垂直布局）
            -- 两套布局默认参数（与 MacroUIResize LAYOUT_SPECS 的 cols/rows 一致；
            -- 约束 min/max 仍在 MacroUIResize 维护，值在此集中）。
            vertical   = {
                buttonCols = 8,
                buttonRows = 4
            },
            horizontal = {
                buttonCols = 6,
                buttonRows = 8
            },
        },
        macrosearch = {                -- 搜索栏（★新增）
            enabled = true,            -- UI 呈现名 showSearchBar，默认 true
            includeBody = false,       -- 搜索是否包含宏体
        },
        automacro = {
            enabled = true,
            prefixEnabled = true,
            prefixChar = "'",
            cleanse = {
                enabled = true,
                base = L["DEFAULT_NAME_CLEANSE"],
                body = "#showtooltip\n/tar [@mouseover,help,nodead] [@target,help,nodead] [@targettarget,help,nodead] [@player]\n/use CLEANSE_SPELL\n/targetlasttarget",
            },
            purge = {
                enabled = true,
                base = L["DEFAULT_NAME_PURGE"],
                body = "#showtooltip PURGE_SPELL\n/use [@target,harm,nodead] [@targettarget,harm,nodead] PURGE_SPELL",
            },
            dispel = {
                enabled = true,
                base = L["DEFAULT_NAME_DISPEL"],
                body = "#showtooltip [@mouseover,help,nodead] CLEANSE_SPELL;PURGE_SPELL\n/use [@mouseover,help,nodead] CLEANSE_SPELL;[@target,harm,nodead] PURGE_SPELL; [@target,help,nodead] CLEANSE_SPELL",
            },
            interrupt = {
                enabled = true,
                base = L["DEFAULT_NAME_INTERRUPT"],
                body = "#showtooltip INTERRUPT_SPELL\n/stopcasting\n/use [@mouseover,harm,nodead][harm,nodead] INTERRUPT_SPELL",
            },
            resurrection = {
                enabled = true,
                base = L["DEFAULT_NAME_RESURRECTION"],
                body = "#showtooltip RESURRECTION_SPELL\n/stopcasting\n/use [@mouseover,help,dead][help,dead] RESURRECTION_SPELL",
            },
            sprint = {
                enabled = true,
                base = L["DEFAULT_NAME_SPRINT"],
                body = "#showtooltip SPRINT_SPELL\n/stopcasting\n/use SPRINT_SPELL",
            },
            taunt = {
                enabled = true,
                base = L["DEFAULT_NAME_TAUNT"],
                body = "#showtooltip TAUNT_SPELL\n/use [@mouseover,harm,nodead][harm,nodead] TAUNT_SPELL",
            },
        },
        uiScale = 1,                   -- 设置窗口整体 UI 缩放（1 = 原始大小；部分控件按此缩放）
        minimap = {
            hide = false,              -- 是否隐藏小地图图标（★已移除小地图图标，此键保留兼容旧存档）
            minimapPos = 220,          -- 小地图图标弧度位置
            radius = 0                -- 图标与地图边缘距离
        },
    },
}
