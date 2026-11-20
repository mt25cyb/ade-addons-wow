# CompassHUD 源码级多语言改造 — 修改位置明细

> 基准 CompassHUD **2.1.1**（原版 = 镜像 `z-ref_retail_Interface_AddOns\CompassHUD`；
> 改造后完整备份 = `_temp\CompassHUD_zhCN\`；项目成果 = `wow_Locales_zhCN\CompassHUD\`
> （插件目录镜像，可整目录覆盖游戏插件安装目录；应用脚本 `_tools\CompassHUD_zhCN_Locations-apply.ps1`）。
> 行号均为 **成果目录版本**行号（与原版差异仅 Locales 两文件新增处的偏移）。
> 上游更新后重做时，按本文档逐文件对照锚点（锚点函数 / 设置块名比行号可靠）。

## 总览

| 文件 | 状态 | 修改点数 | `L[` 引用行数 | 一句话说明 |
|------|------|---------|--------------|-----------|
| `CompassHUD.toc` | 改 | 1 | — | Locales 两行移到 `Libs\libs.xml` 之前 |
| `Locales/enUS.lua` | **新建** | — | 0 | 全局表 `CompassHUDLocale` + 缺键回退元方法 + 回退说明（不登记词条） |
| `Locales/zhCN.lua` | **新建**（主档同步副本） | — | 520 条 | 中英词条主档为子项目根 `_Locales_CompassHUD_zhCN.lua`，本文件是其应用副本 |
| `Init.lua` | 改 | 2 | 0 | env 注入 `L`；键位标签走 CompassHUDLocale |
| `Options.lua` | 改 | 271 个 hunk | 478 | 设置主树全面包裹（见下） |
| `Looks.lua` | 改 | 33 个 hunk | 70 | 外观定义 / 分享导入 / looksArgs |
| `Data.lua` | 改 | 1 | 3 | StaticPopup 弹窗 |
| `EditMode.lua` | 改 | 1 | 1 | 编辑模式覆盖层 tooltip |
| `Speech.lua` | 改 | 2 | 2 | 语音下拉首项；距离拼接片段 |
| `Util.lua` | 改 | 3 | 6 | 纹理显示名 / 层级 / POI 筛选显示值 |
| `API.lua` | 改 | 3 | 3 | 标记源报错 print；默认 desc；titleHeader |
| `databroker.lua` | 改 | 3 | 3 | LDB 文本与 tooltip；⚠ 本文件不进共享环境，需自取语言表 |
| `Markers/Gathering.lua` | 改 | 2 | 4 | 采集源描述与语音 |
| `Markers/HandyNotes.lua` | 改 | 5 | 9 | 插件标签、源描述、选项、语音 |
| `Markers/POI.lua` | 改 | 1 | 2 | 小地图图标语音项 |
| `Markers/Questie.lua` | 改 | 4 | 16 | 任务类型标签 + 16 专业名 |
| `Markers/Supertracker.lua` | 改 | 1 | 1 | 尸体名 `CORPSE or L["Corpse"]` |
| `Markers/TomTom.lua` | 改 | 5 | 9 | 路点名、源描述、选项、语音 |

共 **16 个修改文件 + 2 个新建文件**（成果目录 `CompassHUD\` 内 18 个文件）。
（初版曾新建 `Locales/Localization.lua` 承载全局表，2026-11-19 并入 enUS.lua；
初版曾修改 `Libs\AceDBOptions-3.0` 做值级接入，同日按第三方库不修改的约定撤销还原，
Libs 不再属于成果。）

## 逐文件明细

### CompassHUD.toc

- 在 `## X-Curse-Project-ID: 861865` 之后、`Libs\libs.xml` **之前**插入：
  ```
  Locales\enUS.lua
  Locales\zhCN.lua
  （空行）
  ```
- ⚠ 这是唯一的 TOC 结构改动；其余元数据一字未动。
- 目的：语言文件先于本体与 Libs 加载——enUS 建 `CompassHUDLocale` 全局表、zhCN 覆盖词条。
  （初版值级接入要求其早于 AceDBOptions 加载；该方案撤销后与 Libs 的相对顺序已无硬性
  要求，保持现状。）

### Locales/enUS.lua（新建，24 行，全局表 + 回退说明）

- 头部建全局表（必须是 TOC 第一个 Lua 文件）：
  `_G.CompassHUDLocale = setmetatable({}, { __index = function(_, key) return key end })`
  ——缺键回退返回 key 本身（英文原文）。
- 尾部英文注释：英文不登记词条（回退天然输出原文）+ key 失效桥接示例
  （`CompassHUDLocale["<旧原文>"] = "<新文本>"`）。
- ⚠ 全局表定义曾在独立的 `Locales/Localization.lua`，2026-11-19 并入本文件头部；
  上游重做时不要再建 Localization.lua。

### Locales/zhCN.lua（新建，520 条）

- 主档在子项目根 `_Locales_CompassHUD_zhCN.lua`（唯一权威）；成果目录
  `CompassHUD\Locales\zhCN.lua` 是其同步副本（应用脚本每次运行先刷新），应用时一并
  复制为插件 `Locales\zhCN.lua`。
- 结构：头部 `local L = CompassHUDLocale`；key = 英文原文整串（含颜色码 / `\n` /
  尾随空格 / 原拼写错误，逐字对齐源码）；13 条含 `%s` 模板。
- 词典分类（主档内注释分组）：通用模板/单位、what 动态模板、主选项各页、
  指针外观（outline×11 组 / ticks / progress / icon / Edge line / fading / Scale / Pixels）、
  placeTypes×9、组合指针名、Questie 类型与专业、语音、LDB、键位。
  （初版含 AceDBOptions 值级词条 19 条，2026-11-19 随值级接入撤销而删除；仅保留
  `L["Profiles"]` 供本体 Bliz 选项树入口使用，译值「配置文件」对齐库自带 zhCN 用词。）

### Init.lua

| 行号 | 锚点 | 改动 |
|------|------|------|
| 30-32 | env 建立（`for name, value in pairs(_G)` 循环后） | 新增 `Addon.env.L = CompassHUDLocale`（2 行注释 + 1 行代码） |
| 36 | `BINDING_NAME_COMPASSHUD_SUPERTRACK` | 值改为 `CompassHUDLocale["Toggle Supertracking for Minimap icon"]`（Bindings.xml 键位标签） |

⚠ Init.lua 不在共享环境内，此文件内**必须**用 `CompassHUDLocale[...]` 全名，不能裸写 `L`。

### Options.lua（478 处 L[ 引用，271 个 hunk）

设置主树（`Addon.Options`，第 42 行起）几乎每个条目的 `name` / `desc` / `confirmText` 都包了 L。
按区域归类：

| 区域（成果目录行号） | 锚点 | 内容 |
|------|------|------|
| 26-33 | `speechSourceArgs = {` | 语音源设置 name/desc |
| 42-约 1500 | `Addon.Options = {`（主树） | Compass / Keybinds / Speech 等页全部条目；`values` 表显示值全部包 L（outline×11 组、ticks、progress、icon、Edge line、fading、Scale/Pixels） |
| 1520 | `local placeTypes = {` | 显示名值包 L（×9），内部 key 不动 |
| 1533 | `for index, place in ipairs(placeTypes)` | placeArgs 生成处显示值包 L |
| 1799 | Keybinds 页 | `name = L["Keybind (%s)"]:format(BINDING_NAME_COMPASSHUD_SUPERTRACK)` |
| 2510-2601 | supertracker 各块 | 10 处 what 动态模板：`L["...%s..."]:format(what)`（what ∈ icon/node/waypoint/marker） |
| 2589-2620 | `function markerModuleOptions(prefix, info)` | 标记模块通用 name/desc；`filterToggle` 调用参数包 L |
| 2846 | `pointersDefaults[questPointerIdent .. k]` 循环 | `name = L[v]`（questPointers 显示名变量包裹） |
| 2890-3370 | `Addon:ConstructDefaultsAndOptions()`（Textures/Texts 块） | 每指针外观/文本设置块 name/desc |
| 3405-3444 | 标记源页 / markerTextOptions | `markerTextOptions` 第 4 参（显示名）包 L |
| 3445-3448 | `AceConfigDialog:AddToBlizOptions(...)` | 第 2 参包 L：`L["Supertracker"]` / `L["Minimap tracking"]` / `L["Profiles"]`；⚠ 第 4 参**路径键**（`"Tabs"` / `"Supertracker"` / `"TrackingIntegrations"` / `"Profiles"`）**不译** |

其余散点：`pointersDefaults[...].name = L[v]`（2846）；重置确认 `confirmText =
L["Reset the compass and marker size to the defaults?"]`。

### Looks.lua（70 处 L[ 引用，33 个 hunk）

| 区域（成果目录行号） | 锚点 | 内容 |
|------|------|------|
| 443-537 | `looks = {` 各预置外观 | 每个 look 的 name/desc 包 L（14 处） |
| 539 | 默认外观 desc | 包 L |
| 717-730 | 共享串校验 | `L["That is not a CompassHUD look: it should start with "] .. SHARE_PREFIX`（前缀拼接） |
| 761-810 | `openShareWindow(title, status)` 及两个调用点 | 导出 `L["CompassHUD: your look"]` + 说明；导入 `L["CompassHUD: use a shared look"]` + 说明 |
| 786-798 | `importLook(text)` | 导入校验错误消息包 L |
| 1037 | `looksArgs` 内「Your own look」 | `L["Your own look  |cnGREEN_FONT_COLOR:(trying a shared look)|r"]` / `L["Your own look"]` |
| 1087-1141 | `for index, look in ipairs(looks)` | 动态生成处：试用后缀 `("  |cnGREEN_FONT_COLOR:(" .. L["trying"] .. ")|r")`、各按钮 name/desc/confirm |
| 1141-1144 | `Addon.Options.args.Tabs.args.Looks = {` | Looks 页头 name/desc |

### Data.lua

| 行号 | 锚点 | 改动 |
|------|------|------|
| 11-13 | `StaticPopupDialogs[copyPointersDialogName]` | `text` / `button1` / `button2` 包 L（Do you want to proceed? / Yes / No） |

### EditMode.lua

| 行号 | 锚点 | 改动 |
|------|------|------|
| 52 | `createOverlay()` → `GameTooltip:AddLine` | `L["Drag to move, click to open the options."]` |

### Speech.lua

| 行号 | 锚点 | 改动 |
|------|------|------|
| 30 | `getSpeechVoices()` | 首项 `L["Game setting (Text to Speech voice)"]` |
| 49 | `textFor(name, distance)` | 拼接片段包 L：`name .. L[", "] .. value .. (Options.UseMeters and L[" meters"] or L[" yards"])` |

### Util.lua

| 行号 | 锚点 | 改动 |
|------|------|------|
| 96 | `getPointerAtlasIDs()` | `atlasIDs[value.atlasID] = L[key]`（纹理显示名 + 组合指针名动态覆盖） |
| 147 | `getStrateLevels()` | `values[v] = i .. " - " .. L[v]` |
| 174-180 | `getPOIFrackWQFilter()` | 4 个显示值包 L（None / All / Tracked / WQTracker） |

⚠ `pointerTextures` / `strataLevels` 的**查找键**本身不动（不译清单）。

### API.lua

| 行号 | 锚点 | 改动 |
|------|------|------|
| 65 | `call()` 错误停用 | `string.format(L["The marker source \"%s\" kept failing and is turned off until the next /reload."], source.publicName)` |
| 298 | `API.RegisterMarkerSource` → opts.desc | `speech.desc or L["The markers shown by Minimap tracking -> %s (turn them on there)."]:format(name)` |
| 316 | 同上 → titleHeader 默认值 | `or L["Name"]` |

### databroker.lua

| 行号 | 锚点 | 改动 |
|------|------|------|
| 4-6 | `local ADDON_NAME = ...` 之后 | **新增** `local L = CompassHUDLocale`（2 行注释 + 1 行代码）。⚠ 本文件**没有** `setfenv(1, Addon.env)`，主块跑在全局环境，`L` 不存在——实测进游戏即报 `databroker.lua:7: attempt to index global 'L' (a nil value)`，连带 `CompassHUD.lua:601` 调 `InitializeDataBroker` 失败（本文件主块中断，函数未定义）。 CompassHUDLocale 是真全局（enUS.lua 建立，TOC 先于本文件），local 取用即可 |
| 11 | `ldbLabelText` | `L["A compass tape for your UI"]` |
| 35-36 | tooltip AddLine ×2 | 左键 / 右键说明包 L（含 `|cnGREEN_FONT_COLOR:...|r` 色码，key 逐字含色码） |

⚠ **全局环境文件的通用教训**：包裹前必须确认目标文件是否 `setfenv(1, Addon.env)`
（Init.lua 头部注释即约定）。主块级包裹只在共享环境内有效；不进环境的文件须用
`CompassHUDLocale` 全名或先 `local L = CompassHUDLocale`。本次仅 databroker.lua 一个例外，
其余 14 个本体文件均已 setfenv。

### Markers/Gathering.lua

| 行号 | 锚点 | 改动 |
|------|------|------|
| 93 / 97 | source `description` / `titleHeader` | 包 L（Node name） |
| 116-117 | `speech = {` | name/desc 包 L |

### Markers/HandyNotes.lua

| 行号 | 锚点 | 改动 |
|------|------|------|
| 37 | `pluginLabel(pluginName)` | fallback `or L["HandyNotes (your own notes)"]` |
| 306-307 | source `description` / `enabledDesc` | 包 L |
| 313-314 | 选项 NearbyZones | name/desc 包 L |
| 322-323 | 选项 Plugins | name/desc 包 L |
| 332-333 | `speech = {` | name/desc 包 L |

### Markers/POI.lua

| 行号 | 锚点 | 改动 |
|------|------|------|
| 54-55 | `speech = {` | name/desc 包 L |

### Markers/Questie.lua

| 行号 | 锚点 | 改动 |
|------|------|------|
| 29-34 | `questTypes = {` | 6 个类型 label 包 L（Available quest / Turn-in / Objective） |
| 38-41 | `professionNames = {` | 16 个专业名包 L（First Aid/Blacksmithing/.../Archaeology） |
| 117-118 | source `description` / `enabledDesc` | 包 L |
| 125-126 | 选项 ShowType | name/desc 包 L（含示例串，key 逐字含引号转义） |
| 133-134 | `speech = {` | name/desc 包 L |

### Markers/Supertracker.lua

| 行号 | 锚点 | 改动 |
|------|------|------|
| 237 | `updateCorpseTarget()` | `CORPSE or L["Corpse"]` |

### Markers/TomTom.lua

| 行号 | 锚点 | 改动 |
|------|------|------|
| 59 | `scanMap()` → node.name | fallback `or L["TomTom waypoint"]` |
| 75 / 78 | source `description` / `titleHeader` | 包 L（Waypoint name） |
| 86-87 | 选项 OtherZones | name/desc 包 L |
| 94-95 | 选项 AnyDistance | name/desc 包 L |
| 101-102 | `speech = {` | name/desc 包 L |

### Libs\AceDBOptions-3.0\AceDBOptions-3.0.lua（不修改，已还原）

- 第三方库遵守「不对引入的库做修改」的约定，文件保持原样，**不进入成果目录**。
- Profiles 页无需干预：库自带完整 zhCN 语言块（`elseif LOCALE == "zhCN"` 分发，
  20/20 与基准表齐平），中文客户端下由库自行翻译。
- Bliz 选项树入口显示名由本体 `Options.lua` 的 `L["Profiles"]` 提供（译值对齐库用词）。
- 历史：初版曾在库 L 表闭合后追加 9 行值级翻译接入（key 为库英文原文值），
  2026-11-19 撤销；词典中相应 19 条死词条一并删除，仅保留 `L["Profiles"]`。
- 上游更新重做时：若新版库的 zhCN 块缺失/残缺，优先只核对是否有此问题，
  仍不改库；确需覆盖时改走**运行时包裹 `GetOptionsTable`**（在自己代码里做值级翻译），
  不得直接编辑库文件。

## 不译位置（核对时勿误判为遗漏）

- 表键 / 存档值 key（options key、look id、`questPointerIdent` 拼接）。
- `poiTypeEnum` 值、Enum 枚举值。
- `pointerTextures` / `texturePresets` / `strataLevels` 查找键。
- LSM 媒体名（如 `"Friz Quadrata TT"`）。
- 方向字母 N/E/S/W…。
- `AddToBlizOptions` 第 4 参路径键（`"Tabs"` 等）。
- `markerTextOptions` 内部存储值（只译第 4 参显示名）。

## 上游更新重做时的核对要点

1. 先跑 §五.情况 B 的 git diff，确认上游改了哪些文件；重点看措辞变更 → 主档 key 失效。
2. 新增文本 → 按本文档同类区域补包裹 + 补词条（模板串先 `%s` 化）。
3. `Options.lua` 的 what 模板（`L["...%s..."]:format(what)`）若上游新增 what 值，
   同步检查模板句式。
4. 版本基线更新点：本文档头部、`_CompassHUD_Development-Process.md` 头部、
   `_tools\CompassHUD_zhCN_Locations-apply.ps1` 的 `2.1.1`。
