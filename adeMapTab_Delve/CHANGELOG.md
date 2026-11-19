# adeMapTab_Delve — CHANGELOG

## v6.5-r002 - 2026-11-18

**小地图图标/标题改走 UIKit `GetAddonMeta`（b024）：TOC `## IconTexture` 优先于 `## IconAtlas` 两态识别（本插件 TOC 已换 `IconAtlas: delves-bountiful`，原直读 IconTexture 恒 nil 导致小地图图标为空）。**

## v6.5-r001 - 2026-11-17

**ADE v6.5 原生重写：移除 `_G.ADE` / AceConsole / AceDB / 独立设置页（`UI/Settings.lua` 删除，设置只留世界地图 Tab 内齿轮页）；存档装配改 `ade_UIKit.DB.MergeDefaults`（存档名 `ADEDB_MAP_TAB_DELVE` 不变）；小地图图标改 UIKit 自绘按钮（零依赖，旧存档字段 `minimapPos/radius/hide` 直接沿用）；命令 `/ademaptabdelve`、`/adedelvetab`、`/adedt`、`/adeMTD`；Data/Services/UI 其余文件零改动（`LibStub("AdeMapTab-1.0")` 与新版公共库兼容）。实测修复：战团统计窗玩具按钮点击无效——12.x 的 `SecureActionButtonTemplate` 模板不再自带 `RegisterForClicks`，补显式注册 `AnyDown+AnyUp`。实测修复：小地图按钮加载报错 `attempt to call a nil value`——12.x 已移除全局 `GetAddOnMetadata`，改走 `C_AddOns.GetAddOnMetadata`。**
