# adeMapTab_Portal

世界地图传送标签页（ADE v6.5 原生重写，基于新版 `adeMapTab` 公共库 + `ade_UIKit`）。

## 定位

- 由旧 ADE v4/v5 体系（`_temp/_old_ADE_2/adeMapTab_Portal/`，原样保留）原生重写。
- **无独立设置页**（按口径只保留世界地图 Tab 内齿轮设置，`UI/Settings.lua` 已删除），
  也不注册 UIKit 原生选项入口页（设置不在独立窗口）。
- 存档沿用旧名 `ADEDB_MAP_TAB_PORTAL.profile`，含 3 段插件内部旧键迁移逻辑（v4 逐行保留）；
  缺失键由 `ade_UIKit.DB.MergeDefaults` 补全；无 profile 管理。
- **不注册小地图图标**（口径：仅 Delve 配小地图）。

## v6.5 改造点

| 项 | 变化 |
|---|---|
| `Core.lua` | 去 `_G.ADE` / AceConsole / AceDB / RegisterSettingsPage；UIKit DB 装配；原生 slash；保留绑定系统所需的 4 项全局例外（`BINDING_NAME_*` / `ADEMAPTAB_PORTAL_TOGGLE` / 随机炉石按钮全局名） |
| `UI/ZoneTeleportButtons.lua` | 基座 `ADE.CreateStyledButton` / `SetStyledButtonEdgeShadow` **逐字内联**为本地函数（原 `ade_BaseFramework/widget/StyledButton.lua`），行为不变 |
| `Data/Services/UI` 其余文件 | 零改动（addon env 表共享 + `LibStub("AdeMapTab-1.0")` 与新版公共库兼容） |
| `UI/Settings.lua` | 删除（独立设置页） |

## 命令与绑定

- 命令：`/ademaptabportal`、`/adeportaltab`、`/adept`、`/adeMTP`（旧为设置入口，v6.5 开面板）
- 按键绑定：面板开关、随机炉石（`Bindings.xml`，显示名经 `BINDING_NAME_*` 在加载期注册）

## 依赖

- `ade_UIKit`（`DB.MergeDefaults`）
- `adeMapTab`（`AdeMapTab-1.0` 公共库）
- 可选：Masque（按钮皮肤）

## 验证清单

1. 世界地图出现传送 Tab，图标 28×28 正常；传送按钮圆形/方形与边缘虚影正常（内联 StyledButton）。
2. Tab 内齿轮设置可用；收藏/最近列表、区域传送按钮、随机炉石（含按键绑定）正常。
3. `/adept` 等四条命令开面板；`/reload` 后旧存档无迁移成本直接生效。
