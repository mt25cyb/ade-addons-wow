-- 简体中文覆盖英文默认文案（措辞对齐 EUI zhCN 同功能条目）。
local _, addon = ...
if GetLocale() ~= "zhCN" then return end
local L = addon.L
L["PERF_STATE_ON"] = "已启用"
L["PERF_STATE_OFF"] = "已关闭"
L["PERF_CMD_ENABLED"] = "adePerfGuard 已启用：每次会话首次进入副本时检查。"
L["PERF_CMD_DISABLED"] = "adePerfGuard 已关闭：不再弹出提醒。"
L["PERF_CMD_USAGE"] = "用法：/adeperfguard on|off"
L["PERF_CMD_CVARS"] = "taintLog=%s，scriptProfile=%s"
L["PERF_POPUP_TAINT"] = "taintLog 控制台变量已启用。"
L["PERF_POPUP_PROFILE"] = "scriptProfile 控制台变量已启用。"
L["PERF_POPUP_BOTH"] = "taintLog 和 scriptProfile 这两个控制台变量均已启用。"
L["PERF_POPUP_DESC"] = "这会降低性能，除非您正在捕获错误报告，否则应将其关闭。"
L["PERF_POPUP_CONFIRM"] = "禁用并重载"
L["PERF_POPUP_IGNORE"] = "忽略"
