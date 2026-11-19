## v6.5-r007 - 2026-11-18

**外部支持选项接入统一口径（用户明确要求；规范 _docs/External-Addon-Support-Convention.md）：`enableKrowi`（Krowi_AchievementFilter）与 `enablePrat`（Prat-3.0）开关改为 `disabled = function() return not UIKit.IsAddOnLoaded(...) end`——目标插件未加载时禁用（不可点），desc 提示「未检测到 XX，此选项已禁用」；已加载时显示功能说明。三语补 DESC_ENABLE/DESC_NEED 文案。此前为静默闲置（开关恒可点但不生效），现为显式禁用。**

## v6.5-r006 - 2026-11-18

**日期格式新增「不显示 时:分」开关（`dateFormat.hideTime`，默认关）：成就日期无时间，预设/自定义串中的 `%R`、`%I:%M %p` 会渲染成 00:00——开启后在 `GetFormatString()` 出口剥除时间 token（`%c` 整体不可拆改用 `%x` 本地纯日期），对全部预设与自定义串生效；说明文案（NOTE_FORMAT 三语）同步提示。**

## v6.5-r005 - 2026-11-18

**修复 r004 `Ext_Prat.lua` 登录报错：① Prat 的 `GetModule` 覆盖版（addon/modules.lua:240-248）不透传 silent——Achievements 模块未注册时内部直接对 nil 抛错，改 pcall 保护（未注册/未启用静默闲置）；② Prat 模块经 `AddModuleToLoad` 工厂延迟创建，`Prat-3.0` ADDON_LOADED 时机可能尚未注册，补 `PLAYER_ENTERING_WORLD` 兜底试挂；③ `addDate` 契约检查移到 `enablePrat` 开关启用之后——未开启接管不因 Prat 版本漂移报错。**

## v6.5-r004 - 2026-11-18

**① `Krowi_AF_Ext.lua` 改名 `Ext_Krowi_AF.lua`（对齐 Extend/Ext_*.lua 扩展命名惯例，逻辑不变）；② 新增 `Ext_Prat.lua`：把本插件的成就完成日期格式化扩展到 Prat 3.0「成就 -> 显示完成日期」模块——包装 `module.addDate`（Achievements.lua:177-183 拼接点、:148 动态查找调用），复用 Prat 三语文案（`module.PL.completed`）与白色外壳（全局 `Prat.CLR`），仅把 `FormatShortDate` 换成 `ADF.FormatDate`；设置页新增开关（默认关）；Prat 未装静默闲置，模块契约漂移 error 暴露。**

## v6.5-r003 - 2026-11-18

**TOC 补 `Title-zhCN/zhTW`（[ADE] 成就日期格式化）；名称/版本统一改走 UIKit `GetAddonMeta`（b024）。**

## v6.5-r002 - 2026-11-18

**「打开选项」stub 页改在 ADDON_LOADED 加载期注册（原在惰性 Build 内，未打开过设置窗口时原生设置里看不到）；名称/版本统一经 `C_AddOns.GetAddOnMetadata` 取 TOC 元数据；删除 UIKit 取色与 GetBlizzOptionsFrame 的防御链/兜底（硬依赖缺失即报错暴露）。**

## v6.5-r001 - 2026-11-17

**由 Z_AchievementDateFormat 重构：日期格式化改由 ade_UIKit 公共 API 提供；实测有效的 Krowi_AchievementFilter 行 hook 纳入插件；新增基于 ade_UIKit 的设置页（7 预设 + 自定义、原生/Krowi 生效开关）；在原生「设置 > 插件」注册「打开选项」入口页**
