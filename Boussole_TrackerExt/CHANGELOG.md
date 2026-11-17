# Changelog

> 深度记录（现象 / 根因 / 修法 / 验证）见 `_docs/plans/Boussole_TrackerExt-dev-plan.md` §七。

## 1.2.0 - 2026-11-15

**正式发布（stable）：整合 1.1.1–1.1.8 全部修复与精简——彻底修复「点击可接任务（QuestOffer）扩展信息不显示 / 点其它目标也失效」的解析层 + 渲染层双重回归（task API 取真实坐标 + `positionBelow` 渲染回归修复），并完成死代码精简；全功能游戏内验证通过，静态 LuaLS 0 ERROR。**

## 1.1.8 - 2026-11-15

**1.1.7 验证通过后的代码精简：删除 1.1.6 遗留的死代码（世界地图 offer pin 读取 + 坐标缓存 + `SUPER_TRACKING_CHANGED` 事件捕获，约 60 行，其覆盖已被 1.1.7 task API + questline 兜底完全包含）；勘正过时注释、`ResolveCurrent` 恒真条件简化。行为与 1.1.7 一致（§7.18）。**

## 1.1.7 - 2026-11-15

**真正修复「点击可接任务扩展信息不显示」：1.1.5/1.1.6 连败的真根因是 QuestOffer 分支从未调用含 task API 的 `questPosition()`，且误判 CompassHUD 靠鼠标位置——实为它用 `GetSuperTrackedQuestID()`+`C_TaskQuest.GetQuestZoneID/GetQuestLocation`（用户实测 94790：zoneID=2405、loc=(0.5259,0.7290) 有效；暴雪 WorldQuestDataProvider 同款）。QuestOffer 分支改加 task API 为首选坐标源，与 CompassHUD OnEvent 同源（§7.17）。**

## 1.1.6 - 2026-11-15

**（无效，被 1.1.7 取代）曾改为读世界地图 `QuestOfferPinTemplate` pin 自身坐标 + 缓存 + 事件捕获，但对 94790 仍取不到。**

## 1.1.5 - 2026-11-15

**（无效，被 1.1.6 取代）曾改用 `C_QuestLine.GetQuestLineInfo` 单源取坐标，但对 pinID=94790 仍取不到、扩展信息依旧不显示（task 源 offer / 跨地图）。`_debug.log` 的 taint 报错属宿主 Boussole，与本插件无关（§7.15）。**

## 1.1.4 - 2026-11-15

**真正修复「点可接任务后再点其它目标扩展块不再显示」的渲染层回归：`Emphasis.positionBelow` 误以 `belowFrame:IsShown()` 作为前置条件——`hideBelow()` 隐藏过一次后，`res` 重新有效也永远走不到 `Show()`，块无法重现（§7.14）。改为只判 frame 是否存在 + 新增 `active` 标志约束 `PositionTick`，避免 nil 帧把块重新顶出。**

## 1.1.3 - 2026-11-15

**（方向偏差，被 1.1.4 取代）曾据诊断在解析层加 `resolveTrackedQuest()` 兜底（Offer 顶在超追踪位时退显 tracked 任务），但真正回归在渲染层（§7.14），该改动对「地图点击追踪的 POI」场景无效，保留为无害兜底。`/bte debug` 首行加插件本地化名 + 版本号已并入。**

## 1.1.2 - 2026-11-15

**（半修复）「可接任务」本身不再显示旧图钉/航点顶替（回退守卫改用 `GetHighestPrioritySuperTrackingType()` 判定候选；`QuestOffer` 无坐标不显示；`buildGeneric` 仅兜底未列出类型），但「点其它目标也失效」仍在——根因是渲染层回归而非解析层（§7.14）。**

## 1.1.1 - 2026-11-15

**（无效）尝试修复「可接任务」失效，但回退守卫误用 `IsSuperTrackingAnything()`（可接任务被超追踪时返回 false，回退仍触发旧图钉），且未堵住系统航点坐标顶替，故无效；刷新事件（`QUEST_ACCEPTED`/`WAYPOINT_UPDATE`/`PLAYER_ENTERING_WORLD`）已补齐并保留。**

## 1.1.0 - 2026-11-15

**正式发布（stable）：整合 1.0.6 代码精简与「贴边箭头样式」下拉真实材质图标（`|A`/`|T` 纹理转义）显示；所有增强层（追踪图标、名称/距离块、贴边指针、刻度数字、强调、跨图）经游戏内验证无报错，静态 LuaLS 0 ERROR。**

## 1.0.6 - 2026-11-15

**代码精简与一致性修正：「贴边箭头样式」下拉项嵌入真实材质图标（`CreateAtlasMarkup`/`CreateSimpleTextureMarkup`，与 `Emphasis.ApplyIcon` 同解析）；移除未使用的 `nativeBottom` 版式字段与 `ON_OFF` 文案；修正 `NativeInfo` 紧凑模式字段（`CI.compact`→`CI.compactMode`）；去除 `Overlay` 箭头定位重复代码；`Emphasis` 复用已算版式。**

## 1.0.5 - 2026-11-15

**转向卡顿修复（位置每帧随朝向重算）；原生信息条件性上移让位（仅重叠时移到图标上方，否则留在三角下方）；新增罗盘刻度数字（仿 CompassHUD，30° 间隔）；默认值抽离到独立 InitDB.lua。**

## 1.0.4 - 2026-11-15

**贴边箭头 `bag-arrow` 补 -90° 基准角；追踪扩展信息文本与材质同心；罗盘信息上移改为贴住刻度内容顶边；插件图标对齐主插件。**

## 1.0.3 - 2026-11-15

**修正贴边箭头左右指向；取消按宽高比反推的 texcoord 裁切；贴边改以材质为主体；复刻 CompassHUD 奖励图标（圆形遮罩 + 头像边框）；新增「罗盘信息位置」选项。**

## 1.0.2 - 2026-11-15

**修复颜色取样（8 位 AARRGGBB）与滑条步长；版式贴近刻线 + 与原生信息重叠下移让位；图标三分支等比处理；目标解析复刻 CompassHUD 全类型 + 跨图三级换算；支持主插件选定图钉；新增 `/bte debug`。**

## 1.0.1 - 2026-11-15

**设置改用暴雪 12.x 原生控件；修复追踪标识变形（保宽高比）；任务追踪改用 C_Navigation 同源航点；贴边指针参考主插件选中钉实现（钉环高度 + 边缘 clamp）。**

## 1.0.0 - 2026-11-15

**首版：地图 / 任务追踪超追踪目标上罗盘、用户航点追踪、刻度下方追踪层、贴边指针（PointerStay）、跨大陆隐藏 / 地图转换、放大比例与高亮颜色可配；设置页挂载 Compass 设置树并复用原生控件。**
