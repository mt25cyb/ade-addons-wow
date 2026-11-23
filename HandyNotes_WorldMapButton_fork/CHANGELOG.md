# HandyNotes: WorldMapButton (fork)

## v6.5-r004 - 2026-11-23（用户拍板简化：简易框体下固定在探索按钮左侧，不再跟随「显示探索按钮」）

**r003 探测方案在用户环境仍不生效，用户拍板简化行为：简易框体下本按钮**固定**在探索按钮左侧的位置（`RIGHT to MaximizeMinimizeFrame LEFT, dx - size - 2, 0`），不管「显示探索按钮」勾还是取消。`size` = 最大化按钮高度（探索按钮 Show 时同款尺寸，`Leatrix_Maps.lua:6878-6880`，钳 12~32 默认 22；简易框体保留最大化按钮 20×20，`:369/:443`）；`dx` 与探索按钮 PlaceDiscBtn 同款（`:6885-6891`，默认 -14，任务日志打开时按搜索框/设置按钮位置动态左移，由 QuestMapFrame OnShow/OnHide 钩子同步）。探索按钮隐藏时该位置空着、本按钮固定占据，勾/取消选项不再引起位置变化。删除 r003 的探测/显隐钩子逻辑（`FindDiscButton`/`HookDiscButton`）与 r002 的 `GLOBAL_MOUSE_UP` 监听（固定定位后均无必要），`UpdateButtonPosition` 还原为 local function。TOC bump v6.5-r004。**

## v6.5-r003 - 2026-11-23（r002 仍不刷新的根因：LeaMapsDB 同步滞后，改为探测探索按钮本体）

**用户实测 r002 仍未解决。深挖根因：Leatrix 复选框 OnClick 只更新文件内 local 运行时表 `LeaMapsLC`（`Leatrix_Maps.lua:7909-7917`），SavedVariables 同步 `LeaMapsDB["ShowDiscoveryAreas"] = LeaMapsLC[...]` 在 `:8784`、随 reload 前保存流程才发生——点击当下读 `LeaMapsDB` 是旧值，r002 的"GLOBAL_MOUSE_UP 重定位 + 读 DB 判断"算出的仍是旧位置；探索按钮的运行判据同样是 `LeaMapsLC`（`:6920`）。r003 改为不读任何滞后配置键、直接探测探索按钮本体：`discBtn` 是 `WorldMapFrame.ScrollContainer` 直接子 Button（`:6862`）、图标 `Interface\Icons\Ability_Hunter_Pathfinding`（`:6864`），按 父级+Button 类型+图标纹理 三重特征探测并缓存（`FindDiscButton`）。定位规则升级：探索按钮可见 → 本按钮锚到它本体左侧（`RIGHT to discBtn LEFT, -2, 0`，Leatrix 动态重排时自动跟随）；不可见 → 读它当前已设置的锚点复刻占位（隐藏帧 SetPoint 仍在，`GetPoint` 可读；读不到回退 PlaceDiscBtn 同款 dx 算法）；探测不到（未启用探索系统 `:5962`）回退配置键判断。并挂探索按钮 OnShow/OnHide 钩子精确跟随显隐切换（含选项切换与探索状态锁定）；r002 的 GLOBAL_MOUSE_UP 保留为首次探测触发（已挂钩后直接短路）。修复 HookDiscButton 对 `UpdateButtonPosition` 的前向引用（local 前向声明）。TOC bump v6.5-r003。**

## v6.5-r002 - 2026-11-23（修复：切换「显示探索按钮」时按钮位置不即时刷新）

---

以下为上游原版 CHANGELOG（fuba，GPL-3.0）：

## v6.5-r001 - 2026-11-23（fork：修复 Leatrix Maps 简易地图框体下的按钮定位）

**基于 fuba `HandyNotes_WorldMapButton 20261106.02-Release`（GPL-3.0）的修复分支：原版 Leatrix 适配判断键 `LeaMapsDB["UseDefaultMap"]` 已从当前 Leatrix Maps 移除（12.x 主文件全文 0 命中），判断恒不生效，正式版按钮（锚最大化按钮左侧 -2）在「使用简易地图框体」下与探索按钮重叠。按用户规格重写 retail 适配：判断键改为 `LeaMapsDB["SimpleMapFrame"] == "On"`（简易框体）与 `LeaMapsDB["ShowDiscoveryAreas"] == "On"`（探索按钮，实证 `Leatrix_Maps.lua:339/:8674/:8640`）；定位复刻探索按钮 `PlaceDiscBtn` 算法（`Leatrix_Maps.lua:6873-6914`）——简易框体且不显示探索按钮时占用探索按钮位置（`RIGHT to MaximizeMinimizeFrame LEFT, dx, 0`），显示时放在其左侧（`dx - size - 2`，size=最大化按钮高度钳 12~32），`dx=-14` 且任务日志打开时按标题栏搜索框/设置按钮位置动态左移（`:6885-6891`，基准 `WorldMapFrame.ScrollContainer`）；层级同款（同 strata、FrameLevel+1，`:6894-6897`）；secret 防护同款（`issecretvalue` 包装，`:5976-5977`）。新增 `QuestMapFrame` OnShow/OnHide 同步重定位（任务日志开合改变动态 dx）。fork 改名：目录/TOC/主文件 `_fork`、全局帧名 `HandyNotesWorldMapButton_fork`、AceLocale 命名空间 `_fork`（4 语言文件），新增 `Locale/zhCN.lua` 并注册 TOC，`OptionalDeps` 加 `Leatrix_Maps`；GPL-3.0 LICENSE 全文保留。**

---

以下为上游原版 CHANGELOG（fuba，GPL-3.0）：

## [20261106.02-Release](https://github.com/fubaWoW/HandyNotes_WorldMapButton/tree/20261106.02-Release) (2026-11-06)
[Full Changelog](https://github.com/fubaWoW/HandyNotes_WorldMapButton/compare/20261106.01-Release...20261106.02-Release) [Previous Releases](https://github.com/fubaWoW/HandyNotes_WorldMapButton/releases)

- Updated code to detect game version  
    Fixed Positioning for Forever  
