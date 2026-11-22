# adeStatPlus — CHANGELOG

## v6.5-r008 - 2026-11-21（修复：角色面板进度条启用后装备变动导致原生内容消失）

**修复用户实测：启用角色面板进度条（`charPanel.bars.enabled`）后，装备变动使属性数值变化时，原生角色属性面板（CharacterStatsPane）原有内容消失。`Modules/CharPanel.lua` 三处叠加竞态修复：① `RestoreFontString` 原守卫要求当前锚点精确匹配我们写入的偏移才还原；装备变动时暴雪重锚池化行，守卫失效 → 上一轮 +delta 位移残留 → 下一轮以残留位置为基线再上移 → 文字逐次上飘离开可视区；改为无条件还原到记录的原始锚点（暴雪对同一行锚点稳定，写回 base 不破坏其布局）。② `UpdateScrollRange` 测量失败（行池重建中 `GetTop/GetBottom` 无效）时原逻辑把 pane 高度压到 viewHeight，超出视口内容被 ScrollFrame 裁掉；改为直接 return、保留原生尺寸等下一帧补测。③ `PaperDollFrame_UpdateStats` hook 原只测一次；`Relayout()` 返回 false（行未就绪）时改为 0.05s 后补测一次（OnShow 的 ticker 不覆盖装备变动路径）。TOC bump v6.5-r008。**


## v6.5-r007 - 2026-11-18

**① 背景颜色行错用 execute 按钮改为 UIKit b034 的 kind="color" 色块控件（存档 {r,g,b} 表 ↔ hex 适配，default 取 ns.defaults）；其余 execute（排序窗口切换等）为真执行按钮保留。② 下拉乱序修复（用户实测材质/字体下拉乱序，DBM 无此问题）：Media.FontItems/TextureItems 由哈希表改返回有序数组（内置项/「游戏默认」置顶、其余按显示名排序），SourceItems「无来源」置顶+排序——旧实现 pairs 展开 map 顺序不可预期。注：材质菜单项文字被材质盖住属 UIKit b035 已修（fontString 提 OVERLAY 层 + 加深阴影），本插件升级 UIKit 即生效。**

## v6.5-r006 - 2026-11-18

**字体/材质下拉接入 UIKit b032 的菜单内直接预览（用户需求，参照 DBM 观感）：字体下拉（font.face）菜单项文字直接用该字体渲染（spec.preview → {font=FontPath(key)}），两处进度条材质下拉（bars.texture / charPanel.bars.texture）菜单项铺满该材质（spec.preview → TexturePath(key)）；存档值仍为介质 key 不迁移，名字→路径由 Media 表即时解析（LSM 未注册 key 静默回退默认）。DBM 的实现逻辑 = 统一数据源构造器（MixinSharedMedia3 遍历 LSM HashTable，entry value 即路径）按 mediatype 统一打标（texture=true/font=true），渲染层 SetupMenu 按标志走 initializer 分支——本插件等价物为 preview 函数打标。**

## v6.5-r005 - 2026-11-18

**实测反馈修正（战斗显示异常，参考 _temp/Stats 旧版策略）：12.x 战斗中属性 API 大量返回 secret，joined 行原直通 secret 原值，整行退化成裸浮点且属性名消失（「敏捷: 2135」→「2135」、「24.57%」→「24.566511154175」）。改为：Collector.Read 持久缓存每通道「最近一次非 secret 的数值」（lastValue/lastPercent），Panel 渲染 secret 时优先用缓存渲染完整格式（名字: 值 | 百分比，战斗结束事件刷新恢复实时），从未读到过才裸直通。secret 原值仍绝不参与运算/拼接/比较——缓存的是战斗外已确认的 plain number。**

## v6.5-r004 - 2026-11-18

**实测反馈修正：①推荐来源下拉出现 GIS/CodeX 并可选——来源 items 原为文件加载期固化数组（字母序 GearInsight/ClassCodex 尚未加载，`IsAddOnLoaded` 恒 false，下拉只剩「无」），改函数式 items（UIKit b025），每次行渲染求值；②材质/字体下拉补齐 LSM——LSM 实例原在文件加载期缓存（本插件字母序早于携带 LSM 的插件，加载期常无 LibStub，缓存住 nil 即永久 miss），改每次调用即时取；③Options.Build 的 items 重建块删除（函数式取代）。**

## v6.5-r003 - 2026-11-18

**名称/版本/图标统一改走 UIKit `GetAddonMeta`（b024；小地图图标两态识别——TOC `## IconTexture` 优先于 `## IconAtlas`，用户已把本插件图标换成 IconAtlas）；TOC 版本随统一 bump。**

## v6.5-r002 - 2026-11-18

**小地图图标右键直接打开设置窗口（UIKit MinimapButton 原生支持 RightButtonUp 与键名回调，tooltip 三语补右键提示）；TOC 补 `Title-zhCN/zhTW`（[ADE] 属性面板 / 屬性面板）与 `## Version:`；「打开选项」stub 页改在加载期注册（原在惰性 Build 内，未打开过设置窗口时原生设置里看不到）；名称/版本/图标统一经 `C_AddOns.GetAddOnMetadata` 取 TOC 元数据（Print 前缀/tooltip/设置页名/stub 标题），删除图标防御链与 `or "1530081"` 兜底。**

## v6.5-r001 - 2026-11-17

**ADE v6.5 原生重写（第一批）：移除 `_G.ADE` / AceLocale / AceConsole / LibSharedMedia 依赖，改用私有表 + `ade_UIKit.DB.MergeDefaults`；数据/采集模块原样保留，Bars/Panel 改走原生 `Media.lua`（字体按 LSM 默认注册表转录，材质保留自带两款）；设置页改 UIKit `RegisterTab` 两页（subheading 分组 + 函数式联动禁用 + 官方 ColorPickerFrame 取色）；自绘小地图（UIKit `CreateMinimapButton`，角度持久化）；命令 `/adsp`、`/adeSP`；在原生「设置 > 插件」注册「打开选项」入口页。Radar/Ring/SortWindow/CharPanel 属第二批。存档 `ADEDB_ADESTATPLUS` 旧结构保留，`minimap.angle` 为新增字段。实测调整（2026-11-17）：默认字体改为「游戏默认字体」（存档 key `Game Default`，路径取 `GameFontNormal:GetFont()`，zhCN/zhTW 即 ARKai_T）；字体下拉首项即该选项，旧存档已保存的字体不受影响。第二批（2026-11-17）：Radar（四轴菱形雷达）/ Ring（四副属性环形）/ CharPanel（角色面板内嵌：属性条+图形插入+原生 pane 滚动）/ SortWindow（显示/排序/颜色独立侧窗）原生移植——唯一基座调用 `ADE.CreateScrollFrame` 按 scrollBar 模式逐字内联（CharPanel 无条+滚轮、SortWindow ScrollFrameTemplate+MinimalScrollBar）；SortWindow 锚定改走 `Options.GetWindowFrame`（UIKit 共享窗惰建）；`/adsp sort` 与设置页「排序窗口」按钮接真实现；`RefreshAllViews` 补 CharPanel 刷新。Bars 行内样式深化经核对 R3 已就绪（Panel.lua 行装配与旧版逐字一致，仅 ns/Media 接法差异）。实机反馈修正（2026-11-17）：①字体/材质下拉恢复 LSM 支持——可选接入 `LibSharedMedia-3.0`（零硬依赖，存在即合并其介质并去重，Fetch 静默回退内置表），下拉 items 延迟到首次打开设置页时重建（第三方介质注册晚于本插件加载）；②删除角色面板图形内嵌功能（Radar/Ring 及 charts 设置/存档字段，实测问题较大）；③角色面板条内嵌挂载修正——12.x 角色面板打包在 `Blizzard_UIPanels_Game`（Mainline TOC 含 CharacterFrame.xml/PaperDollFrame.xml 实证），独立的 `Blizzard_CharacterFrame` addon 名已不存在，原 ADDON_LOADED 过滤恒 return 使事件挂载点失效，改为任何 ADDON_LOADED 都尝试补挂载（幂等）。**
