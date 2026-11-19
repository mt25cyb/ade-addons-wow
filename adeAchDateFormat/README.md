# adeAchDateFormat

把成就完成日期按所选格式显示：暴雪原生成就 UI 与 `Krowi_AchievementFilter` 自建成就行同时覆盖。由 `Z_AchievementDateFormat` 重构，Krowi 扩展已在游戏内证实生效。

- 版本：`v6.5-r001`
- 客户端：12.1.5（`## Interface: 120105`）
- 依赖：`ade_UIKit`（强依赖，v6.5-r001-b015 起提供 `FormatDate` 公共 API）
- 开发计划：[`_docs/plans/adeAchDateFormat-dev-plan.md`](../_docs/plans/adeAchDateFormat-dev-plan.md)

## 功能

- 暴雪原生成就列表、详情前序/子成就、首页近期成就、成就比较、同盟种族解锁 tooltip、成就链接 tooltip。
- Krowi 主列表（Small/Normal）、首页总览 Light 行、日历侧栏成就行；兼容 Krowi 的 `HideDateCompleted` 选项。
- 7 种日期预设（照搬 Krowi 事件提醒格式，含时分）+ 自定义 `date()` 格式串；`%B/%b/%A/%a` 使用客户端本地化的月/星期名称。
- 可分别开关「暴雪原生 UI」「Krowi」两处生效范围。

## 设置界面

`/aadf` 或 `/adeachdateformat` 打开 `ade_UIKit` 选项窗；分区「日期格式」「生效范围」。按当前库能力裁剪：不设配置档页、关于页与主题色选项，主题色固定 ADE `#EEE4AE`。

| 命令 | 作用 |
|---|---|
| `/aadf` | 打开/关闭设置窗口 |
| `/aadf reset` | 全部设置恢复默认 |

## 语言策略

- 直接写 FontString 的格式化：全语言生效。
- 成就链接 tooltip 的中文正则改写：仅 zhCN。
- 与 `Z_AchievementDateFormat` 并存会重复写同一处日期文本，请停用 Z 插件。

## 架构

- `ade_UIKit/Function/Format.lua` 是唯一日期格式化出口（`FormatDate(day, month, year, fmt, opts)`）。
- `adeAchDateFormat/Format.lua` 只把本插件设置翻译成 UIKit 调用。
- `NativeHooks.lua` / `Ext_Krowi_AF.lua` / `Ext_Prat.lua` 各自注册刷新回调，设置变更即时重绘可见行。

## 验证清单

1. `/reload` 后 `/aadf` 可打开选项窗，7 预设逐项切换即时生效；Custom 任意格式串即时生效。
2. 暴雪原生 6 处日期按所选格式显示；非 zhCN 客户端直写路径仍生效，链接 tooltip 改写不触发。
3. Krowi 主列表、总览、日历侧栏日期按所选格式；`HideDateCompleted` 开启时仍隐藏。
4. 逐分区恢复默认与 `/aadf reset` 正常；停用 Z 插件后无双重写入。
5. lint 0 error。
