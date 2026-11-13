# Changelog

> 完整变更记录（每项背景与细节）见 `_docs/plans/adeChatMod-dev-plan.md` §7。

当前版本：**v6-r001-b013**（2026-11-14）

- v6-r001-b013 **跟进框架 b009 布局调整（ADE-v6-FrameDesign）并接入配置档**：设置窗口三页「设置 / 配置管理 / 关于」，页切换按钮由模板移入标题栏右侧；新增「配置管理」页（`ProfilePage`：切换/新建/复制/重命名/删除/导出/导入/当前档重置）；存档迁移 `db.settings` → `db.profiles`（配置档）+ `db.state`（barShown/minimapShown/minimapAngle 等会话状态不入档，旧档自动迁移）；设置页原「重置」分区移除（由配置管理页承担）；`/acm reset` 走当前档重置确认弹窗。
- v6-r001-b012 **强依赖 ade_AddonFramework 适配**：TOC 新增 `## Dependencies: ade_AddonFramework`；`Options.lua` 全量重写为库模板组合（`AF.Template.TabbedFrame` 单选项页 720 + `AF.Template.Form.Build` 表单行带逐项重置 + `AF.Template.AboutPage.Build` 结构化关于页）；主题色改走 `AF.ApplyAccent`（新「主题色」分区，颜色控件入库 `AF.Widget.Color`），删除自带 `ACM.COLORS`/`accentRefreshers`/`Solid`/`AddBorder`/`SetTextSize` 与主题派生公式；`ResetSettings` 改为窗口整体重建；小地图保留 PT 原型（库控件无右键）仅颜色走 `AF.Color("accent")`；`ChannelBar.lua`/`ChannelAbbrev.lua`/`InitDB.lua` 零改动；后续选项增多把 `TabbedFrame.Create` 的 `layout="single"` 改 `"multi"` 即切多选项页布局。

- v6-r001-b012 **强依赖 ade_AddonFramework 适配**：TOC 新增 `## Dependencies: ade_AddonFramework`；`Options.lua` 全量重写为库模板组合（`AF.Template.TabbedFrame` 单选项页 720 + `AF.Template.Form.Build` 表单行带逐项重置 + `AF.Template.AboutPage.Build` 结构化关于页）；主题色改走 `AF.ApplyAccent`（新「主题色」分区，颜色控件入库 `AF.Widget.Color`），删除自带 `ACM.COLORS`/`accentRefreshers`/`Solid`/`AddBorder`/`SetTextSize` 与主题派生公式；`ResetSettings` 改为窗口整体重建；小地图保留 PT 原型（库控件无右键）仅颜色走 `AF.Color("accent")`；`ChannelBar.lua`/`ChannelAbbrev.lua`/`InitDB.lua` 零改动；后续选项增多把 `TabbedFrame.Create` 的 `layout="single"` 改 `"multi"` 即切多选项页布局。
- v6-r001-b011 复选框改「填充满 + 空心勾」+ 滑块滑钮色/层级修正：① 复选框勾选时 `goldBright` 填满 14×14 方框、中间用 `ctrlBg` 色两笔线段勾（亮色填充上呈「空心」效果，对齐 GoodRange `Style.lua:242` `UI.Check` 的「填充满 + ink 空心勾」），未勾选为 `ctrlBg` 空框；② 单值滑动条 thumb 颜色由 `goldBright` 改回与进度填充同色 `gold`（不加亮），并把轨道由滑块子级改为同级、置于更低帧层级、滑块置顶，修正滑钮被轨道遮挡（规划 §2.5 / §2.10）。③ ADE 规划新增 §2.14「开关」控件规格（GoodRange 胶囊开关的方角改造，未实装）。
- v6-r001-b010 复选框由「整块填充色块」改为「中间打勾」：参考 GoodRange `Style.lua:242` `UI.Check`（空框 + 中间 tick），勾选标记改用 `Frame:CreateLine()` 自绘两笔 `goldBright` 线段（未勾选仅空框），不再与颜色编辑框混淆；`goldBright` 仍作勾选标记色，主题色变更经 `accentRefreshers` 即时重刷（规划 §2.5）。
- v6-r001-b009 设置界面控件替换：枚举切换格 `< 项 >`（`ChoiceCell`）改为下拉单选框 `DropdownCell`（§2.9）；数值步进格 `- 值 +`（`StepperCell`）改为单值滑动条 `SliderCell`（§2.10）。删除退役的 `ValueCell`/`ValueBox`；下拉菜单父级置于滚动区外的窗口 `frame` 以防裁剪，滚动/切页/按钮 `OnHide` 自动收起。
- v6-r001-b008 修复版本号显示双 `v`（`vv6-r001-b008`）：`ACM.version` 已带 `v`，但窗口标题版本行（`ver:SetText("v"..self.version)`）与关于页标题（`L.ABOUT_TITLE`）又各拼了字面 `v`；去掉多余字面 `v`，显示恢复 `v6-r001-b008`。
- v6-r001-b007 修复关于页带颜色文字不随主题色变化（去除 locale 写死 |cff...|r 转义，改用主题变量集渲染）；新增主题色变量集规范（同色系层级）。
- v6-r001-b006 修复设置窗口打开即崩溃（LiveSolid 漏传 layer）。
- v6-r001-b005 分隔线 + InitDB.lua 独立 + ADE v6 版本规范。
- v6-r001-b004 主题色扩展至控件/背景/文本着色。
- v6-r001-b003 主题色可配置（关于页末行）+ 图标取自 TOC。
- v6-r001-b002 设置窗口改单选项页 720 布局。
- v6-r001-b001 新增 PrimeTooltip 风格小地图按钮。
- v6-r001 首版：基于 ChannelBar 的 ADE 风格设置窗口。
