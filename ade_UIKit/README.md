# ade_UIKit

ADE 系列插件共享的**控件库 + 样式库 + 公共函数库**；当前实现从 KAF `Krowi_AchievementFilter` 的 `Krowi_Options` 2.0 逐模块复刻选项窗口。主窗为「左选项树 + 中内容区」两栏（去掉 KAF 的右侧描述区），顶部多插件 Tab 与搜索栏，选项说明优先走暴雪原生 `SettingsTooltip`（自建 `GameTooltip` 仅兜底）。零第三方依赖、零 `ade_AddonFramework` 依赖，自带简版回调注册表。

- 代际定义：**ADE v6.5**（用户 2026-11-17 指定；版本串已同步为 `v6.5-r001-b014`）
- 版本：`v6.5-r001-b014`
- 客户端：12.1.5（`## Interface: 120105`）
- 唯一开发计划（含复刻依据与历史 v6 线）：[`_docs/plans/ade_UIKit-dev-plan.md`](../_docs/plans/ade_UIKit-dev-plan.md)
- 双形态同步契约：[`SYNC.md`](SYNC.md)

## 快速取用

```lua
local OF = GetBlizzOptionsFrame("ade_UIKit", true)
if not OF then return end

local tab = OF.RegisterTab({
    name = "MyAddon",
    saved = MyDB,
    groups = { { name = "常规", sections = { "general" } } },
    sectionName = function(id) return id == "general" and "常规" or id end,
    elements = function(id) return {
        { kind = "toggle", key = "enable", label = "启用", desc = "说明",
          get = function() return MyDB.enable end,
          set = function(v) MyDB.enable = v end, default = true },
    } end,
})
tab:Open("general")
```

对外 API v6 → v6.5 不变：`GetBlizzOptionsFrame` / `RegisterTab` / Tab 的 `Open/Toggle/Refresh/GetFrame/GetSaved`。

## 能力（均源自 KAF 蓝本）

- 原生模板：`SettingsFrameTemplate` / `MinimalTabTemplate` / `SearchBoxTemplate` / `WowScrollBoxList` + `MinimalScrollBar` / 无模板自绘勾选框、银色九宫格按键按钮、`MinimalSliderWithSteppersTemplate` / `WowStyle2DropdownTemplate`。
- 两栏布局：内框 `Options_InnerFrame` 切片、左侧导航、中部页面；首组标题占据 KAF「概览」位置（本库无概览项）。
- 行为：改值金线、悬停恢复默认、逐行重载图标、底部 reload 条、ChangedCount、Defaults 原位确认态、签名驱动的行内就地刷新、顶部框名称搜索（整文本优先 + 逐词命中）。
- 双层行池：host + 每 Kind 行池，避免暴雪按 frame type 回收导致串 Kind。
- 控件全集：14 种 Kind（Header/SubHeading/Note/Option/Sub/Grid/GridHeader/GridRow/TabList/TabRow/Link/Cards/CardRow/SearchHeading）、6 种 option 类型（toggle/range/select/execute/input/key）及 With 组合、双键位 Slots；`adeBlizzDemo` 三页逐一演示。

## 目录

| 文件 | 内容 |
|---|---|
| `Core/Namespace.lua` | minor 仲裁（全局函数带 `BOF_` 前缀）+ Window mixin 聚合表 |
| `Core/Callbacks.lua` | 库内简版回调注册表 |
| `Core/Config.lua` | 配置校验、Tab 注册、共享状态（几何在 `Widget/Kinds.lua`） |
| `Core/API.lua` | 快速创建门面 |
| `Widget/Kinds.lua` | 几何、Kind 定义、Flatten、InitList 双层行池、宿主 spec 适配 |
| `Widget/RowFrames.lua` | 所有行的 Lua 构建器（无 XML 虚拟模板） |
| `Widget/RowMixins.lua` | option 接口、行刷新、按键捕获、鼠标标记、MakeOption 适配 |
| `Widget/WindowFrame.lua` | 建窗 + 延迟建窗入口 + ESC 代理帧 |
| `Widget/WindowLayout.lua` | 内框切片、两栏锚点、拖拽缩放、导航行 |
| `Widget/WindowMixin.lua` | 窗口核心 + 页面数据流 + 搜索 |
| `Widget/Search.lua` | 搜索匹配算法（仅名称） |
| `Widget/Tooltip.lua` | 原生 GameTooltip 说明 |
| `Locales/` | enUS / zhCN / zhTW |

## 进游戏验证清单

1. `/reload` 后 `GetBlizzOptionsFrame(..., true)` 非空；`/bofdemo` 能打开。
2. 两栏布局、Tab、搜索栏、原生边框标题正确；首组标题贴顶；无常驻右栏。
3. 搜索输入命中、清空/点清除按钮后还原分区；按键按钮可见时全局键盘（含动作条、ESC）正常。
4. 改值金线常显、悬停恢复默认按钮不闪烁、tooltip 随离开消失；needsReload 点亮底部条。
5. 战斗中开关窗无 taint（关闭一律 `frame:Hide()`）。
6. 三语切换无硬编码文案。
