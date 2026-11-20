# adeTimerHUD CHANGELOG

## v6.5-r032 - 2026-11-20（修复：UIScale 参与换算导致面板飞出屏幕）

**r031 的存档↔本地单位换算误用 `frame:GetEffectiveScale()`——它已包含 UIParent 的 UI 缩放（UIScale），而 SetPoint offset 相对父坐标的换算比应为 frame eff ÷ UIParent eff（不含 UIScale）。多除 UIScale 后显示位置 = 存档值 ÷ UIScale，UIScale<1（1080p 默认 ≈0.71）时顶边被推到 `pos.y/0.71` > 屏幕高，恢复默认/水平居中后面板整体飞出屏幕顶部。新增 `ParentRatio()`（frame eff ÷ UIParent eff，带除零防御），`ApplyPosition`/`SavePosition`/`CenterPanelHorizontally` 统一改用；`DefaultPosition` 的 y 简化为 `UIParent:GetHeight() - 10`（UIParent 坐标单位，不再做屏幕像素换算）。「水平居中 - 时间」（x=W/2）与存档坐标语义不变。版本四件套同步 r032。**

## v6.5-r031 - 2026-11-20（定位重构：绝对坐标，修复居中与重置失效）

**参考 CompassHUD `ResetPosition`（CompassHUD.lua:5029-5038）重构定位：存档改绝对坐标（`position.x`=时间文本中心 X、`position.y`=面板顶边 Y，均 UIParent 坐标，**不再存锚点**）——根因：`SavePosition` 持久化 `GetPoint()` 返回的 point，WoW 拖动会改写锚点（如 TOP→TOPLEFT），此后 point+offset 的 x/y 全部错基准，居中与重置双双失效。定位恒 `SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", …)`，存档值除以 effectiveScale 转本地单位并扣除面板内偏移。①「水平居中 - 时间/面板」按 `UIParent:GetWidth()` 实际宽度重算坐标（面板居中 = W/2 − layoutComp×eff），与当前位置无关，拖到屏幕最左/最右也能回到中央；②「重置位置与缩放」先复位 panelScale 再按默认（时间居屏幕中线、顶边距顶 10px）重算坐标必达；③老档含 point 字段或 x/y 缺失 → 清理并落默认位（r006 不迁移）；④RefreshLayout 高度变化也触发重定位（保持顶边稳定）。InitDB 默认 position x/y=nil（首次落位写回）。版本四件套同步 r031。**

## v6.5-r030 - 2026-11-20（修复：水平居中按钮误改 Y 轴基准）

**两个水平居中按钮（`CenterHorizontally`/`CenterPanelHorizontally`）此前把 `position.point` 强改为 `"CENTER"`（r012 遗留，当时默认锚即 CENTER 无感）；r028 默认锚改 TOP 后，点按钮会连锚点一起改——y 从「距屏幕顶边」变为「距屏幕中心」，面板跳到屏幕中部。修为仅写 `position.x`（时间居中 x=0、面板居中 x=-layoutComp），point/y 一概不动。README「均保持 Y」描述本就如此，实现现与文档一致。版本四件套同步 r030。**

## v6.5-r029 - 2026-11-20（主时间冒号随 AM/PM 组着色）

**主时间 `HH:MM` 拆为 HH/:/MM 三个 FontString（`fs.timeColon`/`fs.timeRight`，Clock.lua 内 8 FS）：冒号字体/描边/字号仍随时间组，颜色由 AM/PM 组（`font.meridiem`）覆盖——设置页「AM/PM 字体」的颜色行与「显示职业颜色」开关（含职业色联动）同时控制冒号，12/24 制一致。闹钟居中改锚 `fs.timeRight` 并左移 `(hhW+colonW)/2`，附加区（top/bl）右缘锚点随迁到 `fs.timeRight`；时间总宽 = 三段之和，居中补偿口径不变；ClockText 拆分失败时整体回退 `fs.time`。无新设置项、无三语变更。版本四件套同步 r029。**

## v6.5-r028 - 2026-11-20（默认位置：屏幕上方 + 时间文本居中）

**默认位置由「CENTER + 动态 y（defaultCenterY，约屏顶 50px）」改为「锚屏幕上方 TOP + y=-10，x=0」：r013 定位口径下存档 x 即时间文本中心偏移，x=0 令时间文本居屏幕水平中线（面板整体随附加区内容自动让位）；y=-10 为面板顶边距屏幕顶边偏移。删 `defaultCenterY()`（依赖 GetScreenHeight 的动态计算不再需要）。`/ath reset` 与「重置位置」按钮即恢复该默认。版本四件套同步 r028。**

## v6.5-r027 - 2026-11-20（缩放键改名 panelScale + 选项重排）

**面板缩放比例配置键 `scale` → `panelScale`（InitDB/Options sectionKeys/Clock.ApplyScale/ResetPosition 同步；按 r006 不做旧档迁移，旧存档缩放回落默认 100%）；设置页外观分组顺序改为 背景透明度 → 边框颜色 → 面板缩放 → 面板透明度。版本四件套同步 r027。**

## v6.5-r026 - 2026-11-20（新增面板透明度）

**新增「面板透明度」滑条（`panelAlpha`，0~1 步进 0.05，默认 1.0 = 100%）：`ApplyAppearance` 对整帧 `SetAlpha`，同时影响背景/边框/文字；与既有 `frameAlpha`（仅背景色 alpha）独立叠加，闹钟到期闪烁仍为子元素 alpha 不受影响。三语 +1 键（LABEL_PANEL_ALPHA），sectionKeys 同步。版本四件套同步 r026。**

## v6.5-r025 - 2026-11-20（AM/PM 与前缀支持职业色）

**AM/PM 与前缀字体组新增「显示职业颜色」开关（默认启用，用 `GetClassColor` + `UnitClass("player")` 取玩家职业色覆盖自定义色）；关闭后回到自定义色。设置页为开关+同行色块结构（ade_UIKit b051 的 `ToggleColorOption`），勾选时色块自动禁用。三语 +1 键（LABEL_USE_CLASS_COLOR），sectionKeys 加两条 useClassColor。版本四件套同步 r025。**

## v6.5-r024 - 2026-11-20（六组字体默认描边与颜色）

**时间 粗描边+#FFFFFF、闹钟 描边（颜色仍固定分级）、日期与星期 描边+#A0A0A0、AM/PM 与前缀 描边+#66BBFF；`defaultFont(outline, color)` 支持按组传参。版本四件套同步 r024。**

## v6.5-r023 - 2026-11-20（InitDB 默认值与设置页逐项对齐）

**InitDB 注释重写为当前单面板六元素结构（按内容/外观/字体/位置分组逐项对应设置页），修正过时描述（双面板/4 组字体/字号 32/子帧缩放等）；移除设置页已不暴露的 `font.alarm.color` 默认值，`ApplyFontTo` 在 color 缺省时跳过设色；修复 `sectionKeys` 中 `use24` 重复导致的改动计数翻倍。版本四件套同步 r023。**

## v6.5-r022 - 2026-11-20（中文星期文本、闹钟显示设定时刻、字号基础值 20）

**按用户实测反馈修正三点：① 中文星期全称改为显式「星期X」（TimeFormat 新增 `LOCAL_WEEKDAYS_FULL`，缩写仍「周X」/「週X」）；② 闹钟文本改为显示原生设定的绝对时刻（如 15:25）而非剩余倒计时（原显示 08:45），颜色分级仍按剩余分钟数；③ 附加/前缀字号基础值 24→20（±8 不变），InitDB/三语/README 同步。版本四件套同步 r022。**

## v6.5-r021 - 2026-11-20（闹钟改读原生提醒时间；格式化归并 + 模块拆分）

**闹钟目标时刻不再由插件设置：改读暴雪原生 CVar `timeMgrAlarmTime`/`timeMgrAlarmEnabled`/`timeMgrUseLocalTime`，仅在 Init 与 CVAR_UPDATE 时重读缓存（重载或重设提醒时间才刷新目标信息），倒计时基于缓存每秒计算。「闹钟倒计时」→「显示闹钟」，插件开关与原生闹钟启用同时满足才显示；删 hour/minute，新增 warnMinutes（1~5、step 0.5、默认 1）颜色分级（>10 绿 / n~10 橙 / ≤n 红，固定色不取 font.alarm.color）与 flash 到期闪烁，闹钟字体仅留 face/outline。架构：新建 `Modules/AlarmClock.lua`；`TimeFormat.lua` 并入时钟/日期/星期格式化，Clock 保留两个别名供 Options 预览；TOC 加新文件行。三语各 +3 键，删 OPT_ALARM_HOUR/MINUTE。版本四件套同步 r021。**

## v6.5-r020 - 2026-11-20（星期选项标签改为当天实际星期）

**日期格式下拉已按 `FormatDateText` 渲染当天日期；星期样式下拉原写死示例「星期五/周五/Friday/Fri.」。新增 `Clock.FormatWeekday(style)` 复用实际渲染逻辑，Options 改函数式 `WeekdayStyleItems()` 拼「前缀 + （当天星期）」（函数式 items 每次刷新重求值，实证 `ade_UIKit/Widget/OptionRow.lua:74-78`）；三语四个 `WEEKDAY_*` 键去掉固定示例只留前缀，键数不变。版本四件套同步 r020。**

## v6.5-r019 - 2026-11-20（附加区宽度重构；日期 9 格式与星期文本选项）

**修复 12h+BOTH 短日期时星期与 AM/PM 重叠：附加区宽度 `max(topW, blW+FULLGAP+brW)` 回填「附加上」FS（`SetWidth`），下右有内容时右对齐、否则左对齐，下左恒左对齐、下右恒右对齐。日期格式 6→9 项（本地语言/美式/英式，标签带括号说明），新增 `{EN_MON_SHORT}`/`{EN_MON_FULL}` 占位符取英文月份表，`StripYear` 支持英文逗号/空格年份；「日期显示年份」改为「日期不显示年份」，键 `dateShowYear` → `dateHideYear`（默认 true，外观不变）；新增 `weekdayStyle`（本地/英文 × 全称/缩写，本地缩写按 zhCN/zhTW 自带表，英文缩写带点）。三语 +9 键、NOTE_CLOCK 文案同步单面板布局；版本四件套同步 r019。**

## v6.5-r018 - 2026-11-20（前缀独立子区域 + 独立字体组）

**缩写前缀 `(S)/(L)` 不再拼接进时间文本：新增第 6 个 FontString `fs.prefix`，右上对齐时间左侧中（`TOPRIGHT→时间 LEFT, -GAPX`），字号同附加区（24±8，受 `childFontOffset` 控制）；新增独立字体组 `font.prefix`（face/outline/color，`showPrefix` 关闭时设置页禁用），三语 +1 键（SUBH_FONT_PREFIX）；尺寸与定位补偿把前缀宽度纳入 `timeLeft`，存档 x 仍表示时间中心偏移，两种居中语义不变。版本四件套同步 r018。**

## v6.5-r017 - 2026-11-20（锚点调整：附加区以时间右中为基准上下贴合）

**按用户给定片段调整锚点：「附加上」由 `TOPLEFT→时间 TOPRIGHT` 改为 `BOTTOMLEFT→时间 RIGHT`（左下对齐时间右中，GAPX=2）；「附加下左」由 `BOTTOMLEFT→时间 BOTTOMRIGHT` 改为 `TOPLEFT→时间 RIGHT, -GAPY`（左上对齐时间右中，下方留 GAPY=4）。附加下右仍锚「附加上」右下且右对齐，内容映射与自动尺寸逻辑不变。README 布局表/DevPlan 同步；版本 r017。**

## v6.5-r016 - 2026-11-20（修复运行崩溃；设置入口对齐 ADE 系列；AM/PM 独立字体组）

**① 运行报错 `Clock.lua:250 attempt to call a nil value`：`ApplyPosition` 定义在 `RefreshLayout` 之后，Lua 词法作用域把调用解析为全局 nil（r015 起 layoutComp 首次非零触发）。修复：在 RefreshLayout 前加 `local ApplyPosition` 前向声明，后部改为赋值。② 初入游戏无设置入口、`/adeTimerHUD` 后才出现：对齐 `adeBagPack` 实现——Core 加载期硬校验 `ade_UIKit` 并缓存 `ns.UIKit`（原为软降级、Options 每次重取导致登录时序拿不到），Options.GetOF 优先消费缓存；`ns.Options_Init()` → `ns.InitOptionsStub()` 且 `Build()` 失败时 `error` 暴露（Core 去掉 r011 的 pcall 静默）。③ AM/PM 独立字体组：新增 `font.meridiem`（face/outline/color，默认白色/无描边），设置页第五组 subheading（仅 12h 可用），Clock 在附加下左为标记时应用该组，24h 日期/星期仍走 date/weekday 组。三语各 +1 键（SUBH_FONT_MERIDIEM）；版本四件套 r016。**

## v6.5-r015 - 2026-11-20（逐条核对附加区内容映射；修正 24h+BOTH）

**按用户给出的 12h/24h × dateMode 对照表逐条检查：12 小时制四种组合（不显示/日期/星期/日期+星期）全部已符合——下左恒为 AM/PM，附加上按日期或星期，下右仅 BOTH 显示星期。24 小时制仅「日期+星期」一项不符合：原实现只让下左显示星期、附加上留空；现改为「附加上」显示日期 +「附加下左」显示星期，「附加下右」仍留空（其锚点依赖附加上，24h 不生成）。其余 24h 组合（全空/仅日期/仅星期）已符合。Clock 头部注释与 README 布局表同步，版本 r015。**

## v6.5-r014 - 2026-11-20（补充 24h + 日期+星期 时附加下左显示星期）

**用户补充手绘图遗漏描述：24 小时制且选择「日期+星期」时，「附加下左」显示星期。r013 曾将 24h+BOTH 退化为仅日期，现按补充改为：24h 下 `DATE`→附加下左显示日期、`WEEKDAY` 或 `BOTH`→附加下左显示星期（24h 无「附加上/下右」，仅保留单个附加位，不生成 br 空锚点）。README/DevPlan 同步该口径；版本四件套 r014。**

## v6.5-r013 - 2026-11-20（v9：取消主/子面板，单面板五元素手绘布局）

**按用户新布局手绘图重构：取消主面板/子帧概念——单一 Frame（唯一边框/背景），5 个 FontString 直接挂其内：时间（64，面板内居中、边距减至 6/8）、闹钟（10，X 中心对齐时间、位于其下）、附加上（左上锚时间右上，12h 日期或仅星期）、附加下左（左下锚时间右下，12h AM/PM 标记、24h 日期或星期）、附加下右（右上锚「附加上」右下且文本右对齐，12h 且 BOTH 显示星期）。24h+BOTH 旧档退化为仅日期（避免下右锚点悬空）。所有元素按文本实测自动撑开；附加字号沿用 24±8；字体组按内容动态取 date/weekday。定位口径改为「时间文本中心」：comp = 面板中心 - 时间中心，ApplyPosition 加 comp、SavePosition 反算；「水平居中 - 时间」x=0、「水平居中 - 面板」x=-comp。设置项与三语键不变（childFontOffset 语义改为「附加文字字号微调」）；版本四件套同步 r013。**

## v6.5-r012 - 2026-11-20（子区垂直居中、背景透明度 0.2、双居中按钮）

**用户实拍图对照手绘图反馈：不显示日期时 AM/PM 偏右偏下、显示日期时子面板文本偏右偏上。子区文字改为按主区高度垂直居中（`vShift=max(0,(mainH-contentH)/2-PADY)`），左边距 10→4 更贴两区分界线；取消 r010「仅标记下移到闹钟行」的做法，改为子区内垂直居中（新口径覆盖旧需求）；子帧与主区等高。背景透明度默认 1.0→**0.2**。原「水平居中」改名「水平居中 - 时间」（行为不变：主区中心 X 归零），新增「水平居中 - 面板」（整体面板中心 X 归零，存档 x 置 `-childW/2`）。三语 +1 键（LABEL_CENTER_PANEL）并更新 LABEL_CENTER_X 文案；版本四件套同步 r012。**

## v6.5-r011 - 2026-11-20（修复 r010 时间右移溢出；设置入口静默消失加诊断）

**用户截图反馈默认配置下时间 `12:22` 偏右溢出黑底、设置页与入口消失。根因①（确定）：`SetPoint("TOP", frame, "TOP", x, ...)` 的 x 相对「整体帧顶部中心」而非左边缘——主区时间/闹钟误用 `mainW/2` 作为 x，实际主区中心相对整体中心偏移为 `-childW/2`，改此值后文字回到黑底中央。根因②（防御）：Options.lua 加载期硬依赖 `ns.TimeFormat.IsCJKLocale()`，若 TimeFormat 模块异常会让 Options.lua 中断、`RegisterTab` 不执行、入口静默消失——改为本地 CJK 表判定，格式下拉 disabled 亦做 nil 安全；Core.Init 对 `ns.Options_Init()` 增加 pcall，失败时把真实错误打印到聊天框。**

## v6.5-r010 - 2026-11-20（双区单边框、子面板字号微调、日期年份开关、AM 下移对齐）

**按用户两张参考图调整布局与选项：主帧成为唯一 Backdrop 绘制者，尺寸覆盖「主区+子区」整体；子帧改为不带 Backdrop 的透明内容容器、`SetPoint("TOPLEFT", frame, "TOPLEFT", mainW, 0)` 紧贴主区右侧——两区零间距、中间无边框线；`showBorder` 默认 false。位置仍以主区中心为准：存档 x 存主区中心偏移，`ApplyPosition` 补偿 `childW/2`、`SavePosition` 反算，且仅在子区宽度变化时重定位（不打断每秒刷新期间的拖动）；「水平居中」只归零主区中心 X。子面板字号由固定 32 降为基础 24（时间仍 64、闹钟仍 10），新增 `childFontOffset`（range -8..+8 step 1 默认 0，日期/星期/时段标记统一应用）；新增 `dateShowYear`（默认 false，`FormatDateText(fmt, showYear)` 对 6 种数字日期预设剥离年份，Options 下拉预览传第二参同步）；12h + `dateMode=NONE` 形态把 AM/PM 标记下移到闹钟行 y，与「时间下方」水平对齐，并扩高子区避免外框裁切。三语 +3 键；无旧档迁移，新键由 MergeDefaults 补默认。版本四件套同步 r010。**

## v6.5-r009 - 2026-11-20（中文时段按季节切换分钟级边界）

**用户要求中文格式的时段边界随季节变化（左闭右开）：2/6–5/5 与 8/6–11/5 春秋档——凌晨[00:00,06:00)、早晨[06:00,08:00)、上午[08:00,11:00)、中午[11:00,13:00)、下午[13:00,17:00)、傍晚[17:00,18:30)、晚上[18:30,24:00)；5/6–8/5 夏档——凌晨止于 05:30、傍晚[17:00,19:00)、晚上起于 19:00；11/6–2/5 冬档——凌晨止于 06:30、傍晚[17:00,18:00)、晚上起于 18:00。`TimeFormat` 的固定小时边界表改为三套分钟数边界表（MID/SUMMER/WINTER），`date("*t")` 的 month*100+day 判定季节（跨年区间无需特判、2/29 落春秋），`minute` 参数自本版起正式参与 CHINESE 分支判断（ANCIENT 仍整点）；新增 `TimeFormat.ChineseSeason()` 便于 `/dump` 验证当前档位。标签仍取 L.CN_PERIOD_LABELS 七项，非 CJK 限制沿用 r008。版本四件套同步 r009。**

## v6.5-r008 - 2026-11-20（非 CJK 端限制中文/古代时段格式）

**用户反馈非中日韩客户端缺中文字形、中文/古代标签会乱码：`TimeFormat` 新增 `IsCJKLocale()`（zhCN/zhTW/koKR，集合沿用 Media.lua:20）、`CanUseChinese(force)`、`EffectiveStyle(style, force)`；新设置 `forceChineseMeridiem`（默认 false，非 CJK 专用）：非 CJK 端默认格式下拉禁用、中文/古代只在开关开启后可选且生效，CJK 端无此限制且不显示开关/说明行；Clock 渲染前经 `EffectiveStyle` 钳制，即使存档里 `meridiemStyle` 从 CJK 端复制为中文/古代，未开启开关时也强制国际通用。英文客户端的标签 CSV 由英文翻译改回中文（选项既叫「强制中文格式」就应显示中文，乱码风险由开启者承担）。三语各 +2 键（共 50）；无旧档迁移（r006 口径），新键由 MergeDefaults 补默认。版本四件套同步 r008。**

## v6.5-r007 - 2026-11-20（12 小时制布局重排 + 时段格式 API）

**用户手绘图要求 12 小时制布局调整（24 小时制视觉不变）：主面板只保留 `HH:MM`（12 小时制小时 1–12），不再后缀 AM/PM；时段标记移到右侧子面板——「日期+星期」形态第 1 行日期、第 2 行「标记（左）+星期（右）」，仅日期/仅星期形态标记独占第 2 行左侧，`dateMode=NONE` 且 12h 时子面板仍显示仅标记一行（避免丢失上下午信息）；24 小时制沿用 v3 布局零改动。新增 `Modules/TimeFormat.lua` 格式化 API：`ns.TimeFormat.Format(hour, minute, style)`（INTERNATIONAL=AM/PM；CHINESE=凌晨[0,6)/早晨[6,8)/上午[8,11)/中午[11,13)/下午[13,17)/傍晚[17,19)/晚上[19,24)，左闭右开；ANCIENT=子时[0,2)/…/亥时[22,24)，floor(h/2)+1）与 `Styles()`（函数式下拉项；标签 CSV 走三语 Locales、区间边界固定在模块内）；新增 `meridiemStyle` 默认值与设置页「AM/PM 格式」下拉（仅 12h 可用、sectionKeys 含 use24）；标记 FS 跟随星期字体组、固定 32 号字；r004 遗留的 TIME_AM/TIME_PM 本地化键删除（API 取代）。版本四件套同步 r007。**

## v6.5-r006 - 2026-11-20（移除旧档迁移；明确水平居中只针对主面板）

**用户确认「不考虑老存档」：删除 `ns.MigrateSettings` 与其调用，`InitDB.lua` 只保留 v3 默认配置，装配仅由 `ade_UIKit.DB.MergeDefaults` 补全缺失键；v3 存档格式即唯一格式。用户强调「水平居中按钮只针对主面板」——复核行为本就如此（只把主帧中心点 X 置 0、Y 不变，子帧相对主帧锚定随动、不参与居中计算也不单独存位置），补充注释明确该语义。版本四件套同步 r006。**

## v6.5-r005 - 2026-11-20（v3：双面板布局 / 固定字号 / 缩放与水平居中）

**按用户新布局手绘图落地 v3：拆成主面板（时间 + 闹钟）与右侧子面板（日期/星期，parent=主帧随动随缩放）；主面板时间只显示一个（服务器/本地单选），前缀只保留缩写 `(S)/(L)` 且可开关；字号固定——时间 64、闹钟 10、日期与星期 32（时间的一半），字体选项去掉字号行；四组（时间/闹钟/日期/星期）各自设置字体、描边、颜色（8 位 hex AARRGGBB，字体 alpha 位有效）；子面板可选「不显示/仅日期/仅星期/日期+星期」；位置以主面板中心点为锚（CENTER），拖动只移动主面板，新增「水平居中」按钮（X 归零、Y 不变）；尺寸不再手动拖放，改由缩放比例滑条（0.5~2.0，默认 100%）控制，面板宽高按固定字号文字实测自动撑开不裁切；删除缩放柄与 manualSize。旧档迁移：v1 扁平字体→v2 五组→v3 四组（清 size、补白色），BOTH→SERVER、prefixStyle→showPrefix、dateMode 值改名、TOP→CENTER 锚点换算、清理废弃偏移与 manualSize。三语键同步（新增 LABEL_SHOW_PREFIX/LABEL_SCALE/LABEL_CENTER_X/OPT_COLOR/SUBH_FONT_TIME/SUBH_FONT_WEEKDAY/DATE_DATE/DATE_WEEKDAY/DATE_BOTH，删除前缀风格/双时间/字号相关键）。**

## v6.5-r004 - 2026-11-19（时间格式改为自拼，消除冒号两侧空白）

**用户截图反馈 `21 : 22` 冒号与分钟之间空白过大。根因经游戏内 `/dump` 与源码核实：zhCN 客户端 `TIME_TWENTYFOURHOURS = "%d：%02d"` 用的是全角冒号 U+FF1A（字形居中、占一个汉字宽），并非真的插入空格；`TIME_TWELVEHOURPM = "%d:%02d PM"` 为半角冒号。按用户要求「自己做格式化」，`Modules/Clock.lua` 的 `FormatClockText` 彻底弃用 `TIME_TWENTYFOURHOURS / TIME_TWELVEHOURAM / TIME_TWELVEHOURPM`，24h 自拼 `%d:%02d`、12h 自拼 `%d:%02d AM|PM`，冒号恒为半角、无多余空白（自定义格式范式实证 `adeMapTab_Delve/UI/RosterWindow.lua:212-220`）。12h 后缀新增三语键 `TIME_AM` / `TIME_PM`（"AM"/"PM"，保持官方 zhCN 观感）；闹钟行原本已是半角 `%02d:%02d`，不受影响。lint 0 error、三语 46 键一致。**

## v6.5-r003 - 2026-11-19（修复设置页字体分组空选项）

**用户截图反馈「部分选项是空的」：设置页 4 个字体分组标题正常，但分组下的「字体/字号/描边」行只剩空控件、无标签。根因：`Options.lua` 的 `sections.clock` 数组构造器里直接写了 `FontRows(...)`，而 `FontRows` 返回的是行数组，Lua 数组构造器不会展开嵌套表，该元素变成 `kind=nil / label=nil` 的表，UIKit 渲染成空行（5 次调用共丢失 15 行）。修复：构造后以 `AddRow/AddRows` 逐条 append 4 个 subheading 与 5 组 × 3 行；`elements` 回调仍返回同一 table 引用，`RegisterTab` 之前 append 已完成。lint 0 error。**

## v6.5-r002 - 2026-11-19（v2 迭代：时间源/日期/闹钟倒计时/自适应尺寸/设置页重组）

**按用户确认落地 v2：删除时间偏移（hourOffset/minuteOffset），新增时间源（服务器/本地/两者同时）；两者同时时可选前缀风格——全称（服务器/本地，前缀与时间两端对齐）或简称（(S)/(L)，居中）；新增日期显示（单行=日期、双行=日期+星期，星期取 CALENDAR_WEEKDAY_NAMES 本地化）与 6 种纯数字日期格式预设（下拉实时渲染预览）；新增闹钟倒计时显示 `● HH:MM`（目标时刻基于服务器时间，剩余时长换算、已过视为次日循环，只显示不提醒）；帧尺寸改按各行文字实测宽高自适应撑开，缩放手柄保留为手动覆盖（manualSize 取 max 永不裁切）；本地/服务器/日期两行/闹钟字体拆 5 组分别设置（前缀与 ● 跟随所属行）；设置页「时钟与外观」改名「时钟面板」，字体选项以 subheading 分组移入其中，布局（时间偏移）section 删除。存档迁移：旧扁平 font 三件套回填 5 组、废弃偏移键清理。TOC v6.5-r002。**

## v6.5-r001 - 2026-11-19（首个模块：时钟 HUD，基于 MonkeyClock 一比一复刻 + 字体可配置）

**按用户要求新建 adeTimerHUD，首模块 = 时钟 HUD：以 MonkeyClock v3.6.1 为蓝本一比一复刻帧外观（110×30、TOP -16、黑底橙边 Backdrop、LOW strata、白色 12 号文字、每秒刷新、12/24 制、时/分偏移、左键拖动、右下角 8×8 手柄缩放、锁定位置）与两枚 resize 素材（从只读镜像拷入 assets/textures）；按用户要求去除闹钟（聊天/对话框提醒、闹钟时间、StaticPopup）、贪睡、右键开配置。新增字体调整三件套（字体选择复用 adeStatPlus 的内置 8 款 + LSM 实时合并 + Game Default 置顶、字号 8–32、NONE/OUTLINE/THICKOUTLINE 描边），位置/尺寸持久化（ADE 增强，MonkeyClock 原版无）。TOC v6.5-r001，依赖 ade_UIKit，存档 ADEDB_TIMERHUD.settings.*（颜色走 UIKit kind="color" 的 8 位 hex + 独立 frameAlpha）。设置页走 ade_UIKit RegisterTab + RegisterOptionsStub，入口为 /ath 斜杠命令与「设置 > 插件」Stub。**
