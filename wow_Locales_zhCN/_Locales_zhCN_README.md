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

## 工作流程小结

1. 判断插件属于 A / B / D 类（看语言文件组织方式；硬编码英文 → D 类外挂补丁）。
2. 在本目录新建 / 更新对应项目文件（`{插件}_zhCN.lua`、套件子目录下的镜像文件，或 `Patches/` 下的补丁插件）。
3. 按「同步规则」用 `_tools/zhcn_sync.py` 复制到 `z-ref_retail_Interface_AddOns\` 对应插件目录
   （A-① 还需补加载清单；B 类整体覆盖单文件；D 类整目录复制补丁插件）。
4. 跑 `_tools/zhcn_diff_keys.py` 确认 key 齐平、`_tools/zhcn_check_versions.py` 确认版本基线
   （术语译法与官方译名核实走 [`../_docs/Localization-Terminology-Workflow.md`](../_docs/Localization-Terminology-Workflow.md)
   与 `_tools/wow_dict` 词典库）。
5. 进游戏重载（`/reload`）验证中文生效。
