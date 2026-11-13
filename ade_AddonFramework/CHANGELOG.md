# CHANGELOG

## v6-r001-b010 - 2026-11-14

**预览面板组件化（adeTooltip 开发计划 §九/§十，用户确认「预览面板的创建是单独组件，双布局只留开关」）：新增 `Template/PreviewPanel`（`New/AttachTo/SetAnchor/SetBuild/SetRefresh/Refresh/Show/Hide/Toggle/BindButton`，外框主题色边、内容首次显示构建、主窗隐藏联动隐藏、绑定按钮自动切换 `AF_PREVIEW_OPEN/CLOSE` 文案并接管 OnClick）；`TabbedFrame` 删除内嵌预览（原 opts.preview 块与预览按钮块），只保留开关位（`titleBar:AddRightButton` / `AddSidebarFooterButton` / `AddSidebarFooterCheckbox`），新增 `onPageChanged`/`SetOnPageChanged` 页切换回调供预览联动；`Form` 新增 `spec.enabled`（布尔或函数，禁用态 = 标签灰化 + 控件半透明 + 鼠标遮挡层 + `Refresh()` 重算，遮挡层方案因子帧不受 `EnableMouse(false)` 影响）与 `ScrollToRow(scroll,key)`/`HighlightRow(key)`（主题色底纹 1.5s 消退，供预览点击定位设置项）；`ade_Demo` 迁移到组件并演示页切换联动（三语新增 `DEMO_PREVIEW_PAGE`）。**

## v6-r001-b009 - 2026-11-14

**布局调整（ADE-v6-FrameDesign，2026-11-13 手绘图定稿）：单选项页布局页切换按钮移入标题栏右侧（顶部页签取消，内容区顶距 66→38 与多布局一致），可选预览按钮也在标题栏最左；多选项页布局左栏底部新增页脚区——复选框固定最底槽位（如「小地图图标」）、按钮自其上方堆叠（如「打开预览」）；新增预览面板（窗口左侧独立面板，`opts.preview` 启用，主窗隐藏时一并隐藏，内容首次打开构建一次）；`TitleBar` 新增 `AddRightButton`（右侧按钮区随占宽自动收窄拖拽热区）；三语新增 `AF_PREVIEW_OPEN`/`AF_PREVIEW_CLOSE`。**

## v6-r001-b008 - 2026-11-14

**实机反馈修复（七）：多行编辑框「未达滑块最小高度却仍显示滚动条」——根因为 `ScrollUtil.InitScrollFrameWithScrollBar` 会替换 `OnScrollRangeChanged`，令模板自带的 `scrollBarHideIfUnscrollable` keyvalue 失效；改为手工 `OnScrollRangeChanged` 钩子按 `GetVerticalScrollRange()` 显隐（范围≈0 隐藏、>0.5 显示，滚轮始终可用）。**

## v6-r001-b007 - 2026-11-14

**实机反馈修复（六）：多行编辑框文本错乱（测量串 FontString 透出与正文叠成两份 → measure:Hide()，配置页导出/导入框同修）；配置页导入实时校验失效根因为闭包在 local 声明前引用 importBtn（捕获成全局 nil）→ 前向声明修复，重命名弹窗同类隐患一并修；配置页导出/导入区照抄 MiliUI Tab_Share（列间隔 24、按钮锚框底、导出成功标题换 Ctrl+C 提示 + OnChar 全选防改、导入 pendingData 判断逻辑、导入确认弹窗、底部说明），新增 ImportData；重命名/重置/删除改红色（危险操作）；纵向分隔线改用调暗主题色与外边框区分。**

## v6-r001-b006 - 2026-11-14

**实机反馈修复（五）：关于页版本号 `vv` 前缀修复（TOC 已是 v 开头时不再重复拼 v）；命令/作者/致谢改为固定黄色 `[命令]/[作者]/[致谢]`，`/指令` 固定青蓝；多行编辑框未达可滚动范围时自动隐藏滚动条但滚轮滚动始终可用（scrollBarHideIfUnscrollable）；Demo 表单加入多种多行编辑框（长文本触发滚动条、空/短文本自动隐藏、宽框）。**

## v6-r001-b005 - 2026-11-14

**实机反馈修复（四）：行看板拖拽落点加竖直「光标」示意符（复刻 MiliUI 插入位直觉）；多行编辑框仅在高度变化时重设高度（修输入光标时隐时现）；表单多行编辑框加高到 120（解决滚动条滑块未达可滚动范围）；配置页重写对齐 MiliUI——按钮配色（新建/复制/重命名=accent、删除=red、导入=green）、共用档禁用重命名与删除、导入实时校验且标题提示「前缀不符/字符串无效」；下拉静置边框改回暗色与其他控件一致；标题栏图标与名称间留间距、侧栏纵向分隔条改用主题色、标题栏横向分隔条固定灰白。**

## v6-r001-b004 - 2026-11-14

**实机反馈修复（三）：主窗滚动条贴右缘+内容留位（修右缘控件与滚动条重叠；编辑框/清单滚动条水平位置回退）、Form 多行编辑框改走 onTextChanged 回调（修滑块不激活）、行看板拖拽复刻 MiliUI DropTarget 锚点前插（修同行只能到倒数第二/跨行只能到行尾）、清单列表拖拽 self nil 报错修复、配置档导出改 C_EncodingUtil 线格式字符串（ADEAF!1! 前缀）。**

## v6-r001-b003 - 2026-11-13

**实机反馈修复（二）：AnchorGrid 崩溃（CENTER 单元 nil 箭头）修复并恢复显示、RowDrag 拖拽结束改用 IsMouseButtonDown 轮询（旧版整行调序失败根因）并支持方块跨行/行内调序、多选项页侧栏与内容区纵向分隔线、标题栏插件图标、主窗边框恢复主题色、多行编辑框滚动条激活/可选显隐/整体下移/右侧不重叠、Form 行标签右对齐、清单列表拖拽调序、导出只输出 {}（新增 AF.DB.Serialize/Deserialize 并补种子数据）、组合模板迁 Template/ 目录（保留别名兼容）。**

## v6-r001-b002 - 2026-11-13

**实机反馈修复：1px 线改 MiliUI 像素公式 + 关像素贴齐（线过粗）、按钮/主窗边框改暗色细边不随主题、Locales 报错与「显示为 Key」、行看板改外部移动控件 + 多元素换行、九宫箭头方向修正、字体移至 assets/fonts。**

## v6-r001-b001 - 2026-11-12

**首版交付 P0–P5：ResolveNamespace 双形态注册表与 minor 仲裁、MiliUI 固定色阶与收窄着色、#EEE4AE 主题广播、双布局 720/860、配置页与关于页模板、逐项重置、行首移动控件整行拖拽、原生 Atlas 图标、全部素材真实拷贝登记。**
