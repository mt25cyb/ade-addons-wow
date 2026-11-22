# adeMapMark

ADE 系列地图标记插件。保留 BDmap 的全部标点能力，新增外挂坐标数据包（Provider）支持。

开发计划：[`_docs/plans/adeMapMark-dev-plan.md`](../_docs/plans/adeMapMark-dev-plan.md)

## 功能

- 世界地图任意位置创建/编辑/删除标记（图标或文字），支持尺寸、颜色、灰度、收藏、导航（TomTom / 系统路点）
- 小地图标记、玩家箭头
- 导入导出（`!BDM!` 格式）
- **外挂坐标数据包**：第三方插件可注册只读坐标点到地图
- 地图内嵌设置窗口（齿轮按钮切换），不占用原生「设置 > 插件」入口

## 命令

| 命令 | 功能 |
|---|---|
| `/amm [标题]` | 在当前位置创建标记（缺省标题为「未命名」） |
| `/amm io` | 打开导入导出窗口 |
| `/amm debug [env\|providers\|db\|marks]` | 调试信息 |
| `/amm config` | 打开世界地图设置面板 |

## 依赖

- `LibStub`、`CallbackHandler`、`HereBeDragons`、`LibWorldMapTabs`（均内置于 `Libs/`）
- 不依赖 ade_UIKit / Ace3

## 外挂数据包开发

在自己的插件 TOC 声明 `## Dependencies: adeMapMark` 与同名 `SavedVariables`，然后注册 Provider：

```lua
_G.adeMapMark:RegisterMarkProvider({
    name = "MyPack",                 -- 必填唯一，建议与插件目录名一致
    title = "我的坐标包",
    version = 1,
    readOnly = true,
    GetMarks = function()
        return {
            { mapID = 84, coord = 31752645, title = "暴风城", icon = "SERVICE:FLIGHTMASTER" },
        }
    end,
})
```

mark 字段：`mapID`、`coord`（整型优先）或 `x/y`（0~1）、`title`、`note`、`color{r,g,b,a}`、`icon`（`CAT:KEY` ref）、`size`、`isVisible`。

宿主按 `{插件名}DB` 读取子插件配置：`{ enabled, favorites, visibility, collapsed }`。

完整转换方法（HandyNotes 子插件 → adeMapMark 数据包）见开发计划 §九。

## 材质

`Art/` 下的图标素材来自 BDmap 作者 Lengku，已获授权在 ADE 项目中使用与再分发。
