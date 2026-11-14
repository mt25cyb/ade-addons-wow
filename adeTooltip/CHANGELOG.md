# adeTooltip 更新日志

当前版本：**v6-r001-b009**（2026-11-14）

- v6-r001-b009 **推倒重做 · C0 骨架（经典路线优先）**：按开发计划 v2 推倒重做，物理删除原目录、从零重建。路线改为「经典优先」——`useNewLayout` 默认 `false`（经典路线：原地修饰原生提示），新版排版降为后续 N 阶段并预留接口。C0 落地：TOC / Core / InitDB（双存档层 `profiles`+`state`）/ Locales（zhCN/zhTW/enUS）/ Minimap（修正「取消不立即隐藏」链路）/ Options（真实框架 `AF.Form.Build`+`TabbedFrame`，仅暴露已落地设置）/ PreviewSamples（修正旧版 `UnitAura` 第 3 返回位误取 spellId 的崩溃）/ Hooks（双闸门 `ShouldClassic`/`ShouldNewLayout` 分发骨架）/ Libs/Secret（移植 MiliUI 秘密值守卫，命脉）。C1–C7（经典路线各类型原地修饰）与 N 阶段（新版排版）待逐期实机落地。
