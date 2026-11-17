# 罗盘追踪扩展 (Boussole TrackerExt)

**当前版本：1.2.0（2026-11-15）**

**Compass（宿主文件夹名为 Boussole）的扩展子插件**，为其罗盘补齐 **CompassHUD** 式的超追踪能力。

Compass 本体只负责用三角指向超级追踪目标，缺少目标身份（图标 / 名称 / 距离）与超出视野时的边缘指示。本插件参考经典的 CompassHUD 思路，把「超追踪目标上罗盘」所需的一整套信息层搬进 Compass 的罗盘：追踪层图标（世界任务 / 奖励目标 / 任务 / POI / 飞行点 / Vignette / 用户航点）、刻度下方名称与距离块、超出视野的贴边指针、罗盘刻度数字，以及对追踪目标的放大与高亮强调。增强层完全依附于 Compass、不改动其本体；Boussole 内部层不可用时仅降级运行。

## 功能

- **目标源**：与 CompassHUD 显示的目标范围一致——普通任务、世界任务/奖励目标、任务奖励标记、区域 POI、飞行点、Vignette（事件）、用户航点，以及未列出的新类型（内容追踪等）经系统航点兜底；无超级追踪时显示主插件选定图钉，两者冲突以超级追踪为准。
- **追踪扩展信息**：在刻线附近额外绘制「图标 + 名称 + 距离」块，默认贴近刻线；**位置每帧随朝向平滑重算**（不再 0.12s 一步跳），转向时无卡顿。仅当本块会与原生「罗盘信息」水平重叠时，原生信息条件性上移到罗盘图标上方给本块让位，不重叠时原生信息仍在三角下方、本块不动。
- **贴边指针（PointerStay）**：目标超出罗盘可视半角时，**材质**钳在罗盘左右边缘常显，文本与材质同心锚在其下方；材质本身是方向箭头时原地旋转，否则在外侧补方向箭头（`bag-arrow` 等原生朝向不是「朝上」的 atlas 会自动叠加基准角）。
- **图标来源**：复刻 CompassHUD「Modern」纹理预设——世界任务 / 奖励目标用奖励物品或货币图标（圆形遮罩 + 头像边框），其余按任务分类取 `MiniMap-QuestArrow` / `Rotating-MinimapGuideArrow` / `MiniMap-VignetteArrow` 等，POI / 飞行点 / 事件用其自身 atlas。
- **图标处理**：奖励贴图走 `SetTexture` 铺满；atlas 不裁切（只按原始宽高比等比缩放，长条 atlas 铺满正方形），避免 texcoord 反推裁切取到相邻图素。
- **罗盘刻度数字**：仿 CompassHUD，在罗盘上叠加 30° 间隔的方位读数（复用主插件刻度投影，受罗盘宽度裁剪），宿主本身只显示刻度线；紧凑模式与关闭开关时隐藏。
- **跨图处理**：三级换算——系统转换点（可关）→ 宿主世界坐标换算 → 地图坐标投影；覆盖同大陆不同子图与跨大陆（可隐藏）。
- **追踪强调**：放大比例（0.8–2.5）、高亮颜色、光晕透明度可配。

## 设置

- 游戏内 `系统 → 设置 → 插件 → Compass → 罗盘追踪扩展`（挂进 Compass 设置树；采用暴雪 12.x 原生设置控件：`Settings.RegisterVerticalLayoutSubcategory` + `Settings.CreateCheckbox/Slider/Dropdown/ColorSwatch`，即金勾选框、原生下拉、带菱形滑块与颜色取样）。
- 命令：`/bte` 查看能力探测状态，`/bte options` 打开设置，`/bte debug`（`/bte 调试`）打印当前追踪目标的类型与解析结果。

## 依赖

- **硬依赖**：Boussole（内部层探测失败时仅保留降级能力并以聊天框提示）。
- 设置页挂在 Boussole 根设置分类下（`Options._internal.panels.root.category`），使用暴雪官方 AddOn 设置 API 创建原生控件。

## 兼容性

- 客户端：12.1.5（TOC 120105）
- Boussole 内部层（`Compass._internal`）为非文档接口，启动时逐字段探测；结构变更时增强层自动禁用，不影响 Boussole 本体。

## 开发

规划与实施记录见 [_docs/plans/Boussole_TrackerExt-dev-plan.md](../_docs/plans/Boussole_TrackerExt-dev-plan.md)。
