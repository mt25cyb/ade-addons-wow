# External Locale Patch Handbook（外挂式汉化补丁手册）

> **归属**：`wow_Locales_zhCN` 子项目的**补充手段（类型 D）**。当目标插件自身没有多语言机制、
> 且不便 / 不愿修改源文件时，做一个独立的外挂插件，在运行时劫持目标插件的文本输出 API，
> 把英文原文整串替换为本地化文本。类型 A/B/C 的常规做法见 `_Locales_zhCN_README.md`。
> 本手册基于 `CooldownManagerProfiles_LocalesPatch`（CMP 简体中文补丁）实战提炼，可直接套用到新目标插件。

---

## 1. 适用场景与边界

**适合：**

- 目标插件硬编码英文（无 `Locales/`、无 `AceLocale`、无 `GetLocale` 分发）。
- 你只能/只想在不改原文件的前提下汉化或做其他语种。
- 目标插件 UI 由标准 WoW 控件（`FontString` / `Button` / `GameTooltip` / `StaticPopup` / `Settings` 分类 / LDB）构建。

**不适合 / 需谨慎：**

- 目标控件是 12.x **Forbidden Aspects** 原生框体（如原生 Aura 框体）→ 劫持 `SetText`/`HookScript` 会静默失效，禁止强行处理。
- 文本来自**保密值（secret value）**（战斗中血量/能量/Aura 字段等）→ 禁止比较/算术/作表键/裸格式化，只能整串交给 `SetText`。
- 目标插件用 `AddLine` 追加式写 tooltip 详情行 → 不便劫持，可保留英文（见 §5.3）。

---

## 2. 核心原理

外挂插件通过 TOC `## Dependencies: <目标插件>` 保证在目标之后加载，然后：

1. **字典分离**：每个语种一个 `Lang_<locale>.lua`，只放「英文原文 → 译文」映射，不含逻辑。
2. **加载器统一读取**：`LocalesPatch.lua` 按 `GetLocale()` 选当前语种字典，未命中回退 `zhCN`。
3. **运行时劫持文本输出**：对 `FontString:SetText` / `Button:SetText` / `GameTooltip:SetText` 用 `hooksecurefunc` 挂钩，命中字典则整串重设。
4. **特例通道单独处理**：`StaticPopupDialogs`、`Settings` 分类名、`LibDataBroker` 的 `label` 不走 `SetText`，需单独遍历替换。
5. **对象识别**：钩子里先判断「这个控件是否属于目标插件」（frame 名 / 父级链 / tooltip owner），不属于则跳过，避免影响其他插件。

> 关键特征：**不修改原文件、不改原插件全局、不污染 `_G`**（唯一的刻意共享是插件内部用的字典表，如 `CMPLang`，不挂 `_G` 顶层键）。

---

## 3. 目录结构与命名

**主仓库保存位置**：子项目下建 `Patches/<TARGET>_LocalesPatch/` 保存补丁插件全文
（补丁是独立插件而非语言文件，主仓库按整插件目录保存，便于镜像重装后重新同步）。
**安装位置**：镜像 `z-ref_retail_Interface_AddOns\<TARGET>_LocalesPatch\`（游戏 AddOns 根目录）。

```
<TARGET>_LocalesPatch/                  ← 插件文件夹，必须与 TOC 同名
├── <TARGET>_LocalesPatch.toc           ← TOC 文件名须与文件夹一致
├── Lang_zhCN.lua                       ← 简体中文词典（按语种扩展 Lang_enUS.lua / Lang_deDE.lua ...）
└── LocalesPatch.lua                    ← 加载器 / 工具层（劫持 + 选词 + 识别）
```

命名约定（便于多语种扩展，呼应 ADE 的 `Locales/` 体系但用单文件 `Lang_<locale>`）：

| 元素             | 命名                      | 说明                                                           |
| ---------------- | ------------------------- | -------------------------------------------------------------- |
| 插件文件夹 / TOC | `<TARGET>_LocalesPatch` | 一眼看出是「某插件的多语种补丁」                               |
| 词典文件         | `Lang_<locale>.lua`     | 如 `Lang_zhCN.lua`，`<locale>` 用 `GetLocale()` 的返回值 |
| 加载器           | `LocalesPatch.lua`      | 与语种无关，主入口                                             |
| 共享字典全局     | `<TARGET>Lang`          | 仅插件内部共享（如 `CMPLang`），按语种索引 `CMPLang.zhCN`  |

> TOC 加载顺序：**先 `Lang_<locale>.lua`（注册字典），后 `LocalesPatch.lua`（读取并劫持）**。

## 4. TOC 模板

```toc
## Interface: 120105
## Title: <TARGET> |cff00ccff多语言支持|r
## Notes: <目标插件> 的多语言支持补丁（外挂式，不修改原文件）；本仓库附带简体中文，其他语种可按 Lang_<locale>.lua 模式扩展
## Author: 汉化
## Version: 1.0.0
## Dependencies: <TARGET>
## SavedVariables:

Lang_zhCN.lua
LocalesPatch.lua
```

> **命名约定**：补丁定位是「**多语言支持补丁**」而非「汉化」——机制本身语种无关，字典文件
> `Lang_<locale>.lua` 一个语种一份。本子项目只附带 `Lang_zhCN.lua`，其他语言交由其他开发者
> 按同一模式添加（注册进 `<TARGET>Lang` 全局表即可，无需改动加载器）。

- `## Interface:` **与目标插件当前 TOC 对齐**（本工作区客户端 12.1.5 → `120105`）。
- `## Dependencies: <TARGET>` —— 保证本补丁在目标插件之后加载（钩子才能覆盖其输出）。
- `## SavedVariables:` 留空（补丁无存档）。

---

## 5. 通用模板（复制即用，按 §6 替换占位符）

### 5.1 Lang_zhCN.lua（词典，纯数据）

```lua
---------------------------------------------------------------------------
-- <TARGET> 简体中文语言包 · 字典
--
-- 本文件只存放「英文原文 -> 简体中文」的映射，不含任何逻辑。
-- 由 LocalesPatch.lua 通过全局表 <TARGET>Lang[locale] 读取（同插件内部共享，非 _G 污染）。
--
-- 匹配规则（与 LocalesPatch.lua 的 GetTranslation 一致）：
--   * 先去除颜色码（|cxxxxxxxx / |r）再查表；
--   * StaticPopup 的 text 会先去掉常量前缀（若有）再查；
--   * 形如 "xxx (n/n)" / "xxx (n)" 的计数串，仅翻译 base 部分。
-- 因此本表的 key 均为「去色后的纯文本」，弹窗 key 为「去掉前缀后的完整消息」。
---------------------------------------------------------------------------
local L = {
    -- 主窗口与通用
    ["<TARGET>"] = "（目标插件主标题译文）",
    ["Profiles"] = "配置方案",
    ["Template Library"] = "模板库",

    -- 按钮
    ["New"] = "新建",
    ["Import"] = "导入",
    ["Export"] = "导出",
    ["Rename"] = "重命名",
    ["Delete"] = "删除",
    ["Save"] = "保存",
    ["Cancel"] = "取消",

    -- 其它按需补齐……
}

-- 注册到全局 <TARGET>Lang（按语种索引，便于后续挂载更多语种，如 Lang_enUS.lua）
<TARGET>Lang = <TARGET>Lang or {}
<TARGET>Lang.zhCN = L
```

### 5.2 LocalesPatch.lua（加载器 / 工具层）

```lua
---------------------------------------------------------------------------
-- <TARGET> 语言包 · 工具层
--
-- 仅负责「运行时劫持文本输出并整串替换为本地化文本」，不含字典数据。
-- 字典见 Lang_<locale>.lua（通过 <TARGET>Lang[locale] 读取，未命中回退 zhCN）。
--
-- 适配说明（针对目标插件版本差异填写）：
--   1. 目标插件若有 StaticPopup 常量前缀，记到 POPUP_PREFIX，TranslateStaticPopups 先去前缀再查表。
--   2. 目标主窗口/设置面板 frame 名，补进 Is<TARGET>Frame 的识别命中。
---------------------------------------------------------------------------
local locale = GetLocale()
local L = (<TARGET>Lang and <TARGET>Lang[locale]) or (<TARGET>Lang and <TARGET>Lang.zhCN) or {}

-- 目标插件若有弹窗统一前缀（去色前的原始 text 形如 "<前缀><消息>"），填这里；没有则留空串
local POPUP_PREFIX = ""

---------------------------------------------------------------------------
-- 安全工具函数（保密值防护 + 异常捕获）
---------------------------------------------------------------------------
-- 安全去除颜色码，遇到保密值直接返回 nil
local function SafeStripColor(text)
    if type(text) ~= "string" then return nil end
    if issecretvalue and issecretvalue(text) then return nil end
    local ok, result = pcall(function()
        return text:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")
    end)
    return ok and result or nil
end

-- 安全获取翻译，异常直接返回 nil
local function GetTranslation(str)
    if type(str) ~= "string" or str == "" then return nil end
    if issecretvalue and issecretvalue(str) then return nil end

    local stripped = SafeStripColor(str)
    if not stripped then return nil end

    -- 精确匹配
    local trans = L[stripped]
    if trans then
        local ok, prefix = pcall(string.match, str, "^(|c%x%x%x%x%x%x%x%x)")
        if ok and prefix then return prefix .. trans .. "|r" end
        return trans
    end

    -- 匹配 "xxx (n/n)" 计数格式
    local ok2, base, cur, total = pcall(string.match, stripped, "^(.-)%s*%((%d+)/(%d+)%)$")
    if ok2 and base and cur then
        local transBase = L[base]
        if transBase then
            local result = transBase .. " (" .. cur .. "/" .. total .. ")"
            local ok3, prefix = pcall(string.match, str, "^(|c%x%x%x%x%x%x%x%x)")
            if ok3 and prefix then return prefix .. result .. "|r" end
            return result
        end
    end

    -- 匹配 "xxx (n)" 格式
    local ok4, base2, count = pcall(string.match, stripped, "^(.-)%s*%((%d+)%)$")
    if ok4 and base2 and count then
        local transBase = L[base2]
        if transBase then
            local result = transBase .. " (" .. count .. ")"
            local ok5, prefix = pcall(string.match, str, "^(|c%x%x%x%x%x%x%x%x)")
            if ok5 and prefix then return prefix .. result .. "|r" end
            return result
        end
    end

    return nil
end

-- 判断是否属于目标插件的框架（只操作框架对象，不碰字符串）
local function Is<TARGET>Frame(frame)
    if not frame then return false end
    local ok, name = pcall(frame.GetName, frame)
    if not ok then return false end
    name = name or ""
    -- 命名规律：按目标插件的 frame 名填写（见 §6 识别清单）
    if name:find("<NAME_PATTERN_1>") or name:find("<NAME_PATTERN_2>") then
        return true
    end
    -- 向上遍历父级
    local ok2, parent = pcall(frame.GetParent, frame)
    while ok2 and parent do
        local ok3, pname = pcall(parent.GetName, parent)
        if ok3 and pname and (pname:find("<NAME_PATTERN_1>") or pname:find("<NAME_PATTERN_2>")) then
            return true
        end
        ok2, parent = pcall(parent.GetParent, parent)
    end
    return false
end

---------------------------------------------------------------------------
-- 静态弹窗汉化（先去掉常量前缀再查表）
---------------------------------------------------------------------------
local function TranslateStaticPopups()
    if not StaticPopupDialogs then return end
    for key, dialog in pairs(StaticPopupDialogs) do
        if type(key) == "string" and key:find("^<POPUP_KEY_PREFIX>") and type(dialog) == "table" then
            if dialog.text and type(dialog.text) == "string" and not (issecretvalue and issecretvalue(dialog.text)) then
                local msg = dialog.text
                if POPUP_PREFIX ~= "" and msg:sub(1, #POPUP_PREFIX) == POPUP_PREFIX then
                    msg = msg:sub(#POPUP_PREFIX + 1)
                end
                local trans = GetTranslation(msg)
                if trans then dialog.text = (POPUP_PREFIX ~= "" and POPUP_PREFIX or "") .. trans end
            end
            for i = 1, 3 do
                local btn = dialog["button"..i]
                if btn and type(btn) == "string" and L[btn] then
                    dialog["button"..i] = L[btn]
                end
            end
        end
    end
end

---------------------------------------------------------------------------
-- 全局文本 Hook（全链路安全防护）
---------------------------------------------------------------------------
local function InstallHooks()
    -- 拦截 FontString:SetText
    local dummyFS = UIParent:CreateFontString()
    local fsMeta = getmetatable(dummyFS).__index
    local inFSHook = false
    hooksecurefunc(fsMeta, "SetText", function(self, text)
        if inFSHook then return end
        if issecretvalue and issecretvalue(text) then return end
        if type(text) ~= "string" or text == "" then return end
        if not Is<TARGET>Frame(self) then return end
        local trans = GetTranslation(text)
        if trans then
            inFSHook = true
            pcall(self.SetText, self, trans)
            inFSHook = false
        end
    end)

    -- 拦截 Button:SetText
    local dummyBtn = CreateFrame("Button")
    local btnMeta = getmetatable(dummyBtn).__index
    local inBtnHook = false
    hooksecurefunc(btnMeta, "SetText", function(self, text)
        if inBtnHook then return end
        if issecretvalue and issecretvalue(text) then return end
        if type(text) ~= "string" or text == "" then return end
        if not Is<TARGET>Frame(self) then return end
        local trans = GetTranslation(text)
        if trans then
            inBtnHook = true
            pcall(self.SetText, self, trans)
            inBtnHook = false
        end
    end)

    -- 拦截工具提示标题 GameTooltip:SetText（仅翻译目标框架内对象的 tooltip）
    -- 注意：SetText 为覆盖式写入，重设不会重复；AddLine 为追加式，不便劫持。
    local inTipHook = false
    hooksecurefunc(GameTooltip, "SetText", function(self, text)
        if inTipHook then return end
        if issecretvalue and issecretvalue(text) then return end
        if type(text) ~= "string" or text == "" then return end
        local ok, owner = pcall(self.GetOwner, self)
        if not ok or not owner then return end
        if not Is<TARGET>Frame(owner) then return end
        local trans = GetTranslation(text)
        if trans then
            inTipHook = true
            pcall(self.SetText, self, trans)
            inTipHook = false
        end
    end)
end

---------------------------------------------------------------------------
-- 设置面板汉化
---------------------------------------------------------------------------
local function TranslateSettingsPanel()
    if not Settings or not Settings.GetCategory then return end
    local ok, category = pcall(Settings.GetCategory, Settings, "<TARGET_TITLE>")
    if ok and category and category.Name and not (issecretvalue and issecretvalue(category.Name)) then
        category.Name = L["<TARGET_TITLE>"] or category.Name
    end
end

---------------------------------------------------------------------------
-- 小地图 LDB 汉化（目标插件若用 LibDataBroker 才需要）
---------------------------------------------------------------------------
local function TranslateLDB()
    if not LibStub then return end
    local ok, LDB = pcall(LibStub.GetLibrary, LibStub, "LibDataBroker-1.1", true)
    if not ok or not LDB then return end
    local ok2, obj = pcall(LDB.GetDataObjectByName, LDB, "<TARGET_TITLE>")
    if ok2 and obj then
        obj.label = L["<LDB_LABEL>"] or obj.label
    end
end

---------------------------------------------------------------------------
-- 初始化入口
---------------------------------------------------------------------------
C_Timer.After(0.2, function()
    TranslateStaticPopups()
    InstallHooks()
    TranslateSettingsPanel()
    TranslateLDB()
    print("|cFF00CCFF[<TARGET> 汉化]|r 简体中文语言包已加载（安全模式）")
end)
```

---

## 6. 落地前必做的识别（替换清单）

复制模板后，按目标插件实际情况填下面这些占位符：

| 占位符                 | 怎么找                                                | 示例（CMP）                                                               |
| ---------------------- | ----------------------------------------------------- | ------------------------------------------------------------------------- |
| `<TARGET>`           | 目标插件文件夹/TOC 名                                 | `CooldownManagerProfiles`                                               |
| `<TARGET_TITLE>`     | 设置面板分类标题原文（字符串精确匹配）                | `Cooldown Manager Profiles`                                             |
| `<TARGET>Lang`       | 共享字典全局表名，建议 `<TARGET>Lang`               | `CMPLang`                                                               |
| `<NAME_PATTERN_1/2>` | 目标 frame 名规律（`/fstack` 或 `_debug.log` 看） | `CooldownManager` / `Cooldown Manager Profiles` / `^CM` / `^CMP_` |
| `<POPUP_KEY_PREFIX>` | `StaticPopupDialogs` 的 key 前缀                    | `^CMP_`                                                                 |
| `POPUP_PREFIX`       | 弹窗 text 的常量前缀（去色前）                        | `CM Profiles\n\n`                                                       |
| `<LDB_LABEL>`        | LDB 对象的 label 原文                                 | `CM Profiles`                                                           |

**识别目标控件的三条路径（按优先级）：**

1. 游戏内 `/fstack` 打开鼠标指向框体看名字。
2. `_debug.log` 或 BugSack 抓目标插件创建 frame 时的 `CreateFrame("...", "Name", ...)` 第二参。
3. 读目标插件源码（镜像 `z-ref_retail_Interface_AddOns\<TARGET>\` 内），搜 `:SetText(` / `CreateFrame(` / `StaticPopupDialogs[` 定位文本出口与 frame 命名规律。

---

## 7. 翻译匹配规则（必须遵守，否则漏翻/误翻）

字典 `key` 一律用「去色后的纯文本」：

1. **去色码**：`|cxxxxxxxx` 与 `|r` 在查表前剥掉；若原文带色，翻译后自动把前缀色码 + `|r` 接回。
2. **弹窗前缀**：`StaticPopup` 的 `text` 常带常量前缀（如 `CM Profiles\n\n`）→ 先按长度截取前缀再查表，命中后拼回前缀。
3. **计数串**：`xxx (n/n)` / `xxx (n)` 只翻译 `xxx` 基名，数字原样保留。
4. **精确匹配**：`L[stripped]` 是整串精确查找；同值不同语境若需不同译法，靠不同 key 或上下文通道（弹窗/Setting/LDB）分别处理。
5. **兜底**：字典无对应项 → 返回 `nil` → 保留原文（**禁止静默兜底成空串/Unknown**，见红线）。

---

## 8. 12.x 安全红线（强制）

- **保密值**：`if issecretvalue and issecretvalue(x) then return nil end` —— 所有进入查表/格式化的文本先过此关；命中则保留原文，绝不比较/算术/作表键/裸 `string.format`。`SetText` 可直接吃 secret，由客户端渲染。
- **Forbidden Aspects**：原生受限框体（原生 Aura 等）上的 `SetText`/`HookScript` 静默失效，**不要为它们写补丁**；只处理目标插件自建控件。
- **钩子方式**：用 `hooksecurefunc(meta, "SetText", ...)` 劫持元表方法，**禁止重包装 `CreateFrame` 或写 `_G.SetText`**；唯一刻意全局是内部共享字典表（如 `CMPLang`），不污染 `_G` 顶层。
- **初始化时机**：用 `C_Timer.After(0.2, ...)` 延迟到目标插件建好 UI 后再劫持/替换，避免早于目标加载导致漏翻。
- **防递归**：钩子内用 `inXxxHook` 标志位，重设 `SetText` 时跳过自身，避免无限循环。

---

## 9. 多语种扩展步骤

1. 新建 `Lang_<locale>.lua`（`<locale>` 取 `GetLocale()` 返回值，如 `enUS`/`deDE`/`frFR`），字典表结尾 `<TARGET>Lang.<locale> = L`。
2. 在 TOC 的 `Lang_zhCN.lua` 之后追加一行 `Lang_<locale>.lua`。
3. **无需改 `LocalesPatch.lua`**：加载器按 `GetLocale()` 自动选词，未命中回退 `zhCN`。
4. 各语种字典 `key` 规则完全共用（去色、弹窗前缀、计数格式一致），只需翻译 `value`。

---

## 10. 新插件落地清单（Checklist）

- [ ] TOC：`## Interface:` 与目标插件对齐（当前 12.1.5 = `120105`）、`## Dependencies: <TARGET>`、文件顺序 `Lang_zhCN.lua` → `LocalesPatch.lua`。
- [ ] 文件夹/TOC 同名 `<TARGET>_LocalesPatch`；全文保存到子项目 `Patches/<TARGET>_LocalesPatch/`，再整目录复制进镜像。
- [ ] `Lang_zhCN.lua`：纯字典，`<TARGET>Lang.zhCN = L` 注册。
- [ ] `LocalesPatch.lua`：填 `<TARGET>` / `<TARGET_TITLE>` / 识别 pattern / 弹窗前缀 / LDB 名。
- [ ] 用 `/fstack` + 读目标源码确认 frame 命名规律，写进 `Is<TARGET>Frame`。
- [ ] 静态检查：`python -c "from luaparser import ast; ast.parse(open(f).read())"` 过两个 Lua 文件。
- [ ] 实机验证：`/console scriptErrors 1` 进游戏，检查目标 UI 是否整串汉化、其他插件是否被误伤、战斗中是否报 `ADDON_ACTION_FORBIDDEN`（若报，说明碰了受限框体，须剔除该通道）。

---

## 11. 已知局限

- 只对「整串 `SetText`/字典项」有效；**动态拼接、变量插值**的文本（如 `"Hello, " .. name`）无法整串匹配，需靠 key 穷举或放弃。
- `GameTooltip:AddLine` 追加式详情行不便劫持，通常保留英文。
- 目标插件每次大版本改文案/改 frame 命名，补丁需重新适配（见模板顶部「适配说明」）。
- 多插件并存时，`Is<TARGET>Frame` 的 pattern 必须足够特异，避免误翻其他插件。
- **下拉选项标签（dropdown option label）默认不译**：不少插件的 `dropdown()` 把 `info.value` 直接设为 `item.label`，
  使 label 同时成为存档值并被反查比较；且展开后的列表项渲染在暴雪共享的 `DropDownList` 框体，
  不属于目标插件、无法安全劫持。只译收起态会导致「收起显示中文 / 展开仍是英文」，
  并有显示值与存档值错配的风险。遇到这种结构应**整项跳过**并在文件头注明
  （实例见 `PintaWorldQuests_LocalesPatch`）。
- **动态拼接的「常量前缀 + 数值」**（如 `"Item Level " .. itemLevel`）无法整串匹配，
  可在 `GetTranslation` 里加一条 `PREFIX_NUMBER` 特例规则按「前缀 + 数字」翻译，勿为它改主匹配逻辑。
