# adeMapTab_Delve

世界地图地下堡标签页（ADE v6.5 原生重写，基于新版 `adeMapTab` 公共库 + `ade_UIKit`）。

## 定位

- 由旧 ADE v4/v5 体系（`_temp/_old_ADE_2/adeMapTab_Delve/`，原样保留）原生重写。
- **无独立设置页**（按口径只保留世界地图 Tab 内齿轮设置，`UI/Settings.lua` 已删除），
  也不注册 UIKit 原生选项入口页（设置不在独立窗口）。
- 存档沿用旧名 `ADEDB_MAP_TAB_DELVE.profile`，扁平键 + `Database.Initialize` 显式建嵌套表，
  缺失键由 `ade_UIKit.DB.MergeDefaults` 补全；无 profile 管理。

## v6.5 改造点

| 项 | 变化 |
|---|---|
| `Core.lua` | 去 `_G.ADE` / AceConsole / AceDB / RegisterSettingsPage；UIKit DB 装配；原生 slash；ADDON_LOADED→PLAYER_LOGIN→PLAYER_ENTERING_WORLD 事件顺序沿用 v5 |
| `UI/MinimapIcon.lua` | 小地图图标改 `ade_UIKit.CreateMinimapButton`（零依赖自绘）：位置/显隐仍存旧字段 `minimap.minimapPos/radius/hide`，无需存档迁移；单一入口（点击开战团统计窗）保留 |
| `Data/Services/UI` 其余文件 | 零改动（addon env 表共享 + `LibStub("AdeMapTab-1.0")` 与新版公共库兼容） |
| `UI/Settings.lua` | 删除（独立设置页） |
| `UI/StatsPanel.lua` | r003 删除：综合统计面板（含 `showStats` 设置项与货币/道具专用事件）；机器人按钮迁至面板顶栏最左（原战团按钮位置，其余控件右移）|

## 命令

- `/ademaptabdelve`、`/adedelvetab`、`/adedt`、`/adeMTD`：打开地下堡面板
  （`/adeMTD` 旧为基座设置入口，v6.5 无独立设置页故开面板）。
- `/way #<mapID> x y <名称>`（r003）：设置路点并立即追踪。`#mapID` 可省略（默认当前地图），
  `名称` 可选（TomTom 路点会显示为标题；原生 user waypoint 无名称通道——API 不支持，
  名称出现在聊天反馈中并附带原生 Map Pin 链接，可点击查看/分享，与 Simple Waypoints 同款处理）；
  坐标为百分数（≤1 的小数也兼容）。
  注册前通用检测 `/way` 是否已被**任何**插件声明（遍历全局 `SLASH_*` 变量匹配命令文本，
  不限于特定插件）：已占用即让位、优先使用对方实现；未被占用才注册本插件命令。
  条目**右键**（r003 重设计）同样按 `/way` 占用情况自动适配：占用 → 调对方 handler
  （等价 `/way #<mapID> x y <名称>`，支持名称）；未占用 → 本插件实现（原生路点 + TomTom 同步）。
  旧的「右键=原生 / Shift+右键=TomTom」修饰键区分已删除。

## 依赖

- `ade_UIKit`（`DB.MergeDefaults` + `CreateMinimapButton`）
- `adeMapTab`（`AdeMapTab-1.0` 公共库；其内部已走 UIKit `ApplyIcon` 绘制 Tab 图标）

## 验证清单

1. 世界地图出现地下堡 Tab，图标 28×28 正常（UIKit ApplyIcon 路径）。
2. Tab 内齿轮设置可用（SettingsPanel 各项即时生效）。
3. 小地图图标：拖动定位（`minimapPos` 持久化）、左键开战团统计窗、设置页开关即时显隐。
4. `/reload` 后旧存档（`minimap.hide/minimapPos/radius`）无迁移成本直接生效。
5. `/adedt` 等四条命令开面板；战团统计窗口、路点、过滤/搜索正常。
6. `/reload` 后顶栏顺序为 机器人 → 战团 → 类型 → 过滤 → 搜索开关；机器人按钮 tooltip/冷却/未持有灰显正常。
7. `/way #2274 37.6 65.2 测试路点` 设置并追踪；无 `#mapID` 时落在当前地图；装了 TomTom 时 `/way` 仍归 TomTom。
