## v6.5-r003 - 2026-11-18

**TOC 补 `Title-zhCN/zhTW`（[ADE] 快捷聊天栏 / 快捷聊天欄）；名称/版本/图标统一改走 UIKit `GetAddonMeta`（b024），自绘小地图图标改经 `ApplyIcon` 两态识别（IconTexture 优先于 IconAtlas，本插件 TOC 已为 IconAtlas）。**

## v6.5-r002 - 2026-11-18

**「打开选项」stub 页改在 ADDON_LOADED 加载期注册（原在惰性 Build 内，未打开过设置窗口时原生设置里看不到）；名称/版本/图标统一经 `C_AddOns.GetAddOnMetadata` 取 TOC 元数据（tooltip/设置页名/stub 标题/Print 前缀）；删除 Minimap 图标的防御链与 `ICON_FALLBACK` 纹理兜底（TOC 元数据缺失即暴露）。**

## v6.5-r001 - 2026-11-17

**由 adeChatMod 改造：设置窗口切换为 ade_UIKit v6.5 原生 Tab/控件；移除频道名缩写功能；改用独立存档 adeChatBarDB 与命令 /acb；按确认口径裁剪配置档页、关于页与主题色选项；在原生「设置 > 插件」注册「打开选项」入口页。**
