# CHANGELOG

## v6-r001-b016 - 2026-11-15

**实机反馈修复（十三）：b015 参数顺序回归——`AF.ThemeColor/ThemeColorTable` 定义成 `(key, alpha, owner)`，但全部调用点按 `(owner, key, alpha)` 传参，导致 `key` 收到控件本身、`alpha` 收到 `"accent"` 字符串，主题解析错乱并抛 `SetVertexColor` 参数错误，致使选项页构建中断（只剩「设置」按钮）。纠正定义为 `(owner, key, alpha)`，与 26 处调用点一致。**

## v6-r001-b015 - 2026-11-14

**实机反馈根因修复（十二）：主题色不随控件/页签/页脚传递——此前靠瞬态全局 `_activeTheme` + 逐方法补丁（`AddPage`/`ShowPage`/页脚）治标，仍漏页签。改为根因机制：主题色顺控件父子层级传递——`AF.Stylize` 给每个控件从 `parent` 链记自己的主题 `_afTheme`；框架公共着色函数 `AF.Tint`/`AF.RegisterTheme` 按「控件归属主题」解析（不再依赖瞬态全局）；新增 `AF.ThemeOf`/`AF.ThemeColor`/`AF.ThemeColorTable`，组件 `Paint`/hover 用同一公共函数带上自身主题参数。所有框架控件（按钮/勾选/滑块/下拉/开关/信息条/锚点/列表/重排/编辑模式遮罩/Form 行高亮/页签/页脚）统一跟色；换色时按归属主题重刷。删去 b014 的 `withFrameTheme` 逐方法补丁。**

## v6-r001-b014 - 2026-11-14

**实机反馈修复（十一）：标题栏页签按钮（及多布局侧栏页脚）仍不跟主题色——`AddPage`/`ShowPage`/`AddSidebarFooter*` 是窗体对象方法，由插件直接调用、绕过门面包裹作用域，控件创建时落到全局默认主题。`TabbedFrame` 在 `W.Create` 记录创建时活动主题（`frame._afTheme`），并在这些窗体方法内临时还原，使页签/页脚控件当下着色且换色时随 `ApplyAccent` 重绘。**

## v6-r001-b013 - 2026-11-14

**实机反馈修复（十）：改主题色只有窗体边框跟色、按钮/滑块/下拉/分隔线等控件不变——b012 漏包 `AF.Form`（`Template/Form.lua` 的顶层别名，设置页全部控件经 `AF.Form.Build` 创建），控件落进全局默认主题、只着一次默认色；主题门面补包 `Form` 后，控件创建与后续 `ApplyAccent` 均落在插件自有主题。**

## v6-r001-b012 - 2026-11-14

**实机反馈修复（九）：主题色跨插件串色——`Theme.lua` 原全局唯一 accent 派生表，`ApplyAccent` 改写它并广播 `ThemeChanged`，导致所有插件共享一个主题色（谁最后 `ApplyAccent` 谁赢）。改为「按插件隔离」：`GetFramework(major, silent, addonName)` 第三参数传入插件名时返回一个独立主题门面（自有 accent 派生 + 着色登记表）；控件/模板/配置页创建期间把该插件主题设为活动主题，其内部 `AF.Color/AF.Tint/AF.RegisterTheme` 自动落入该插件主题，实现「每插件独立主题色」。不传 addonName 返回裸库（共享全局默认主题，向后兼容）。已同步 adeTooltip/adeChatMod/ade_Demo 的 `GetFramework` 调用传入各自插件名。**

## v6-r001-b011 - 2026-11-14

**实机反馈修复（八）：单选项页标题栏右侧按钮错位溢出（adeTooltip/adeChatMod/ade_Demo 同现）——`AddRightButton` 旧实现只按第一颗按钮自身占宽定位、后续按钮链式向右排而不回移，页数一多直接压出窗口右缘并盖住 X 关闭钮；改为倒序锚定（2026-11-14 用户定稿）：以最右一颗右缘为基准（距 X 26px 安全区），第一颗按钮随总占宽向左让位，Visual 顺序仍 = AddPage 顺序，拖拽热区同步收窄。**

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
