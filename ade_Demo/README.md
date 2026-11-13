# ade_Demo

`ade_AddonFramework` 的控件画廊与功能自测插件，`## Dependencies: ade_AddonFramework`（验证独立形态）。

- 版本：`v6-r001-b008`
- 客户端：12.1.5（`## Interface: 120105`）
- 存档：`ade_DemoDB`，统一 `settings.*`，颜色 `{red,green,blue}`
- 本地化：enUS / zhCN / zhTW
- 图标：`assets/ade_128.tga`（自 `wow-textures/ade_128.tga` 拷贝）

## 命令

| 命令 | 作用 |
|---|---|
| `/afdemo` | 打开/关闭控件画廊（默认多选项页 860 布局） |
| `/afdemo single` / `/afdemo multi` | 以单选项页 720 / 多选项页 860 布局重建画廊 |
| `/afdemo test` | 运行公共函数自测（命名空间、主题色、DB、回调、三态图标、Masque 探测等） |

八个页签：基础控件、表单（含逐项重置三态）、信息条与预览、清单（支持拖拽调序）与行看板拖拽（每行多个元素方块、超宽自动换行、每行左侧外部移动控件拖整行、方块亦可跨行/行内拖拽）、弹窗/菜单/搜索、集成控件、配置页模板、关于页。

关于页正文按规划文档 §十一 的 `ABOUT_*` 范本填写，颜色由 `AF.AccentHex()` 生成，不在 Locales 里写死颜色转义。

## 内置形态试点

`Libs/ade_AddonFramework/TESTING.md` 给出内置副本的同步与验证步骤；该试点需手动拷贝库源码后进游戏执行，**当前未标记为已验证**。

## 主题色

默认 `#EEE4AE`，存 `ade_DemoDB.settings.globalColor`；`DEMO.SetGlobalColor(color)` 会写回存档并调用 `AF.ApplyAccent()` 广播。

## 进游戏验证清单

- 插件列表图标正常；`/reload` 后 `GetFramework()` 非空且 `AF.MINOR` 与库一致。
- 切换主题色时只有着色部位变色。
- 三语客户端下本地化互不覆盖。
