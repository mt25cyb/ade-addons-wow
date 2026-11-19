# adeBagPack CHANGELOG

## v6.5-r001-a15 - 2026-11-19（逐项核对 119 件物品 + 诊断 stub 装备部位/tie-break 修复）

**应用户要求按最新存档与日志逐项核对全部 119 件物品：分类 idx 与物理槽位全部对应正确（逆序 desc=true 下 idx 1→100000 沿槽序单调不减），`286563` 落到末尾 idx=27、垃圾沉底 idx=100000、模拟整理「待搬移=0 全部已归位」——整理引擎本身无隐藏错位。核对中发现诊断假象：4 件 armor 的 `boundFirst` 在日志里看似交错，实为 `Debug.lua:MakeStub` 缺 `GetItemEquipLoc`（invSlot 恒 99，抹平装备部位维度）与 `GetGUID=nil`（丢 tie-break），使逐槽 SORTKEY 无法据以核对部位排序；a15 补齐第 9 列 equipLoc 与真实 GUID（按 GUID 缓存不与真实整理互污）。另记录待用户定夺的口径差异（未改行为）：`junkSource=builtin` 下 Poor 品质即垃圾，日志中 2 件任务类物品（278279/278397）被判 junk 沉底，而 Baganator 以 `not hasNoValue` 豁免无价值任务物品（OrderBags.lua:260-261）。TOC bump v6.5-r001-a15。**

## v6.5-r001-a14 - 2026-11-19（规则序号统一 + 精确规则覆盖宽泛）

**用户实测 a13 后「把 ItemID 286563 排在清单最后，实际却排在 #物品强化##其他 与药水之间」。根因两处：① 序号分层——ID/类型规则取数组下标（27）、分类规则取 `CATEGORY_BASE+下标`（1002），导致任何 ID 规则永远先于所有分类，拖到末尾也无法沉底；② `BuildCategoryOrder` 用分类条目重新计数（1..N）而非数组原始下标，会与类型规则下标撞号。a14 取消 `CATEGORY_BASE`：四类规则（ID / 类型 / 分类）统一取 CustomOrder 数组原始下标，冲突按「精确覆盖宽泛」——ID > 类型 > 分类（取最小下标会让末尾 ID 规则被靠前的宽泛分类拉回，违背用户意图）；未配置分类基线取规则总数之后，垃圾仍固定末尾。另修诊断 stub 缺 `GetItemType/GetItemSubType` 导致 a13 全背包 `idx=ERR:Rule.lua:51` 的连带错误。TOC bump v6.5-r001-a14。**

## v6.5-r001-a13 - 2026-11-19（自定义类型规则接线 + 垃圾固定沉底）

**用户实测「关闭垃圾对称整理后排序未按自定义顺序、垃圾排在非垃圾中间」，依最新存档/日志定位两处断点：① `RuleDialog` 四类规则生成的键里，`#主类##子类 / ##子类 / #主类` 类型规则只被 `Rule:GetTypeOrder` 读取，而 `GetTypeOrder` 从未接入 `GetSortKeys`/`GetCategoryIndex` → 用户新增的 `#物品强化##其他`（列表第 1 位）完全无效（日志 cat=itemenhancement idx=1008）。a13 新增 `GetCustomTypeOrder`（精确命中、不取 `__unknownOrder` 默认值以免误伤全部分类），`GetCategoryIndex` 与 ID 规则同列、取数组序号更小者，规则清单相对顺序真正生效。② `Categories` 顺序里 `junk` 在 `miscellaneous/usable` 之后，灰色杂项先命中前两类（日志 idx=1021/1022）绕过 junk 末尾判定 → 垃圾混在非垃圾中间；`GetCategoryKey` 前置 `IsJunkItem`（与对称整理同口径）返回 `junk`，分类键/末尾序号/垃圾段三者一致，关闭对称整理时垃圾也稳定沉底。另修诊断「物理槽=0」误导：`Group:InitSlots` 记录过滤前 `physicalSlotCount`，Debug 输出改用它。TOC bump v6.5-r001-a13。**

## v6.5-r001-a12 - 2026-11-19（垃圾对称整理真·双端槽位分配 + 旧档 junkZone 迁移）

**用户实测「垃圾对称整理未生效 / 整理未按分类顺序」根因：a11 只在 `Rule:SortItems` 里反排 `items`，而 `Group:FilterSlots` 会剔除空槽、使 `items[i]↔slots[i]` 紧密对齐——物理上无法产生「非垃圾与垃圾之间的空格」，反排等价于垃圾紧邻非垃圾，看不出对称。依 Baganator `Sorting/OrderBags.lua:246-328` 真实实现重构：`Rule:SortItems` 恢复纯排序；`Group:BuildItemSlots` 建立显式「物品→目标槽」映射——非垃圾按排序序从 slots 首游标递增、垃圾按排序序从尾游标递减，front/back 相遇后未消费的槽留空（即用户定义：100 格时非垃圾从格1、垃圾从格100、中间空）；desc 靠 `InitSlots` 反向生成槽表实现整体镜像（等价 Baganator isReverse 交换两段）。`Group:Pack`/收敛校验改走 `GetTargetSlot`，对称模式 `FilterSlots` 保留全部物理槽。`Core:Init` 在 MergeDefaults 前迁移旧档 `junkZone`（none→关、其余→开）为 `symmetricJunk` 并删旧键，解决现有存档无新键问题。`DebugSimulateSort` 改走真实 Bag:Sort 链、输出「当前槽→目标槽」映射，修正旧逻辑永远输出 0/0 的误导。TOC bump v6.5-r001-a12。**

## v6.5-r001-a11 - 2026-11-19（顺序不生效入口断点修复 + Baganator 式垃圾对称整理）

**「顺序不生效」入口断点（深挖确认，非排序引擎问题）：① Extra/Blizzard.lua 的 DoSort 在 Baganator 在场时直接 `return`——用户点原生整理按钮完全无动作（表现为顺序/添加都无效），a11 删除让位逻辑，三条入口（原生按钮 / Baganator 注册式 / 注入按钮）统一收敛 Pack:Start → BeginPacking → Rule:OnProfileUpdate（a10 已保证每次整理从当前 profile 重建顺序）。② Extra/Baganator.lua 注册式回调用 Baganator 传入的 isReverse 调 SetReversePack 覆盖本插件 desc——每次排序翻转物理方向，看起来像顺序没变；a11 忽略该参数，方向只认 adeBagPack 设置页。**

**垃圾对称整理（替代垃圾钉放区）：基于镜像目录 Baganator v862 真实实现 Baganator/Sorting/OrderBags.lua:169-359（双列表 + 双游标：groupA 非垃圾从 first 递增、groupB 垃圾从 last 递减，isReverse 交换两段；垃圾判定 junk plugin 回调优先、回退 Poor 且 hasNoValue 豁免）。adeBagPack 等价实现（单槽表 items[i]↔slots[i] + Group:InitSlots 方向扫描，无需改搬运引擎）：Rule.lua 删除 GetJunkZoneKey 与排序键首位垃圾维度；新增 Rule:IsJunkItem（Dejunk 接管/Poor，独立于分类——Poor 装备仍归垃圾段）；Rule:SortItems 排序后把垃圾从所有分类抽出、保持排序序追加末尾并**反排垃圾段**——垃圾[1] 落最后一格，正序 = 非垃圾正向/垃圾逆向，逆序 = 整体镜像；关闭 symmetricJunk 时垃圾仍固定末尾（a8 catIndex）。**

**配置切换：InitDB junkZone → symmetricJunk=true；Options sort section 的「垃圾钉放区」下拉改为「垃圾对称整理」开关（SORT_KEYS/sectionKeys 同步）；三语 LABEL/DESC_SYMMETRIC_JUNK 替换 JUNK_ZONE_*（117 键覆盖核对通过）；README 同步。TOC bump v6.5-r001-a11。**
# adeBagPack CHANGELOG

## v6.5-r001-a10 - 2026-11-19（分类顺序回归修复 + 垃圾固定末尾）

**① 顺序调整/添加整理不生效：Pack:BeginPacking 原来只 `Rule:ClearSortKeyCache()`，若设置页 onChanged 链未触发 `Rule:OnProfileUpdate()`，整理仍用旧 CategoryOrder/CustomOrder——改为每次整理调 `Rule:OnProfileUpdate()`（清缓存 + BuildRule 从当前 profile 重建，开销极小），确保调整顺序必然生效。② 添加分类后不实时显示：`AddRuleItem`/`onDrop` 只改数组 + 重建 Rule，UIKit ListRow 不会因外部数组变化自行重绘（只在自身增删改时 Refresh）——Options 顶部持有 tabRef（词法作用域需在 AddRuleItem 之前声明），两处变更后调 `tabRef:Refresh()`（Tab.Refresh → window:RefreshPage → 已构建行 row:Refresh）。③ 垃圾剔除出顺序调整并固定最后：Config.DefaultCategoryOrder 删 '@category:junk'；Core 首启迁移始终清理旧档 CustomOrder 残留 junk；RuleDialog 分类下拉过滤 junk；Rule:BuildCategoryOrder 跳过 junk（兼容旧档）；Rule:GetCategoryIndex 对 junk 在自定义 ID 规则之前返回固定末尾序号（CATEGORY_BASE+10000）。junkZone 物理钉区选项保留原语义（默认 auto/正序下垃圾在物理底）。TOC bump v6.5-r001-a10。**
# adeBagPack CHANGELOG

## v6.5-r001-a9 - 2026-11-19（子窗口固定在设置窗中心 + 遮罩排除标题栏）

**按用户反馈：① 添加规则子窗口 parent 改为 ade_UIKit 设置窗口（GetOptionsWindow 取 lib.WindowName），SetPoint("CENTER", window, "CENTER", 0, 0) 固定中心，移除 SetMovable/RegisterForDrag/OnDragStart/OnDragStop（不再可拖动）；② 模态遮罩由 SetAllPoints(window) 改为按 UIKit Geometry body insets 定位（TOPLEFT 18/-76、BOTTOMRIGHT -18/46，WindowLayout.lua:115-116 同款）——只覆盖内容区，标题栏不被遮罩、保持可操作。TOC bump v6.5-r001-a9。**
# adeBagPack CHANGELOG

## v6.5-r001-a8 - 2026-11-19（子窗口模态遮罩范围收窄至设置窗口）

**按用户反馈调整：a7 的全屏/全 UIParent 遮罩改为只覆盖 ade_UIKit 设置窗口内容区——遮罩 parent 取 `lib.WindowName`（"AdeBlizzOptionsFrame_Window"），`SetAllPoints(window)`，strata=HIGH + window:GetFrameLevel()+10（设置窗 strata=HIGH）；dialog 仍 strata=DIALOG（高于遮罩），MenuUtil 菜单不受影响；窗口隐藏时遮罩随之隐藏。TOC bump v6.5-r001-a8。**
# adeBagPack CHANGELOG

## v6.5-r001-a7 - 2026-11-19（添加规则对话框：tab 错位修复 + 模态遮罩 + 入口行去重）

**修复：添加排序规则子窗口四类型 tab 阶梯错位（中文客户端截图实证）——tab:SetPoint 后续按钮相对前一个 TOPRIGHT 且每次 Y-28，偏移累积。改全部相对 dialog 绝对定位（X 步进 100、Y 恒定 -28、按钮宽 96）。**

**新增：子窗口打开时启用全屏模态遮罩（ABPRuleDialogMask，FULLSCREEN strata、黑色 55% 半透明，吞鼠标/滚轮事件，背后设置页与状态计时面板不可操作）；dialog 同 strata 更高 level（20 > 10）；close/取消/添加/ESC（UISpecialFrames）经 OnHide 统一收遮罩。顺手修分类顺序 section 的 execute 入口行重复 label（左侧黄字 + 右侧按钮 → 仅保留按钮）。TOC bump v6.5-r001-a7。**
# adeBagPack CHANGELOG

## v6.5-r001-a6 - 2026-11-18（中文客户端实测修复：列表 key/禁用/按钮串位同源 bug + 添加规则对话框）

**修复（根因级，UIKit b049）：分类/装备两清单切页后显示 key、▲▼ 禁用错乱、+/T 按钮串位——三现象同源：ListRow:Init 闭包捕获局部 spec + Panel 行池跨 list 复用帧（`if not self.View` 跳过）→ display/getItems 固化为帧首次所在的列表（奇偶交替复用 → 中文与 key 交替、count 按错表）。factory 回调改 list.Spec 动态取 + 按钮集按 spec 身份重建（UIKit b049 详录）。**

**交互调整（用户反馈）：撤销 a5 的列表内 +/T 按钮（每行按钮不合适 + 跨 tab 复用串位），改回源插件 adeBackpack 同款「添加排序规则」弹出对话框——新建 UI/RuleDialog.lua（旧 Settings.lua:508-724 全量移植）：四类型 tab（按物品/按类型/按主类子类/按分类）+ 拖入物品槽（同时捕获 ID 与 #类型##子类，旧 OnRuleDrop 同款）+ 主类/子类两级下拉（12.x C_Item.GetItemSubClassInfo）+ 分类下拉 + 预览 + 添加/取消；旧 ADE 库件以手绘 BackdropTemplate 帧 + UIPanelButtonTemplate + MenuUtil 菜单轻量替代；可拖动、ESC 关闭（UISpecialFrames）。入口 = 分类顺序清单上方「添加排序规则…」按钮行（kind=execute）；列表拖入物品直接添加 ID 规则保留。三语补 RULE_* 15 键（核对全覆盖 65 键）。TOC 加载序 External→UI/RuleDialog→Options，bump v6.5-r001-a6。**
# adeBagPack CHANGELOG

## v6.5-r001-a5 - 2026-11-18（列表显示/禁用修复 + 「添加规则」入口移植）

**修复：分类顺序/装备部位顺序两清单显示原始 key + ▲▼ 禁用状态错乱。根因链：ListRow RenderEntry 的 display 调用未包保护——宿主 display 运行时报错即中断整行渲染（SetText 与 ▲▼ SetEnabled 均不执行）→ 行池残留上一轮文本、禁用状态错乱，与截图现象吻合（截图左上 UI 错误弹窗佐证有运行时错误）。修（UIKit b048）：display 包 xpcall（错误显式显示于行文本 = ERR+消息，诊断纪律非静默兜底）、禁用状态设置移到无条件路径；/reload 后每行会显示真实本地化文本或具体 ERR 位置，据此可定位残余根因。静态复核：GetRuleText（Config L385）/ABP.L 链/Categories key 集合/Options display 闭包/Kinds Normalize→MakeOption→ListRow Spec 传递全部通过。**

**移植：旧 Settings「添加规则」入口（旧 UI/Settings.lua:508-620 对话框）→ 分类顺序列表三个途径：① 「+」按钮 = 单层菜单列出全部分类（BuildCategoryList 同款）点击追加 @category:key；② 「T」按钮 = 物品大类单层菜单（GetItemClassInfo 枚举 0-20）追加 #大类名 规则；③ 拖入物品 = 添加物品 ID 规则（ListRow accept.item + onDrop 去重插入，旧 OnRuleDrop kind="id" 分支）。display 对数字条目显示「物品名 (ID:n)」（旧版裸 ID 升级）。旧对话框子类二级下拉暂缺。规则引擎对 ID/#类型条目的支持已核对（Rule:GetCustomOrder/GetTypeOrder 原样在位）。UIKit ListRow 自定义 entryButtons onClick 第三参 = 按钮自身（MenuUtil owner 定位）。三语补 RULE_ADD_CATEGORY/RULE_ADD_TYPE。TOC bump v6.5-r001-a5。**
# adeBagPack CHANGELOG

## v6.5-r001-a4 - 2026-11-18（P3.5 外部对接 + 恢复默认修复 + P4 收尾）

**P3.5 完成（External.lua）：① junkSource="dejunk" 排序侧判定接管（Config junk 分类 check 经 External:IsDejunkActive→DejunkApi:IsJunk(bag,slot)，pcall 双保险）+ DejunkApi:AddListener 监听过滤器变更重算 Rule 排序键缓存（切换来源即清理缓存；出售不接管）；② infoSource="itemera" 显示文本（External:GetExpansionText/GetProfessionText——ItemEra 隐式 API 只读 + 子表存在性/返回值域校验，版本漂移回退 nil；/adebp debug 逐槽输出追加 era=/prof= 字段）；③ baganatorSort/baganatorButton 挂卸随开关（Baganator:ApplySettings——排序回调运行时查开关无反注册 API、按钮 Show/Hide 即时切换、加载后开启补注册）；④ Options AfterSet 即时生效链（overrideNativeSort/useBlizzardSort→Blizzard:ApplyOverride；external.*→External:Apply）；MODULE_KEYS 加 External，TOC 加载序 External→Options→Debug。**

**修复：分类顺序「恢复默认」后清单全空——defaults.orders.* 只是空表结构占位，ResetSection 把空表当默认值写入。修：Options GetSectionDefault（orders.CustomOrder/EquipLocOrder 落 ABP.DefaultCategoryOrder/DefaultEquipLocOrder 真实默认表，CountChanged 同口径）；Core 首启迁移改 DeepCopy（原共享引用，拖动会污染默认表）。另删 InitDB uiScale 死键（UIKit 无缩放口，无消费端）。**

**P4 收尾：README.md（功能/依赖/命令/目录结构，旧版裁剪口径）；计划 §四 P3.5/P4 标 ✅，adeBagPack 计划全部阶段完成。TOC bump v6.5-r001-a4。**
# adeBagPack CHANGELOG

## v6.5-r001-a3 - 2026-11-18（P3：入口三件 + 分类清单改按钮序）

**P3 完成（计划 §二决策 4/5/6）：① Minimap.lua——UIKit CreateMinimapButton（替代旧 AbstractFramework 依赖），左键开设置、右键两项上下文菜单（整理背包/设置，MenuUtil.CreateContextMenu 同仓库 Panel.lua:624 先例；旧 MENU_SELL_JUNK/转移菜单项收敛），拖拽换角即时持久化 minimapPos、minimap.hide 经 getShown 消费（radius=0 语义转 nil 落 UIKit 默认半径）；② Extra/Blizzard.lua——hook BagItemAutoSortButton 原样搬移（overrideNativeSort/useBlizzardSort 语义不变，Baganator API 在场让位）；③ Extra/Baganator.lua——官方 API 版：RegisterContainerSort（Backpack/CharacterBank/WarbandBank 三容器，id=adebagpack）+ RegisterRegion 背包视图 bottom_left 注入整理按钮（Shift+左键=bag2bank 转移；旧自建挂帧路径废弃；失败 print 提示不静默）；junk 回调剔除（决策 7）。MODULE_KEYS 尾部追加三入口（各 Init 读 profile 自驱）；baganatorSort/baganatorButton 开关注册时读档，即时挂/卸留 P3.5 External.lua。分类顺序两清单改 reorder="buttons"（用户指定：去掉拖动，仅按钮调整）。三语补 P3 键 12 个（核对全覆盖）。TOC bump v6.5-r001-a3。**
# adeBagPack CHANGELOG

## v6.5-r001-a2 - 2026-11-18（P2：设置页四分组）

**P2 完成（计划 §二决策 2/3/7）：新增 Options.lua——ade_UIKit RegisterTab 四分组（整理/排序/界面/外部插件支持）+ 原生「打开选项」stub 页（Core:Init 加载期注册，achDateFormat 同款时点）；分类顺序与装备部位顺序两行走 UIKit kind="list"（getItems 数组引用语义，拖动/按钮 reorder="both"，改动经 onChanged 即时重建 Rule）；外部插件支持四选项（junkSource/infoSource/baganatorSort/baganatorButton）按统一口径 disabled fn + 动态 desc 实时探测 Dejunk/ItemEra/Baganator（消费端 P3.5 External.lua 接入）；三语补 P2 键 43 个（核对全覆盖）；/adebp 空参数 = 打开设置页。InitDB 注释的 uiScale 键暂无 UIKit 窗口缩放口消费，P3 评估或删除。TOC bump v6.5-r001-a2。**
# adeBagPack CHANGELOG

## v6.5-r001-a1 - 2026-11-18（P1 后热修：/adebp debug 诊断中断）

**/adebp debug 全背包扫描在 bag1 逐槽 Report 处中断（仅输出到「诊断 bag1」）：Debug stub 缺 `GetQuestInfo` 方法——Config `queststarter` 分类 check 必调 → 扫到任务起始物品即 attempt to call nil（旧 Core stub 同缺口，搬移时未察觉）。修：stub 补 GetQuestInfo（容器层 C_Container.GetContainerItemQuestInfo 快照，同 Item.lua:92-97），并把 GetCategoryKey 调用也包 pcall（诊断工具自身防崩，报 ERR:栈）。**

## v6.5-r001 - 2026-11-18（首版：P1 骨架 + 逻辑层搬移）

**P1 完成（计划 _docs/plans/adeBagPack-dev-plan.md）：① 骨架：TOC（Dependencies: ade_UIKit / SavedVariables: ADEDB_BACKPACK / 加载序 Locales→Core→InitDB→Modules 七件→Debug）+ Locales 三语（enUS 默认表 + zhCN/zhTW GetLocale 覆盖，键集 = 整理状态 15 + 分类名 26，P2/P3 键随后续阶段追加）+ Core（私有 addon 表 adeBagPack，statPlus 同款 _G.x or {} 复用模式；UIKit GetAddonMeta 取元数据；ABP.Debug=no-op；共享数据层 C_* 收口原样移植；ADDON_LOADED 自驱 Init：ADEDB_BACKPACK 装配 + DB.MergeDefaults 补全 + 首启迁移 CustomOrder/EquipLocOrder + InitModules + /adebp 斜杠）；② Modules 七件原样搬移（Config/Rule/Slot/Item/Bag/Group/Pack）：ADE 守卫行删除、local _, ns = ... 统一改 _G.adeBagPack or {}（vararg 私有表与全局命名空间不是同一表——Locales 先建表会断裂，statPlus 先例同款口径）、ns:GetLocale() 改 ns.L、ADE.CreateFrame() 改 CreateFrame("Frame")；Item.lua 按计划 §1.3 裁剪纯垃圾方法 7 个（GetSellPrice/GetQuantity/IsArtifactRelic/IsWarbandEquipment/IsRefundable/IsEquipmentSet/IsSuitable+BuildSuitableTable）；③ Debug.lua（/adebp debug 诊断：全背包逐槽 + 模拟整理，旧 Core:189-404 移植）；④ 修复两个 tdCore 遗产全局依赖：Bag.lua 补本地 ripairs（Group/Pack 已有本地定义先例）、Debug 补 tremove 局部。P2（设置页）/P3（入口按钮/暴雪接管/Baganator/小地图）待续。