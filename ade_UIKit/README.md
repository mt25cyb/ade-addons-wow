# ade_UIKit

ADE 系列插件共享的**控件库 + 样式库 + 公共函数库**；当前实现从 KAF `Krowi_AchievementFilter` 的 `Krowi_Options` 2.0 逐模块复刻选项窗口。主窗为「左选项树 + 中内容区」两栏（去掉 KAF 的右侧描述区），顶部多插件 Tab 与搜索栏，选项说明优先走暴雪原生 `SettingsTooltip`（自建 `GameTooltip` 仅兜底）。零第三方依赖、零 `ade_AddonFramework` 依赖，自带简版回调注册表。

- 代际定义：**ADE v6.5**（用户 2026-11-17 指定；版本串已同步为 `v6.5-r001-b023`）
- 版本：`v6.5-r001-b023`
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

对外 API v6 → v6.5 不变：`GetBlizzOptionsFrame` / `RegisterTab` / Tab 的 `Open/Toggle/Refresh/GetFrame/GetSaved`；b028 新增 **`lib.CreateScrollableTabStrip(parent, opts)`**——限宽 + 横向滚动 + 端点箭头的可复用标签条（设置窗口顶部插件切换标签即由它托管；opts 与方法详见 `Widget/ScrollTabs.lua` 文件头）。

公共函数（b015 起；b023 起统一放在 `Function/` 子目录，`lib.X` 名称不变）：

- 原生选项入口（b023）：`OF.RegisterOptionsStub({ title, version, hint, ways, buttonText, tab, sectionId })`，在「设置 > 插件」注册一个说明页与「打开选项」按钮（KAF Stub 同款），点击调 `tab:Open(sectionId)`；返回 Settings category。adeMapTab 系列不用（设置在世界地图 Tab 内）。

- 日期：`OF.FormatDate(day, month, year, fmt, opts)`、`OF.DATE_FORMATS[1..7]`、`OF.DATE_PRESET_COUNT`、`OF.DATE_CUSTOM_DEFAULT`、`OF.DatePresetFormat(i)`、`OF.DatePresetKeys()`、`OF.LocalizeDateFormat(fmt, time)`。`fmt` 省略时为 `%Y/%m/%d`；`%B/%b/%A/%a` 用暴雪本地化日历名称替换。
- 通用：`OF.GetPath/SetPath`、`OF.Clamp/Clamp01/Round/SnapValue/Reindex/SortByOrder/IndexOf`、`OF.ColorUtil.*`、`OF.ColorHex(r,g,b)`、`OF.DB.DeepCopy/MergeDefaults`。
- 图标（b017）：`OF.ResolveIcon(icon)` / `OF.ApplyIcon(texture, icon, opts)` / `OF.IconEscape(icon, size)` / `OF.SetButtonIcon(button, icon, opts)`，支持 FilePath / FileID / Atlas 三态。
- 小地图（b017）：`OF.CreateMinimapButton(opts)` / `OF.ApplyMinimapPosition(btn, angle, radius)` / `OF.SetMinimapButtonShown(btn, shown)` / `OF.AngleFromCursor(frame)`；零依赖自绘，显隐由宿主的 `getShown/setShown` 委托。
- 行类型（b018/b019）：在 `RegisterTab` 的 `elements` 中使用 `{ kind = "multiline", label, get, set, default, disabled }`，就地渲染**可滚动**多行 EditBox（label 贴顶且与 NameLeft 同缩进、Enter 换行、失焦提交、`disabled` 只读，行高 118），适合宏体 / 导入导出等长文本。b019 增加 `onTextChanged(edit, userChanged)` 与 `onEditBox(edit)` 回调（后者把实际 EditBox 交给宿主），`disabled` 支持函数形式。
- 配置分享字符串（b019）：`lib.ShareString.Encode(prefix, payload)` / `Decode(text, prefix, validate)` / `Sanitize(profile, defaults, nestedKey)`；`C_EncodingUtil` CBOR→压缩→Base64，前缀识别来源，每步 pcall，错误返回本地化 key。宿主自行构造 payload（`{schemaVersion, profile}`）与校验回调，本 API 不碰存档、不 ReloadUI。

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
| `Core/Config.lua` | 配置校验、Tab 注册、共享状态（几何在 `Widget/Kinds.lua`） |
| `Function/` | 公共 API 函数（见下）：`Util/Format/Icon/ShareString/Callbacks/API.lua` |
| `Widget/Kinds.lua` | 几何、Kind 定义、Flatten、InitList 双层行池、宿主 spec 适配 |
| `Widget/Parts.lua` | 控件公共积木（Text/Color/Finish/Hover/CheckButton/RowGeometry）+ Protected·Ask 调用保护 |
| `Widget/KeyButton.lua` | 键位捕获按钮（单控件，双键位 Slots） |
| `Widget/StaticText.lua` | 静态文本条目族（Header/SubHeading/Note） |
| `Widget/OptionRow.lua` | 选项行组合控件（七类 option 一行）+ MakeOption 适配 + 键位捕获 |
| `Widget/CheckGrid.lua` | 复选网格条目族（SubRow/GridHeaderRow/GridRow） |
| `Widget/TabOrder.lua` | 页签排序条目（位置/显隐/上下移） |
| `Widget/Links.lua` | 链接 / 搜索标题条目 |
| `Widget/Cards.lua` | 卡片条目族（Card + CardRow） |
| `Widget/ListRow.lua` | 列表行控件 `kind="list"`：拖动排序 / 拖入物品 / 组合条目 / 斑马纹（b038） |
| `Widget/WindowFrame.lua` | 建窗 + 延迟建窗入口 + ESC 代理帧 |
| `Widget/WindowLayout.lua` | 内框切片、两栏锚点、拖拽缩放、导航行 |
| `Widget/WindowMixin.lua` | 窗口核心（生命周期 / 字符串 / tooltip 转发） |
| `Widget/WindowTabs.lua` | 顶部插件切换标签接线（滚动由 `Widget/ScrollTabs.lua` API 承担） |
| `Widget/WindowPage.lua` | 导航树 + 分区/页面填充与就地刷新 |
| `Widget/WindowFooter.lua` | 页脚（确认条 / 变更计数 / 重载提示）与默认值流程 |
| `Widget/WindowSearch.lua` | 搜索框接线（算法在 `Widget/Search.lua`） |
| `Widget/ScrollTabs.lua` | 可滚动标签条独立 API `lib.CreateScrollableTabStrip` |
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
