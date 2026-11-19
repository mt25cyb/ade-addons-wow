# adeStatPlus

属性信息面板（ADE v6.5 原生重写，分两批移植；本目录当前为**第一批**）。

## 定位

- 由旧 ADE v5 / Ace 体系（`_temp/_old_ADE_2/adeStatPlus/`，原样保留）原生重写：
  私有表 `adeStatPlus` + `ade_UIKit.DB.MergeDefaults` + `RegisterTab` 设置页 + 自绘小地图。
- 存档沿用旧名 `ADEDB_ADESTATPLUS`（`profile` 旧结构全保留），缺失键由 UIKit 补全；
  `profile.minimap` 新增 `angle` 字段（自绘按钮的角度持久化）。

## 第一批内容（当前）

| 模块 | 状态 |
|---|---|
| `Data/StatDefs.lua`、`Modules/SourceRegistry.lua`、`Modules/Collector.lua`、`Extend/Ext_*.lua` | 原样保留（无框架依赖），仅头部 `ns` 改走全局私有表 |
| `Modules/Bars.lua` + `Modules/Panel.lua` | 去 LSM：字体/材质改走 `Modules/Media.lua` 原生表 |
| `Modules/Media.lua` | 新增：字体清单逐项转录 LSM-3.0 默认注册表（按 locale 分支），材质保留自带 atrocity + 原生 Raid-Bar-Hp-Fill |
| `Options.lua` | UIKit `RegisterTab` 两页（general / charpanel）；旧卡片 → subheading 分组；分段/条高/环宽联动禁用用函数式 `disabled`；背景颜色用官方 `ColorPickerFrame:SetupColorPickerAndShow`（12.x 契约） |
| `Core.lua` | 入口：UIKit DB 装配、第一批模块调度、自绘小地图（左键切换面板、右键打开设置 + 角度持久化）、双命令 |
| `Radar/Ring/SortWindow/CharPanel` | **第二批**；其存档字段（`charPanel.*`）已随默认值合并，设置页先落字段 |

## 命令

- `/adsp panel` 显示/隐藏面板；`/adsp sort` 排序窗口（第二批）；`/adsp config` 打开设置
- `/adeSP` 直接打开设置窗口
- 原生「设置 > 插件」里有「打开选项」入口页（UIKit b023）

## 依赖

- `ade_UIKit`（强依赖：`DB.MergeDefaults` + `RegisterTab` + `CreateMinimapButton`）

## 第二批 UI（2026-11-17）

- **CharPanel**：内嵌原生角色面板——属性行下 8px 进度条（刻度/火花）、原生 `CharacterStatsPane` 整体 reparent 到无滚动条 ScrollFrame（滚轮滚动，基座 scrollBar="none" 等价内联）。12.x 注意：角色面板代码在 `Blizzard_UIPanels_Game` 包内，`Blizzard_CharacterFrame` addon 名已不存在。
- **SortWindow**：「显示/排序/颜色」侧窗（`/adsp sort` 或设置页按钮），双点锚主设置窗左外侧；锚定走 `Options.GetWindowFrame`（UIKit 共享窗惰建），滚动容器内联 `ScrollFrameTemplate + MinimalScrollBar`。
- ~~图形内嵌（Radar/Ring）~~：已删除（实测问题较大）；旧存档 charts 键不消费。

## 须知（介质来源）

- 字体下拉：首项「游戏默认字体」（存档 key `Game Default`，路径取 `GameFontNormal:GetFont()`，
  即客户端默认 UI 字体；默认值即该选项）+ 内置转录的 8 款 LSM 默认字体 + 环境中
  `LibSharedMedia-3.0` 已注册的第三方字体（可选合并，去重）。
- 材质下拉：本插件两款 + LSM statusbar 已注册介质（可选合并）。
- 下拉 items 在首次打开设置页时重建（第三方介质注册可能晚于本插件加载）；
  存档 key 未命中时按内置表回退。

## 验证清单

1. `/reload` 后面板出现且可拖动/折叠/锁定；数据行随装备/等级刷新。
2. 小地图按钮可拖动（角度持久化）、左键切换面板、右键打开设置窗口、tooltip 显示标题与左右键提示。
3. 设置页两页可切换，逐分组恢复默认可用；分段开关联动禁用对齐/拆分项即时生效。
4. 「背景颜色…」打开官方取色器，拖动实时预览、取消还原。
5. `/adsp panel|config`、`/adeSP` 生效；旧 `ADEDB_ADESTATPLUS` 存档无迁移成本。
