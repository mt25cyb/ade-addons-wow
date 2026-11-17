# MapPinEnhanced_FixTrackerPatch

修复 MapPinEnhanced（MPE）追踪器在重载（`/reload`、重新登录）后位置偏移的补丁子插件。

- 适用客户端：12.x（TOC `120105`，实测镜像 MPE 4.0.2）
- 依赖：`MapPinEnhanced`（硬依赖，加载顺序由 WoW 保证）
- 存档：`MapPinEnhancedFixTrackerPatchDB`（全局，与 MPE 的 `MapPinEnhancedDB` 作用域一致）

## 一、问题与根因（基于真实源码）

用户实测：拖动定位后存档为 `TOPLEFT / x=344.97 / y=-35.0076 / scale=0.9`，重载后存档变为 `TOP / x=-195.94 / y=-35.0076 / scale=0.9`（y 两次完全一致，仅差 `5×10⁻⁵` 的浮点抖动），且此后再重载不再变化；但一旦重新拖动，重载后又复现。

源码证据链（路径相对 `z-ref_retail_Interface_AddOns/MapPinEnhanced/`）：

1. **位置存取走 LibWindow-1.1**：`core/frame.lua:115-125`（`SaveFramePosition` / `RestoreFrame`）、拖动停止直接调用 `LibWindow.SavePosition`（`core/frame.lua:29`）。
2. **锚点表述每次保存都重选**：LibWindow 按「离哪条边/中心近」动态挑锚点，`x` 的含义随之变化（`TOPLEFT` 时 `x` = 左边距；`TOP` 时 `x` = 相对屏幕中心的偏移），见 `libs/LibWindow-1.1/LibWindow-1.1.lua:133-162`。两次快照 `TOPLEFT→TOP`、`x: 344.97→-195.94` 本质是同一位置两种表述；两种表述经还原换算（`LibWindow-1.1.lua:187-202`，偏移 = `x/scale`）落在不同像素位置 → 重载偏移。
3. **scale ≠ 1 的坐标口径混用**：保存侧 `left = GetLeft()*s`（`LibWindow-1.1.lua:129`）与还原侧 `x/s` 直接当 `SetPoint` 偏移，两端对「自身缩放」的换算方向相反，是偏移的温床。
4. **每次显示都会重写存档**：MPE `ApplyTrackerScale`（`modules/tracker/templates/TrackerPosition.lua:22-35`）比较 `Tracker.Scale` 选项值与 `GetScale()`；`0.9` 的双精度值与 `GetScale()` 返回的 float32 表示（`0.8999999761581421`，即用户存档中的值）不相等时，每次 OnShow 都会重锚定并调用 `SaveFramePosition` 重写存档——这解释了「没拖动，重载后存档也被改写」。还原入口在 `modules/tracker/templates/Tracker.lua:269-271`（OnShow → `RestoreTrackerPosition` → `ApplyTrackerScale`）。
5. **换算方向的实证**：`GetLeft()` 是自身缩放坐标、`×GetScale()` 才是 UIParent 坐标——原生同款用法见 `z-ref_wow-dev-git/wow-ui-source/Interface/AddOns/Blizzard_SharedTalentFrame.lua:35-39`；`SetPoint` 偏移 `×自身 GetScale()` = UIParent 坐标——与用户存档 y 值跨重载完全不变（即 LibWindow 的 `y/scale` 偏移恰好还原出原 y）的实测行为吻合。

## 二、为什么追踪器被重写、坐标/导航不变

1. **只有追踪器有「每次显示都重写存档」的路径**：`ApplyTrackerScale`（`modules/tracker/templates/TrackerPosition.lua:22-35`）比较 `Tracker.Scale` 选项值与 `GetScale()`；选项里的 `0.9` 是双精度，存档里的 `0.8999999761581421` 是 `GetScale()` 返回的 float32，两者永不相等 → 每次 OnShow 都重锚定并重写存档。坐标/导航没有 per-show 重存路径，只在拖动停止时写一次。
2. **scale=1 的帧换算恒等**：LibWindow 存储用 `GetLeft()*s`（`LibWindow-1.1.lua:129`）、还原用 `x/s`（`:187-202`）。`s=1` 时两侧恒等、往返精确，即使被重写也是同值（同一几何 → 同一分支 → 同一数值）。追踪器 `s=0.9` 时两侧不对称。
3. **锚点表述翻转**：LibWindow 每次保存都按屏幕几何重新挑锚点（`LibWindow-1.1.lua:133-158`）——`TOPLEFT` 时 `x`=左边距、`TOP` 时 `x`=相对屏幕中心的偏移。追踪器位置靠近「左边距 ≈ 中心偏移」的判定边界，重存时表述在 `TOPLEFT↔TOP` 间翻转，两种表述经还原换算的落点不一致 → 漂移。用真实分支条件反推用户两组快照：两次存档描述的位置差为正（`W/2 − 683` UI 单位，16:9 下为 0、带鱼屏下约 213），即重载链路中位置框被整体平移，并非纯表述翻转。

## 三、修法（v2）

不改动 MPE / LibWindow 内部，补丁插件自持一份**绝对位置快照**（`TOPLEFT` 锚 UIParent `BOTTOMLEFT`，UIParent 坐标单位，`MapPinEnhancedFixTrackerPatchDB.tracker`）：

| 时机 | 动作 |
|---|---|
| 用户拖动结束（header 的 `OnMouseUp` / `OnHide`，MPE `StopDragging` 之后） | 捕获快照（`GetLeft()*GetScale()` 换算） |
| 位置宿主框的**任何** `SetPoint` 之后（`RestoreFrame` / `ApplyTrackerScale` / 迁移 / 松手重锚定） | `C_Timer.After(0)` 回放快照（有偏差 > 0.25 单位才重锚定） |
| 1s 周期巡检 | 捕捉不经过 `SetPoint` 的位移（如 clampedToScreen 引擎修正）；连续 5 次回放未收敛自动停用（防单位语义不符时抖动），`/mpefixpos reset` 可重置 |
| 无快照时的首次还原 | 以当前位置建立基线 |

v2 实现要点（v1.0.0 的缺陷修复）：
- **不再依赖 `MapPinEnhancedTrackerPositionMixin` 全局**——v1 在该全局缺失时 `hooksecurefunc(nil, ...)` 抛错、整个 Core.lua 中断、快照永远为空。v2 按固定帧名 `_G.MapPinEnhancedTrackerPosition` 解析（`modules/tracker/tracker.lua:13-14`），登录事件 + 0.5s 重试（最多 60s）直到惰性创建完成，全部使用实例级钩子，对 MPE 小版本的方法重命名免疫。
- 坐标换算依据与 MPE/LibWindow 自身存取约定逐位一致（见 `Core.lua` 头注释）：`GetLeft()/GetTop()` 为自身缩放坐标、`×GetScale()` = UIParent 坐标（原生同款用法 `Blizzard_SharedTalentFrame.lua:35-39`）；`SetPoint` 偏移 `×自身 GetScale()` = UIParent 坐标。

## 四、使用说明

1. 安装后进游戏：补丁在追踪器首次显示时把当前位置记为基线（若当前已是漂移后的位置，基线即该位置）。
2. **把追踪器拖到想要的位置一次**——从这次拖动起，位置即被快照固定，之后任意次 `/reload` 都不会再偏移。
3. 想重新以「当前 MPE 还原结果」为基线：`/mpefixpos reset`（或 `/mpefixtrackerpos reset`）清除快照。
4. 诊断：`/mpefixpos status` 输出 MPE 版本、位置宿主框是否找到、各钩子安装状态、快照值、当前偏差、回放是否被自动停用。

## 五、进游戏验证清单

1. 安装补丁 → `/mpefixpos status` → 确认「位置宿主框：已找到」「SetPoint 钩子：已安装」「快照」有值。
2. 显示追踪器 → 拖到某处 → `/reload` → 落点应与拖动结束时的像素位置一致（可截图对比）。
3. 连续 `/reload` 两次以上 → 位置不再变化。
4. 修改 `Tracker.Scale`（追踪器缩放选项）→ 可见位置不应挪动，仅大小变化。
5. `MapPinEnhancedDB.frames.tracker`（MPE 自身存档）仍会被 MPE 改写——属预期（补丁不干预其内部存取），以补丁快照为准。
6. 最小化/关闭再展开追踪器、隐藏后再显示 → 位置不偏移。
7. `/mpefixpos reset` → 提示已清除；`/mpefixpos status` → 快照显示「无」。

## 六、边界与已知限制

- 只处理**追踪器**（`MapPinEnhancedTrackerPosition`）；MPE 的浮动导航窗、箭头等其他可拖元素不受影响。
- 快照为 UIParent 坐标（与 MPE 自身存档同一坐标系）：跨分辨率/界面缩放的不同角色共享同一数值（与 MPE 全局存档行为一致），分辨率变化大时可能需要重新拖一次。
- 回放连续 5 次未收敛会自动停用（`status` 中显示 DISABLED）——出现该情况请把 `/mpefixpos status` 的完整输出发给作者排查。
- MPE 若后续改名 `MapPinEnhancedTrackerPosition` 帧或重构拖拽区，钩子将静默失效（`status` 中「位置宿主框：未找到」）——届时需按新实现同步补丁。
