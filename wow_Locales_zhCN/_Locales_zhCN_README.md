# wow_Locales_zhCN — 简体中文本地化子项目

为「已内置多语言机制、但简体中文（zhCN）不完整」的魔兽世界插件制作并维护简体中文语言包。
本子项目的产出**只是语言文件本身**，不修改插件逻辑代码；契合插件既有机制即可被自动加载。

> ⚠ **特例声明（只读镜像的唯一例外）**：本工作区的 `z-ref_*` 目录一律只读，
> 但 `z-ref_retail_Interface_AddOns\`（游戏端实际加载的插件镜像）是本子项目**唯一**的写入例外——
> 语言文件按下方「同步规则」落入镜像中的目标插件目录。
> 该例外**仅适用于本子项目**，勿套用到工作区内任何其他项目 / 插件。

## 适用情况（按多语言机制分类）

不同插件存放多语言的方式不同，处理方式也因此不同。目前归纳出以下类型：

| 类型 | 多语言机制 | zhCN 缺失表现 | 处理方式 |
|------|-----------|---------------|----------|
| **A · 每语言独立文件** | 每种语言一个文件（如 `Locales/xxXX.lua`），由 `.toc` 或 `locale.xml` 显式加载 | ① 完全没有 `zhCN.lua`；② 已有 `zhCN.lua` 但部分 key 缺失 / 大量 value 仍为英文 | ① 新建并登记清单；② 对照英文基准补全并覆盖原文件 |
| **B · 单文件集中多语言** | 所有语言写在**同一个文件**里（含 AceLocale 同文件多语种分段），zhCN 往往靠回退显示英文 | zhCN 表 / zhCN 段不存在或严重残缺 | 在该文件内补全 zhCN 表 / zhCN 段，整体覆盖同步该文件 |
| **D · 外挂劫持补丁** | 插件硬编码英文、无任何多语言机制，且不愿改源文件 | 全部英文 | 做独立外挂插件运行时劫持 `SetText` 整串替换，见 [`_Locales_zhCN_External-Locale-Patch-Handbook.md`](_Locales_zhCN_External-Locale-Patch-Handbook.md)；已落地实例：`Patches/Retrace_LocalesPatch/` |
| **E · 源码级自建多语言改造** | 插件硬编码英文，且外挂补丁覆盖不全（如 AceGUI 组件内文本），改走源码：硬编码包 `L["<英文原文>"]` + 全局语言表缺键回退 | 全部英文 | 按插件改造文档在**源码内**包裹文本并新建语言文件；产物含源码改动，**不适用 zhcn_sync 同步流程**，插件重装后须按文档重新应用。已落地实例：`CompassHUD`（文档在子项目根，成果目录 `CompassHUD/`，脚本在 `_tools`，见下文条目） |
| *（预留）C · 框架式 locale* | 使用 Ace3 / LibStub / 注册式 locale 表等 | 取决于具体框架 | 按框架约定写入对应 locale 表，必要时注册 |

> 判断属于哪类，只需看插件目录：有 `Locales/` 且里面是 `enUS.lua`/`deDE.lua`… 的多半是 A 类；
> 只有一个 `Localization.lua` 或同文件内多语种分段的，是 B 类；
> 完全没有语言文件/语言目录、文案以英文硬编码在 `SetText`/`AddLine` 调用里的，是 D 类候选
> （判定前先确认控件是标准类型、且有可识别的具名锚点或可从插件表取到的根帧引用）。

## 语言文件首行注释（插件名 + 版本号）

每个补充语言文件的**第一行**必须是一条注释，写明「插件名 + 版本号 + 基准语言版本」，便于原插件日后更新时能精准对标：

    -- ReputationGuide full-1.6.0-release · zhCN 本地化（基准 enUS full-1.6.0-release）

格式：`-- <插件名> <版本号> · zhCN 本地化（基准 enUS <版本号>）`。
特殊写法（插件 TOC 本无版本号，如 MouseoverActionSettings）：
`-- <插件名> · zhCN 本地化（基准 enUS；该插件 TOC 无版本号）`。
AceLocale 分段套件（VanasKoS）无独立首行版本头，基线版本登记在 `_tools/zhcn_check_versions.py` 的 `BASELINE_OVERRIDE`。

## 目录与命名约定

- 本目录（`wow_Locales_zhCN/`）是简体中文语言文件的**主仓库**。
- **A 类（每语言独立文件）**：根目录下一个插件一个文件，命名 `{插件文件夹名}_zhCN.lua`
  - 例：`ReputationGuide_zhCN.lua`、`MinimalArchaeology_zhCN.lua`
- **B 类（单文件集中多语言）**：建**套件子目录**镜像插件本身的目录结构，文件名与游戏端完全一致，
  同步时**整体覆盖**这些文件
  - 例：`VanasKoS/`（`VanasKoS_Locale.lua` + `modules/*_Locale.lua` 共 15 个文件）、`Altoholic/`（9 个 Altoholic + 8 个 DataStore 文件，另含 `DataStore_Talents_zhCN.lua` 暂无落点）
- `Patches/`：**D 类外挂补丁插件**的主仓库保存处，每个补丁一个整插件目录
  （`Patches/<TARGET>_LocalesPatch/`），安装 = 整目录镜像进 AddOns 根（`zhcn_sync.py` 的 `PATCHES` 登记可直接同步）；手册见
  [`_Locales_zhCN_External-Locale-Patch-Handbook.md`](_Locales_zhCN_External-Locale-Patch-Handbook.md)。
- 工具脚本在**仓库根 `_tools/`**（大项目统一工具目录），zhCN 相关脚本均以 `zhcn_` 前缀命名（见下节）。

## 工具脚本（仓库根 _tools/，zhcn_ 前缀）

| 脚本 | 用途 |
|------|------|
| `_tools/zhcn_sync.py` | 把子项目语言文件同步进镜像。默认同步所有不一致文件；`--dry-run` 只报告不写入；`--plugin <名>` 指定插件；`--list` 列出登记表。`ADDONS` 登记文件级落点（状态含 `UNINSTALLED` / `NO_LOCALE`），`PATCHES` 登记 **D 类补丁整目录**（逐文件比对后补/覆盖，重装目标插件后可一键恢复） |
| `_tools/zhcn_check_versions.py` | 语言文件首行版本头 vs 镜像 TOC `## Version:` 的基线核对；版本升高 = 插件已更新，需对照 enUS 复查。支持标准版本头与套件旧式头 `-- <名> <版本> (zhCN 汉化 / Ade)` |
| `_tools/zhcn_diff_keys.py` | enUS ↔ zhCN key 齐平比对（缺失 / 多余 / 值相同），支持方括号型、点号型（`REP_TXT.*` / `BINDING_*`）、多行长括号字符串、跨行赋值四种取词写法 + AceLocale 同文件分段（VanasKoS）；enUS 基准支持三种来源：常规赋值文件、`list`（字符串清单表，Fitter）、`scan`（enUS 无 key 表，扫源码 `L[...]` 调用点） |

仓库根 `_tools/` 同时存放 `wow_dict/`（英中词典库工具，规范与用法见
[`../_docs/Localization-Terminology-Workflow.md`](../_docs/Localization-Terminology-Workflow.md) §四）；
本子项目的脚本一律 `zhcn_` 前缀，勿混用。

新增插件时的登记点：三个脚本的登记表（`ADDONS` / `HEADER_FILES` / `SEGMENT_FILES`）+ 本 README 各插件条目。

## 同步规则（更新语言文件后执行）

游戏插件目录通过软链接映射到本项目内的 `z-ref_retail_Interface_AddOns\`（对应
`{游戏安装目录}\_retail_\Interface\AddOns\`）。同步时遵循：

1. **保存位置**：放到目标插件目录下**与其他语言文件相同的位置**
   （A 类多为 `插件目录/Locales/zhCN.lua`，以插件实际目录为准；B 类整体覆盖其多语言单文件）。
2. **注册清单**：
   - A-①（新建 zhCN）：在 `.toc` 或 `locale.xml` 的其他语言文件加载行附近追加 `zhCN.lua` 加载行。
     **不为 TOC 追加多语言元数据**（如 `## Title-zhCN` / `## Notes-zhCN`），保留插件原有的多语言支持。
   - A-②（已有 zhCN）：清单已登记，**无需改动**，直接覆盖文件。
   - B 类：zhCN 表写在文件内部，清单无需改；用项目文件**整体覆盖**游戏对应文件。
   - D 类（外挂补丁）：补丁本身是独立插件，主仓库保存于 `Patches/`，安装 = **整目录镜像**进
     `z-ref_retail_Interface_AddOns\<TARGET>_LocalesPatch\`（已由 `zhcn_sync.py` 的 `PATCHES` 实现，
     `--plugin <补丁名>` 即可；镜像重装/更新目标插件后重跑一次即恢复）。
3. **无对应插件则跳过**：若镜像中不存在该插件目录，不做任何改动（同步脚本自动报 `UNINSTALLED`；
   插件在但上游无本地化机制时报 `NO_LOCALE`）。
4. **只同步最近更新者**：每次只把本次改动过的语言文件同步到游戏目录，不批量重刷全部
   （`zhcn_sync.py --plugin <名>`）。
5. **更新 / 重装插件后必须重新同步**：游戏解压插件会用原版文件覆盖镜像，我们同步的 zhCN 会一并被抹掉
   ——重装或更新任何插件后，跑一遍 `zhcn_sync.py`（详见踩坑记录第 1 条）。

## 各插件本地化机制与处理记录

### MapPinEnhanced（A-②：Phanx 覆盖层补齐，2026-11-15）

- 机制：**Phanx 方法**——`locales/locales.lua` 建 `MapPinEnhanced.L`（metatable 回退返回 key），
  `_imports.xml` 先加载 enUS 全量默认，再按 `[TextLocale]` 加载覆盖文件；
  `locales/zhCN.lua` 上游自带（38KB，机翻底子），有 GetLocale 守卫。
- 落地：复制镜像 zhCN 为项目主档 `MapPinEnhanced_zhCN.lua`（加版本头）→ 补齐 19 条、
  删除 4 条上游改名死条目（`Navigation.Minimap/WorldMap_*` → 4.0.2 改为
  `Navigation.Lock_*` / `Navigation.RouteMaps_*`）→ **600=600，0 缺失 / 0 多余**。
- 新增专名核实：`Shadowforge City` → `暗炉城`（中文维基）、`Xibala` → `希巴拉`、
  `Zalamar` → `扎拉玛`（8.0 官方地图用字）；`The Masonary` → `石匠坊`（无官方流通译名，
  黑石铸造厂分区，社区译法）；Mole Machine 条目值 = 纯地点名（沿用既有风格）。
- 刻意保留（3 条）：`'%s - %s'`（占位格式）、`X` / `Y`（坐标轴）。
  `Location Lexicon` → `地址簿`（MPE 自有词条、非暴雪术语，用户指定译名；无需词典入库）。
- **官方术语对照修正（2026-11-15，用户确认）**：`Dungeon` → `地下城`（原「地牢」）、
  `Raid` → `团队副本`（原「突袭」）、`Vignette` → `小场景`（原「缩略图」）、
  `Whisper` → `密语`（原「低语/耳语」）、`Instance` → `副本`（原「实例」）、
  `Hearthstone` → `炉石`（原「归家石/炉石传说」——**如有特地说明才译为「炉石传说」**）；
  连带修正描述用词 3 处（`请输入城市、地下城…` 等）。六条已入 `wow_dict` term 分类。
- **第二轮术语修正（2026-11-15，用户确认）**：`Track` 系 → `追踪`（本插件无音轨语境；
  原「曲目/赛道/按订单查询/跟踪」均错，`Track by Order` 的 Order=顺序）、`Atlas` → `素材集`
  （游戏素材集合）、`Name` → `名称`；导航方式 `Item=道具 / Flight Taxi=飞行管理员 /
  Phase Change=相位传送 / Tram=矿道地铁`（连带 Tram 乘句式 4 条）。以上已追加进
  `wow_dict` 术语规范与记忆。
- **第三轮术语修正（2026-11-15，用户确认）**：Lexicon 地点搜索的 NPC 服务类型与专业词 19 条
  （Bag Vendor=背包商人、Reagent Vendor=施法材料商、Class Trainer=职业训练师、Blacksmithing=锻造、
  Enchanting=附魔、Tailoring=裁缝、Stable Master=兽栏管理员、Point of interest=兴趣点、Town=城镇、
  Inn=旅店等，全表见 `wow_dict` term 分类 id 94212-94230 与记忆术语表）——原机翻
  「包包摊主/班级培训师/迷人的/量身定制」等全部纠正。Spell/Walking/Flight 系/Portal/Walking 修正见上轮。
  ⚠ 仍存明显机翻（用户未指示、暂保留）：`Ammunition Vendor=弹药供应商`、`Food Vendor=食品摊贩`、
  `Weapon Vendor=武器商人`、`Riding=骑行`（官方技能名「骑术」）、部分条目的「引脚」（Pin 官方语境
  更常用「图钉」）。
- 尺寸档：Tiny → `特小号`（对齐既有 Small=小号 / Default=默认 / Large=大号）。
- 已完成文件：`MapPinEnhanced_zhCN.lua`（同步至镜像 `locales/zhCN.lua`）。

### RCT（A-①：AceLocale 新建 zhCN.lua，2026-11-21）

- 机制：标准 **AceLocale-3.0**——注册名 `RdysCrateTracker`，`Locale/enUS.lua` 为默认表
  （`NewLocale(..., "enUS", true)`），其余语言 `NewLocale` 覆盖，`Locale/locale.lua` 用
  `GetLocale(..., true)` 取表挂 `_G.RCT_LOCALE`。TOC 中 `Locale/` 段在所有主文件之前加载。
- 落地：主档 `RCT_zhCN.lua`（版本头 14.5.5）全译 **438 条**（含 3 条跨行/单引号长文本：
  `ADDON_ADVERTISEMENT`、`VERSION_UPDATE_MESSAGE`、`WAR_CRATE_GUIDELINES`），
  TOC 在 `Locale/ruRU.lua` 后、`Locale/locale.lua` 前登记 `Locale/zhCN.lua`。
- 现 **enUS 453 / zhCN 453，缺失 0 / 多余 0**。刻意保留 15 条：插件名 4
  （`ADDON_NAME/TITLE/SHORT_NAME/TRACKER_TITLE`）、按钮字面量 `X`/`Opt`、Discord URL、
  格式串 `WINDOW_LABEL`/`WINDOW_TIMER`/`%dh %dm`、字体表 5 条（字体路径+字体名）。
- 官方地名（wow_dict confirmed）：多恩岛 / 喧鸣深窟 / 陨圣峪 / 艾基-卡赫特 / 海妖岛 / 安德麦。
  `DF`/`DRGF`/`DragonFlight` 三种缩写同指**巨龙时代**，已统一；`Shard`→位面、
  `War Supply Crate`→战争补给箱、`Raid Warning`→团队警告、`War Mode`→战争模式。
- 长 HOWTO 指南共 10 章全译（起始/计时器/位面/掉落/组队/日志/争夺/节奏/停靠/区域/队长/须知），
  保留 `/rct` 命令字面量与 `%s`/`%d` 占位符。
- 工具登记：diff_keys / sync / check_versions，落点 `RCT/Locale/zhCN.lua`（sync 首次
  `SYNC->MISSING` 即创建，复跑 `EQUAL`）；版本 14.5.5 MATCH。

### EmberLedger（A-① 变体：自建框架 localeOverrides 插表，2026-11-19）

- 机制：**自建本地化框架**（非 AceLocale）——`Localization.lua` 内嵌 `local enUS = {...}`
  基线表（**英文串即 key**，141 条）→ 装入 `EL.L` → `localeOverrides` 表按
  `EL.locale` 合并（上游已有 `["ruRU"]` 社区全译）。TOC 第三位加载。
- 落地（**B 类整文件模式**，同 VanasKoS）：主档 `EmberLedger/Localization.lua` 为镜像
  完整副本 + 版本头，在 `localeOverrides` 的 ruRU 表后平级插入 `["zhCN"]` 全译 141 条；
  sync 整文件覆盖镜像。**diff_keys 不登记**（enUS/zhCN 同文件且结构与 SEGMENT 模式不同，
  齐平用一次性脚本比对 enUS 141 / zhCN 141，缺失 0）。
- 专名查证：`Concentration` → `专注`（10.2 现役官方资源名）；`Artisan Moxie`、
  `Imbued Mulch`/`Mulch` 为 12.0「至暗之夜」新系统，Wowhead CN 被地域封锁、社区无权威
  官方译名 → **保留英文**（不臆造，待用户给出口径或官方译名后更新）。
- 译法：`Conc 1/2` → `专注 1/2`、`charges` → `次数`、`Realm` → `服务器`、
  `/el` 命令字面量保留英文、`P1/P2` 保留；Welcome 长文本保留 `\n\n` 结构全译。
- 工具登记：sync / check_versions（版本头规范格式——⚠ 首行括号内不得加后缀，
  HEADER_RE 要求 `（基准 enUS <版本>）` 严格收尾）；版本基线 2.3.5 MATCH。

### Prat-3.0（A-②：PRAT_L 全局共享表补齐，2026-11-17）

- 机制：与 QuestPrism 同族但已有社区覆盖层——`locales/enUS.lua` 建 `local L = {}` 并挂
  `PRAT_L` 全局表，其余语言文件 GetLocale 守卫 + 同表覆盖，`locales/includes.xml` 分发。
  上游 zhCN.lua 60.5KB（社区汉化底子），enUS 70.9KB。
- 落地：复制镜像 zhCN 为主档 `Prat-3.0_zhCN.lua` → 补齐 **119 条**（ChatTabs 闪烁/高亮、
  CopyChat 透明度、DebugModules、Filtering AI 反垃圾、Font/Frames 透明度、Highlight 公会/自己、
  History 存储位置与回卷时长、LinkInfoIcons 链接信息、Mentions @提及、NewcomersChat 导师/新人、
  PlayerNames 战网客户端图标、Search、ServerNames、SideTabs 侧边标签整块、Timestamps 日期格式）、
  删除 1 条死条目（`AltNames/No arg string given to :addAlt()`——全源码无调用点）。
- 现 **enUS 981 / zhCN 982，缺失 0**。多余 1 条 `Substitutions/current-prompt` 为**活翻译**
  （Substitutions.lua:94 直接 `PL["current-prompt"]:format(...)`，enUS 基线不完备——踩坑 #2
  同款情形，diff 的「多余」是预期状态）。
- 刻意保留（值相同 5 条）：`prat`、`AltNames/.*[Aa]lts?$`（正则模式）、
  `AltNames/.*[Tt]wink.*$`（正则模式）、`CustomFilters/<string>`、`TellTarget//tt`（命令字面量）。
- 译名惯例沿用社区版：alt=马甲、main=本尊、Scrollback=回卷、module_name 译中文
  （侧边标签/链接信息图标/提及/新人聊天/调试模块）；时间戳格式串译法沿用
  「时:分 上午(12-小时)」（格式串仅作显示标签，真实格式在代码 `DATE_FORMATS` 的 key 中，
  已核对 Timestamps.lua:42-48 确认翻译安全）。
- 新人频道官方词：Guide=导师、Newcomer=新人。
- 工具登记：diff_keys / sync / check_versions 三处，落点 `Prat-3.0/locales/zhCN.lua`，
  版本基线 3.9.117 MATCH。

### QuestPrism（A-①：全局共享表点号赋值，2026-11-15）

- 机制：**非 AceLocale**。`Locales/enUS.lua` 建 `QuestPrism_L = {}` 全局共享表并直接
  `L.KEY = "value"` 点号赋值；TOC 只登记 enUS，**无 GetLocale 分发**。
- 落地：新建 `Locales/zhCN.lua`（GetLocale 守卫 + 同表覆盖，未覆盖 key 回退英文）+
  TOC 在 enUS 之后登记一行（镜像写入例外）。enUS 之后加载是关键——若放前面会被
  enUS 全量覆盖（同一张表）。
- 特殊结构：`L.HELP_LINES = {...}`（表值）与 3 个 `BINDING_*` `_G` 全局赋值。
  BINDING 保留插件名 `QuestPrism` 英文（值相同 2 条为刻意）。
- 任务分类八类术语：战役 / 重要 / 传说 / 综合（Meta）/ 可重复 / 本地故事 / 活动（Events）/
  低级任务（Trivial）+ 世界任务；指南（guide）支持 Zygor / RestedXP / BtWQuests。
- 已完成文件：`QuestPrism_zhCN.lua`（143 键齐平 0 缺失 0 多余；源码调用点扫描 136 个
  key 全部被 enUS 定义覆盖，无遗漏）。
- 工具适配：`zhcn_diff_keys.py` 登记 `dotted: L\.\w+|BINDING_\w+`（点号型首个 BINDING
  全局混合用例）；`L.HELP_LINES` 表值被 extract 的字符串值过滤跳过，两侧一致不影响齐平。

### ReputationGuide（A-②：已有 zhCN 但缺失 / 大量未译，全局变量赋值型）

- 语言文件位置：`ReputationGuide/locales/`（小写 `locales/`；清单 `locales/locale.xml` 已含
  `<Include file="zhCN.lua"/>`，无需改动）。镜像侧 6 个资料片 TOC 版本一致（`full-1.6.0-release`）。
- 机制：语言文件直接给全局表赋值（`REP_TXT.xxx = "..."` 与少量 `BINDING_*` 全局），
  整个文件包在 `if (GetLocale() == "zhCN") then ... end` 中；英文基准为 `enUS.lua`（含子表 `REP_TXT.Mob = {}` 等）。
- 官方 zhCN 的已修正问题：**缺失 key 4 个**（`REP_TXT.Mob.BoulderfistOgre`、`REP_TXT.Mob.MoshOgg_Spellcrafter`、
  `REP_TXT.elements.name/tip.REP_ShowDarkmoonFaireButton`），且官方 zhCN **漏建 `REP_TXT.Mob = {}` 子表声明**
  （会导致 Mob 赋值直接报错，已补）；**未翻译 value 61 处**已逐条翻译。
- 刻意保留（5 个）：`[G]`/`[M]`/`[Q]`/`[D]`/`[I]` 方括号单字母 UI 标签（`*Short` 键），非可译词汇。
- 结果：key 集合 enUS 245 = zhCN 245，缺失 0、多余 0、值相同 5（即上述刻意保留）。
- 已完成文件：`ReputationGuide_zhCN.lua`（覆盖同步至镜像 `locales/zhCN.lua`）。

### VanasKoS（B-多文件：每个 `*_Locale.lua` 内含全部语种段，AceLocale）

- 基线 `12.1.5.1`。语言文件共 **15 个**：根目录 `VanasKoS_Locale.lua` + `modules/` 下 14 个；
  项目子目录 `VanasKoS/` 结构与插件完全一致，同步时**整体覆盖**这 15 个文件（TOC 无需改动）。
- 机制：`LibStub("AceLocale-3.0"):NewLocale("<模块名>", "<语种>")` 按模块注册，
  同一文件里依次写 enUS / frFR / … / zhCN / zhTW 等段；enUS 段多为 `L["key"] = true`（值即 key 本身）。
- ⚠ **关键 1：少数 enUS 值不是 `true`，而是实际显示文本**，此时必须译「值」而非译 key：
  `_UNKNOWN_NAME_` / `_UNKNOWN_REALM_` → 值 `"unknown"` → 译「未知」；
  `Save data gathered in normal mode` → 值 `"Gather in Normal Mode"`；Notifier 的 5 个 key
  enUS 值含 `|cffff00ff...|r` 颜色代码，翻译时必须保留。
- ⚠ **关键 2：enUS 段不是完备基线**。AceLocale 对未注册 key 回退为 key 本身，
  故 zhCN 段里「enUS 没有」的 key 仍会被源码引用并显示中文，**绝不可当废弃 key 删除**。
  实测此类 key 共 34 个（根 13 + Importer 5 + PvPDataGatherer 15 + Synchronizer 1），均在用。
- 缺失标记写法：`--[[Translation missing --]]` 紧邻一行被注释的空译文；补齐时须**同时删掉标记行**。
- 排版约定：zhCN 段的 key 顺序与行首缩进对齐 enUS 段（enUS 首次出现顺序；zhCN 独有 key 排末尾；
  段首注释与 `if L then` / `end` 结构保留，其它语种段完全不动）。
- 上游 enUS 段自带的重复 key（后值覆盖前值、无功能影响）属上游打包问题，**不改动上游 enUS 段**。
- 校验：`zhcn_diff_keys.py --addon VanasKoS`（同文件切段比对），当前 15 个文件缺失 0。
- 已完成文件：`VanasKoS/` 下 15 个文件（已覆盖同步至镜像）。

### Krowi_AchievementFilter_Khamuls_ExpMetaAchievementFilter（A-①：AceLocale，机翻精修）

- 语言文件位置：`Localization/zhCN.lua`（`Localization/Files.xml` 已登记加载，无需改动）。
- 机制：A 类 + AceLocale 子 locale（enUS 建基准，缺 key 自动回退）。
- 原译文为 chatgpt 机翻，其中 **15 个词条值仍为英文**（坐骑收藏设置、RewardPreview 奖励预览、调试设置等
  分区），已补 14 条；`NPC` 官方中文即「NPC」保留不译。
- 遗留：部分词条**翻译有误**，待后续单独精修（见踩坑记录第 9 条）。
- 已完成文件：`Krowi_..._zhCN.lua`（52 键齐平，同步至镜像 `Localization/zhCN.lua`）。

### MinimalArchaeology（A-①：AceLocale，文件存在但译文残缺）

- 语言文件位置：`addon/locales/ZhCN.lua`（**首字母大写**，作者命名如此；`Locales.xml` 已登记，无需改动）。
- 机制：A 类 + AceLocale。另一 `addon/locales/DigSiteLocales/ZhCN.lua`（挖掘场地名）作者已提供且完整，**无需维护**。
- 原有 13 处 `--[[Translation missing --]]`（值仍英文），已全部填充（化石密文提示、边框样式/颜色/粗细/
  按钮位置/现代边框自定义等）并移除缺失标记；主文件 **322 键**与 enUS 齐平、占位符一致。
- 已完成文件：`MinimalArchaeology_zhCN.lua`（同步至镜像 `addon/locales/ZhCN.lua`）。

### MouseoverActionSettings（A-①：zhCN 是空壳，全量自译）

- 语言文件位置：`Locales/zhCN.lua`（根目录 `locales.xml` 已登记，无需改动）。
- 机制：A 类；`local addonName = ...` 取模块名。原 zhCN 为**纯空壳**（0 条译文）。
- 全量自译 **184 键**；enUS 的 `create_module_info_field` 等值用 `\124cFF..\124r`（`\124`=`|`），
  按约定已转为常规 `|cFF..|r`；`HUD` 保留不译；部分 `*_update_desc` 键 enUS 本身就是空串，照留空。
- 该插件 TOC **没有 `## Version:`**，版本头按上文特殊写法登记。
- 已完成文件：`MouseoverActionSettings_zhCN.lua`（184 键齐平，同步至镜像 `Locales/zhCN.lua`）。

### TLDRMissions（已卸载，文件保留）

- 曾维护至镜像 `12.1-002`（`Locales/zhcn.lua` 全小写落点，90 键齐平）。
- 2026-11-13 镜像更新后插件被卸载（整个目录消失），主文件 `TLDRMissions_zhCN.lua` 保留以备重装，
  同步脚本自动报 `UNINSTALLED`。

### Altoholic / DataStore 套件（已安装并同步，2026-11-13）

- 套件为 **AddonFactory:SetLocale 注册表型**（`local L = AddonFactory:SetLocale(addonName, "zhCN")`），
  每模块独立 `Locales/zhCN.lua`，由各自 `Locale.xml` 加载（均自带 zhCN 登记，清单无需改动）。
- 镜像版本：Altoholic 9 模块 `12.1.007`、DataStore 8 模块 `2026.10.14`，与语言文件版本头基线完全一致；
  已用 `zhcn_diff_keys.py` 逐模块核对（如 `Altoholic_Options` 268=268、`Altoholic_Summary` 285=285），**0 缺失 / 0 废弃**。
- 17 个模块文件已同步至镜像各模块 `Locales/zhCN.lua`；套件版本头用旧式格式
  `-- <模块名> <版本> (zhCN 汉化 / Ade)`（`zhcn_check_versions.py` 已兼容）。
- ⚠ **DataStore_Talents 不再维护落点**：新版上游移除了该模块的本地化机制（无 `Locales/` 与 `Locale.xml`），
  项目文件 `Altoholic/DataStore_Talents_zhCN.lua` 保留备查，同步脚本报 `NO_LOCALE`。
- ⚠ 其余 8 个 DataStore 模块（Achievements / Agenda / Containers / Currencies / Pets / Reputations /
  Spells / Stats）上游本就**无本地化机制**（纯数据层、无可翻译字符串），本项目不维护，属正常排除。
- ⚠ 上游打包痕迹（旧镜像实测）：`DataStore_Talents` 目录内曾混有 `DataStore_Quests.*` 副本、
  两模块 enUS/zhCN 内容完全相同；若上游日后把 Talents 的 enUS 改成真正天赋文本，译文须拆开处理。

### Fitter（A-②：覆盖层补齐 + 译名修正，2026-11-13）

- 机制：`Locales/Localization.lua` 建 `ns.L`，`__index` 回退返回 key；`Locales/enUS.lua`
  是**字符串清单表**（`local strings = {...}`，权威 key 清单），各语种文件按 key 覆盖。
  TOC 已登记 `Locales\zhCN.lua`（清单无需改动）。
- **2.12.2 重构（2026-11-14）**：上游把 `Localization/` 目录改名为 `Locales/`，zhCN 落点变为
  `Locales\zhCN.lua`（sync 登记已跟着改）。对照 enUS 2.12.2 全量清单 **399 条**补齐 95 条
  （条件系统/宏/角色导出/分享/后备坐骑/区域情境联动），删除 7 条失效 key（4 条为 2.12.1
  提取器截断产生的「半截串」、3 条新版已改写），现 **399=399，0 缺失 / 0 多余 / 0 值相同**。
- **2.12.3（2026-11-14）**：上游纯 bugfix，enUS key 集合不变（399=399 复核通过），
  仅版本头 bump 与镜像同步。
- **2.13.0（2026-11-17，镜像更新后复查）**：enUS 新增 4 条「坐下（Sit）」活动词条
  （含德鲁伊坐骑宏替换长串 1 条），已补译；现 **403=403，0 缺失 / 0 多余**，
  版本头 bump 与镜像同步（重装被抹后已重跑 sync 恢复）。
- 译名修正：`座骑` → `坐骑`（官方用字）、favorite 系 → `最爱`、`Astral Recall` → `星界回溯`、
  `Nazjatar` → `纳沙塔尔`（原「纳斯雅塔尔」有误，词典 confirmed）。
- 新增专名核实：G-99 Breakneck → `G-99疾飙飞车`（游戏内官方译名）、Undermine → `安德麦`、
  Zen Flight → `禅意飞行`（Wowhead CN spell=195197）。
- 修饰键 `Alt`/`Ctrl`/`Shift` 保留英文同值（官方按键名不翻译）。
- 格式约定：**每行一个 key**（`["key"] = "value",`），不合并多条到同一行。
- enUS 基准为清单型，`zhcn_diff_keys.py` 以 `enus_mode="list"` 登记；
  版本头 `-- Fitter 2.12.2 · zhCN 本地化（基准 enUS 2.12.2）`。
- 节日名取官方日历用词：新年节 / 爱就在空中 / 贵族花园节 / 儿童周 / 仲夏火焰节 / 美酒节 /
  万圣节 / 亡者节 / 朝圣者的恩赐 / 冬幕节 / 暗月马戏团 / 魔兽世界周年庆。

### CooldownManagerCentered（A-②：AceLocale 覆盖层，社区汉化底子 + 5.12.2 新增，2026-11-17）

- 语言文件位置：`locales/zhCN.lua`（小写 `locales/`；根目录 `local.xml` 已登记，无需改动）。
- 机制：A 类 + AceLocale（enUS `NewLocale(..., "enUS", true)` 为默认，zhCN 覆盖层缺 key 回退）。
- 译文底子：**社区爱好者汉化**（`_temp/CooldownManagerCentered_CN`，基于 5.12.1，510 条无死条目），
  按其原有风格（半角标点、`%s` 紧贴中文）沿用；未做全局标点重排。
- **5.12.1 → 5.12.2 新增 5 条**（编辑模式锚定 / 暴雪可见性设置冲突提示，`core/anchoring.lua` +
  `modules/visibility.lua`，均为 `%s` 格式串，`%s` 实参为查看器名 / 高亮的暴雪设置名 / 蓝色高亮的
  `HUD_EDIT_MODE_MENU`（官译「编辑模式」），色码结构已保留），插入位置对齐 enUS 行序。
- 刻意保留（1 条）：`Slug`（自定义字体 flag 名，各语言版本均同值）。
- 已完成文件：`CooldownManagerCentered_zhCN.lua`（515 键齐平，同步至镜像 `locales/zhCN.lua`）。

### Questwise（已停止支持，2026-11-13）

- 插件不符合使用需求，决定不再提供支持。当天的 A-① 产出（`Questwise_zhCN.lua`、
  镜像 `Locales/zhCN.lua` 与 TOC 登记行）已全部移除，三脚本登记已撤销。
- 遗留经验保留在踩坑记录 #13/#14（A-① 加载清单登记、scan 型 enUS 基准），工具的
  `scan` 模式作为通用能力保留。

### Retrace（D 类：外挂汉化补丁，2026-11-13）

- 判定**适用（有限覆盖）**：无任何本地化机制、文本走标准控件 `SetText`/`AddLine`；
  有具名锚点 `RetraceReplayFrame`、`RetraceMinimapButton`，另有两个无名根帧可从插件表取引用
  （`Retrace.xpBarFrame`、`Retrace._BuildOptions()` 返回的设置面板，首次构建后有缓存）。
- 补丁：`Patches/Retrace_LocalesPatch/`（TOC + `Lang_zhCN.lua` + `LocalesPatch.lua`），
  已镜像到 `z-ref_retail_Interface_AddOns\Retrace_LocalesPatch\`；字典 **98 条**，全部经
  「Lua 反转义后与源码字面量逐字一致」校验（含前导双空格、`|cff` 色码、`\n`）。
- 覆盖：设置面板全部文案（含 BACKUP 长文本）、回放筛选/按钮/侧栏提示、日志搜索与分类
  （15 类）、地下城档案统计标签与页签提示、小地图按钮提示、经验追踪提示、3 条确认弹窗。
- 动态串走 `PrefixRules`：`Lv N`→`等级 N`、`Speed xN`→`速度 xN`、`Level N  ·  …`→`等级 N  ·  …`、
  `Restore removed entries (N)` / `Notable loot (N)`、`recording paused` 状态段、`(blue) = within the Trail window:`
- 已知局限（手册 §11 口径）：事件叙述/日期/距离统计等运行时格式化串、地图事件气泡内容、
  `Atlas.lua` 内置的经典副本与首领英文名（数据类，未译）、聊天命令输出（走 `print`）保留英文。

### CompassHUD（E 类：源码级自建多语言改造，2026-11-19）

- 判定：全部界面文案硬编码英文、无任何多语言机制。曾按 D 类做过外挂劫持补丁，
  **实测只命中小地图图标 tooltip**，设置界面等 AceGUI-3.0 组件内文本无法劫持——
  外挂方案整体废弃删除，改走 **E 类源码改造**（本子项目首例；见踩坑记录 #17）。
- **独立子项目（文件位于 `wow_Locales_zhCN/` 根 + 成果目录 + `_tools` 脚本）**：
  - [`_Locales_CompassHUD_zhCN_Development-Process.md`](_Locales_CompassHUD_zhCN_Development-Process.md)：
    完整开发流程（路线变更、机制设计、加载时序、开发实录、校验、快速应用、实机验证清单）；
  - [`_Locales_CompassHUD_zhCN_Modification-Locations.md`](_Locales_CompassHUD_zhCN_Modification-Locations.md)：
    修改位置明细（20 个文件逐个表格，含锚点行号与不译位置核对清单）；
  - [`_Locales_CompassHUD_zhCN.lua`](_Locales_CompassHUD_zhCN.lua)：
    中英对照词条主档（**520 条**，507 静态 + 13 条 `%s` 模板；key=英文原文逐字对齐；唯一权威）；
  - `CompassHUD/`：**项目成果 = 插件目录镜像**（20 个文件），可整目录直接覆盖游戏插件安装目录；
  - `_tools/CompassHUD_zhCN_Locations-apply.ps1`：一键应用脚本。
- 机制：全局表 `CompassHUDLocale`（`__index` 缺键回退返回 key 即英文原文，英文零维护）；
  源码硬编码全部包 `L["<英文原文>"]`；`Init.lua` 经 `Addon.env.L` 注入共享环境
  （⚠ 仅对执行了 `setfenv(1, Addon.env)` 的文件生效，`databroker.lua` 等主块文件须
  自行 `local L = CompassHUDLocale`，见踩坑 #18）；
  Profiles 页由 `Libs\AceDBOptions-3.0` **自带 zhCN 语言块**自译——第三方库保持原样不改；
  TOC 中 Locales 两文件位于 `Libs\libs.xml` 之前（全局表与回退说明同在 enUS.lua 头部，
  不再单独加载 Localization.lua）。
- 规模：Options.lua 478 + Looks.lua 70 + 其余 59 ≈ **607 处 L[ 引用**，对应主档 520 条。
- **快速应用**（插件重装同版本后一条命令）：
  `powershell -ExecutionPolicy Bypass -File _tools\CompassHUD_zhCN_Locations-apply.ps1`
  （版本基线核对 → 主档刷新成果目录 → 成果整体覆盖 → 哨兵行核验；版本不符时拒绝执行需 `-Force`）。
- **上游更新流程**：先 `git diff --no-index` 对比成果目录与新版 → 按修改位置文档逐文件
  复核 → 更新主档/成果/版本基线 → 脚本加 `-Force` 重跑。
- 改造后完整插件备份：`_temp\CompassHUD_zhCN\`（2.1.1 多语言版；Libs 与原版一致）。
- 不译清单：内部存档键、poiTypeEnum / Enum 值、纹理查找键、LSM 媒体名、方向字母、
  AddToBlizOptions 路径键（详见修改位置文档）。

## 踩坑记录

开发过程中实际踩到的坑，按机制归类沉淀于此；新增条目须写清「现象 → 原因 → 对策」。

1. **插件更新 / 重装会抹掉镜像里的 zhCN**。游戏解压插件必然以原版文件覆盖镜像目录
   ——原项目曾实测：重解压后同步过的 zhCN 被英文空壳覆盖（部分文件甚至变 0 字节）。
   对策：**更新或重装任何插件后，必须重跑 `_tools/zhcn_sync.py`**，并用
   `zhcn_check_versions.py` 确认版本基线是否随之升高。
2. **AceLocale 的 enUS 段不是完备基线**（VanasKoS）。AceLocale 对未注册 key 回退为 key 本身，
   zhCN 段里「enUS 没有」的 key 仍会被源码引用并显示中文，绝不可当废弃 key 删除（实测 34 个均在用）。
   ⚠ 因此 `zhcn_diff_keys.py` 对 VanasKoS（SEGMENT 模式）报的 **「多余」不是死条目，是预期内的
   正常状态**（VanasKoS 13 + Importer 5 + PvPDataGatherer 15 + Synchronizer 1 = 34 条），比对时只看
   「缺失」。2026-11-14 曾误当死条目删除，后经源码调用点扫描证实 17 条有直接调用、其余为动态
   拼接 key（`L[cmd]` / `L["by " .. x]`）无法静态排除，全部恢复——删任何「多余」key 前必须先
   grep 源码调用点，SEGMENT 模式直接跳过多余项。
3. **enUS 段的值可能是实际显示文本而非占位**（VanasKoS）。此时必须译「值」而非译 key；
   值内含 `|cFF..|r` 颜色代码时翻译必须保留色码结构。
4. **缺失标记要连标记行一起删**。`--[[Translation missing --]]` + 被注释的空译文是作者的缺失标记，
   补齐后残留会误导后续维护。
5. **注册表型 locale 的 `Apply` 会先 `wipe` 再铺英文基准**（原项目 ShinyHunter 实例，机制通用）。
   凡在英文基准捕获**之后**声明的 key 不会进基准，必须由 zhCN 包自带，
   否则加载后显示原始 key 字符串而非英文回退。
6. **转义形式不同 = 字符串不同**。enUS 用数字转义 `\124c`（即 `|c`）时，zhCN 按约定写常规 `|cFF..|r`
   （本项目约定）；`\n` 与 `\\n` 经 Lua 解析后不相等（原项目 LaegersProfession 上游转义笔误导致英文客户端都查不到表）。
   校验工具必须按 Lua 转义规则解析后比对，不能比原始文本。
7. **不要从 zhTW 直转，也不要反向回填官方 zhCN**。官方 / 上游自带 zhCN 普遍不完整且有错
   （ReputationGuide 官方 zhCN 缺 4 key、漏建 `REP_TXT.Mob = {}` 子表会直接报错；TLDRMissions 繁简混合机翻）。
   一律以 enUS 为基准自译，上游自带 zhCN 只作术语参考。
8. **落点文件名以插件实际为准**。TLDRMissions 是全小写 `Locales/zhcn.lua`、MinimalArchaeology 是
   首字母大写 `addon/locales/ZhCN.lua`——不能想当然写 `zhCN.lua`；落点已逐个登记在
   `zhcn_sync.py` 的 `ADDONS`。
9. **命令词 / 宏名 / 方法名硬编码不可译**。命令处理器按字面匹配输入（如 `/qmblizz`、`help`/`reset`）、
   宏名带 `-- DO NOT TRANSLATE` 标注——译了会「显示中文却输入不生效」，一律保留英文。
10. **机翻基底必须全量复核**。Krowi 元成就子插件的原 zhCN 是机翻，除英文残留外部分译文语义有误；
    凡接手机翻底子，补齐后仍需逐条精修，不能只补缺失就当完成。
11. **比对工具必须吃下多行长括号字符串**。zhCN 文件常用 `L["KEY"] = [[多行
    译文]]` 形式（Altoholic 主插件 / Summary 实测），逐行正则会漏掉这些赋值，
    把已翻译词条误报成「缺失」。对策：`zhcn_diff_keys.py` 已在提取前把
    `[[...]]` 折叠为单行再扫描；自行写脚本时同样要预处理。
12. **跨行赋值也要吃下**。`["KEY"] =\n  "值"`（key 与值分两行）在逐行扫描里同样会漏
    （Fitter 实测漏 1 条）。对策：工具已在提取前把 `] =` 与值之间的换行并回一行；
    写语言文件时尽量 key/value 同行。
13. **A-① 必须同步登记加载清单**。给没有 zhCN 槽位的插件新建语言文件后，必须在其 `.toc`
    （或 Locale.xml）里追加加载行——文件存在但 TOC 不加载等于没做。这是本子项目唯一需要
    改动插件自身文件的情形，且**插件重装后要重新登记**（Questwise 曾实测，现已退坑）。
14. **enUS 基准不一定在 enUS 文件里**。Fitter 的 `enUS.lua` 是字符串清单表（`local strings = {...}`）；
    已退坑的 Questwise 则是 enUS 文件只有 `setmetatable` 回退、真实 key 散在源码
    `L["..."]` 调用点。照搬「读 enUS 文件的 `L[k]=v`」会得到 0 key 的假象；
    `zhcn_diff_keys.py` 支持 `enus_mode="list"` / `"scan"` 两种基准来源。
15. **D 类字典 key 必须与 `SetText` 实收串逐字一致**。Retrace 实测三类坑：
    ① 前导空格（Atlas 的 `"  Runs / time inside"`、`"  Bosses defeated / deaths"`）——
    少一个空格就永不命中；② 拼接串（`date(...)  ·  "recording paused"`、`"(blue) = within the Trail window: " .. 筛选名`）
    必须转 `PrefixRules` 而非写死整串；③ 调试用 `print` 串（`"  game list "`）不是 UI，别塞进字典。
    对策：写完字典后用「Lua 反转义 + 与源码字面量集合比对」的脚本兜底（本轮 98/98 命中）。
16. **清单表提取器不能截取表体**。`zhcn_diff_keys.py` 的 `list` 模式最初用
    `local strings = {...}(.*?)^}` 非贪婪截断——表内有行首 `}`（嵌套表/续行）时会提前结束，
    后面几十条 key 整段漏提（Fitter 2.12.1 实测：实际 ~390 条只提取到 311，且抓到的部分含
    「跨行拆开的半截串」）。对策：改为全文抓引号字面量 + 去注释行（不依赖行结构，同行多串
    天然免疫）；**不要重排镜像里的原版 enUS 来"修复"**（镜像只读）。Fitter 2.12.2 升级时由
    此补回 95 条、删 7 条半截串。
17. **D 类外挂补丁对 AceGUI/框架内文本覆盖不全时，果断升级为 E 类源码改造**（CompassHUD）。
    实测：劫持 `SetText` 只命中小地图图标 tooltip，AceConfig 设置面板（AceGUI-3.0 组件树、
    动态构建的 label/checkbox 文本）大量文本无法静态枚举劫持。凡设置界面基于 AceConfig
    / AceGUI 或类似运行时构建框架的硬编码插件，直接走源码包裹 `L["<原文>"]` +
    全局语言表缺键回退，不做外挂补丁（避免双重维护与半覆盖状态）。
18. **包裹全局语言表引用前，先确认目标文件是否进入共享环境**（CompassHUD 实机报错）。
    CompassHUD 靠各文件头部 `setfenv(1, Addon.env)` 共享顶层名，`Init.lua` 注入
    `Addon.env.L` 只对已 setfenv 的文件可见；`databroker.lua` 无 setfenv（主块跑在
    全局环境），顶层包裹 `L[...]` 直接报 `attempt to index global 'L' (a nil value)`，
    且主块中断导致后续文件引用其函数连锁报错。对策：包裹前 grep 目标文件的 setfenv
    情况；不进环境的文件先 `local L = CompassHUDLocale`（语言表本身是真全局，
    由 TOC 中更早加载的 enUS 文件建立）。

## 工作流程小结

1. 判断插件属于 A / B / D 类（看语言文件组织方式；硬编码英文 → D 类外挂补丁）。
2. 在本目录新建 / 更新对应项目文件（`{插件}_zhCN.lua`、套件子目录下的镜像文件，或 `Patches/` 下的补丁插件）。
3. 按「同步规则」用 `_tools/zhcn_sync.py` 复制到 `z-ref_retail_Interface_AddOns\` 对应插件目录
   （A-① 还需补加载清单；B 类整体覆盖单文件；D 类整目录复制补丁插件）。
4. 跑 `_tools/zhcn_diff_keys.py` 确认 key 齐平、`_tools/zhcn_check_versions.py` 确认版本基线
   （术语译法与官方译名核实走 [`../_docs/Localization-Terminology-Workflow.md`](../_docs/Localization-Terminology-Workflow.md)
   与 `_tools/wow_dict` 词典库）。
5. 进游戏重载（`/reload`）验证中文生效。

## 2026-11-17 插件更新/重装复查小结

- `zhcn_check_versions.py` 全量核对：除下述两例外全部 MATCH；
- **Fitter 2.12.3 → 2.13.0**：补 4 条新增（坐下活动），403=403，已同步；
- **MapPinEnhanced / MouseoverActionSettings / Retrace_LocalesPatch**：重装被抹，sync 恢复；
- 新登记 **CooldownManagerCentered**（见上文条目）；
- 其余（QuestPrism / ReputationGuide / Krowi 元成就 / MinimalArchaeology / TLDRMissions / VanasKoS /
  Altoholic + DataStore 17 模块）全部 EQUAL 无需动作。
