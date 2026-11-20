# adePerfGuard CHANGELOG

## v6.5-r001 - 2026-11-19

**首版：性能护栏——EUI「Performance Reminder」（EllesmereUI.lua:4783-4826）的脱库独立移植。进副本时检查调试 CVar（taintLog/scriptProfile），任一开启则弹引擎 StaticPopup 提醒，一键「禁用并重载」（原生 C_CVar.SetCVar 写 0 + ReloadUI，不经任何包装，卸载本插件也不回滚该修复）。零常驻成本：单 Frame 双事件；三条件（开关开 + 在副本 + 本会话未提醒过）齐备才弹，/reload 重置会话标志；GetCVar 防御式读取（nil/非数字安全）。无设置界面，仅 /adeperfguard（别名 /adeperf）on|off 持久开关，无参显示状态（含两个 CVar 当前值）。存档 ADEDB_PERF_GUARD.settings.enabled 默认 true，自写 MergeDefaults（不依赖 ade_UIKit.DB）。三语 Locales。TOC v6.5-r001。**
