# Changelog

> 完整变更记录（每项背景与细节）见 `_docs/plans/adeTooltip-dev-plan.md` §十一 阶段表与变更记录。

当前版本：**v6-r001-b001**（2026-11-14）

- v6-r001-b001 **P0/P1 骨架落地**：依赖框架 b010（预览面板组件化 + Form 禁用态/行定位）；新插件骨架——TOC/根目录四文件（Core/InitDB/Colors/Hooks）/三语 Locales/小地图按钮（仅左键 + 圆周拖拽）/设置窗口多选项页 8 页（常规/单位/物品/法术/其他/锚点/配置管理/关于）；常规页真实表单（`usePrettyStyle`、缩放、主题色），物品页先挂两段式开关验证「`usePrettyStyle=false` 时新版专属选项置灰」；侧栏页脚 = 打开预览按钮（独立 `PreviewPanel` 组件，P1 占位内容 + 页切换联动）+ 小地图图标显示复选框（最底槽位）；配置管理页接入 `ProfilePage + ProfileDB`（存档 `profiles + state` 两层）；命令 `/adeTooltip` 与 `/atip`（about/minimap/reset）；MiliUI_Tooltip 共存提示。
