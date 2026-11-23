# LibWMT_LeatrixMaps_Patch

修复 Leatrix Maps（镜像实测 `12.1.19`）开启「使用简易地图框体 / Use simple map frame」后，**所有经 `LibWorldMapTabs` 创建的世界地图 Tab 面板**相对原生任务日志上移、顶部控件落入新标题栏的偏移。独立补丁插件，零侵入：不修改 Leatrix Maps、不修改任何插件、不修改任何 `LibWorldMapTabs` 库副本。

- **v6.5-r002**：在 r001 的 `-50` 基础上**再下沉 30px 到 `-80`**，让出各插件外扩到面板上方的顶栏（标题 / 过滤器 / 齿轮），解决「溢出修好后顶栏标题等控件被 Leatrix 标题栏遮盖」的问题。下沉量可 `/lwmtlmp offset <n>` 会话内微调（默认 80，`/reload` 复位）。
- 适用客户端：12.x（TOC `120105`，与工作区各插件一致）
- 加载：`## OptionalDeps` 声明 Leatrix 与各使用方（仅影响加载顺序，未安装时静默不生效）；无 `## Dependencies`、无 `SavedVariables`
- 诊断命令：`/lwmtlmp status`、`/lwmtlmp apply`、`/lwmtlmp offset <n>`

## 一、问题与根因（全部来自磁盘实证）

结论：**偏移 = 21px**，来自「原生标准 `-29`」与「Leatrix 简易框体 `-50`」两套顶部基准。

1. **暴雪原生基准**：`z-ref_wow-dev-git/wow-ui-source/Interface/AddOns/Blizzard_UIPanels_Game/Mainline/QuestMapFrame.xml`
   - `:466-473` 定义 `QuestMapFrame.ContentsAnchor`（供其它帧锚定）；
   - `:479-480` `QuestsFrame` 锚 `ContentsAnchor`，右侧 `-22`；
   - `:483-490` `QuestScrollFrame` 的 `TOPLEFT y=-29`；
   - `:848-849` / `:937-938` `MapLegend` / `EventsFrame` 锚 `ContentsAnchor` 的 `TOPLEFT y=-29` / `BOTTOMRIGHT x=-22`。
2. **第三方全部照抄 -29**（这正是无 Leatrix 时各 Tab 面板与原生任务列表对齐的原因）：
   - `adeMapTab/Public/MapTab.lua:43-44`（`ANCHOR_TOP_Y=-29` / `ANCHOR_RIGHT_X=-22`）、`:186-187`（内容帧双锚 `ContentsAnchor`）、`:189-191`（三次重锚兜底）；
   - `adeMapMark/Settings.lua:396`（`adeMapMarkContent` 全铺 `ContentsAnchor`）、`:401-405`（主面板/设置面板跨父锚 `ContentsAnchor y=-29 / x=-22`）；
   - `z-ref_retail_Interface_AddOns/WorldQuestTab/WorldQuestTab.xml:615-622`（`WQT_WorldQuestFrame` 锚 `ContentsAnchor y=-29 / x=-22`）、`WorldQuestTab.lua:2122-2125`（world 模式改锚 `WQT.contentFrame`，同为 `-29`）。
3. **库本身把内容帧全铺 `ContentsAnchor`**：`LibWorldMapTabs.lua:294-296`（`CreateFrame(..., QuestMapFrame.ContentsAnchor)` + `SetAllPoints`）、`:312`（`SetParent(QuestMapFrame)`）、`:314`（登记进 `lib.contentFrames`）。库只负责显示切换（`:328-330`），不参与锚定适配。
4. **Leatrix 简易框体把原生内容整体下移 50px 让出标题栏**：`z-ref_retail_Interface_AddOns/Leatrix_Maps/Leatrix_Maps.lua`
   - `:364-378` 隐藏原边框/导航栏，`:402-407` 新建 22px 标题栏，`:692-805` `SetFrameLayout`；
   - `:735-740` `QuestScrollFrame` → `TOPLEFT 0,-50 / BOTTOMRIGHT 0,0`；
   - `:744-752` `MapLegend` / `EventsFrame` → 锚 `ContentsAnchor 0,-50 / -22,0`；
   - `:755-773` `DetailsFrame` 下移 47px；`:783-791` 搜索框/设置按钮移入标题栏。
   - 它只认识上述原生帧，**不认识** `LibWorldMapTabs` 动态创建的 contentFrame（库中 `:294` 创建，无全局名约定），因此第三方面板仍停在 `-29`：比原生少下移 `50 - 29 = 21px`，且顶部工具区与 Leatrix 标题栏重叠（截图中的「全部 / 过滤器」「传送大全」等跑到框体上沿）。
5. **r002：为何 `-50` 仍不够、必须再下沉 30px 到 `-80`**。各插件顶栏并非在面板内部，而是外扩到面板**上方** 4~30px：
   - `adeMapTab/Public/MapTab.lua:273-282` `MapTab.CreateTopBar`：`bar:SetPoint("TOPLEFT", panel, "TOPLEFT", 2, 30)` / `TOPRIGHT ... 30` + `SetHeight(26)` → 顶边 = `panel.top + 30`，底边 = `panel.top + 4`（Portal `WorldMapPanel.lua:586`、Delve `WorldMapPanel.lua:135` 均用默认值）；
   - `WorldQuestTab/WorldQuestTab.xml:650-658` WQT `TopBar`：`BOTTOM → 父 TOP y=4` + `Size y=26` → 同样 `+30 / +4`；
   - 齿轮按钮：`MapTab.lua:217`、`WorldQuestTab.xml:418/771`、`adeMapMark/Settings.lua:446` 均 `TOPRIGHT panel +25`；边框 `WorldMapPanel.lua:658` `+7`、滚动条 `MapTab.lua:309` `+2`。
   
   panel 停在 `-50` 时，顶栏占据距内容区顶部 **20~46px**，正压在 Leatrix 标题栏（原生内容下移到 `-50` 让出的 0~50px，`Leatrix_Maps.lua:737-740`）内；而第三方面板 `FrameLevel = qmf + 200`（`MapTab.lua:194` / `PANEL_LEVEL_OFFSET`）远高于标题栏 → **标题栏里的地图标题、搜索框、设置按钮被第三方面板盖住**（用户 2026-11-23 截图反馈）。让顶栏顶边落到 50px 线以下需 `panel.top = -50 - 30 = -80`：顶边恰好 50px（与原生内容起始线齐平）、底边 76px，与 panel 内容区 80px 仍保持原设计的 4px 间隙。

## 二、受影响范围（全量排查，非举例）

全工作区 + 游戏镜像 + `z-ref_wow-addons-libs` 检索 `LibWorldMapTabs` 后确认：

| 使用方 | 内容帧 / 主面板 | 标准锚点 | 本补丁覆盖 |
|---|---|---|---|
| `WorldQuestTab` | `LWMT_Content_LWMT_n`（容器，全铺 CA）+ `WQT_WorldQuestFrame` | 容器全铺；主界面 `-29/-22`（XML `:621` / Lua `:2124`） | 是（改主界面，容器不动，避免叠加成 -79） |
| `adeMapTab_Portal` | `ADEMapTabPortalWorldMapPanel`（经 `AdeMapTab-1.0`） | CA `-29/-22` | 是 |
| `adeMapTab_Delve` | `ADEMapTabDelveWorldMapPanel`（经 `AdeMapTab-1.0`） | CA `-29/-22` | 是 |
| `adeMapMark` | `adeMapMarkContent`（容器，全铺 CA）+ 主面板 / 设置面板 | 两 panel 跨父锚 CA `-29/-22` | 是 |
| `adeMapTab`（基座库） | 自身不建 Tab，只提供 `CreateContentFrame` | CA `-29/-22` | 是（经子插件内容帧） |
| `adeMapMark_Portal` | 仅数据包，间接依赖 | 无内容帧 | 不适用 |

库副本共 6 份（工作区 2、镜像 3、`z-ref_wow-addons-libs` 1），均为 `LibStub:NewLibrary('LibWorldMapTabs', 6)`（`:20`、`:22`），**逻辑完全一致（仅行尾空白差异）**；同 minor 先加载者胜出，`lib.contentFrames` 是全体共享的单例清单——这是一个补丁能覆盖所有使用方（含第三方 WQT）的根本原因。

## 三、修法与时序

补丁在运行时取 `LibStub("LibWorldMapTabs", true)` 单例，扫描 `lib.contentFrames`、它们的直接子帧、`QuestMapFrame` 与 `ContentsAnchor` 的直接子帧（排除暴雪原生内容帧），把满足以下条件的帧重锚：

```
TOPLEFT 的相对帧 == ContentsAnchor 或「全铺 ContentsAnchor 的 contentFrame」，
且 y ≈ -29（源值）或 y ≈ -50（r001 已应用值）
→ y 改为 -80（r002 默认，/lwmtlmp offset <n> 可调）；其余锚点（含 BOTTOMRIGHT x=-22）原样保留
```

- **只下沉顶部、底部不动**：与 Leatrix 对 `QuestScrollFrame` 的处理同构（`:739-740` `TOPLEFT -50` + `BOTTOMRIGHT 0,0`），面板变矮但不越出窗口底部。
- **目标值幂等与热更新**：`SnapTop` 已是目标值的帧不再重锚；`appliedTopY` 在每轮 `ApplyAll` 末尾同步，因此 r001 已改成 `-50` 的帧、`/lwmtlmp offset` 改值后的帧都能被下一轮识别并改到新目标。
- **全铺型容器本身不改**：`WQT.contentFrame` / `adeMapMarkContent` 是 `SetAllPoints(ContentsAnchor)`（y=0），改它们会让相对容器 `-29` 的 WQT 主界面叠加成 `-109`。
- **生效判据**（不依赖 Leatrix 的 local 表）：`LeaMapsLC` / `LeaLockList` 是 Leatrix 的局部变量（`Leatrix_Maps_Library.lua:11`、`Leatrix_Maps.lua:16`），外部不可读。故用两条可观测条件：`C_AddOns.IsAddOnLoaded("Leatrix_Maps")` + SavedVariables 全局 `LeaMapsDB["SimpleMapFrame"] == "On"`（`.toc:9`、`:8640`、`:8750`），并且行为确认 `QuestScrollFrame` 的 `TOPLEFT y≈-50`（Leatrix `:739` 已执行）。ElvUI 皮肤冲突把选项锁定时（`:8738`、`:339` 的 `not LeaLockList` 分支），原生列表不会被改成 -50，判据天然排除，不误修。开关切换需 `/reload`（`:7807` ReloadCheck），与 Leatrix 自身一致。
- **触发时机**：`PLAYER_LOGIN` / `PLAYER_ENTERING_WORLD` / `ADDON_LOADED(Blizzard_WorldMap|Blizzard_UIPanels_Game)` / `PLAYER_REGEN_ENABLED`；`EventRegistry "WorldMapOnShow"`（`Blizzard_WorldMap.lua:375` 触发）、`QuestMapFrame` 的 OnShow/OnHide（Leatrix 同在 `:798-804` 挂 `SetFrameLayout`）、`WorldMapFrame` 的 OnShow。每次排两阶段应用（下一帧 + 0.2s），覆盖 `adeMapTab` 基座的三次重锚兜底（`MapTab.lua:189-191`，含 `C_Timer.After(0.1)`）。
- **抗重锚**：对被修正的帧安装实例级 `hooksecurefunc(frame, "SetPoint")`（先例 `MapPinEnhanced_FixTrackerPatch/Core.lua:149-152`），任何后续重锚（如 WQT `ChangeAnchorLocation` `:2122-2130`、各插件自建兜底）之后下一帧回放修正；`hooksecurefunc(lib, "LinkTabToContentFrame")` 捕获之后新建的 contentFrame（库 `:297/:302`）。战斗中不触碰锚点（Leatrix 自身也用 `CanChange` 防护，`:342-344`、`:735`）。

## 四、为什么不直接改 `LibWorldMapTabs` 库文件

1. 库有 6 份内嵌副本（WQT / adeMapTab / adeMapMark 各带一份），`LibStub` 单例「先加载者胜出」，改任意一份都可能被别的副本覆盖，且第三方 WQT 的副本不在本仓库工作区可维护范围。
2. 直接把库的 `SetAllPoints(ContentsAnchor)` 改成 `-50` 会**同时影响未开启 Leatrix 的用户**（无 Leatrix 时原生标准仍是 -29）。
3. 独立补丁通过单例统一作用于 `lib.contentFrames`，零侵入、可随时禁用，且能覆盖未来新增的同库插件（只要沿用 `-29` 基准）。

## 五、验证清单（进游戏）

1. Leatrix Maps 选项勾「使用简易地图框体」→ `/reload` → 打开世界地图与任务日志侧栏。
2. `/lwmtlmp status`：Leatrix 已加载、简易地图框体 On、原生任务列表 `TOPLEFT y=-50`、生效判据「通过」、**补丁目标 y=-80**、上次应用修正帧列出各插件面板名。
3. 逐个切换 WQT / 传送大全 / 地下堡 / 地图标记 Tab（对照用户 2026-11-23 四张截图）：**「全部 / 过滤器」「传送大全」「至暗之夜」等顶栏标题与 Leatrix 标题栏里的地图标题 / 搜索框 / 设置按钮互不遮盖**；面板内容区比原生任务列表低 30px（这是让出顶栏的预期效果），右侧滚动条不外溢。
4. 若视觉上仍偏上/偏下：`/lwmtlmp offset 85`（或 75~95 之间微调，输入正数即下沉像素），无需改代码；满意后记下数值，如要固化请改主文件 `PATCH_TOP_Y` 常量（`/reload` 会复位为默认 80）。
5. 切换地图 / 最大化 / 最小化 / 折叠再展开任务日志 / 开关任务日志侧栏后，位置保持稳定（钩子会回放修正）。
6. 关闭「使用简易地图框体」→ `/reload` → `status` 显示判据未通过，各面板回到原生 `-29`，与任务列表仍对齐。
7. 未安装 Leatrix Maps 时：补丁加载但不修正，`status` 显示未加载/判据未通过。

## 六、边界与已知限制

- 只修正「相对 `ContentsAnchor` / 全铺型 contentFrame 的 `TOPLEFT y=-29`（源值）或 `-50`（r001 值）」这两条真实偏移基准；WQT 的飞行地图 / 全屏容器模式（`WorldQuestTab.lua:2114-2130`，锚 `WQT_FlightMapContainer` / `WQT_WorldMapContainer`）不属于任务日志区域，补丁不干预。
- `PATCH_TOP_Y` 默认 `-80` 是按「顶栏最高外扩 +30」与「Leatrix 标题栏 0~50px」推算的精确值；若某使用方改用更大的顶栏外扩，用 `/lwmtlmp offset <n>` 加大下沉量，或固化到常量。若某使用方未来改用其它顶部源偏移（不再是 -29/-50），该帧不会被识别，需在补丁常量或规则中同步（可用 `/lwmtlmp status` 诊断）。
- 补丁不处理 Leatrix 之外的第三方地图框架改造（如 ElvUI 世界地图皮肤把 `QuestScrollFrame` 也改成 -50 且 `LeaMapsDB` 为 On 的极端组合）。
- 锚点读写使用 `GetNumPoints/GetPoint`（`z-ref_wow-dev-doc/wow_API_wiki.gg/_2-1_Widget_API.md:153,155`）；战斗中偏移可能为 secret，故补丁整体避开战斗（脱战事件后重扫）。
