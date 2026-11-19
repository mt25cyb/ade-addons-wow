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

## 命令

`/ademaptabdelve`、`/adedelvetab`、`/adedt`、`/adeMTD` 打开地下堡面板
（`/adeMTD` 旧为基座设置入口，v6.5 无独立设置页故开面板）。

## 依赖

- `ade_UIKit`（`DB.MergeDefaults` + `CreateMinimapButton`）
- `adeMapTab`（`AdeMapTab-1.0` 公共库；其内部已走 UIKit `ApplyIcon` 绘制 Tab 图标）

## 验证清单

1. 世界地图出现地下堡 Tab，图标 28×28 正常（UIKit ApplyIcon 路径）。
2. Tab 内齿轮设置可用（SettingsPanel 各项即时生效）。
3. 小地图图标：拖动定位（`minimapPos` 持久化）、左键开战团统计窗、设置页开关即时显隐。
4. `/reload` 后旧存档（`minimap.hide/minimapPos/radius`）无迁移成本直接生效。
5. `/adedt` 等四条命令开面板；战团统计窗口、路点、过滤/搜索正常。
