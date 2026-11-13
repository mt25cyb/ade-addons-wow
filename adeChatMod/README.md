# adeChatMod

聊天频道快捷条 + 频道名缩写 + 设置界面 + 小地图按钮。客户端版本 **12.1.5**（TOC 120105），插件版本 `v6-r001-b013`。**强依赖 [`ade_AddonFramework`](../ade_AddonFramework/README.md)**（TOC `## Dependencies: ade_AddonFramework`）：窗口、表单、配置档、关于页与主题色均来自库模板。

## 来源与致谢

- 业务逻辑：`ChannelBar`（作者 CHANGEEN，MIT）——频道快捷按钮、自动加入世界频道、频道名缩写 Hook，行为保持不变。
- 设置界面与小地图按钮原型：`PrimeTooltip`（作者 PrimeCraze）；b012 起界面层全部改用 `ade_AddonFramework` 模板实现，原型仅保留行为规格（左右键、拖拽定位、确认弹窗）。
- 图标取自 TOC 的 `## IconTexture` / `## IconAtlas`（设置窗口标题栏与小地图按钮中心图标统一由此读取，默认兜底 `Interface\ChatFrame\UI-ChatIcon-ArmoryChat`）；小地图按钮背景/高亮/边框用标准 Minimap 纹理，不复制第三方美术资源。

## 功能

- 12 个频道/功能按钮（说、喊、队、团、副、会、世、交、就、倒、骰、R），左/右键行为沿用原插件。
- 频道名显示为短标签（如 `[世界]`），Hook `ChatFrameN.AddMessage`。
- 设置窗口：`/acm` 打开，**单选项页 720 布局**（`AF.Template.TabbedFrame`，可拖动、Esc 关闭）；b013 起页切换按钮在**标题栏右侧**（ADE-v6-FrameDesign）：「设置 / 配置管理 / 关于」三页；设置页每行带「偏离默认才显示」的逐项重置按钮（`AF.Template.Form.Build`），分区含外观、主题色、频道、位置、备用位置、小地图按钮。
- 配置管理页（`AF.Template.ProfilePage` + `ProfileDB`）：配置档切换/新建/复制/重命名/删除、导出/导入字符串、当前档恢复默认（均带确认弹窗）；显隐/小地图角度等会话状态不随配置档切换。
- 设置即时生效：按钮尺寸/间距/字号/配色、条宽、吸附目标与偏移；每行可单独还原默认值；当前档恢复默认有确认弹窗。
- 主题色（强调色）默认黄色，在「设置」页「主题色」分区调整（`AF.Widget.Color` 取色器）；派生与控件自刷新由库 `AF.ApplyAccent` 完成。
- 小地图按钮：**左键显示/隐藏快捷条**、**右键打开设置界面**、左键拖拽沿小地图圆周移动、悬停显示四行提示；显隐与角度入存档。

## 命令

| 命令 | 作用 |
|---|---|
| `/acm` | 打开/关闭设置窗口（`/adechatmod` 等效） |
| `/acm about` | 打开关于页 |
| `/acm minimap` | 显示/隐藏小地图按钮 |
| `/acm reset` | 恢复默认设置（确认弹窗） |

## 存档

`adeChatModDB`（账号级，TOC `## SavedVariables`），b013 起分两层：

- `db.profiles = { current, list }`：配置档（`AF.Template.ProfileDB` 适配器），每档为一份完整设置表；初始化时合并默认值、按 `RANGES` 限幅、按 `CHOICES` 校验。主题色键 `settings.themeColor = {red,green,blue}` 经 `AF.ApplyAccent` 派生。导出/导入用库线格式（`AF.DB.Encode/Decode`）。
- `db.state`：会话状态，不随配置档切换/重置——`barShown`（快捷条显隐）、`minimapShown`（按钮显隐）、`minimapAngle`（圆周角度，0–360）。
- 旧存档（`db.settings.*`）在首次加载时自动迁移：设置整体搬进 `profiles.list["Shared"]`，三个状态键搬进 `db.state`。

## 目录结构

```
adeChatMod/
├── adeChatMod.toc                 # ## Dependencies: ade_AddonFramework
├── Locales/{enUS,zhCN,zhTW}.lua   # 界面文本本地化（关于页为结构化 ABOUT_* 键）
├── Core.lua                      # 存档、RANGES/CHOICES、ApplyAccent 委托、登录与 slash 入口
├── InitDB.lua                    # ACM.DEFAULTS（默认值）
├── ChannelBar.lua                # 原业务逻辑 + RefreshBar / SetBarShown / ToggleBar
├── ChannelAbbrev.lua              # 原频道名缩写 Hook
├── Minimap.lua                    # 小地图按钮（左右键/拖拽/tooltip/显隐，颜色走 AF accent）
├── Options.lua                    # AF.Template.TabbedFrame + Form + AboutPage 组合
├── CHANGELOG.md
└── README.md
```

## 技术依据

- API 查证：`../_docs/api/README.md`、`../_docs/api/api-changes-overview-12.x.md`；小地图按钮的完整 API 核验表见规划文档 §四。
- 相对 ChannelBar 的 API 迁移：全局 `DoReadyCheck()` → `C_PartyInfo.DoReadyCheck()`（12.0.7 废弃）；`ChatFrame_OpenChat` → 优先 `ChatFrameUtil.OpenChat(text, chatFrame)`，旧别名兜底；不使用 12.1.5 已移除的 `Blizzard_Deprecated*` 全局回退与 `getglobal`/`setglobal`。
- TOC 首行直接写 `## Interface`（12.0.7 首行注释 Bug）。
- **框架组合（b012）**：窗口 = `AF.Template.TabbedFrame`（**当前 `layout="single"`；后续选项增多把该行改 `"multi"` 即切左栏页切换**，内容区两种布局等宽 672、控件同一套标准）；设置页 = `AF.Template.Form.Build`（ctx.get/set 桥接 `ACM:Get/Set` 点号路径）；关于页 = `AF.Template.AboutPage.Build`（结构化 `ABOUT_*` 三语键）。滚动高度显式用 Form 实测高度设置，不依赖 `SetAllPoints` 页 holder 的 `GetHeight`。
- 小地图按钮未复用库 `Widget/MinimapButton`：该控件不支持右键行为，adeChatMod 需要「左键显隐快捷条、右键开设置」双击行为，故保留 PT 原型实现，仅颜色改走 `AF.Color("accent")`。

## 验证清单（进游戏）

1. `/acm` 打开窗口；页按钮「设置 / 配置管理 / 关于」在标题栏右侧、选中项高亮；拖动标题栏（按钮区不触发拖拽）、Esc/X 关闭；某行改动后该行出现重置小按钮，点击还原。
2. 滚动条仅在内容超高时出现，滚轮可滚到设置页底部，文字无截断重叠。
3. 改任一设置即时反映到快捷条；频道名/自动加入下次登录生效。
4. 小地图按钮出现且位置正确；左键显隐快捷条、右键开关设置界面；拖拽沿圆周移动且 `/reload` 后角度保留；悬停 tooltip 四行、移开消失。
5. 设置界面「小地图按钮」分区的两个复选框与行重置即时生效；`/acm minimap` 可找回被隐藏的按钮。
6. 「配置管理」页：新建/复制/重命名/删除档位正常（Shared 档重命名/删除禁用）；切换档位即时生效且 `/reload` 后保持；导出框 Ctrl+C 可复制、粘贴有效串后「导入」亮起、导入确认后设置切换；当前档重置确认后回默认。
7. `/acm reset` 确认后当前档恢复默认并刷新；`/reload` 后设置（含按钮显隐与角度）保留；显隐/角度在切换配置档后不变。
8. 「主题色」分区改色：取色即时生效、取消还原、`/reload` 持久化、恢复默认回默认黄。
9. 旧版存档（db.settings）升级后自动迁移，原设置与按钮显隐/角度不丢。
10. 仅装 adeChatMod + ade_AddonFramework 可正常运行；未装框架时不加载且无 Lua 报错。
11. 12.1.5 客户端无 Lua 报错、无 blocked 提示。
