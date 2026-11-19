# adeMacroAssistant

按职业自动生成 7 类宏（净化 / 驱散 / 打断 / 战复 / 疾跑 / 嘲讽）并调整宏界面尺寸。由旧 ADE v5 体系**原生重写**为 ADE v6.5。

- 版本：`v6.5-r001`
- 客户端：12.1.5（`## Interface: 120105`）
- 依赖：`ade_UIKit`（强依赖：`DB.MergeDefaults` + `RegisterTab` + b019 `ShareString` / 可滚动 `multiline`）
- 存档：`ADEMA_DB`，沿用旧 `profile` 结构（不迁移旧数据，缺失键自动补默认）
- 迁移计划：[`_docs/plans/ade-v65-migration-dev-plan.md`](../_docs/plans/ade-v65-migration-dev-plan.md) §2.2

## 功能

- 7 类宏按职业法术表自动创建 / 改名 / 清理，支持自定义前缀。
- 宏界面垂直 / 水平双布局，列数、行数、文本区高度 / 宽度可调；搜索栏可过滤宏名与宏体。
- 宏配置导入 / 导出（仅自动宏的名称与宏体，与 v5 同格式）。

## 设置界面

基于 `ade_UIKit` 的 `RegisterTab`，三个分区：

| 分区 | 内容 |
|---|---|
| 宏界面 | 分组「宏界面尺寸调整」（启用、布局模式、双布局行列、文本区高 / 宽、重置当前布局）与「搜索栏」（启用搜索栏、同时搜索宏内容） |
| 自动宏 | 分组「宏名前缀」（启用自动宏、启用前缀、前缀字符）；其下 7 类宏各为一组（启用、基名、宏体内嵌多行编辑框 + 灰色说明行） |
| 导入 / 导出宏 | 「生成导出字符串」按钮产出 `ADEMA!` 前缀的分享字符串（CBOR+压缩+Base64，非明文）；导入框贴入后实时校验，成功才亮「导入宏」按钮 |

按已确认口径**不提供配置档管理页、关于页与主题色选项**；宏体使用 UIKit b019 可滚动 `multiline` 内嵌行（就地编辑、失焦提交），说明在内容框下方以灰色文本行呈现；导入导出字符串编解码走 UIKit `lib.ShareString`。

## 命令

| 命令 | 作用 |
|---|---|
| `/adeMacroAssistant`、`/adema`、`/adeMA` | 打开 / 关闭设置窗口 |

## 目录

| 文件 | 内容 |
|---|---|
| `InitDB.lua` | `ns.defaults` 单一真源、私有 locale 选择、`CopyTable` / `ResetSubtree` |
| `Locales/` | enUS / zhCN / zhTW 私有 locale 表（不再经 AceLocale） |
| `Modules/AutoMacroData.lua` | 7 类宏的技能 ID 表（纯数据） |
| `Modules/AutoMacro.lua` | 按职业解析法术、宏创建 / 改名 / 清理 |
| `Modules/MacroUIResize.lua` | 宏界面双布局重排与几何还原 |
| `Modules/MacroSearch.lua` | 宏界面搜索栏、过滤与布局菜单 |
| `Core.lua` | 私有表、存档装配（UIKit `DB.MergeDefaults`）、模块调度、原生 slash |
| `Settings.lua` | 导出 payload 构造 / 校验 / 写回（编解码走 UIKit `ShareString`） |
| `Options.lua` | UIKit `RegisterTab` 设置页（3 分区） |

## 进游戏验证清单

1. `/reload` 无 Lua error；`/adema` 能打开 UIKit 选项窗，三个分区可切换、搜索可用。
2. 宏界面布局项改值即时生效；切换布局模式后对应滑块范围与数值正确；「重置当前布局」只重置当前模式。
3. 自动宏开关 / 前缀 / 7 类基名即时生效；7 类宏体在设置页内嵌多行框中就地编辑、失焦写回，悬停各自显示不同的法术占位符说明。
4. 「生成导出字符串」产出 `ADEMA!` 开头的字符串且自动全选；贴回导入框即时校验（前缀错立即显示错误，无需切页），提示在「导入宏」按钮下一行，串有效时按钮变亮；点击后自动宏立即刷新、导入框清空。
5. 旧 `ADEMA_DB` 存档加载后缺失键自动补齐，已有值不被覆盖。
6. 三语切换无硬编码文案；lint 0 error。
