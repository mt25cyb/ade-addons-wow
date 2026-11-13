# WoW 英中词典（enUS → zhCN）

> ⚠️ **本文件为历史种子快照，已不再手动维护。** 权威数据已迁入数据库 `_wow_dict.db`（SQLite）。
> 新增/修改词条请走数据库（用法见 `_wow_dict_GUIDE.md`）；本文件仅作可读备份，**不反向写库**。

> **适用范围**：**所有 WoW 插件开发与文档生成** —— 插件本地化、汉化包、UI 文案、
> 说明文档与注释翻译。本词典**不是某个项目专用**。
>
> **收录范围**：仅收录「**与常规翻译有区别**的」游戏专有名词 —— 资料片/版本、种族、势力/声望、地理/区域、
> NPC/角色名、怪物/生物、物件/可交互物、物品、任务、成就、游戏内容/玩法、游戏机制术语等。
>
> **不收录**：字面直译即可的普通词句（`Talk to`→与…交谈、`Use`→使用、`Complete`→完成）。
>
> **收录标准**：**游戏含义不同于日常用法，或有官方指定译法**。
> 例：`instance`→副本（日常义"实例"）、`dragonriding`→驭龙术（非字面"骑龙"）。
>
> **来源**：国服官方译名 / wowhead CN / 游戏内文本 / 用户确认。
> **未确认者不臆造** —— 查不到就留空并标注待确认，禁止凭印象补全。
> 详见 `.codebuddy/references/anti-fabrication.md`。
>
> **项目专属译名不进本词典**，放各自项目目录（如 RXPGuides 的指南名见 `_tools/rxp/TRANSLATION_RULES.md`）。

## 自动获取译名的方法（wowhead CN）

> 适用于所有 wowhead 有独立页面的实体：**NPC / 角色、怪物 / 生物（`npc`）、物件 / 可交互物（`object`）、
> 任务（`quest`）、成就（`achievement`）、物品（`item`）、法术 / 技能（`spell`）、地图 / 区域（`zone`）** 等。
> （种族、势力/声望多为分类标签，无独立 ID 页，需从实体页或分类页取。）
>
> 操作流程：
>
> 1. `web_search("{英文名}" site:www.wowhead.com)` 拿带 `ID` 的页面 URL
>    —— wowhead 站内搜索对撇号 / 特殊字符不友好，用 Google `site:` 限制更稳。
> 2. 取 URL 中的数字 `ID` 与类型前缀（`npc` / `object` / `quest` / `item` / `achievement` / `spell` / `zone` …）。
> 3. GET `https://www.wowhead.com/cn/{type}={ID}`，解析 `<meta property="og:title">`
>    第一段（按 `—` 分割）即官方中文名。
> 4. 批量可用脚本 `_tools/rxp/fetch_ids.py`（`(label, type, id)` 列表驱动），**须走代理 `http://127.0.0.1:7890`**。
>    `web_fetch` 对怪物页有 10s JS 超时，批量请直接用 Python `urllib` 抓静态 `og:title`（代理对 Python 已生效）。
> 5. 拿到译名后按分类写入下方对应表（首列填 ID，消除同名歧义）。

## 关于 ID 列

- 实体类词条（NPC / 任务 / 物品 / 成就 / 物件）**首列为 ID**，用于唯一对应，消除同名歧义：

| 分类                      | ID 列             | 说明                                      |
| ------------------------- | ----------------- | ----------------------------------------- |
| NPC / 角色名、怪物 / 生物 | `npcID`         |                                           |
| 物件 / 可交互物           | `objectID`      | wowhead`object` 类型（场景交互物/装置） |
| 任务名                    | `questID`       |                                           |
| 物品                      | `itemID`        |                                           |
| 成就                      | `achievementID` | 本词典暂无成就词条，补充时沿用此约定      |

- ⚠️ **当前多数 ID 为空**：本地暂无 ID 数据源（仅存译名对照），**未臆造任何 ID**。
  空 ID 表示**待补**，不代表该实体无 ID。
- **补充 ID 的可靠途径**（按优先级）：
  1. 游戏内 `/dump` 或插件输出（最可靠）
  2. wowhead 页面 URL 中的数字（如 `wowhead.com/npc=12345`）
  3. 国服数据库 / 达迷京等中文站
- **禁止**凭印象或"看起来合理"填写 ID —— 错误 ID 比空 ID 危害更大（会静默指向错误实体）。

---

## 一、资料片 / 版本

> 英文原名 → 资料片中文 → 缩写；`Value` / `Constant` 为游戏内可用标识（`Constant` 可直接取得本地化字符串）。来源：[LE_EXPANSION](https://warcraft.wiki.gg/wiki/LE_EXPANSION)。

| Value | 英文原名               | 中文         | 缩写    | Constant         | 发布版本 | 发布时间   |
| ----- | ---------------------- | ------------ | ------- | ---------------- | -------- | ---------- |
| 0     | World of Warcraft      | 经典旧世     | Vanilla | EXPANSION_NAME0  | 1.x      | 2004-11-23 |
| 1     | The Burning Crusade    | 燃烧的远征   | TBC     | EXPANSION_NAME1  | 2.x      | 2007-01-16 |
| 2     | Wrath of the Lich King | 巫妖王之怒   | WotLK   | EXPANSION_NAME2  | 3.x      | 2008-11-13 |
| 3     | Cataclysm              | 大地的裂变   | CATA    | EXPANSION_NAME3  | 4.x      | 2010-12-07 |
| 4     | Mists of Pandaria      | 熊猫人之谜   | MoP     | EXPANSION_NAME4  | 5.x      | 2012-09-25 |
| 5     | Warlords of Draenor    | 德拉诺之王   | WoD     | EXPANSION_NAME5  | 6.x      | 2014-11-13 |
| 6     | Legion                 | 军团再临     | LEG     | EXPANSION_NAME6  | 7.x      | 2016-08-30 |
| 7     | Battle for Azeroth     | 争霸艾泽拉斯 | BfA     | EXPANSION_NAME7  | 8.x      | 2018-08-14 |
| 8     | Shadowlands            | 暗影国度     | SL      | EXPANSION_NAME8  | 9.x      | 2020-11-23 |
| 9     | Dragonflight           | 巨龙时代     | DF      | EXPANSION_NAME9  | 10.x     | 2022-11-28 |
| 10    | The War Within         | 地心之战     | TWW     | EXPANSION_NAME10 | 11.x     | 2024-08-26 |
| 11    | Midnight               | 至暗之夜     | MN      | EXPANSION_NAME11 | 12.x     | 2026-03-02 |

## 二、种族

> 阵营归属取自 [wowhead races](https://www.wowhead.com/cn/races) 页

| raceID | 英文                | 中文         | 阵营 | 说明                               |
| ------ | ------------------- | ------------ | ---- | ---------------------------------- |
| 1      | Human               | 人类         | 联盟 |                                    |
| 2      | Orc                 | 兽人         | 部落 |                                    |
| 3      | Dwarf               | 矮人         | 联盟 |                                    |
| 4      | Night Elf           | 暗夜精灵     | 联盟 |                                    |
| 5      | Undead              | 亡灵         | 部落 |                                    |
| 6      | Tauren              | 牛头人       | 部落 |                                    |
| 7      | Gnome               | 侏儒         | 联盟 |                                    |
| 8      | Troll               | 巨魔         | 部落 |                                    |
| 9      | Goblin              | 地精         | 部落 |                                    |
| 10     | Blood Elf           | 血精灵       | 部落 |                                    |
| 11     | Draenei             | 德莱尼       | 联盟 |                                    |
| 22     | Worgen              | 狼人         | 联盟 |                                    |
| 24     | Pandaren            | 熊猫人       | 双方 |                                    |
| 27     | Nightborne          | 夜之子       | 部落 |                                    |
| 28     | Highmountain Tauren | 至高岭牛头人 | 部落 |                                    |
| 29     | Void Elf            | 虚空精灵     | 联盟 |                                    |
| 30     | Lightforged Draenei | 光铸德莱尼   | 联盟 |                                    |
| 31     | Zandalari Troll     | 赞达拉巨魔   | 部落 |                                    |
| 32     | Kul Tiran           | 库尔提拉斯人 | 联盟 |                                    |
| 34     | Dark Iron Dwarf     | 黑铁矮人     | 联盟 |                                    |
| 35     | Vulpera             | 狐人         | 部落 |                                    |
| 36     | Mag'har Orc         | 玛格汉兽人   | 部落 |                                    |
| 37     | Mechagnome          | 机械侏儒     | 联盟 |                                    |
| 52     | Dracthyr            | 龙希尔       | 双方 |                                    |
| 84     | Earthen             | 土灵         | 双方 |                                    |
| 86     | Haranir             | 哈籁尼尔     | 双方 |                                    |
| —     | Nerubian            | 蛛魔         | —   | 种族专名，非字面（非可选可玩种族） |

## 三、地理 / 区域

| 英文               | 中文         |
| ------------------ | ------------ |
| Isle of Dorn       | 多恩岛       |
| The Ringing Deeps  | 喧鸣深窟     |
| Hall of Awakening  | 觉醒大厅     |
| Hallowfall         | 陨圣峪       |
| Azj-Kahet          | 艾基-卡赫特  |
| Siren Isle         | 海妖岛       |
| Undermine          | 安德麦       |
| K'aresh            | 卡雷什       |
| Eversong Woods     | 永歌森林     |
| Isle of Quel'Danas | 奎尔丹纳斯岛 |
| Zul'Aman           | 祖阿曼       |
| Harandar           | 哈籁恩达尔   |
| The Den            | 大巢穴       |
| Voidstorm          | 虚影风暴     |
| Stormarion         | 斯托玛兰     |
| Slayer's Rise      | 屠戮者高地   |
| Masters' Perch     | 主宰者之座   |
| The Coiled Isle    | 盘卷蛇岛     |

## 四、NPC / 角色

| npcID          | 英文                     | 中文               |
| -------------- | ------------------------ | ------------------ |
| 130216         | Magni Bronzebeard        | 麦格尼·铜须       |
| 216149         | Moira Thaurissan         | 茉艾拉·索瑞森     |
| 217888         | Dagran Thaurissan II     | 达格兰·索瑞森二世 |
| 206017         | Brann Bronzebeard        | 布兰·铜须         |
| 107574         | Anduin Wrynn             | 安度因·乌瑞恩     |
| 149684, 216168 | Lady Jaina Proudmoore    | 吉安娜·普罗德摩尔 |
|                | Thrall                   | 萨尔               |
|                | Alleria Windrunner       | 奥蕾莉亚·风行者   |
|                | Xal'atath                | 萨拉塔斯           |
|                | Ve'nari                  | 薇娜丽             |
|                | Faerin Lothar            | 法琳·洛萨         |
|                | Monte Gazlowe            | 蒙提·加兹鲁       |
|                | Merrix                   | 梅里克斯           |
|                | Orweyna                  | 奥威娜             |
| 218944         | Inferno Sprayer          | 地狱火喷射器       |
| 228221         | Ethereal Heartseeker     | 虚灵觅心者         |
| 248802         | Phase-General Ameer      | 相位统帅阿米尔     |
| 213658         | Kol Bruncrag             | 寇尔·棕峭         |
| 209230         | Kyrioss                  | 凯里欧斯           |
| 207205         | Stormguard Gorren        | 雷卫戈伦           |
|                | Locus-Walker             | 双界行者           |
|                | Baelgrim                 | 贝尔格里姆         |
|                | Adelgonn                 | 艾德贡             |
|                | Speaker Brinthe          | 代言人布琳泽       |
|                | General Steelstrike      | 斯蒂泰克将军       |
|                | Findorn                  | 芬多恩             |
|                | Master Machinist Dunstan | 机械大师顿斯坦     |
| 228040         | Executor Nizrek          | 执行官尼兹雷克     |
| 216541         | Threadmaestro Fothis     | 纺线大师弗西斯     |
| 230781         | Shadow-Captain Lakheesh  | 暗影队长拉基什     |
| 207471, 219903 | Widow Arak'nai           | 寡妇阿拉克奈       |
| 216578         | Swarm-Maven Donmiss      | 虫群专家多米丝     |
| 217299         | Ostiary Wystan           | 护门者威斯坦       |
| 216111         | Ebona                    | 艾博纳             |
| 216581         | Vizier's Getaway Flyer   | 宰相的脱身飞虫     |
| 216582         | Kx                       | 凯克斯             |
| 230966         | Shadowlord Al'zar        | 暗影领主艾·扎尔   |

## 五、怪物 / 生物

| npcID  | 英文                  | 中文           |
| ------ | --------------------- | -------------- |
| 211866 | Horrid Effusia        | 可怖的涌泻软泥 |
|        | Stormrook             | 雷鸫           |
| 212761 | Swarming Skyterror    | 聚生恐天魔     |
| 207207 | Voidstone Monstrosity | 虚空石畸体     |
| 162719 | Void Ascendant        | 虚空晋升者     |
| 217463 | Enraged Colossus      | 被激怒的巨像   |

## 六、物件 / 可交互物（object）

> wowhead `object` 类型：场景中的可交互装置 / 物体（传送器、提取器、可点击机关等），
> 既不是 `npc`/怪物，也不是背包 `item`。首列填 `objectID`（待补）。

| objectID | 英文               | 中文       | 说明                       |
| -------- | ------------------ | ---------- | -------------------------- |
|          | Nerubian Extractor | 蛛魔提取器 | 可交互物件（type=object）  |
|          | Earthen Teleporter | 土灵传送器 | 场景传送装置（可交互物件） |
|          | Ironfuse Bomb      | 注铁炸弹   | 可交互装置                 |

## 七、物品

| itemID | 英文            | 中文     |
| ------ | --------------- | -------- |
|        | Tome of History | 历史之书 |
|        | Dark Fragment   | 黑暗碎片 |

## 八、任务

| questID | 英文                 | 中文         |
| ------- | -------------------- | ------------ |
| 93929   | The War Within Recap | 地心之战回顾 |
| 91843   | Recap: The Harbinger | 回顾-先驱    |

## 九、成就

| achievementID | 英文 | 中文 |
| ------------- | ---- | ---- |
|               |      |      |

（暂无词条；补充时首列填 `achievementID`，对应 wowhead `achievement` 类型）

## 十、势力 / 声望

> 数据取自 wowhead factions 分类页：至暗之夜（`/factions/midnight`）、地心之战（`/factions/the-war-within`）、巨龙时代（`/factions/dragonflight`）、暗影国度（`/factions/shadowlands`）。
> `factionID` 为势力在游戏内 / wowhead 的编号，首列「资料片」标注所属资料片。
> 排序：先按资料片（发布版本倒序），再按 factionID 升序。已剔除开发占位条目（`DEPRECATED` / `[PH]`）。

| 资料片 | factionID | 英文 | 中文 | 说明 |
| --- | --- | --- | --- | --- |
| 至暗之夜 | 2696 | Amani Tribe | 阿曼尼部族 | |
| 至暗之夜 | 2699 | The Singularity | 奇点特勤 | |
| 至暗之夜 | 2704 | Hara'ti | 哈籁提 | |
| 至暗之夜 | 2705 | Amani Tribe (Paragon) | 阿曼尼部族（典范） | |
| 至暗之夜 | 2710 | Silvermoon Court | 银月宫廷 | |
| 至暗之夜 | 2711 | Magisters | 魔导师 | |
| 至暗之夜 | 2712 | Blood Knights | 血骑士 | |
| 至暗之夜 | 2713 | Farstriders | 远行者 | |
| 至暗之夜 | 2714 | Shades of the Row | 径巷之影 | |
| 至暗之夜 | 2725 | The Singularity (Paragon) | 奇点特勤（典范） | |
| 至暗之夜 | 2726 | Hara'ti (Paragon) | 哈籁提（典范） | |
| 至暗之夜 | 2727 | Silvermoon Court (Paragon) | 银月宫廷（典范） | |
| 至暗之夜 | 2742 | Delves: Season 1 | 地下堡：第1赛季 | |
| 至暗之夜 | 2744 | Valeera Sanguinar | 瓦莉拉·萨古纳尔 | |
| 至暗之夜 | 2764 | Prey: Season 1 | 狩猎：第1赛季 | |
| 至暗之夜 | 2770 | Slayer's Duellum | 屠戮角斗 | |
| 至暗之夜 | 2771 | Zul'jarra's Forces (Paragon) | 祖尔加拉的部队（典范） | |
| 至暗之夜 | 2772 | Zul'jarra's Forces | 祖尔加拉的部队 | |
| 至暗之夜 | 2773 | Captain Tokka | 托卡船长 | |
| 至暗之夜 | 2774 | Slayer's Duellum (Paragon) | 屠戮角斗（典范） | |
| 至暗之夜 | 2792 | Ritual Sites | 仪式场地 | |
| 至暗之夜 | 2793 | Ritual Sites (Paragon) | 仪式场地（典范） | |
| 至暗之夜 | 2796 | Delves: Season 2 | 地下堡：第2赛季 | |
| 至暗之夜 | 2808 | Preyhunter's Journey | 猎捕手的旅程 | |
| 至暗之夜 | 2839 | Delves: Season 3 | 地下堡：第3赛季 | |
| 地心之战 | 2570 | Hallowfall Arathi | 陨圣峪阿拉希人 | |
| 地心之战 | 2590 | Council of Dornogal | 多恩诺嘉尔议会 | |
| 地心之战 | 2594 | The Assembly of the Deeps | 邃渊协盟 | |
| 地心之战 | 2596 | The Severed Threads (Paragon) | 斩离之丝（典范） | |
| 地心之战 | 2600 | The Severed Threads | 斩离之丝 | |
| 地心之战 | 2601 | The Weaver | 纺丝者 | |
| 地心之战 | 2605 | The General | 将军 | |
| 地心之战 | 2607 | The Vizier | 宰相 | |
| 地心之战 | 2611 | Hallowfall Arathi (Paragon) | 陨圣峪阿拉希人（典范） | |
| 地心之战 | 2612 | Council of Dornogal (Paragon) | 多恩诺嘉尔议会（典范） | |
| 地心之战 | 2613 | The Assembly of the Deeps (Paragon) | 邃渊协盟（典范） | |
| 地心之战 | 2640 | Brann Bronzebeard | 布莱恩·铜须 | |
| 地心之战 | 2644 | Delves: Season 1 | 地下堡：第1赛季 | |
| 地心之战 | 2645 | Earthen | 土灵 | |
| 地心之战 | 2647 | The Vizier (Paragon) | 宰相（典范） | |
| 地心之战 | 2648 | The Weaver (Paragon) | 纺丝者（典范） | |
| 地心之战 | 2649 | The General (Paragon) | 将军（典范） | |
| 地心之战 | 2653 | The Cartels of Undermine | 安德麦财阀 | |
| 地心之战 | 2658 | The K'aresh Trust | 卡雷什托拉斯 | |
| 地心之战 | 2659 | The K'aresh Trust (Paragon) | 卡雷什托拉斯（典范） | |
| 地心之战 | 2663 | Meerah | 米尔拉 | |
| 地心之战 | 2664 | Flynn Fairwind | 弗林·法温德 | |
| 地心之战 | 2665 | Lillistrasza | 莉莉斯塔萨 | |
| 地心之战 | 2666 | Roasts and Boasts | 烘烤与夸耀 | |
| 地心之战 | 2667 | The Cartels of Undermine (Paragon) | 安德麦财阀（典范） | |
| 地心之战 | 2668 | Darkfuse Solutions (Paragon) | 暗索处理服务（典范） | |
| 地心之战 | 2669 | Darkfuse Solutions | 暗索处理服务 | |
| 地心之战 | 2670 | Venture Company (Paragon) | 风险投资公司（典范） | |
| 地心之战 | 2671 | Venture Company | 风险投资公司 | |
| 地心之战 | 2672 | Bilgewater Cartel (Paragon) | 锈水财阀（典范） | |
| 地心之战 | 2673 | Bilgewater Cartel | 锈水财阀 | |
| 地心之战 | 2674 | Blackwater Cartel (Paragon) | 黑水财阀（典范） | |
| 地心之战 | 2675 | Blackwater Cartel | 黑水财阀 | |
| 地心之战 | 2676 | Steamwheedle Cartel (Paragon) | 热砂财阀（典范） | |
| 地心之战 | 2677 | Steamwheedle Cartel | 热砂财阀 | |
| 地心之战 | 2683 | Delves: Season 2 | 地下堡：第2赛季 | |
| 地心之战 | 2684 | Gallagio Loyalty Rewards Club (Paragon) | 加乐宫会员奖励俱乐部（典范） | |
| 地心之战 | 2685 | Gallagio Loyalty Rewards Club | 加乐宫会员奖励俱乐部 | |
| 地心之战 | 2688 | Flame's Radiance | 圣焰之耀 | |
| 地心之战 | 2689 | Flame's Radiance (Paragon) | 圣焰之耀（典范） | |
| 地心之战 | 2693 | Delver's Journey (Season 1) | 地下堡行者的旅程（第1赛季） | |
| 地心之战 | 2722 | Delves: Season 3 | 地下堡：第3赛季 | |
| 地心之战 | 2736 | Manaforge Vandals | 法力熔炉破袭队 | |
| 地心之战 | 2739 | Delves: Coffer Key Shards Conversion | 地下堡：宝匣钥匙碎片转化 | |
| 巨龙时代 | 2503 | Maruuk Centaur | 马鲁克半人马 | |
| 巨龙时代 | 2504 | Maruuk Centaur (Paragon) | 马鲁克半人马（典范） | |
| 巨龙时代 | 2507 | Dragonscale Expedition | 龙鳞探险队 | |
| 巨龙时代 | 2508 | Dragonscale Expedition (Paragon) | 龙鳞探险队（典范） | |
| 巨龙时代 | 2509 | Clan Shikaar | 席卡尔氏族 | |
| 巨龙时代 | 2510 | Valdrakken Accord | 瓦德拉肯联军 | |
| 巨龙时代 | 2511 | Iskaara Tuskarr | 伊斯卡拉海象人 | |
| 巨龙时代 | 2512 | Clan Aylaag | 艾拉格氏族 | |
| 巨龙时代 | 2513 | Clan Ohn'ir | 欧恩伊尔氏族 | |
| 巨龙时代 | 2517 | Wrathion | 拉希奥 | |
| 巨龙时代 | 2518 | Sabellian | 萨贝里安 | |
| 巨龙时代 | 2520 | Clan Nokhud | 诺库德氏族 | |
| 巨龙时代 | 2521 | Clan Nokhud (Paragon) | 诺库德氏族（典范） | |
| 巨龙时代 | 2522 | Clan Teerai | 提莱氏族 | |
| 巨龙时代 | 2526 | Winterpelt Furbolg | 冬裘熊怪 | |
| 巨龙时代 | 2542 | Clan Ukhel | 尤克赫尔氏族 | |
| 巨龙时代 | 2544 | Artisan's Consortium - Dragon Isles Branch | 工匠商盟 - 巨龙群岛支部 | |
| 巨龙时代 | 2550 | Cobalt Assembly | 钴蓝集所 | |
| 巨龙时代 | 2551 | Iskaara Tuskarr (Paragon) | 伊斯卡拉海象人（典范） | |
| 巨龙时代 | 2552 | Valdrakken Accord (Paragon) | 瓦德拉肯联军（典范） | |
| 巨龙时代 | 2553 | Soridormi | 索莉多米 | |
| 巨龙时代 | 2554 | Clan Toghus | 托古斯氏族 | |
| 巨龙时代 | 2555 | Clan Kaighan | 凯甘氏族 | |
| 巨龙时代 | 2564 | Loamm Niffen | 峈姆鼹鼠人 | |
| 巨龙时代 | 2565 | Loamm Niffen (Paragon) | 峈姆鼹鼠人（典范） | |
| 巨龙时代 | 2568 | Glimmerogg Racer | 格里梅罗格竞速者 | |
| 巨龙时代 | 2574 | Dream Wardens | 梦境守望者 | |
| 巨龙时代 | 2575 | Dream Wardens (Paragon) | 梦境守望者（典范） | |
| 巨龙时代 | 2615 | Azerothian Archives | 艾泽拉斯档案馆 | |
| 暗影国度 | 2407 | The Ascended | 晋升者 | |
| 暗影国度 | 2410 | The Undying Army | 不朽军团 | |
| 暗影国度 | 2413 | Court of Harvesters | 收割者之庭 | |
| 暗影国度 | 2422 | Night Fae | 法夜 | |
| 暗影国度 | 2432 | Ve'nari | 威·娜莉 | |
| 暗影国度 | 2439 | The Avowed | 宣罪者 | |
| 暗影国度 | 2440 | The Undying Army (Paragon) | 不朽军团（典范） | |
| 暗影国度 | 2441 | The Ascended (Paragon) | 晋升者（典范） | |
| 暗影国度 | 2442 | Court of Harvesters (Paragon) | 收割者之庭（典范） | |
| 暗影国度 | 2444 | The Wild Hunt (Paragon) | 荒猎团（典范） | |
| 暗影国度 | 2445 | The Ember Court | 灰烬王庭 | |
| 暗影国度 | 2446 | Baroness Vashj | 瓦丝琪女男爵 | |
| 暗影国度 | 2447 | Lady Moonberry | 月莓女勋爵 | |
| 暗影国度 | 2448 | Mikanikos | 米卡尼科斯 | |
| 暗影国度 | 2449 | The Countess | 女伯爵 | |
| 暗影国度 | 2450 | Alexandros Mograine | 亚历山德罗斯·莫格莱尼 | |
| 暗影国度 | 2451 | Hunt-Captain Korayn | 狩猎队长柯莱恩 | |
| 暗影国度 | 2452 | Polemarch Adrestes | 文官阿得赖斯提斯 | |
| 暗影国度 | 2453 | Rendle and Cudgelface | 伦德尔和棍脸 | |
| 暗影国度 | 2454 | Choofa | 丘法 | |
| 暗影国度 | 2455 | Cryptkeeper Kassir | 地穴看守者卡希尔 | |
| 暗影国度 | 2456 | Droman Aliothe | 宗主艾莉奥瑟 | |
| 暗影国度 | 2457 | Grandmaster Vole | 沃尔大师 | |
| 暗影国度 | 2458 | Kleia and Pelagos | 克雷雅和裴拉戈斯 | |
| 暗影国度 | 2459 | Sika | 西卡 | |
| 暗影国度 | 2460 | Stonehead | 石首 | |
| 暗影国度 | 2461 | Plague Deviser Marileth | 魔药设计师马里莱斯 | |
| 暗影国度 | 2462 | Stitchmasters | 缝合大师 | |
| 暗影国度 | 2463 | Marasmius | 玛拉斯缪斯 | |
| 暗影国度 | 2464 | Court of Night | 魅夜王庭 | |
| 暗影国度 | 2465 | The Wild Hunt | 荒猎团 | |
| 暗影国度 | 2469 | Fractal Lore | 分形知识 | |
| 暗影国度 | 2470 | Death's Advance | 死亡先锋军 | |
| 暗影国度 | 2471 | Death's Advance (Paragon) | 死亡先锋军（典范） | |
| 暗影国度 | 2472 | The Archivists' Codex | 档案员卷宗 | |
| 暗影国度 | 2473 | The Archivists' Codex (Paragon) | 档案员卷宗（典范） | |
| 暗影国度 | 2474 | Ve'nari (Paragon) | 威·娜莉（典范） | |
| 暗影国度 | 2478 | The Enlightened | 开悟者 | |
| 暗影国度 | 2479 | The Enlightened (Paragon) | 开悟者（典范） | |

（共 137 个势力；开发占位已排除）

## 十一、游戏内容 / 玩法

| 英文             | 中文       | 说明                                                             |
| ---------------- | ---------- | ---------------------------------------------------------------- |
| Delves           | 地下堡     | 日常义「钻研/探究」；游戏中为 11.0 起的玩法名                    |
| Bountiful Delves | 丰裕地下堡 | delves 的丰裕版本                                                |
| Prey             | 狩猎       | ⚠️**与常规义相反**：日常义「猎物」，游戏中指「狩猎」玩法 |
| Curse Surges     | 诅咒狂潮   |                                                                  |
| Purge Vaults     | 净化宝库   |                                                                  |
| Anniversary      | 周年庆     |                                                                  |

## 十二、游戏机制术语

| 英文         | 中文   | 说明                         |
| ------------ | ------ | ---------------------------- |
| instance     | 副本   | 日常义「实例」；游戏中指副本 |
| dragonriding | 驭龙术 | 官方译法，非字面「骑龙」     |

---

## 维护

- **新增词条**：确认译名后追加到对应分类；**不确定则标 `待确认`，不得臆造**。
- **补充 ID**：查到可靠来源后填入首列；**不得凭印象填写**（见上文「关于 ID 列」）。
- **分类扩展**：现有 12 类。后续可按需增加：法术/技能/专精、专业与材料、副本与团本名、头衔、UI 术语等 —— **有实证来源才建表，不建空表**。
  物件类（可交互装置/场景物体）首列用 `objectID`，对应 wowhead `object` 类型。
- **⚠️ 易错提醒**：收录时须**核对日常义与游戏义是否相反**。
  典型如 `prey`（日常"猎物"→游戏中"狩猎"）、`instance`（日常"实例"→游戏中"副本"）——
  这类**方向相反**的词最易直译出错，是词典价值最高的部分，务必在「说明」列标注。
- **Vanilla** 存在两个通行译名（经典旧世 / 香草时代），按上下文选用；**Classic** 官方译「经典旧世」。
- 资料片名以**国服官方译名为准**，已收录至 `Midnight`（至暗之夜）。
- 相关规范：`.codebuddy/references/anti-fabrication.md`（防臆造）、
  `.codebuddy/rules/wow-localization.mdc`（本地化键与占位符规范）。
