# adeMapTab

`adeMapTab` 是 **ADE v6.5 系列**的世界地图标签页公共函数库：基于 `LibWorldMapTabs` 提供布局 / 控件 / 生命周期的公共构件。

> 只装本插件时不会看到任何世界地图标签页、设置界面或小地图图标 —— 这是预期行为。
> 功能的实际载体是 `adeMapTab_Delve` 与 `adeMapTab_Portal`。

- 版本：`v6.5-r001`
- 客户端：12.1.5（`## Interface: 120105`）
- 依赖：无强依赖（自带 `LibStub` / `LibWorldMapTabs`）；图标三态绘制为 `ade_UIKit` 软依赖，未加载时回退原生写法
- 零 `ade_BaseFramework`、零 `AceGUI`、零全局 `ADE`
- 迁移计划：[`_docs/plans/ade-v65-migration-dev-plan.md`](../_docs/plans/ade-v65-migration-dev-plan.md) §2.1

## 定位

| 插件 | 角色 | 独立设置界面 | 小地图图标 |
|---|---|---|---|
| `adeMapTab` | 公共函数库 | 无 | 无 |
| `adeMapTab_Delve` | 地下堡标签页 | 无（仅 WorldMapTab 齿轮面板） | 有 |
| `adeMapTab_Portal` | 传送标签页 | 无（仅 WorldMapTab 齿轮面板） | 无 |

两个子插件**各自都能单独**与主插件结合使用；同时安装时，库按注册顺序分配
`LWMT_0` / `LWMT_1` 两个 `displayMode`，互不冲突。

## 依赖与加载

- 本插件**不声明 SavedVariables**、**不注册设置页**、**不注册小地图图标**。
- 子插件 `## Dependencies: adeMapTab` —— 保证主插件的库先完成注册。
- 图标 API 通过全局 `GetBlizzOptionsFrame("ade_UIKit", true)` 软取；UIKit 未加载时
  `MapTab.CreateTab` 回退原生 `SetAtlas` / `SetTexCoord`，因此本库可独立加载。

### 加载顺序（TOC）

```
Libs/LibStub/LibStub.lua
Libs/LibWorldMapTabs/LibWorldMapTabs.lua   ← 全系列唯一一份库副本
Public/MapTab.lua                          ← LibStub:NewLibrary("AdeMapTab-1.0", 1)
Core.lua                                   ← 私有表入口，仅校验库就绪
```

`LibStub` 是全局单例（先到先得，MINOR 2）；基座不再依赖，主插件内嵌的副本保证库可独立加载。

## 公共 API：`LibStub("AdeMapTab-1.0")`

| 函数 | 职责 |
|---|---|
| `GetLib()` | 返回 `LibWorldMapTabs` 实例 |
| `IsDefaultTabClaimed()` | WorldQuestTab 已占用默认页签时让位 |
| `CreateTab(spec)` | 建侧边 Tab；图标优先走 UIKit `ApplyIcon` 三态 API，含 12.x `SetChecked` 28×28 修复 hook |
| `CreateContentFrame(tab, name, opts)` | 由库建内容框架，含 parent 覆盖回 `ContentsAnchor`、三次锚定兜底、层级、背景、可选边框与齿轮 |
| `HookOnHideReset(panel, fn)` | 把「切 Tab 回列表页」重置挂在面板自身 `OnHide` |
| `SetDisplayMode(tab)` / `Open(tab)` | 只走库 `SetDisplayMode`，不绕过库传自定义值（taint） |
| `CreateTopBar(panel, opts)` | WQT 26px 顶栏容器 |
| `CreateScrollBox(panel, opts)` | `WowScrollBoxList` + `MinimalScrollBar` + `ScrollUtil` 现代列表 |
| `CreateScrollFrame(panel, opts)` | `ScrollFrameTemplate` 老式滚动容器（12.x 只调 `bar:Update()`） |
| `CreateSettingsFrame(parent, opts)` | WQT 设置页骨架（背景 / 边框 / 标题 / 关闭 / 滚动 / `UpdateScrollRange`） |
| `CreateCategoryButton(parent, text, onClick, width)` | WQT 可折叠分组标题 |
| `NewRefreshQueue(callback)` | `C_Timer.After` 一次性去抖刷新 |
| `CopyTable(value)` | 深拷贝，用于嵌套默认值表 |

### `CreateTab(spec)` 图标字段

- `icon`：ADE v6.5 新增，UIKit 三态描述表（`{ atlas = ... }` / `{ fileID = ... }` / `{ texture = ... }`）。
- `iconAtlas`：v5 兼容字段，自动转成 `{ atlas = ... }`。
- `iconSize`（默认 20）、`texCoord`（贴图裁边）保持不变。

## 不抽成公共函数的构件

搜索框与设置页复选行**保留在子插件内逐行复刻**：它们各自带实证修复
（放大镜 `OnButtonStateChanged` 覆写、复选行 tooltip / 父子联动灰显 / `RefreshState`），
抽成通用实现会丢失这些修复。

## 文档

- 变更记录：`CHANGELOG.md`
- v6.5 迁移总计划：`_docs/plans/ade-v65-migration-dev-plan.md`
- 布局 / 控件构成的设计依据与红线见 `Public/MapTab.lua` 头部注释。

## 进游戏验证清单

1. `/reload` 后无 Lua error，`LibStub("AdeMapTab-1.0")` 与 `LibStub("LibWorldMapTabs")` 均非空。
2. 单独启用本插件时不出现任何地图 Tab、设置界面或小地图图标。
3. 启用 `adeMapTab_Delve` / `adeMapTab_Portal` 后，Tab 图标尺寸为 20×20（不被库的 28×28 覆盖），选中/未选中状态正常。
4. 切 Tab 时设置页能回到列表页（面板自身 `OnHide` 生效）。
