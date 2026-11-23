--[[
adeMapMark_Portal - Core（业务代码：标记汇总 / Provider 注册）
体系：ADE v6.5；adeMapMark 的第一个 Provider 数据包
按资料片拆分的数据：Data_Portal_Legion.lua（7.x）、Data_Portal_WarWithin.lua（11.x）、Data_Portal_Midnight.lua（12.x）
计划：_docs/plans/adeMapMark-dev-plan.md §九
]]

local addonName = ...
local PACK_NAME = addonName

-- 包内跨文件共享命名空间：本文件先加载建表，Locales 填 L、数据文件填 Data
local ns = {}
_G[PACK_NAME] = ns
ns.L = {}
local L = ns.L
local Data = {}
ns.Data = Data

-- 三份数据库共用的数据常量（颜色/图标/尺寸/可见性）
Data.Common = {
    COLOR_ORANGE     = { r = 1.0, g = 0.4863, b = 0.0392, a = 1.0 },
    COLOR_WHITE      = { r = 1.0, g = 1.0, b = 1.0, a = 1.0 },
    ICON_FMARGUS     = "ATLAS:FlightMasterArgus",
    ICON_ANCIENT     = "ATLAS:flightmaster_ancientwaygate-taxinode_neutral",
    ICON_RIFT        = "ATLAS:poi-rift1",
    TEXT_SIZE        = 10,
    IS_VISIBLE       = true,
}
local C = Data.Common

-- 独立配置库（由 adeMapMark 的 GetSubDB 接管）
_G[PACK_NAME .. "DB"] = _G[PACK_NAME .. "DB"] or {
    enabled = true, favorites = {}, visibility = {}, collapsed = {}, overrides = {},
}

-- 标记字段约定：iconSize（图标尺寸）/ textSize（大地图文字字号）不在包内硬编码，
-- 缺省由宿主默认值接管；用户也可在面板为单个标记设置覆写。

-- 数据表只存各记录特有的字段；公共值在此补齐（全局默认 + 按库指定赋值）
local function AddMarks(result, marks, color, icon)
    for _, raw in ipairs(marks) do
        tinsert(result, {
            mapID     = raw.mapID,
            coord     = raw.coord,
            title     = raw.title,
            note      = raw.note or "",
            color     = color or C.COLOR_ORANGE,
            icon      = raw.icon or icon,
            isVisible = true,
            textSize  = C.TEXT_SIZE,
        })
    end
end

local function GetAllMarks()
    local result = {}
    AddMarks(result, Data.LegionMarks)                                        -- 橙色默认、无默认图标
    AddMarks(result, Data.WarWithinMarks, C.COLOR_WHITE, C.ICON_ANCIENT)   -- 11.x 导管：白色 + 导管图标
    AddMarks(result, Data.MidnightMarks, nil, C.ICON_FMARGUS)            -- 12.x：橙色 + 三角图标
    return result
end

-- ---------------------------------------------------------------------------
-- 注册为 adeMapMark 的 Provider（兼容双向加载顺序）
-- ---------------------------------------------------------------------------
local function TryRegister()
    if not _G.adeMapMark or not _G.adeMapMark.RegisterMarkProvider then return false end
    local shortName = L.PROVIDER_SHORT_NAME
    _G[PACK_NAME .. "_SHORT_NAME"] = shortName  -- 注册前落到全局，供主插件读取
    _G.adeMapMark:RegisterMarkProvider({
        name = PACK_NAME,
        title = L.PROVIDER_TITLE,
        shortName = shortName,
        version = 1,
        readOnly = true,
        GetMarks = GetAllMarks,
    })
    return true
end

local f = CreateFrame("Frame")
f:RegisterEvent("ADDON_LOADED")
f:RegisterEvent("PLAYER_LOGIN")
f:SetScript("OnEvent", function(self, event, loaded)
    if TryRegister() then
        self:UnregisterEvent("ADDON_LOADED")
        self:UnregisterEvent("PLAYER_LOGIN")
    end
end)
