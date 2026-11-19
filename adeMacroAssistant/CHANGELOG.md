# adeMacroAssistant 变更记录

## v6.5-r003 - 2026-11-18

**名称/版本/图标统一改走 UIKit `GetAddonMeta`（b024；图标两态识别，本插件 TOC 已为 IconAtlas）。**

## v6.5-r002 - 2026-11-18

**「打开选项」stub 页改在加载期注册（原在惰性 Build 内，未打开过设置窗口时原生设置里看不到）；名称/版本统一经 `C_AddOns.GetAddOnMetadata` 取 TOC 元数据（设置页名/stub 标题/Print 前缀）；`/adema` 与 `ToggleOptions` 打开路径不变。**

## v6.5-r001 - 2026-11-17

**ADE v6.5 原生重写：移除 `_G.ADE` / AceLocale / AceConsole / AceGUI 依赖，改用私有表 + `ade_UIKit.DB.MergeDefaults`；4 个 AceGUI 设置页改为 UIKit `RegisterTab`，宏体用可滚动 `multiline` 就地编辑、说明为内容下方灰色行；导入导出走 UIKit `ShareString`（CBOR+压缩+Base64 字符串）+ 按钮实时校验；修复导出 payload 结构校验、占位符说明零匹配与多行框边框变形；导入状态提示实时更新并移至按钮下方，前缀改为 `ADEMA!`；各选项补齐源插件 tooltip，宏界面与自动宏按「宏界面尺寸调整 / 搜索栏 / 宏名前缀」重组分组标题；在原生「设置 > 插件」注册「打开选项」入口页；保留 `ADEMA_DB.profile` 旧存档结构与全部业务模块。**
