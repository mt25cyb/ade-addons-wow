# adeMapMark_Portal

`adeMapMark` 的第一个外挂坐标数据包插件。

## 代码结构

- `Core.lua`：业务代码——共享常量、缺失字段补齐、标记汇总、Provider 注册；先加载并建立包内命名空间 `_G[addonName]`（`ns.L` 本地化表、`ns.Data` 数据表及 `Data.Common` 公共常量）。`AddMarks` 为数据表补齐公共字段：默认橙色/空备注/可见/46/12，并按库指定白色+导管图标、飞行点图标
- `Locales\enUS.lua` / `zhCN.lua` / `zhTW.lua`：Provider 标题与短名的三语本地化（与宿主同模式：enUS 默认、其余带 `GetLocale()` 守卫覆盖）
- `Data_Portal_Legion.lua`：7.x 军团再临——职业大厅传送点 10 点（来源旧版 `BDmap_ade_Portal`），仅存 `mapID`/`coord`/`title`，梦境林地 2 点另存 `note`/`icon` 例外 → `Data.LegionMarks`
- `Data_Portal_WarWithin.lua`：11.x 地心之战——卡雷什•相位导管 14 条（2371 十三条 + 2472 一条），存 `mapID`/`coord`/`title`（三语 `L.CONDUIT_*` 键）/`note` → `Data.WarWithinConduits`
- `Data_Portal_Midnight.lua`：12.x 至暗之夜——瓦尔 & 奈格塔尔传送点 8 点（来源旧版 `BDmap_ade_Portal`），仅存 `mapID`/`coord`/`title` → `Data.MidnightMarks`

数据表只存各记录特有字段；颜色/图标/备注/可见性/尺寸等公共值由 `Core.lua` 补默认值或按库指定赋值。

## 数据来源

1. **静态传送点**（10 条）：7.x 职业大厅，来自旧版 `BDmap_ade_Portal`
2. **11.x 卡雷什•相位导管**（14 条）与 **12.x 瓦尔 & 奈格塔尔**（8 条）：世界坐标经游戏内 `/ammcoord`（`C_Map.GetMapPosFromWorldPos`）转换得到 `coord`；名称引用三语 `L.CONDUIT_*` / `L.MIDNIGHT_*`，`note` 保留 `taxiNodeID`

图标材质：11.x 为 `ATLAS:flightmaster_ancientwaygate-taxinode_neutral`，12.x 为 `ATLAS:FlightMaster_Argus-TaxiNode_Neutral`。`C_TaxiMap` 飞行点 API 与相位导管不是同一对象，未采用。

不依赖 HandyNotes / PhaseDivingConduit / Ace3 安装。

## 配置

宿主 `adeMapMark` 按 `adeMapMark_PortalDB` 读取包级开关、收藏、逐标可见、折叠状态。
在地图设置窗口的「外挂数据包」分区可切换。

## 标记字段

- `iconSize`：图标尺寸（仅图标生效，默认 46）
- `textSize`：大地图文字字号（仅文本生效，默认 12；不提供时宿主取默认值，与 `iconSize` 无关）
- 其余字段（`mapID`/`coord`/`title`/`note`/`color`/`icon`/`isVisible`）见宿主 Provider 的 `NormalizeMark`
