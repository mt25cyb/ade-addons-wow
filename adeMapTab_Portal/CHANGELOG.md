# adeMapTab_Portal — CHANGELOG

## v6.5-r004 - 2026-11-24（传送播报与主数据表统一：消除重复白名单 + 新增传送自动播报）

**按用户要求把播报的数据源并入本插件主表：① `Data/TeleportAnnouncer.lua` 删除 232 条法术白名单与 232×2 双语目的地名表，只留原表未收录的 68 条老传送（带 enUS/zhCN 目的地与 item 标记）+ 78 条 keystone/heartstone 布尔过滤标记（主表无法推导，非重复数据）；② `Services/Catalog.lua` 新增 `AnnounceInfo(spellID)` 单一适配层：可播报集合 = TeleportData 全部 spellID + 68 条补充（排除 spellID 0 宠物占位），目的地名按 extras 双语 > DestinationOverrides(name/nameFn) > 主表 destination.mapID 地图名 派生，item 从 action.id / 补充表 / 炉石 id 派生；③ `Services/TeleportAnnouncer.lua` 的 `AnnounceSpell` 改走 `AnnounceInfo`，不再引用已删的 `TeleportAnnouncerSpells` / `destinationNames`；④ 核对：原 232 条全部保留零丢失，新增 47 条主表传送（要塞炉石/家宅/法师传送门/新资料片传送等）自动进入播报；随机炉石池不纳入（与原插件行为一致，原本就不播报）；半自动化的设置项/频道/节流逻辑不变。TOC bump v6.5-r004。**


## v6.5-r003 - 2026-11-23（修复：侧边日志栏开合导致横向布局变纵向 + 图标材质闪烁）

**修复用户实测（布局「右下，横向」）：点击世界地图侧边日志栏关闭按钮（WorldMapFrame.SidePanelToggle.CloseButton）后区域按钮从横排变纵排、切换地图才恢复；开合时偶发图标额外材质轻微变大变小。`UI/ZoneTeleportButtons.lua` 两处：① `WorldMapFrame:OnSizeChanged` 原同步调 `Update()`——侧边栏开合改地图尺寸的同一帧里，`SetAllPoints` 的 rootFrame rect 还没重排完，`GetWidth()` 读到旧值甚至 0，横向布局 `maxCols = max(1, floor((负数)/30)) = 1` 每行只放 1 个按钮，BOTTOMRIGHT 锚下向上堆叠即"横排变纵排"（切图走 OnMapChanged 时 rect 已稳定所以恢复）；改为 `UpdateAfterLayout()` 延迟一帧重排 + pending 去抖（开合动画连续触发只排一次），并在 `Update` 顶部加 rootFrame 宽高有效性守卫（无效时保留现状）。② `Configure` 原每次重建都无条件重跑 `ApplyZoneButtonStyle`（内部反复 `Icon:ClearAllPoints` + 重设遮罩/EdgeShadow），OnSizeChanged 高频触发时与布局 pass 时序冲突产生一帧尺寸抖动；新增 `CurrentStyleKey()`（形状|虚影程度），按钮池复用只在参数变化后才重跑样式（Acquire 新建时记录键，设置切换即时生效不受影响）。TOC bump v6.5-r003。**


## v6.5-r002 - 2026-11-21（并入 TeleportAnnouncer 传送通报功能模块）

**按用户要求把 `TeleportAnnouncer` v1.9.0（z-ref 只读镜像，原作者 电视卫士(SGSwdzgr), KeiraMetz，MIT）作为功能模块并入：① 新增 `Data/TeleportAnnouncer.lua`——232 条法术白名单（M+/团本/道具/虫洞/职业传送，含 keystone/item/heartstone 标记）+ 232×2 目的地名（enUS/zhCN，自包含双表不污染主 Locales）+ 装备物品→法术异步映射（generation 防竞态）；原插件 MIT 版权与许可声明全文保留在新文件头（依其 LICENSE 要求）。② 新增 `Services/TeleportAnnouncer.lua`——施法开始/成功事件通报，实例小队 > 团队 > 队伍频道、单人静默；castGUID 120s 去重 + 同法术 2s 节流（被节流也记入历史防 SUCCESS 补发）；12.x 纪律 SetScript 先于 RegisterEvent；设置实时读 addon.db。③ 接入：Bootstrap 占位、TOC 两行、InitDB 六个扁平默认键（`announceTeleport` 默认 false，其余为时机/频道/不报物品名/仅 M+/忽略炉石）、齿轮设置页新增「传送通报」分组（总开关 + 5 个子项，parent 置灰）、两语各 22 键（设置项/选项/公告模板）。不 vendored LibBlzSettings（ADE 口径：设置走已有 UIKit 齿轮页），原插件零修改。TOC bump v6.5-r002。**


## v6.5-r001 - 2026-11-17

**ADE v6.5 原生重写：移除 `_G.ADE` / AceConsole / AceDB / 独立设置页（`UI/Settings.lua` 删除，设置只留世界地图 Tab 内齿轮页）；存档装配改 `ade_UIKit.DB.MergeDefaults`（存档名 `ADEDB_MAP_TAB_PORTAL` 不变，3 段插件内部旧键迁移逻辑保留）；基座样式按钮（`ADE.CreateStyledButton` / `SetStyledButtonEdgeShadow`）逐字内联为本地函数；命令 `/ademaptabportal`、`/adeportaltab`、`/adept`、`/adeMTP`；按键绑定与随机炉石的全局例外保留；不注册小地图图标（口径：仅 Delve 配）。实测修复：区域传送按钮点击无效——12.x 的 `InsecureActionButtonTemplate` 模板不再自带 `RegisterForClicks`（SecureTemplates.xml 实证），按钮池创建后补显式注册 `AnyDown+AnyUp`（down/up 分支由 cvar 互斥决定，兼容 `ActionButtonUseKeyDown`）。数据调整（2026-11-17）：地下堡机器人7001型（spellID 467470）从地心之战组移入角色组；百变之镜（spellID 194812）同时在德拉诺之王与燃烧的远征两组显示（共用 entryKey，收藏/最近使用互通）；角色组排序——统一炉石按钮固定最前、地下堡机器人固定最后（重排在收藏置顶之后，两锚位不受收藏影响）。实测修复：家宅传送「离家归来」切换失效——对照 AstralGate 原版（WorldMapPanel.lua:223-228）确认为移植遗漏而非游戏更新：housing 条目的 `ConfigureButtonTeleportAction` 分支漏挂 PreClick（每次左键点击前重评 `CanReturn` 重设 returnhome/teleporthome 安全属性 + 记录 `lastClickedFaction`），补挂后 Tab 内与地图区域按钮的家宅条目均恢复。实测修复：区域按钮只显示联盟家宅——home 分支按裸 spellID 去重，而联盟/部落家宅共用 spellID 1233637，第二个阵营被剔除；housing 条目改按阵营去重（键 `housing:`..faction，对齐 RecentHistory 风格），其余分支去重口径不变。实测修复：圆形按钮的 CD 暗色 swipe 是方形的——swipe 是引擎内部纹理（`GetRegions`/`AddMaskTexture` 首轮方案实测无效），改用 API 实证的 `SetSwipeTexture`（FrameAPICooldownDocumentation:526）换用同形状 alpha 遮罩纹理（圆形 commonmaskcircle / 方形 common-iconmask），随 `ApplyZoneButtonStyle` 在 shape 热切换时重设；Tab 内列表按钮保持原生方形不受影响。**
