# ade_UIKit CHANGELOG

## b050 - 2026-11-19（ListRow：排序按钮扩为四项 + CovenantSanctum 材质三态）

**按用户要求：预置 showMove 按钮由「上移/下移」两项扩为「移到最上 / 上移 / 下移 / 移到最下」四项——视觉从左到右（删除仍最右）；自右向左构建次序 = delete/moveToBottom/moveDown/moveUp/moveToTop，自定义 entryButtons 仍追加最左。材质按用户指定：单箭头（移一层）= `CovenantSanctum-Renown-Arrow` / `-Hover` / `-Disabled`；双箭头（移到顶/底）= `CovenantSanctum-Renown-DoubleArrow` / `-Hover` / `-Disabled`，均向左箭头：rotation −90° = 向上、+90° = 向下（b041 旋转实证）；hoverAtlas 走 EntryButton 既有 OnEnter/OnLeave 三态切换。新增 `ListRowMixin:MoveTo(idx, target)`（remove+insert 保序搬运）；首项禁用「移到最上/上移」、末项禁用「下移/移到最下」。三语补 `BOF_LIST_MOVE_TOP` / `BOF_LIST_MOVE_BOTTOM`。旧 backarrow/forwardarrow 组仍供 TabRow 使用。TOC bump v6.5-r001-b050。**
# ade_UIKit CHANGELOG

## b049 - 2026-11-18（ListRow：跨 list 帧复用 spec 固化修复——根因级 bug）

**b038 起遗留：Init 中 factory/SetupEntry 闭包捕获局部 spec，而 Panel 行池跨 list 复用 ListRow 帧时（`if not self.View` 跳过重建），固化的 spec 使 display/getItems 用错列表——宿主两个列表切页互换复用后：① display 用错（分类 value 走装备 display `_G[value]` nil → 显示原串 key，奇偶交替）；② RenderEntry 的 count 按错表 → ▲▼ 禁用错乱；③ SetupEntry 按钮实体仅首次构建 → 自定义 entryButtons 串位到另一清单（adeBagPack 中文客户端实测三现象同源）。修：① factory 回调改 list.Spec 动态取；② SetupEntry 拆出 BuildEntryButtons——按钮集按 spec 表身份重建（同 spec 复用跳过；异 spec 先 Hide 全部旧实体（AllEntryButtons 防泄漏）再重建，ButtonUp/Down 重指）。**
# ade_UIKit CHANGELOG

## b048 - 2026-11-18（ListRow：display 错误显式化 + onClick 传 owner）

**① RenderEntry 的 display 包 xpcall（handler=tostring）——宿主 display 报错时行文本显式显示 ERR+消息（诊断纪律，Debug.lua b046 先例），渲染不再中断；此前错误中断渲染 → 行池残留上一轮文本 + ▲▼ 禁用状态错乱（adeBagPack 分类清单实测表现：显示原始 key、多行 ▼ 误禁用）。禁用状态设置移到无条件路径（错误时也执行）。② 自定义 entryButtons 的 onClick 第三参新增 = 按钮自身（向后兼容），宿主可作 MenuUtil.CreateContextMenu 的 owner 定位（adeBagPack「添加规则」菜单用）。**
## v6.5-r001-b047 - 2026-11-18

**清单尾部按钮顺序与留白（用户指定「上移、下移、删除」顺序 + 最右按钮右侧留白）：预置按钮视觉顺序改为 上移 → 下移 → 删除（删除恒在最右），布局自右向左按数组次序放置故构建次序改为 delete/moveDown/moveUp、自定义 entryButtons 仍在最左（追加语义不变，frame.ButtonUp/ButtonDown 按 action 名引用不受顺序影响）；首个（最右）按钮右侧留 6px 空白（原 0px 紧贴边框），其余按钮间距 2px 不变。**
## v6.5-r001-b046 - 2026-11-18

**清单尾部按钮指向高亮（用户要求「常态调暗些、指向高亮」）：ListRow 尾部三按钮（▲▼✕ 及自定义项）常态图标调暗至 0.6 灰，悬停提亮发白（1.3,1.3,1.15）作为指向反馈，禁用态仍由 -disable 灰材质承担（不叠加调暗）；TabRow 页签顺序行箭头（Normal/Pushed 纹理）同步同款视觉。**

## v6.5-r001-b045 - 2026-11-18

**ListRow 排序形式三规格（用户要求，后续带拖动顺序需求的清单控件沿用同语义）：`spec.reorder = "buttons"`（仅按钮，拖动 behavior 不挂载）| `"drag"`（仅拖动）| `"both"`（默认；无此字段时行为与 b038-b044 一致 = showMove 按钮 + 恒拖动，向后兼容）。showMove 控制按钮显隐的语义不变。**

## v6.5-r001-b044 - 2026-11-18

**ListRow 尾部按钮去外框（用户反馈「外框偏大，或去掉」）：弃用 WowStyle2IconButtonMixin 的 common-dropdown-c-button 底框（26×25 原生 atlas 对 14px 图标明显偏大），改裸材质风格与 TabRow 页签顺序行箭头统一——按钮 20×20、图标 16×16，悬停反馈 = 图标提亮发白（SetVertexColor 1.3），禁用态由 -disable 材质承担（OnEnable/OnDisable 自管切换），rotation 与文字兜底模式保留。**

## v6.5-r001-b043 - 2026-11-18

**ListRow 两处修正（用户实测 _debug.log）：① 条目空白 = b042 把 OnButtonStateChanged 当 script handler SetScript 报「Usage: self:SetScript(...)」且初始化中断——它实为 lua 方法；照 OptionRow.IconButton 成熟做法重写（绑定 mixin 脚本集 + 调 OnLoad，实例覆盖 button.OnButtonStateChanged：Background 走 mixin GetBackgroundAtlas 四态、Icon 固定 14×14 + 旋转自管）；② 拖动写回报「elementData (a number value)」= WriteBack 枚举误调 GetData()——官方 OnDragStop 已用 provider:Remove/InsertAtIndex 真实重排 collection（ScrollUtil.lua:1447-1498），CreateDataProvider 不包装 elementData、collection 元素即原始数据，EnumerateEntireRange 产出 (index, value) 直接取 value 写回，并省去冗余 Refresh（provider 已正确且 ScrollBox 随事件自动重渲染）。**

## v6.5-r001-b042 - 2026-11-18

**ListRow/TabRow 两项修正（用户实测）：① 悬停变形 = WowStyle2IconButtonMixin 的 OnButtonStateChanged 对 Icon 调 SetAtlas(atlas, UseAtlasSize) 重置为 atlas 原生尺寸并丢旋转（common-icon-* 原生远大于 14×14）——EntryButton 覆盖 OnButtonStateChanged：Background 仍走 mixin GetBackgroundAtlas 四态按钮底，Icon 固定 14×14 + 旋转自管；② 箭头方向用反 = SetRotation 正值实为视觉逆时针（b041 的 +90° 把向左箭头转成了向下）——ListRow 预置项与 TabOrder.ArrowButton 一并改 -90°（顺时针：向左→向上、向右→向下）。**

## v6.5-r001-b041 - 2026-11-18

**ListRow/TabRow 交互与观感修正（用户实测五项反馈）：① 拖动无效报错 = 官方 behavior 默认 cursorFactory 为空，拖动开始 AcquireFromPool(nil) 报「templateInfo (a nil value)」（ScrollUtil.lua:921）——显式 `SetCursorFactory`（CharacterSelectList.lua:240-242 官方先例），ghost = InsetFrameTemplate 边框 + 候选条目文本（cursor 路径 initializer 实参签名与正常 acquire 不一致，不复用条目 initializer）；② 斑马纹改 WHITE8X8 淡白交替（alternate 0.07/0）——auctionhouse-rowstripe atlas 在黑底上无感；③ ▲▼✕ 文字改材质（字体缺字形显示乱码），用户指定组：common-icon-delete/-disable（删除）、common-icon-backarrow/-disable 旋转 90°（上移，视觉向左→向上）、common-icon-forwardarrow/-disable 旋转 90°（下移）；④ 首项 ▲ / 末项 ▼ 自动禁用（渲染时按 idx SetEnabled，disabledAtlas 自动切换）；⑤ TabRow 页签顺序行的 ArrowButton 同步换这组材质（SetRotation 三个状态纹理）。**

## v6.5-r001-b040 - 2026-11-18

**修复 ListRow 实跑报错（用户实测 _debug.log 两处）：① `SetElementFactory` 内层回调第二参是数据值本身而非 elementData（Kinds.InitList 的 `(host, data)` 同款签名）——b038 误写 `elementData:GetData()` 报「attempt to index local 'elementData' (a number value)」，条目渲染整体中断（列表空白 + 按钮组成孤块，demoList 为 number 数组正好触发）；Move/Delete 的 idx nil 同源。② EntryButton 文字 FontString 未 `SetFontString`——▲▼✕ 显示为空白方块。两处修正后条目/斑马纹/尾部按钮正常渲染。**

## v6.5-r001-b039 - 2026-11-18

**新增外部插件加载状态 API 与函数式 desc（外部支持选项统一口径的库侧支撑，规范 _docs/External-Addon-Support-Convention.md，用户明确要求「所有 ADE 系列插件外部联动选项按加载状态禁用，不得静默闲置」）：① `lib.IsAddOnLoaded(name)`（Core/Namespace.lua，封装 C_AddOns.IsAddOnLoaded，name = 目标插件 TOC 目录名）；② `option:GetDescription()` 支持 spec.desc 为函数（每次取描述求值）——未加载时动态提示「未检测到 XX，此选项已禁用」。disabled 函数式每次 Refresh 重估（既有能力）与函数式 desc 配合构成完整口径。注：已退役的 ade_AddonFramework 全量核查并无加载 API（仅 _G.ResolveNamespace/GetFramework 库加载仲裁），此 API 由 UIKit 承载。**

## v6.5-r001-b038 - 2026-11-18

**新增 kind="list" 列表行控件（Widget/ListRow.lua，计划 _docs/plans/ade_UIKit-ListRow-dev-plan.md 全规格）：① 拖动排序 = 官方 `ScrollUtil.AddLinearDragBehavior` + `SetReorderable` + `SetDragRelativeToCursor`（Inside=交换、Above/Below=插入，ScrollUtil.lua:1450-1520 实证直接重排 DataProvider），宿主数组写回走 `SetFinalizeDrop`（OnDragStopInternal 的 finalizeDrop，:853-857/1069）——getItems() 数组引用契约（旧 adeBackpack ListFrame 同款）；② 拖入物品/法术 opt-in（spec.accept）→ OnReceiveDrag + GetCursorInfo + IG_ABILITY_ICON_DROP 音效，条目上=插入该条目前、空白区=追加，spec.unique 去重，spec.onDrop 自定义口；③ 条目 = 图标/文本/声明式尾部按钮（entryButtons + showDelete/showMove 预置），rowBuilder 高级定制口；④ bindings 声明式鼠标按键+修饰键（键格式 ButtonName[+修饰键...]）；⑤ 斑马纹 RegisterAlternateRowBehavior + auctionhouse-rowstripe-1/2；⑥ 缩进遵循组合类规则 16+indent×20；空态文案；spec 校验 error 暴露（无兜底纪律）。Kinds 注册 kinds.List（Height 按可见行数）+ kindMap + Normalize List 分支；三语补删除/上移/下移文案；demo「其它形态」页接入演示（拖入物品/排序/绑定）。**

## v6.5-r001-b037 - 2026-11-18

**修复「修改项黄色前置标识变黑」并重做色块观感（用户实测反馈）：① 根因 = b034 新增色块按钮误用 `build.Color` 名称——覆盖了 Parts.lua 的纯色 Texture 积木 `build.Color(frame,layer,r,g,b,a)`（ChangedBar 前置标识同用），变更条被建成了黑边按钮。色块控件更名 `build.ColorSwatch`，build.Color 积木恢复生效。② 色块外观对齐暴雪原生 ColorSwatchTemplate（Blizzard_SharedXMLBase/ColorSwatch.xml:3-39 + ColorSwatch.lua Mixin，Lua 复刻不用 XML 模板）：16×16 三层嵌套方块——金色外框 14×14（HIGHLIGHT_FONT_COLOR）→ 黑框 12×12 → 色块 10×10；悬停外框变 NORMAL_FONT_COLOR（OnEnter/OnLeave 同款）；texelSnappingBias=0/snapToPixelGrid=false 防像素错位。**

## v6.5-r001-b036 - 2026-11-18

**修复 color 行整行消失（用户实测）：b034 新增 kind="color" 时漏登 `Kinds.lua` 的宿主 kind 归一化表（kindMap）——fallback `gsub("^%l", upper)` 生成未知 Kind="Color"，kinds 表无定义，Flatten 丢弃该行。kindMap 补 `color = "Option"`；复查全库其余按 Type 枚举的分支（行高/with 组合/搜索/页脚）均与 color 兼容，无同类遗漏。**

## v6.5-r001-b035 - 2026-11-18

**select 材质菜单项文字可读性修复（用户实测：材质铺满整行后材质名称被盖住，DBM 同款问题）：initializer 中把 button.fontString 提到 OVERLAY 层（fs:SetDrawLayer）并加深阴影（SetShadowColor 黑色 / SetShadowOffset(1,-1)），材质保持 BACKGROUND 层铺满整行——效果 = 文字浮于材质之上。排序问题为宿主数据源缺陷（哈希表 pairs 展开乱序），UIKit 不强排（items 顺序可能是宿主意图），宿主改为有序数组（adeStatPlus r007）。**

## v6.5-r001-b034 - 2026-11-18

**① 修复 execute 类型点击静默失效（用户实测 adeMapExt 颜色按钮无反应）：根因 = 宿主 KeySpec 类包装无条件给 spec 塞 set，MakeOption 的 Set 分支 `if spec.set … elseif spec.onClick` 使 onClick 永不执行、点击反而执行 set(true) 污染存档——Execute OnClick 改为 onClick 优先（仅用户点击路径；程序化 Set/Reset 仍走 set，避免 Reset 误弹 onClick）。② 新增 kind="color" 颜色选择器控件：64×18 色块（BackdropTemplate WHITE8X8 着色 + 1px 黑边，实色显示当前存档色），点击弹官方 ColorPickerFrame（12.x 契约 SetupColorPickerAndShow；swatchFunc 实时回写 + 刷新色块，cancelFunc 经 closure 捕获 startHex 直接还原）；get/set/default 均为 8 位 hex（AARRGGBB，CreateColorFromHexString 只接受 8 位），hasOpacity 由 spec.opacity 开启（GetColorAlpha 写 alpha 位）；色块几何 Parts.placement.Color（右列、与 Input 同内缩）。optionTypes 八类。demo 补 color 演示项。**

## v6.5-r001-b033 - 2026-11-18

**字体预览 Font 对象创建改为带唯一名 `CreateFont("BOF_SELECT_FONT_PREVIEW_"..value)`（官方用例均带名，FontableFrameMixin.lua:120；DBM 同模式；匿名 CreateFont 无官方先例），修正初次实现中循环变量名误用导致的同名冲突风险（同名 CreateFont 返回既有对象，会让全部字体项渲染成同一种字体）。**

## v6.5-r001-b032 - 2026-11-18

**select 材质/字体预览按 DBM 真实实现重做（用户反馈 b031 无效果；参照镜像 DBM-GUI\DBM-GUI_DropDownNEW.lua:160-181 与 DBM-GUI.lua:170-206 的 MixinSharedMedia3 数据源）：① 材质项改为 AttachTexture 铺满整行（`TOPLEFT(15,0)`/`BOTTOMRIGHT` + return 200,25，DBM 同款，弃 b031 右侧小长条与 fontString 改锚）；② 新增字体项——`CreateFont` 在菜单外创建（可缓存）、initializer 内 `button.fontString:SetFontObject`，⚠ DBM 源注释实证 initializer 内直接 SetFont 会静默失效；③ spec 契约扩展：items 项 `texture`/`font`(+fontsize/fontflags) 字段，spec.preview(value) 返回 string=材质 / table={font,size,flags}；④ adeBlizzDemo 接入材质下拉（4 种原生状态条材质）与字体下拉（4 种原生字体）演示页。根因备忘：b031 仅加字段无任何宿主接入，故测试无效果。**

## v6.5-r001-b031 - 2026-11-18

**select 类下拉支持材质直接预览（用户需求：材质下拉直接显示效果）：① 菜单项——items 项新增 `texture` 字段或 spec 级 `preview=function(value)`，`CreateRadio:AddInitializer` 内 `button:AttachTexture()` 渲染 84×18 材质长条、文字右移（官方 11_0_0_MenuImplementationGuide.lua:268-291 货币图标同款，Attach 区域菜单关闭自动回收）；② 选中区——Dropdown 新增 BACKGROUND 层 `Preview` 纹理铺满（SetBackdrop bgFile 同为拉伸铺满，观感即实际效果），◄ ► 步进/点选时经 `RefreshPreview` 实时换材质。UIKit 不依赖 LSM：LSM 名→路径转换由宿主 `spec.preview` 完成。**

## v6.5-r001-b030 - 2026-11-18

**标签条左右箭头定位修正（实机截图：两箭头均偏上）：根因 = `MinimalTab` 模板的 tab 可见图形锚 `BOTTOMLEFT/BOTTOMRIGHT` + `UseAtlasSize`（MinimalTab.xml），内容贴按钮底、按钮上部留空，箭头按按钮几何中心放即视觉偏上 6~8px——修正为箭头中心下移补偿 `ARROW_Y_NUDGE=8`（opts.nudge 可调）；左箭头向左偏移 `ARROW_LEFT` 14→10（b027 已 32→14，本轮再向左贴窗口左缘）。官方 Blizzard_SettingsPanel 的 GameTab 锚 `TOPLEFT x=32 y=-27` 证实 TAB_TOP=-27 与我们一致、且官方原生面板无箭头（无官方箭头 y 参照），补偿量按实机观感微调。**

## v6.5-r001-b029 - 2026-11-18

**控件文件去「Row 场景前缀」、按内容本质重命名（仅文件名与注释，代码与加载序不变）：`RowParts→Parts`（通用积木，FitButton 自 WindowTabs 收编）、`RowKeyButton→KeyButton`、`RowText→StaticText`（Header/SubHeading/Note 全静态文本）、`RowOption→OptionRow`（组合控件专名）、`RowGrid→CheckGrid`（复选网格）、`RowTabList→TabOrder`（页签排序）、`RowLinks→Links`、`RowCards→Cards`、`WindowSearchUI→WindowSearch`；TOC 加载序不变（只换文件名），Kinds/ScrollTabs/Window 族其余文件名不动。**

## v6.5-r001-b028 - 2026-11-18

**① 顶栏标签滚动提炼为独立 API：新增 `Widget/ScrollTabs.lua`，`lib.CreateScrollableTabStrip(parent, opts)`（限宽 + 横向滚动 + 端点箭头四态 + 滚轮），窗口 `WindowTabs.lua` 只做数据接线（Internal.Tabs → strip:SetTabs / SetSelected）；b027 的全部实跑教训内化到 API 实现（无 0×0 中间层、偏移设首钮锚点、EnableMouseWheel/OnMouseWheel、箭头 x 基准含 BodyRight）。② 控件代码按单控件/控件家族拆分（原 RowFrames.lua 384 行 + RowMixins.lua 795 行 + WindowMixin.lua 518 行 → 12 个职责单一文件）：`RowParts`（积木：Text/Color/Finish/Row/Hover/CheckButton/RowGeometry/Protected·Ask 升 Internal 单一来源）、`RowKeyButton`（键位按钮）、`RowText`（文本行族）、`RowOption`（选项行组合控件 + MakeOption 适配 + 键位捕获）、`RowGrid`（网格行族）、`RowTabList`（页签排序行）、`RowLinks`（搜索结果行族）、`RowCards`（卡片行族）；窗口侧 `WindowMixin.lua` 精简为生命周期/字符串/tooltip 核心，拆出 `WindowTabs`（标签接线）、`WindowPage`（导航+页面填充）、`WindowFooter`（页脚/确认/默认值）、`WindowSearchUI`（搜索挂接，算法仍在 Search.lua）。TOC 加载序按依赖重排；对外行为与 API 面不变（新增 CreateScrollableTabStrip），KAF 溯源行号注释逐块保留。**

## v6.5-r001-b027 - 2026-11-18

**设置窗口顶部插件切换标签区限宽 + 横向滚动（修复系列插件多时最右标签与搜索栏重叠）：tab 区右界收在搜索框左缘留 12px 安全空白（左箭头 + clip 容器 + 右箭头，CatalogShop `NavigationBarTemplate:601-630` 官方同款布局）；内容超宽时两侧显示箭头按钮，点击步进 60px、标签区滚轮同效，已滚到端点该侧置 disabled 态，未超宽时箭头隐藏。箭头四态 atlas `shop-header-arrow / -hover / -pressed / -disabled`（默认箭头向左，右钮 `SetTexCoord(1,0,0,1)` 镜像，CatalogShop Elements.lua:82-87 官方同款翻转）；标签按索引复用与选中态逻辑不变，仅宿主由窗口改为 clip 内 Content frame（滚动偏移驱动）。实跑修正：滚轮启用 API 三处——`RegisterForMouseWheel` 在 12.x 已整体移除（Frame/Button 均无，实证 _debug.log 两次报 nil）→ ScriptRegion 层 `EnableMouseWheel`（SimpleScriptRegionAPIDocumentation.lua:95）；handler 名为 `"OnMouseWheel"`（写 `"OnWheel"` 报 SetScript bad argument #2）；方向惯例 `delta * -1`（滚轮向上=回滚到开头，ScrollableTabsContainer.lua:27）。滚轮只挂 TabClip。几何实跑修正：右箭头改与左箭头共用同一 y 公式、直接相对窗口顶定位（原锚搜索框 TOPLEFT+51 的 y 推算与实际锚定链不符，上偏）；TabClip 两锚点 y 统一为 TAB_TOP（原双顶锚 y 错位致矩形畸形，SetClipsChildren 把标签整条裁掉）；x 基准补 `BodyRight` 偏移（搜索框锚 body 而非窗口右缘，差 18px 致右箭头压搜索框）；删除 0×0 的 TabContent 中间层、标签直接挂 TabClip（SetClipsChildren 递归裁剪按层 rect 求交，无尺寸中间层把子帧裁空——官方 ScrollableTabsContainer 的 Contents 双锚填满、标签是它直接 child），滚动偏移改设在首钮锚点（官方 Update():227 同款）；左箭头位置独立常量 ARROW_LEFT=14（原沿用 TAB_LEFT=32，实机观感偏右）。**

## v6.5-r001-b026 - 2026-11-18

**select 下拉开启滚动（`root:SetScrollMode(500)`，实证 Blizzard_Menu/Menu.lua:227：新 Menu 系统默认不滚动、超出屏幕即截断；暴雪自家下拉取 400–600）——修复 LSM 材质等长列表下拉无法滚动。**

## v6.5-r001-b025 - 2026-11-18

**select 行 `option:GetValues()` 支持 `spec.items` 为函数（MINOR 11→12）——调用时求值；行 Init/Refresh 每次渲染都重跑 GetValues，动态下拉（LSM 介质、外部插件来源可用性）不再依赖宿主手动重建快照。**

## v6.5-r001-b024 - 2026-11-18

**新增 `lib.GetAddonMeta(addonName)`（Function/Meta.lua，MINOR 10→11）——一次读取插件 TOC 元数据（Title/Version 按客户端 locale；icon 归一为三态 spec：`## IconTexture` 优先于 `## IconAtlas`，纯数字 IconTexture 转 FileID number），返回值可直接传 `CreateMinimapButton` 的 `icon` / `ApplyIcon`；`CreateMinimapButton` opts 注释补三态 icon 说明。**

## v6.5-r001-b023 - 2026-11-17

**公共 API 文件统一迁入 `Function/` 子目录（Util/Format/Icon/ShareString/Callbacks/API，加载顺序与 `lib.X` 名称不变）；新增 `lib.RegisterOptionsStub(spec)`——照 KAF Stub 在原生「设置 > 插件」注册「打开选项」入口页；MINOR 9→10**

## v6.5-r001-b022 - 2026-11-17

**TextRow 增加就地 `Refresh`（函数式 Text 每次重算），修正状态/错误提示须切页才显示；MINOR 8→9**

## v6.5-r001-b021 - 2026-11-17

**note 行支持 `indent`（文字与行高同步缩进），`multiline` 框锚点跟随标题缩进，使宏体框/说明行与「宏体」标题左缘对齐；MINOR 7→8**

## v6.5-r001-b020 - 2026-11-17

**`ShareString` payload 泛化（不再硬编码 `profile` 字段，由宿主 validate 决定结构）；多行框 backdrop 补 `edgeSize=1` 修复边框变形；MINOR 6→7**

## v6.5-r001-b019 - 2026-11-17

**`multiline` 行改为可滚动 ScrollFrame+EditBox、标题缩进跟随 NameLeft；新增 `ShareString` 配置分享字符串 API（CBOR→压缩→Base64）与 multiline 的 `onTextChanged`/`onEditBox` 回调；MINOR 5→6**

## v6.5-r001-b018 - 2026-11-17

**新增 `kind="multiline"` 内嵌多行文本行（OptionRow 复用，label 贴顶、失焦提交、可只读），供宏体等长文本设置直接就地编辑；MINOR 4→5**

## v6.5-r001-b017 - 2026-11-17

**新增零依赖公共 API：图标三态解析/绘制/文本转义（Core/Icon.lua）与自绘小地图按钮工厂（Widget/MinimapButton.lua）；MINOR 3→4**

## v6.5-r001-b016 - 2026-11-17

**删除 GetStrings 的硬编码中文兜底（缺译文直接回显本地化 key）；搜索栏宽度由 350 减半为 160（Core/Config.lua 与 Widget/Kinds.lua 同步）**

## v6.5-r001-b015 - 2026-11-17

**新增公共 API：`Core/Util.lua`（路径读写/数值校验/颜色互转/DB 默认值合并，提取自 ade_apis 与 ade_AddonFramework）+ `Core/Format.lua`（FormatDate 日期格式化，含 Krowi 七预设与本地化月/星期替换）；MINOR 2→3**

## v6.5-r001-b014 - 2026-11-17

**按实测日志修复两项：tooltip 改用暴雪原生 SettingsTooltip（自建 GameTooltipTemplate 比原生大 1.5 倍）；键位 Slots 的 Get/Set 补 self 参数（冒号调用参数错位导致 table 流入 SetBinding）**

## v6.5-r001-b013 - 2026-11-17

**按 debug log 修复：tooltip SetOwner 断言（改 ANCHOR_NONE + SetPoint 到控件右缘，视觉仍为原生右侧浮出）**

## v6.5-r001-b012 - 2026-11-17

**Tooltip 对齐暴雪原生选项（锚定悬停控件 ANCHOR_RIGHT）；补 with 控件的说明分支**

## v6.5-r001-b011 - 2026-11-17

**Tooltip 锚定对齐暴雪设置窗口样式；key 恢复默认清全部键位槽；导航树首组头贴顶**

## v6.5-r001-b010 - 2026-11-17

**按 _debug.log 实证修复三处崩溃/坏功能：mouseButtons 作用域、搜索 and/or 截断、确认条「否」无文本**

## v6.5-r001-b009 - 2026-11-17

**Tab 点击补切换音效；补齐 KAF 的「搜索全部 / 搜索描述」复选框与多 Tab 分组搜索**

## v6.5-r001-b008 - 2026-11-17

**键位显示防空串并补鼠标侧键/滚轮捕获；左侧导航树按 KAF 对齐（头部字体/锚点、按钮状态机、新标识不改色）**

## v6.5-r001-b007 - 2026-11-17

**逐行对齐 KAF 布局：All/None 回归 Sub 家族行、GridHeaderRow 恢复纯列标题、GridRow 五列 CENTER 锚点与空单元格隐藏**

## v6.5-r001-b006 - 2026-11-17

**按 KAF 家族行布局把全选/无并入矩阵标题行并修复点击刷新；补全四个缺失的三语文本**

## v6.5-r001-b005 - 2026-11-16

**按 KAF 层级补齐缩进：SubHeading 与无 SubHeading 的选项同为 X 级，其下选项自动进一级到 2X（显式 indent 优先）**

## v6.5-r001-b004 - 2026-11-16

**五处按 KAF 复刻修正：滑块两位小数、All/None 按钮锚点、矩阵表头黄字、搜索占位符去省略号且输入时隐藏；Demo「组合控件」升为分组标题**

## v6.5-r001-b003 - 2026-11-16

**补齐 KAF 控件契约：修正控件类型判定、滑块初始化与变更回调、With 组合/双键位/文案透传；CardRow 与 TabRow 改为完整渲染**

## v6.5-r001-b002 - 2026-11-16

**内容区标题下分隔线恢复 KAF 原生 630px 全宽（原误设 32px 导致过短）**

## v6.5-r001-b001 - 2026-11-16

**按 KAF 补齐按键按钮构建时的 EnableKeyboard(false)（修复可见即吞键）；「新」标签改为贴名字左侧右对齐**

## v6.5-r001 - 2026-11-16

**从 KAF Krowi_Options 2.0 全量重写：两栏窗口、双层行池、签名就地刷新、按键绑定、名称搜索、原生 tooltip；丢弃 list/RichDescription 等自造模块**

## v6-r001-b008 - 2026-11-16

**三处按 KAF 源码复刻：银色九宫格按键绑定控件、搜索清空还原与匹配语义、恢复按钮双命中显隐**

## v6-r001-b007 - 2026-11-16

**彻底删除底部两个搜索选项：控件、跨 Tab/描述命中逻辑、存档字段与三语文本全清；顶部搜索框保留**

## v6-r001-b006 - 2026-11-16

**修复按键绑定按钮与图片放大遮罩吞掉全部按键；恢复按钮闪烁与 tooltip 残留；移除底部搜索加强选项；右侧留安全距离**

## v6-r001-b005 - 2026-11-16

**首个组头占据 KAF「概览」位置；内容行起点比页标题右移 19px；清除残留按键捕获避免吞掉 ESC**

## v6-r001-b004 - 2026-11-16

**修复 ESC 关窗（改用加载期注册的代理帧）与左侧组头底图拉伸不一致**

## v6-r001-b003 - 2026-11-16

**视觉对齐 KAF：补 Options_InnerFrame 切片/分隔线/页标题，重置按钮移到标题左侧，组标题白/项标题黄+层级缩进**

## v6-r001-b002 - 2026-11-16

**修复选项行 tooltip 报错（可选 get 为 nil）与 ESC 无法关闭窗口（登记 UISpecialFrames）**

## v6-r001-b001 - 2026-11-16

**修复 `/bofdemo` 无反应：ShowTab 补上 frame:Show()，此前建窗后一直处于隐藏状态**

## v6-r001 - 2026-11-16

**首版：两栏原生风格选项窗库（多插件 Tab / 搜索 / 原生控件 / 改值与重载标识 / Grid / 动态 List / 富描述 / 自带回调）**
