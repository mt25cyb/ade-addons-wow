-- 繁體中文覆蓋英文預設文案。
local _, addon = ...
if GetLocale() ~= "zhTW" then return end
local L = addon.L
L["PERF_STATE_ON"] = "已啟用"
L["PERF_STATE_OFF"] = "已關閉"
L["PERF_CMD_ENABLED"] = "adePerfGuard 已啟用：每次會話首次進入副本時檢查。"
L["PERF_CMD_DISABLED"] = "adePerfGuard 已關閉：不再彈出提醒。"
L["PERF_CMD_USAGE"] = "用法：/adeperfguard on|off"
L["PERF_CMD_CVARS"] = "taintLog=%s，scriptProfile=%s"
L["PERF_POPUP_TAINT"] = "taintLog 主控台變數已啟用。"
L["PERF_POPUP_PROFILE"] = "scriptProfile 主控台變數已啟用。"
L["PERF_POPUP_BOTH"] = "taintLog 與 scriptProfile 兩個主控台變數均已啟用。"
L["PERF_POPUP_DESC"] = "這會降低效能，除非您正在擷取錯誤報告，否則應將其關閉。"
L["PERF_POPUP_CONFIRM"] = "停用並重載"
L["PERF_POPUP_IGNORE"] = "忽略"
