# adeChatBar

聊天频道快捷条。由 `adeChatMod` 改造而来：**设置窗口改用 `ade_UIKit`（ADE v6.5）原生 Tab/控件**，并**移除频道名缩写功能**。

- 版本：`v6.5-r001`
- 客户端：12.1.5（`## Interface: 120105`）
- 依赖：`ade_UIKit`（强依赖；零 `ade_AddonFramework` 依赖）
- 开发计划：[`_docs/plans/adeChatBar-dev-plan.md`](../_docs/plans/adeChatBar-dev-plan.md)

## 功能

- 12 个频道/功能按钮，配色「彩色 / 默认金色」两套，字号与间距可调。
- 可吸附到任意全局框体（默认 `ChatFrame1EditBox`），目标缺失或隐藏时使用备用位置。
- 世界频道名/交易频道名可配置，支持登录时延迟自动加入世界频道（`/reload` 不触发）。
- 小地图按钮：左键显隐快捷条、右键打开设置、拖拽沿圆周移动。

## 设置界面

基于 `ade_UIKit` 的 `RegisterTab`，两个分组、五个分区：界面（外观 / 频道）、位置与小地图（位置 / 备用位置 / 小地图按钮）。按已确认口径**不提供配置档管理页、关于页与主题色选项**；主题色固定 ADE `#EEE4AE`。各分区支持「恢复默认」（逐分区 `resetSection`）。

## 命令

| 命令 | 作用 |
|---|---|
| `/acb`、`/adechatbar` | 打开/关闭设置窗口 |
| `/acb minimap` | 显示/隐藏小地图按钮 |
| `/acb reset` | 全部设置恢复默认 |

## 存档

`adeChatBarDB`：`settings`（设置项）+ `state`（快捷条显隐、小地图显隐与角度）。原 `adeChatModDB` 不迁移，本插件使用独立存档。

## 目录

| 文件 | 内容 |
|---|---|
| `Core.lua` | 命名空间 `ACB`、默认值合并、设置读写、`ApplyAll`、事件与 slash |
| `InitDB.lua` | `ACB.DEFAULTS` 唯一默认值源 |
| `ChannelBar.lua` | 快捷条业务与事件（源自 ChannelBar，MIT） |
| `Minimap.lua` | 小地图按钮 |
| `Options.lua` | BOF `RegisterTab` 设置页与逐分区恢复默认 |
| `Locales/` | enUS / zhCN / zhTW |

## 进游戏验证清单

1. `/reload` 后 `/acb` 能打开 BOF 选项窗；两个分组、五个分区均可切换，搜索可用。
2. 改值即时生效：按钮大小/间距/字号、配色、频道名、位置与小地图开关。
3. 逐分区「恢复默认」只重置本分区；`/acb reset` 重置全部。
4. 小地图按钮左键/右键/拖拽正常；隐藏后 `/acb minimap` 可找回。
5. 频道消息中不再出现任何频道名缩写替换。
6. 三语切换无硬编码文案；lint 0 error。

## 致谢

ChannelBar 原始实现作者 CHANGEEN（MIT）。原 `adeChatMod` 快照保存在 `_backup/adeChatMod_2026-11-17/`。
