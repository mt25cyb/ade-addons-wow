# Protoform Synthesis Journal

原生体合成手册的 12.1.5（Midnight）适配版，显示可通过原生体合成制造的战斗宠物与坐骑，并统计角色身上的材料与材料银行中的存量。

基于 Gello 的 [Protoform Synthesis Field Journal](https://www.wowinterface.com/downloads/info26267.html) 1.3.11 派生；原作者版权与署名归 Gello 所有，适配与维护由 ADE 阿德负责。

## 代码结构

- `Data.lua`：页签样式、52 个合成物配方、设置项与空列表等纯数据，导出到 `ns.Data`。
- `ProtoformSynthesisJournal.lua`：功能逻辑（事件、筛选排序、材料统计、收集状态判定）。
- `UI.lua`：界面渲染与交互（列表/设置填充、tooltip、地图打点、窗口拖动、小地图按钮）。
- `Guides.lua`：来源说明的坐标与文本键；`Alerts.lua`：制作就绪提醒；`localization/`：三语文案。
- `AutoScrollFrame.lua` / `AutoScrollFrame.xml`：列表滚动框控件；`assets/`：全部 blp 材质统一存放。

## 安装

将 `ProtoformSynthesisJournal` 目录放入 `World of Warcraft\Interface\AddOns\`，重进游戏即可。本插件不依赖其他插件；如已安装 LibDataBroker，会自动注册一个启动器。

## 使用方法

- 命令：`/psj`（兼容旧命令 `/psfj`）；也可点击小地图按钮或插件下拉菜单图标开关窗口。
- 快捷键：在「按键绑定 → 插件」中绑定 *Toggle Protoform Synthesis Journal*。
- 窗口下方可切换「宠物 / 坐骑 / 设置」三页；默认尺寸 500×420，拖动标题栏移动，拖动右下角手柄缩放（可在设置页锁定）。
- `Shift + 鼠标拖动` 可在锁定位置后临时移动窗口。
- 按住 `DRESSUP` 修饰键（默认 `Shift`）点击宠物或坐骑可打开试衣间预览。
- 悬停条目或材料行可查看图纸/材料来源说明（简中、繁中、英文三语）；带图钉按钮的来源可用原生地图打点并自动超级追踪，无需 TomTom。
- 登录后若出现新的可制造项，会弹出可拖动的提醒（设置页可关闭）。

## 12.1.5 适配内容

- TOC 提升为 `120105`；`GetItemInfo` / `GetItemInfoInstant` / `GetItemCount` 迁移到 `C_Item.*`，`GetAddOnMetadata` / `IsAddOnLoaded` 迁移到 `C_AddOns.*`。
- 材料数量包含背包、材料袋、角色银行与战团银行：`C_Item.GetItemCount` 的 `includeAccountBank` 传 `true`，与暴雪专业界面的 `ItemUtil.GetCraftingReagentCount` 同路径。
- `GetMouseFocus()` 与 `MouseIsOver()` 已随客户端移除，改为 `GetMouseFoci()` 配合 `RegionUtil.IsAnyDescendantOfOrSame` 判断悬停目标。
- 修正 TOC 中 `AddonCompartmentFunc` 的拼写错误，存档变量随插件名改为 `ProtoformSynthesisJournalSettings`（旧插件的存档不会自动继承）。
- 本地化只保留英文（隐式回退）、简体中文与繁体中文；按项目词典统一「原生体」「构造图」等术语。
- 清理调试代码、未被调用的方法、注释掉的代码与冗余旁白。

## 语言与词典依据

- 英文：主 Lua 中 `setmetatable(L, {__index = key})` 的隐式回退，不单独提供 `enUS.lua`。
- 简体 / 繁体：`localization/zhCN.lua`、`localization/zhTW.lua`，键集合与代码中使用的文案一一对应；`Guides.lua` 的来源说明同样以 `L[...]` 键读取，不在代码内保存译文表。
- 术语依据：`_tools/wow_dict/` 词典（`The Protoform Matrix → 原生体黑客`，确认 `protoform → 原生体`）。词典仅覆盖 enUS→zhCN，繁中按对应繁体字调整。

## 进游戏验证清单

1. 插件列表无加载错误，窗口可用 `/psj` 打开及关闭。
2. 宠物 / 坐骑页正确显示名称、图标、材料数量与可制造数量。
3. 设置页各复选框生效：锁定移动、锁定缩放、材料提示、小地图按钮、可制造提醒、隐藏已收集、隐藏未解锁、跨角色窗口位置。
4. 鼠标悬停材料行显示物品提示与来源说明；点击行内/材料行图钉可在扎雷殁提斯打点并超级追踪；`Shift + 点击` 可打开宠物 / 坐骑试衣间。
5. 角色银行与战团银行中的材料数量正确计入（在银行外打开窗口也应计入）；中文客户端下界面文案与词典用语一致。
6. 战斗中窗口按 ESC 可关闭且不做 protected 操作；不出现 taint 报错。
