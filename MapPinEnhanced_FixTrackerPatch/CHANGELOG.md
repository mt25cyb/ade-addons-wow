# Changelog

## 1.1.0 - 2026-11-17

**修复 v1.0.0 钩子从未生效（快照恒为空）的问题：不再依赖 MPE Mixin 全局（缺失时 v1 的 hooksecurefunc 抛错并中断整个 Core.lua），改为按帧名 `_G.MapPinEnhancedTrackerPosition` 解析 + 实例级 `SetPoint` 后置万能回放钩子 + 拖动结束捕获（header OnMouseUp/OnHide）+ 1s 周期巡检（含连续未收敛自动停用保护）；新增 `/mpefixpos status` 诊断命令。**

## 1.0.0 - 2026-11-17

**首个版本：修复 MapPinEnhanced 追踪器重载后位置偏移（自持 UIParent 绝对锚点快照，在 MPE 每条还原路径之后强制回放；仅在用户拖动结束时更新快照）。**
