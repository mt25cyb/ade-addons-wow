# CompassHUD 源码级多语言改造 — 完整开发流程

> 子项目：`wow_Locales_zhCN`（CompassHUD 部分）· 2026-11-19 完成 · 基准 CompassHUD **2.1.1**
> 修改位置明细见 [`_Locales_CompassHUD_zhCN_Modification-Locations.md`](_Locales_CompassHUD_zhCN_Modification-Locations.md)
> 中英词条对照（主档）：[`_Locales_CompassHUD_zhCN.lua`](_Locales_CompassHUD_zhCN.lua)
> 应用脚本：`_tools\CompassHUD_zhCN_Locations-apply.ps1`
> 项目成果：`wow_Locales_zhCN\CompassHUD\`（插件目录镜像，可整目录覆盖游戏插件安装目录）

## 〇、背景与路线变更

CompassHUD 全部界面文案（设置界面 / 屏幕显示 / 弹窗 / 语音 / LDB / 键位）为**硬编码英文**，
无任何多语言机制。开发过程走了两条路线：

1. **D 类外挂劫持补丁（已废弃）**：运行时劫持 `SetText` 做整串替换。实测只命中小地图
   图标 tooltip，设置界面（AceConfig-3.0 + AceGUI-3.0 运行时构建的组件树）大量文本
   无法静态枚举劫持。外挂产物（补丁插件、同步登记、旧文档）已全部删除。
2. **E 类源码级自建多语言（最终路线）**：把原代码中的硬编码文本包成 `L["<英文原文>"]`
   （英文原文即 key），配全局语言表 + 缺键回退。经验教训沉淀在
   README 踩坑记录 #17：**AceConfig/AceGUI 类硬编码插件直接走源码改造，不做外挂补丁**。

## 一、机制设计

1. **全局语言表** `CompassHUDLocale`（`Locales/enUS.lua` 头部，与英文回退说明同文件）：
   ```lua
   _G.CompassHUDLocale = setmetatable({}, {
       __index = function(_, key) return key end,
   })
   ```
   任何语种缺失 key 时，元方法返回 key 本身（即英文原文）——**英文零维护**。
2. **英文文件**（`Locales/enUS.lua`）只建全局表与回退机制，**不登记词条**；上游措辞变更导致
   旧 key 失效时，可在此登记 `CompassHUDLocale["<旧原文>"] = "<新文本>"` 做桥接。
3. **中文词条主档**（`_Locales_CompassHUD_zhCN.lua`）：`local L = CompassHUDLocale` 后逐条登记，
   共 **520 条**（507 静态 + 13 条含 `%s` 模板，调用点以 `:format(...)` 填充）。
   key 逐字对齐源码字面量（含颜色码 / `\n` / 尾随空格 / 原拼写错误）。
4. **共享环境注入**（`Init.lua`）：CompassHUD 本体文件跑在 `Addon.env`
   （`setmetatable(..., {__index = _G})`）。Init.lua 建 env 后执行
   `Addon.env.L = CompassHUDLocale`，此后所有本体文件直接引用 `L`。
   ⚠ 前提是文件**自己执行了 `setfenv(1, Addon.env)`** 才在共享环境内——本体 14 个文件均满足；
   唯一例外 `databroker.lua` 无 setfenv（主块跑在全局环境），须先 `local L = CompassHUDLocale`
   （实机验证发现：直接引用 `L` 报 `attempt to index global 'L' (a nil value)`，见实录）。
   ⚠ Init.lua 自身也不在共享环境内，文件内直接用 `CompassHUDLocale[...]`。
5. **Profiles 页（AceDBOptions）**：**不修改第三方库**。`Libs\AceDBOptions-3.0` 自带完整
   zhCN 语言块（`GetLocale()=="zhCN"` 分发，20/20 与基准表齐平），中文客户端下 Profiles 页
   由库自行翻译；Bliz 选项树入口显示名走本体的 `L["Profiles"]`（译值「配置文件」对齐库用词）。
   初版曾在库 L 表闭合后追加值级接入，2026-11-19 按第三方库不修改的约定撤销并还原库文件，
   词典中相应 19 条死词条已删除。

## 二、加载时序（关键）

`CompassHUD.toc` 中 **Locales 两文件必须位于 `Libs\libs.xml` 之前**（TOC 头部之后立即加载）：

```
Locales\enUS.lua
Locales\zhCN.lua

Libs\libs.xml
```

要求：两个语言文件均须在 `Init.lua`（建立共享环境）之前加载，enUS 必须是第一个 Lua 文件
（先建 `CompassHUDLocale` 全局表，zhCN 随后覆盖词条）。当前排在 `Libs\libs.xml` 之前
——历史原因是初版在 AceDBOptions 值级接入需要它更早就绪；现库自带 zhCN 后该约束已
放宽，保持现状不折腾。
（初版曾单独建 `Locales/Localization.lua` 承载全局表，2026-11-19 已并入 enUS.lua 头部，
TOC 少一个加载项。）

## 三、开发流程实录（2026-11-19）

按实际执行顺序记录，供上游新版重做时参考：

1. **通读源码、枚举用户可见英文**：逐文件排查 Options / Looks / Data / Speech / Util /
   API / Markers×5 / databroker / EditMode / Init / Bindings，区分「显示文本」与
   「内部键」（表键 / 存档值 / 纹理查找键 / 枚举值）。
2. **建立机制文件**：`Locales/Localization.lua`（全局表）+ `enUS.lua`（仅说明）；
   定稿时全局表已并入 enUS.lua（见 §二），不再单独加载。
3. **批量包裹脚本**（Python，临时，用完即删）：
   - 第一轮自动包裹：正则匹配字段赋值（name/desc/text/label/title/confirm 等）、
     `L["..."]` 字符串、`Addon:Print(...)` 参数，统一包 L。
   - 严重 bug 修复：FIELD 类替换丢了 ` = ` 分隔符（产物 `nameL["Enabled"]` 语法错 490 处），
     修正则后重跑全 PASS。
4. **手动精修**：values 表显示值、动态拼接串转 `%s` 模板 + `:format(...)`、
   what 模板（10 处）、`Keybind (%s)`、变量包裹路径（`L[v]` / `L[key]`）、
   AddToBlizOptions 第 2 参（第 4 参路径键不译）、confirmText 补包。
5. **编写 zhCN 词条主档**：初版 539 条，key 逐字对齐源码字面量（脚本提取 + Lua 反转义核对）。
6. **加载时序修复（自查发现）**：AceDBOptions 在 Libs 加载时取不到 CompassHUDLocale
   → TOC 重排 + 语言文件改纯全局实现。
7. **Init.lua 注入写法纠正（自查发现）**：Init.lua 不在共享环境，裸写 `L = ...` 会污染
   全局 → 改 `Addon.env.L = CompassHUDLocale`。
8. **AceDBOptions 值级接入（已撤销）**：初版在库 L 表闭合后追加 9 行做值级翻译；
   2026-11-19 按「不修改引入的第三方库」的约定撤销，库文件还原原版——Profiles 页由库
   自带 zhCN 语言块自译，词典相应 19 条死词条删除（539 → 520 条）。
9. **实机报错修复（进游戏验证发现）**：BugGrabber 报
   `databroker.lua:7: attempt to index global 'L' (a nil value)`——该文件**没有**
   `setfenv(1, Addon.env)`，主块跑在全局环境，`L` 不可见；连带
   `CompassHUD.lua:601` 调 `InitializeDataBroker` 失败（主块中断函数未定义）。
   修复：文件头部补 `local L = CompassHUDLocale`（真全局，TOC 先于本文件加载）。
   教训：包裹前必须核对文件是否 setfenv（Init.lua 头部注释即约定）；逐文件静态扫描
   时把「不进共享环境的文件」当成了和其余文件一样的运行环境，静态检查没拦住。
10. **校验**（Python 临时脚本，用完即删）：
    - 裸字面量复核：剩余 136 行英文均为内部键（表键 / 存档值 / CreateTexture 层级 /
      key 拼接 / look id / 比较），正确保留。
    - 词典覆盖：49 个「无直接包裹点」key 中 48 个走变量包裹路径 + 1 个 confirmText 已补。
    - 引号平衡启发式扫描：全文件 0 可疑行。
    - MCP lint：机制文件 0 error / 0 warning。
11. **产物归档**：修改后完整插件备份于 `_temp\CompassHUD_zhCN\`；成果收进
    `wow_Locales_zhCN\CompassHUD\`（18 个文件，含词条主档同步副本）；词条主档
    `_Locales_CompassHUD_zhCN.lua` 与两份文档放子项目根；临时脚本全部删除。

## 四、成果清单（目录结构）

```
wow_Locales_zhCN/                            ← 子项目根
├── _Locales_CompassHUD_zhCN_Development-Process.md    ← 本文档（开发流程）
├── _Locales_CompassHUD_zhCN_Modification-Locations.md ← 修改位置明细（逐文件）
├── _Locales_CompassHUD_zhCN.lua             ← zhCN 词条主档（中英对照，520 条，唯一权威）
└── CompassHUD/                              ← 项目成果 = 插件目录镜像（整目录可覆盖游戏插件安装目录）
    ├── CompassHUD.toc
    ├── Init.lua / Data.lua / EditMode.lua / Options.lua / Looks.lua
    ├── Speech.lua / Util.lua / API.lua / databroker.lua
    ├── Markers\  (Gathering / HandyNotes / POI / Questie / Supertracker / TomTom)
    └── Locales\  (enUS.lua＝全局表+回退说明 / zhCN.lua←主档同步副本)
_tools/CompassHUD_zhCN_Locations-apply.ps1   ← 一键应用脚本（统一脚本目录）
```

⚠ 主档唯一权威：`CompassHUD\Locales\zhCN.lua` 是主档的同步副本，应用脚本每次运行会先用
主档刷新它（改词条只改根主档，勿直接改成果目录内的副本）；整目录手动覆盖也因副本存在而自洽。

词条引用规模（修改后源码中 `L[` 引用行数）：Options.lua 478、Looks.lua 70、其余合计 59，
共约 607 处引用，对应主档 520 条。

## 五、插件重装 / 更新后快速应用

### 情况 A：重装同一版本（2.1.1）

一条命令：

```powershell
powershell -ExecutionPolicy Bypass -File "_tools\CompassHUD_zhCN_Locations-apply.ps1"
```

脚本会：核对插件目录与版本基线 → 用词条主档刷新成果目录 `Locales\zhCN.lua` →
覆盖成果目录全部文件到插件目录 → 哨兵行核验（`Init.lua` 含
`Addon.env.L = CompassHUDLocale`）。完成后进游戏 `/reload` 验证。
（也可以手动整目录把 `wow_Locales_zhCN\CompassHUD\` 覆盖到游戏插件安装目录，效果相同。）

### 情况 B：上游更新到新版本

1. 跑脚本会因版本不符而**拒绝执行**（需 `-Force` 才放行）——这是刻意设计，
   防止旧成果直接覆盖新上游造成错位。
2. 先 diff 上游新版与成果目录基准，排查措辞 / 结构变化：
   ```powershell
   git diff --no-index --stat "wow_Locales_zhCN/CompassHUD" "z-ref_retail_Interface_AddOns/CompassHUD"
   ```
3. 按 [`_Locales_CompassHUD_zhCN_Modification-Locations.md`](_Locales_CompassHUD_zhCN_Modification-Locations.md)
   逐文件对照：措辞变了 → 更新主档 key（旧 key 可在 enUS.lua 桥接）；新增文本 → 补包裹 +
   补词条；删除文本 → 清理死词条。
4. 更新成果目录受影响文件与版本基线（脚本内的 `2.1.1` 与本文档头部），
   再跑脚本加 `-Force`。

### 情况 C：改动词条（不动源码）

只改 `wow_Locales_zhCN\_Locales_CompassHUD_zhCN.lua`（主档唯一权威），重跑脚本即可
（脚本会先把主档刷新进成果目录 `CompassHUD\Locales\zhCN.lua`，再整体覆盖）。
⚠ 不要直接改插件目录或成果目录里的 `Locales\zhCN.lua`——每次应用都会被主档刷新。

## 六、不译清单（刻意保留）

- 内部存档键（options 表 key、SavedVariables 值 key——译了丢存档）。
- poiTypeEnum / Enum 枚举值；pointerTextures / texturePresets 查找键（只译显示名）。
- LSM 媒体名；方向字母 N/E/S/W…（字体无中文字形）；AddToBlizOptions 路径键。

## 七、已知局限

- `print` 类聊天消息中嵌的运行时内部值仍为英文。
- 方向字母、LSM 媒体名、存档键等见 §六。

## 八、实机验证清单（进游戏 /reload 后）

1. 设置界面各页（主选项 / 小地图追踪 / Supertracker / 外观 / 语音播报 / 键位）全中文。
2. 外观预设：试用（trying 后缀）、导入校验错误消息、导出/分享窗口。
3. Bliz 选项树三个入口显示中文且路径正常。
4. Profiles 页（ACE 数据配置）整页中文（由 AceDBOptions 自带 zhCN 块自译；
   Bliz 选项树入口显示「配置文件」，走本体 `L["Profiles"]`）。
5. 语音播报：名称与距离片段（「，」/「米/码」）。
6. 键位绑定：Supertrack 条目中文且按键功能正常。
7. Questie / HandyNotes / TomTom 标记：类型标签与标题中文、无报错。
8. 标记源容错：停用某源后聊天 print 报错消息中文。
9. 英文客户端回归（可选）：`__index` 回退显示英文原文，无 key 串泄漏。
10. 重载持久化：设置改动后 /reload 不丢失（确认没有误译存档键）。
