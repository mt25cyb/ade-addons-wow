# 更新日志

## v6-r010 - 2026-11-23

**修复拆分后 UI 模块在加载期捕获旧存档表导致三页内容报错，以及主逻辑缺失小地图按钮引用。**

## v6-r009 - 2026-11-23

**滚动框代码移到根目录的 AutoScrollFrame.lua/xml，全部 blp 材质统一归入 assets/，并更新所有路径引用。**

## v6-r008 - 2026-11-23

**统一多语言调用格式：Guides 的来源说明改为字面 `L["..."]`，加载顺序调整为 Data 先于 Guides。**

## v6-r007 - 2026-11-23

**主代码拆分为数据（Data.lua）、功能逻辑（ProtoformSynthesisJournal.lua）与界面交互（UI.lua）三类，并调整加载顺序。**

## v6-r006 - 2026-11-23

**统一多语言机制：Guides 的来源说明改为通过 `L[...]` 读取，三语译文全部移入本地化文件，移除代码内自建语言表。**

## v6-r005 - 2026-11-23

**新增来源说明 tooltip（52 图纸 + 41 材料，简中/繁中/英文三语）、原生地图打点导航，以及只提示新增可制造项的就绪提醒。**

## v6-r004 - 2026-11-23

**修复 12.1.0 已移除的 `MouseIsOver` 导致的修饰键事件报错，改用 `GetMouseFoci()` + `RegionUtil.IsAnyDescendantOfOrSame`。**

## v6-r003 - 2026-11-23

**材料计数纳入战团银行库存（`C_Item.GetItemCount` 的 `includeAccountBank` 传 `true`）。**

## v6-r002 - 2026-11-23

**修复 12.1.5 已移除的 `PLAYERREAGENTBANKSLOTS_CHANGED` 事件导致的注册报错，改用银行槽位事件；默认窗口尺寸改为 500×420。**

## v6-r001 - 2026-11-23

**基于 Protoform Synthesis Field Journal 1.3.11 适配 12.1.5：重命名为 ProtoformSynthesisJournal，迁移废弃 API，精简三语本地化并清理冗余代码。**
