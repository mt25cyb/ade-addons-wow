-- 插件内部只通过 addon 表（TOC vararg 私有表）共享数据，不写任何 _G 全局。
-- v6.5：模块占位与 v5 一致；SettingsPage 独立设置页已删除（口径：设置只留世界地图 Tab 内齿轮页）。
local _, addon = ...
addon.Database = {}
addon.Settings = {} -- 世界地图 Tab 内齿轮设置页（UI/SettingsPanel.lua）；独立设置页已删除
addon.Catalog = {}
addon.Scanner = {}
addon.Stats = {}
addon.Roster = {}
addon.MapPanel = {}
addon.MinimapIcon = {}
addon.RosterWindow = {}
addon.State = {} -- 本次登录的临时状态，不写入 SavedVariables。
addon.Player = {
    unitClass = select(2, UnitClass("player")),
    unitRace = select(2, UnitRace("player")),
    defaultFont = STANDARD_TEXT_FONT,
}
