# adeAnnivGuide — 艾泽拉斯之秘任务攻略

20 周年「艾泽拉斯之秘」解密任务图文攻略的游戏内阅读器（ADE v6 / 12.1.5）。

## 功能

- **主界面**：39 个解密任务条目（对应攻略文档二级标题，按文档顺序）两列网格排布，整页滚动；顶部搜索栏即时过滤（匹配标题与条目全部步骤文本，不区分大小写）。
- **内容界面**：点击条目进入，逐块渲染该任务的全部步骤文本与截图；任务名【】与坐标（63,53）自动上主题色（`#EEE4AE`）；图块点击放大（点击任意处 / ESC 关闭）；左上「返回」回主界面。
- **入口**：小地图按钮（左键开关窗口，可拖拽换角度，位置/显隐持久化）+ `/adeanniv` 斜杠命令；标题栏可拖动移动，窗口位置持久化（`ADEDB_ADEANNIVGUIDE.settings`）。
- **窗口**：720×600，12.x 原生风格（BasicFrameTemplate 原生标题栏与关闭 X、UIPanelButtonTemplate 按钮、InsetFrameTemplate 内衬区、SearchBoxTemplate 搜索栏），标题栏拖动、ESC 关闭、位置持久化。

## 依赖

- 无（零插件/库依赖；小地图按钮为 `Core/Minimap.lua` 自绘实现，逻辑对齐 ade_UIKit MinimapButton）。

## 数据与图片

- `Data/GuideData.lua`：攻略数据（39 条目 / 293 文本步骤 / 271 图片步骤），由 `_temp/anniv_build.py` 从
  `_temp/【WoW】20周年解密任务图文攻略.docx` 构建生成，勿手改。
- `assets/guide/imgNNN.jpg`：截图重编码产物（内容宽 ≤512、四边补边到 2 的幂、JPEG q72，共 ≈5.8MB）；
  运行时用数据内 `u/v` 比例 `SetTexCoord` 裁掉补边。新增/更新攻略：改 Word 源文档后重跑构建脚本。

## 内容来源

攻略文本与截图来自游侠网《魔兽世界》艾泽拉斯之秘任务攻略（20 周年解密，已完结），仅自用。

## 加载

无依赖；`Interface: 120105`；版本 `12.1.0-4-01.03`（与 CHANGELOG 同步）。
