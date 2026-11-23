# BattlePetBreedID 简体中文改造：开发流程与修改位置

> E 类：源码级自建多语言改造（先例 CompassHUD）。上游 v1.42.0 硬编码英文、无任何本地化机制
> → 硬编码串包 `L["<英文原文>"]` + 全局语言表 `internal.L` 缺键回退。
> 本文是唯一改造文档：流程、机制、修改位置明细、重新应用方法、实机验证清单。

## 一、机制设计

- **语言表**：新文件 `BPBIDLocale.lua`（TOC 首位，`internal` 命名空间首个使用者）——
  `local addonname, internal = ...` 后挂 `internal.L`：
  - zhCN 客户端：`setmetatable(zhCN 表, { __index = function(_, k) return k end })`
  - 其他语言：空表 + 同款元表（**缺键回退 key = 英文原文**，行为与原版完全一致）
- **key 约定**：英文原文逐字对齐（含 `\124c` 颜色码等源码字面转义）；未翻译串自动回退英文。
- **命名空间安全**：BattlePetBreedID 各文件均以 `local addonname, internal = ...` 取共享
  命名空间（全局 `BPBID_Internal`），`internal.L` 对全部文件可见——无 CompassHUD 踩坑 #18
  的 setfenv 环境问题。
- **词条主档**：`_Locales_BattlePetBreedID_zhCN.lua`（53 条中英对照，唯一权威）；
  插件内 `BPBIDLocale.lua` 由 `_tools/_bpbid_build.py` 从主档生成。

## 二、翻译范围决策

| 范围 | 决策 |
|------|------|
| `BreedTooltips.lua` 品种 tooltip（当前品种/已收集/可能品种/基础属性/25 级属性各行） | 全包全译（拼接短串逐个作 key：`" or "`、`", "` 等） |
| `OptionsPanel.lua` 设置面板（标题区、格式下拉、3 段说明文、21 个复选框、按钮） | 全包全译 |
| `BattlePetBreedID.lua` | **不改**——仅含 Debug 串（须 `/run BPBID_Options.Debug = true` 才显示） |
| `ERR*` / `NEW` / `???` 返回值 | **禁止翻译**——`RetrieveBreedName` 依赖 `sub(tostring(breedID),1,3)=="ERR"` 前缀比较，改值破坏逻辑 |
| `PetData.lua` | 纯品种数据（501KB），不动 |
| 插件名 `Battle Pet BreedID`、slash 命令 `/BPBID` 等 | 保留英文 |

## 三、修改位置明细（产物 = `wow_Locales_zhCN/BattlePetBreedID/`）

| 文件 | 改动 |
|------|------|
| `BPBIDLocale.lua` | **新增**：53 条 zhCN 表 + GetLocale 分支挂 `internal.L` |
| `BattlePetBreedID.toc` | 首位插入 `BPBIDLocale.lua` |
| `BreedTooltips.lua` | 头部 `local L = internal.L`；**22 处包裹**（当前品种/已收集/可能品种枚举、`s:` 复数冒号、`Base Stats`、`品种 ` 前缀 3 处、`* at 25:` 等） |
| `OptionsPanel.lua` | 头部 `local L = internal.L`；**36 处包裹**（version/created by/描述长句、3 个格式名、3 段 formatTexts、21 个复选框、`Fix Bugs:`、`Defaults`） |
| `BattlePetBreedID.lua` / `PetData.lua` / `BPBIDAccessOptions.lua` / `CHANGELOG.md` | 未改动 |

## 四、重新应用（上游更新 / 重装后）

1. 用上游新文件覆盖 `wow_Locales_zhCN/BattlePetBreedID/` 中的**未改文件**
   （BattlePetBreedID.lua、PetData.lua、BPBIDAccessOptions.lua、CHANGELOG.md）；
2. 若上游改动 `BreedTooltips.lua` / `OptionsPanel.lua`：对照新版重新执行
   `python _tools/_bpbid_build.py`（脚本逐条断言命中数，上游行文变化会报错并指出锚点）；
3. 对照上游新增/改动的英文串更新主档 `_Locales_BattlePetBreedID_zhCN.lua` 后重跑构建；
4. `python _tools/_bpbid_verify.py` 语法 + 残留校验，整目录覆盖游戏插件目录。

## 五、实机验证清单

- [ ] 中文客户端：宠物手册悬停 tooltip 出现「当前品种：」「可能的品种：」「已收集：」
- [ ] 战斗中宠物名旁显示 `(P/P)` 等品种代码
- [ ] 25 级属性行显示「品名* 25级：1400/…」
- [ ] 设置界面（ESC > 插件设置 / `/bpbid`）：标题区「版本 v1.42.0 作者：…」、
      三个格式说明段全中文、21 个复选框中文
- [ ] 英文客户端抽查：全部回退英文原文（与原版一致）
- [ ] 切换格式下拉（数字/双数字/字母）说明文联动正常
