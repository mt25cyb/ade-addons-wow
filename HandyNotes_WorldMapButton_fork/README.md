# HandyNotes: WorldMapButton (fork)

基于 fuba 的 `HandyNotes_WorldMapButton`（`20261106.02-Release`，GPL-3.0，见 `LICENSE.txt`）的修复分支。原插件功能不变：在世界地图上添加一个按钮，点击切换 HandyNotes 图标显隐、右键打开 HandyNotes 设置；世界地图追踪菜单内也有开关项。

## 为什么 fork

原插件对 Leatrix Maps 的适配使用判断键 `LeaMapsDB["UseDefaultMap"] == "Off"`，但该键**已从当前 Leatrix Maps 移除**（12.x 主文件 `Leatrix_Maps.lua` 全文检索 0 命中），判断永远不成立——正式版路径（`HandyNotes_WorldMapButton.lua:161-166` 原版行号）锚在世界地图最大化按钮左侧 `x=-2`，在 Leatrix「使用简易地图框体」下会与 Leatrix 的**探索按钮**（discBtn）重叠/覆盖。

## 修改内容（v6.5-r001，2026-11-23）

### 1. 按用户规格重写 retail 的 Leatrix 适配（判断键 + 定位）

判断键（均为 Leatrix 的 SavedVariables 全局，`LeaMapsDB`，`Leatrix_Maps.toc` `LoadSavedVariablesFirst` 早加载）：

| 键 | 语义 | 证据 |
|---|---|---|
| `LeaMapsDB["SimpleMapFrame"] == "On"` | 使用简易地图框体（切换需 `/reload`，`ReloadCheck`） | `Leatrix_Maps.lua:339`（运行判据）、`:8640`（LoadVarChk）、`:8784`（保存） |
| `LeaMapsDB["ShowDiscoveryAreas"] == "On"` | 显示探索按钮（默认 "On"） | `Leatrix_Maps.lua:8674`、`:8907`（选项描述） |

定位规则（复刻 Leatrix 探索按钮的 `PlaceDiscBtn` 算法，`Leatrix_Maps.lua:6873-6914`）：

- **简易框体 + 不显示探索按钮** → 按钮放在**探索按钮的位置**：`RIGHT to MaximizeMinimizeFrame LEFT, dx, 0`；
- **简易框体 + 显示探索按钮** → 按钮放在**探索按钮的左侧**（间隙 2px）：探索按钮宽 = 最大化按钮高度（`:6878-6880`，钳制 12~32，默认 22），故偏移为 `dx - size - 2`；
- `dx` 与探索按钮同款：默认 `-14`，**任务日志打开时**按标题栏内搜索框/设置按钮的位置动态左移（`:6885-6891`，以 `WorldMapFrame.ScrollContainer` 右缘为基准）；
- 层级与探索按钮同款：同 strata、`FrameLevel + 1`（`:6894-6897`）；战斗中 secret 值防护与 Leatrix 的 `IsSecret` 包装（`:5976-5977`，`issecretvalue`）同款思路。

简易框体下最大化按钮保留（`Leatrix_Maps.lua:369/:443`，20×20），因此该定位在简易框体下总是可用；最大化按钮不可见时回退原版通用锚定。探索按钮本体是 Leatrix 的匿名局部帧（`:6862`），外部拿不到引用，只能按同款算法复算位置——Leatrix 调整其定位规则时需同步本插件。

### 2. 任务日志开合同步重定位

简易框体下任务日志（`QuestMapFrame`）开合会改变探索按钮的动态 `dx`，fork 挂 `QuestMapFrame` 的 OnShow/OnHide 同步重定位按钮（仅世界地图可见时执行），避免标题栏内错位。

### 2b. 「显示探索按钮」与按钮位置的关系（r002→r003→r004 演进，最终为固定定位）

「显示探索按钮」复选框在 Leatrix 里**即时生效**（`Leatrix_Maps.lua:7052-7055`），但其运行时表 `LeaMapsLC` 是文件内 local（`:16`）、SavedVariables `LeaMapsDB` 同步滞后到 reload 前保存流程（`:7909-7917`、`:8784`）——外部插件**无法可靠获知该选项的运行时状态**（r002 读 DB、r003 探测探索按钮本体均未在用户环境稳定生效）。

**r004 最终方案（用户拍板）**：放弃跟随切换，简易框体下把按钮**固定**在探索按钮左侧的位置：

```
RIGHT to WorldMapFrame.BorderFrame.MaximizeMinimizeFrame LEFT, (dx - size - 2), 0
```

- `size` = 最大化按钮高度（探索按钮 Show 时同款尺寸，`Leatrix_Maps.lua:6878-6880`，钳 12~32 默认 22；简易框体保留最大化按钮 20×20，`:369/:443`）；
- `dx` 与探索按钮 PlaceDiscBtn 同款（`:6885-6891`）：默认 -14，任务日志打开时按标题栏内搜索框/设置按钮位置动态左移，由 `QuestMapFrame` OnShow/OnHide 钩子同步；
- 探索按钮隐藏（不勾选项/区域全探索锁定）时该位置空着，按钮固定占据——勾/取消「显示探索按钮」不再引起位置变化。

### 3. fork 改名（可与原版共存）

- 目录 / TOC / 主文件：`HandyNotes_WorldMapButton_fork`；
- 全局帧名：`HandyNotesWorldMapButton_fork`（原版为 `HandyNotesWorldMapButton`，避免复用同一帧）；
- AceLocale 命名空间：`HandyNotes_WorldMapButton_fork`（4 个 Locale 文件同步）；
- 新增 `Locale/zhCN.lua` 中文文案并注册进 TOC；
- 图标路径随 `AddOnName` 自动指向 fork 目录。

## 验证清单

1. 不装 / 不开 Leatrix Maps：按钮位置与原版一致（最大化按钮左侧）。
2. Leatrix 开「使用简易地图框体」+ 关「显示探索按钮」→ `/reload`：按钮出现在原探索按钮位置（最大化按钮左侧），不与关闭按钮重叠。
3. 同上但开「显示探索按钮」：探索按钮在最大化按钮左侧，HandyNotes 按钮紧贴其左侧，两个按钮都不重叠。
4. 简易框体下开合任务日志侧栏：两个按钮同步移动，不落入搜索框/设置按钮区域。
5. 点击按钮切换 HandyNotes 图标显隐、右键打开设置、指向显示 tooltip，均正常。
