# adePerfGuard（ADE 性能护栏）

独立小插件（脱库，零依赖）：进副本时检测两个「悄悄拖累战斗性能」的调试 CVar 并一次性提醒，一键禁用。移植自 EllesmereUI 的 Performance Reminder（`EllesmereUI.lua:4783-4826`），弹窗改用引擎标准 `StaticPopupDialogs`。

## 功能

- **检测对象**：`taintLog`（抓 bug 报告后常忘记关）与 `scriptProfile`（给每个插件的每次调用加统计开销，仅在 reload 后生效）。
- **触发条件**（三者齐备才弹，每次会话最多一次）：
  1. 功能开关为 `on`；
  2. 人在副本中（野外不弹——调试 CVar 只在战斗场景才真正拖帧数）；
  3. 本次会话未提醒过（`/reload` 后重新允许一次）。
- **一键「禁用并重载」**：把两个 CVar 写回 0 并 `ReloadUI`。使用原生 `C_CVar.SetCVar`，不经任何包装——这是玩家自己的修复，卸载/重装本插件不会回滚。
- **零常驻成本**：一个 Frame 监听两个事件，其余时间无任何开销。

## 命令

```
/adeperfguard on      启用（持久化）
/adeperfguard off     停用（持久化）
/adeperfguard         显示状态：启用/关闭 + 两个 CVar 当前值
/adeperf              同上（简写别名）
```

默认启用。无设置界面。

## 安装

将 `adePerfGuard/` 文件夹放入 `Interface\AddOns\`，无任何依赖插件。

## 结构

```
adePerfGuard/
├── adePerfGuard.toc   Interface 120105 / SavedVariables: ADEDB_PERF_GUARD
├── Locales/           enUS（回退）/ zhCN / zhTW
├── InitDB.lua         存档装配（settings.enabled 默认 true）
└── Core.lua           事件检查 + StaticPopup + 命令
```
