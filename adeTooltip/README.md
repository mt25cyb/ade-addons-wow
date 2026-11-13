# adeTooltip

ADE v6 工具提示美化：以 **MiliUI_Tooltip** 为蓝本，新版排版采用 **PrettyTooltip** 观感，吸收 **PrimeTooltip** 的增量能力。客户端版本 **12.1.5**（TOC 120105），插件版本 `v6-r001-b001`。**强依赖 [`ade_AddonFramework`](../ade_AddonFramework/README.md)**（TOC `## Dependencies: ade_AddonFramework`，需 **b010+**）。

> 当前为 **P0/P1 骨架**：设置窗口、配置档、预览组件、小地图与数据层已可用；tooltip 渲染管线按开发计划 P2–P9 推进。开发计划：[`_docs/plans/adeTooltip-dev-plan.md`](../_docs/plans/adeTooltip-dev-plan.md)。

## 功能（b001）

- 设置窗口：`/adeTooltip` 或 `/atip` 打开，**多选项页 860×680 布局**（`AF.Template.TabbedFrame`，可拖动、Esc 关闭）；8 页「常规 / 单位 / 物品 / 法术 / 其他 / 锚点 / 配置管理 / 关于」。
- 常规页：「使用新版排版」（`usePrettyStyle`）、整体缩放、主题色（`AF.ApplyAccent` 派生）。
- 物品页：两段式开关（`twoStage`）——`usePrettyStyle=false` 时自动置灰（框架 b010 `Form.enabled` 禁用态）。
- 预览区：侧栏页脚「打开预览」按钮开关，**独立组件** `AF.Template.PreviewPanel`（主窗左侧停靠、主窗隐藏联动隐藏）；P1 为占位内容并随页切换联动，P7 接入真实分类样例与点击定位。
- 小地图按钮：仅左键开关设置窗口 + 圆周拖拽换位；侧栏页脚最底槽位「显示小地图按钮」复选框；`/atip minimap` 找回。
- 配置管理页：`AF.Options.ProfilePage + ProfileDB`——配置档切换/新建/复制/重命名/删除、导出/导入字符串、当前档恢复默认。
- 与 MiliUI_Tooltip 同装时聊天框提示一次（不建议双 tooltip 插件并跑）。

## 存档

`adeTooltipDB`（账号级，TOC `## SavedVariables`）：

- `db.profiles = { current, list }`：配置档，每档一份完整设置表；初始化合并默认值、`RANGES` 限幅、`CHOICES` 校验。
- `db.state`：会话状态，不随配置档切换/重置——`minimapShown`、`minimapAngle`、`previewOpen`。

## 验证清单（进游戏，P1 部分）

1. 仅装 adeTooltip + ade_AddonFramework（b010）可加载，无 Lua 报错；未装框架时不加载且无报错。
2. `/adeTooltip` 与 `/atip` 均可打开 8 页设置窗口；页切换按钮在左栏，选中项高亮。
3. 常规页关掉「使用新版排版」→ 物品页「两段式呈现」立即置灰且不可交互；重新开启后恢复。
4. 侧栏「打开预览」开合预览面板（按钮文案随开合切换），切页时预览占位文本跟随页名；主窗关闭时预览一并隐藏。
5. 小地图按钮左键开窗、拖拽换位、`/reload` 后角度保留；页脚「显示小地图按钮」复选框即时生效，`/atip minimap` 可找回。
6. 配置管理页新建/复制/重命名/删除/切换/导出/导入/当前档重置正常；切换档位后设置生效、`/reload` 保持，显隐/角度不随档位变化。
7. `/atip reset` 确认后当前档恢复默认；三语界面无缺译。

## 许可

MIT。蓝本 MiliUI_Tooltip；新版观感与修饰键 PrettyTooltip；增量能力 PrimeTooltip。
