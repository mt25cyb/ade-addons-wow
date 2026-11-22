-- RCT 14.5.5 · zhCN 本地化（基准 enUS 14.5.5）
-- AceLocale 注册名 RdysCrateTracker；TOC 须在 Locale/ruRU.lua 后加载。
-------------------------------------------------------------------------------
-- Hated Crate Tracker -- (c) Hated Gaming / Rdy. All Rights Reserved.
-- Do not copy, redistribute, or use this file to train or fine-tune AI
-- models without written permission.
--
-- Commenting and lint verification assisted by Hated Gaming LLM by Rdy.
-- Powered by Hated WoW MCP: https://github.com/RdyGaming/hated-wow-mcp
-------------------------------------------------------------------------------
local AceLocale = LibStub("AceLocale-3.0")
local L = AceLocale:NewLocale("RdysCrateTracker", "zhCN")

if not L then return end

-- Addon Info
L["ADDON_NAME"] = "Hated Crate Tracker"
L["ADDON_TITLE"] = "Hated Crate Tracker"
L["ADDON_SHORT_NAME"] = "Hated Crate Tracker 3.0"

-- WoW Forever announcement popup

-- Discord and Links
L["DISCORD_POPUP_TEXT"] = "复制此链接并在浏览器中打开。"
L["THANKS_EYEBROW"] = "来自 RDY，HATED GAMING"
L["THANKS_TITLE"] = "感谢你和我一起猎取补给箱。"
L["THANKS_BODY"] = "一切始于让大型团队能够沟通与协作的工具需求。Rdy's Crate Tracker 由此诞生，并演变成这款出色的工具。我是 Hated Gaming 唯一的开发者，你们每一位使用者都是我继续开发的动力。"
L["THANKS_PVP"] = "特别感谢庞大的世界 PvP 社区。没有你们，刷补给箱不会如此流行。"
L["SUPPORT_MY_WORK"] = "支持我的工作"
L["JOIN_DISCORD"] = "加入 Discord"
L["DISCORD_LINK"] = "https://discord.gg/qHHSMFsJ9f"

-- Version Update Messages
L["VERSION_UPDATE_TITLE"] = "Hated Crate Tracker！"
L["VERSION_UPDATE_WELCOME"] = "欢迎来到 8.0"
L["VERSION_UPDATE_MESSAGE"] = [[这里是来自 Hated Gaming 的 Rdy，感谢你使用我们的工具。

最近暴雪对 PvP 的关注不多，很容易觉得自己像是这个游戏里被冷落的孩子。但 PvP 社区始终互相照应，分享计时器、彼此照应、互相制作像这样的工具。

这值得坚守。无论你身在哪个公会、阵营或服务器，我们始终是同一个社区。让这种精神延续下去，一起继续称霸。

Hated Gaming

保持讨厌！]]

-- Buttons
L["RESET"] = "重置"
L["CLOSE"] = "关闭"
L["DONT_SHOW_AGAIN"] = "不再显示"

-- Guidelines
L["WAR_CRATE_GUIDELINES"] = [[
要做的：
- 加入我们的 Discord，使用 /rct help 查看插件信息。
- 和朋友或公会成员一起加入；满编队伍玩得最开心。
- 使用语音沟通；我们协同作战并呼叫补给箱。
- 做好准备；补给箱掉得快，我们行动也快。
- 帮助新手；我们都曾从这里开始，社区因此成长。
- 加入 Whisperwind 服务器的 Hated Gaming 公会（部落公会查找器中）
联盟玩家请在 Discord 上私信 @Rdy 邀请。
]]

-- Warning Messages
L["CRATE_ALERT_MESSAGE"] = "Hated Gaming 补给箱警报！正在飞往 %s - 位面 = %s"
L["CRATE_ANNOUNCE_MESSAGE"] = "%s 刚刚播报了 %s - %s 的战争补给箱（%s 收到）"
L["CRATE_SPOT_MESSAGE"] = "%s - %s 出现战争补给箱（%s - %s 发现）"
L["SHARD_MATCH_WARNING"] = "Hated Gaming 警告：%s 的位面匹配。位面 ID：%s"
L["SHARD_CHANGED_WARNING"] = "Hated Gaming 警告：%s 的位面发生变化。旧：%s，新：%s"

-- Vignette Messages
L["SUPPLY_CRATE_CLAIMED"] = "Hated Gaming 补给箱已在 %s 被开启"
L["CRATE_FLYING"] = "战争补给箱 - 飞行中"
L["CRATE_HOVERING"] = "战争补给箱 - 悬停中"
L["CRATE_CLAIMED"] = "战争补给箱 - 已开启"
L["CRATE_STILL_FIGHTING"] = "战争补给箱 - 激战中"

-- UI Elements
L["CLOSE_WINDOW"] = "关闭窗口"
L["HIDE_SHOW_TIMERS"] = "隐藏/显示计时器"
L["OPEN_OPTIONS"] = "打开设置"
L["PLACEMENT_TEXT"] = "Hated Gaming Crate Tracker：插件放置文本"

-- Zone Names
L["ISLE_OF_DORN"] = "多恩岛"
L["RINGING_DEEPS"] = "喧鸣深窟"
L["HALLOWFALL"] = "陨圣峪"
L["AZJ_KAHET"] = "艾基-卡赫特"
L["SIREN_ISLE"] = "海妖岛"
L["UNDERMINE"] = "安德麦"
L["UNKNOWN_ZONE"] = "未知区域"

-- Settings Labels
L["GENERAL_SETTINGS"] = "常规设置"
L["ENABLE"] = "启用"
L["ENABLE_DESC"] = "启用或禁用插件"
L["DEBUG_MODE"] = "调试模式"
L["DEBUG_MODE_DESC"] = "启用调试消息"
L["SCALE"] = "缩放"
L["SCALE_DESC"] = "设置主框体的缩放"

-- Warning Frame Settings
L["WARNING_FRAME"] = "警告框体"
L["WARNING_FRAME_DESC"] = "与警告框体相关的设置"
L["ENABLE_WARNING_FRAME"] = "启用警告框体"
L["ENABLE_WARNING_FRAME_DESC"] = "启用或禁用警告框体"
L["WARNING_X_POSITION"] = "警告 X 位置"
L["WARNING_X_POSITION_DESC"] = "设置警告文本的 X 位置"
L["WARNING_Y_POSITION"] = "警告 Y 位置"
L["WARNING_Y_POSITION_DESC"] = "设置警告文本的 Y 位置"
L["WARNING_FRAME_FONT"] = "警告框体字体"
L["WARNING_FRAME_FONT_DESC"] = "选择警告框体的字体"
L["WARNING_FRAME_FONT_SIZE"] = "警告框体字号"
L["WARNING_FRAME_FONT_SIZE_DESC"] = "设置警告框体的字体大小"

-- Zone-specific Settings
L["UNDERMINE_ANNOUNCE"] = "安德麦 - 播报"
L["UNDERMINE_ANNOUNCE_DESC"] = "播放声音并播报安德麦补给箱"
L["UNDERMINE_TRACK"] = "安德麦 - 追踪"
L["UNDERMINE_TRACK_DESC"] = "在 /rct 输出中显示安德麦补给箱"
L["UNDERMINE_WARN"] = "安德麦 - 警告"
L["UNDERMINE_WARN_DESC"] = "在安德麦补给箱掉落前播放声音并发出警告"

L["DF_ANNOUNCE"] = "巨龙时代 - 播报"
L["DF_ANNOUNCE_DESC"] = "播放声音并播报巨龙时代补给箱"
L["DF_TRACK"] = "巨龙时代 - 追踪"
L["DF_TRACK_DESC"] = "在 /rct 输出中显示巨龙时代补给箱"
L["DF_WARN"] = "巨龙时代 - 警告"
L["DF_WARN_DESC"] = "在巨龙时代补给箱掉落前播放声音并发出警告"

L["TWW_ANNOUNCE"] = "地心之战 - 播报"
L["TWW_ANNOUNCE_DESC"] = "播放声音并播报地心之战补给箱"
L["TWW_TRACK"] = "地心之战 - 追踪"
L["TWW_TRACK_DESC"] = "在 /rct 输出中显示地心之战补给箱"
L["TWW_WARN"] = "地心之战 - 警告"
L["TWW_WARN_DESC"] = "在地心之战补给箱掉落前播放声音并发出警告"

L["DRGF_ANNOUNCE"] = "巨龙时代 - 播报"
L["DRGF_ANNOUNCE_DESC"] = "播放声音并播报巨龙补给箱"
L["DRGF_TRACK"] = "巨龙时代 - 追踪" 
L["DRGF_TRACK_DESC"] = "在 /rct 输出中显示巨龙补给箱"
L["DRGF_WARN"] = "巨龙时代 - 警告"
L["DRGF_WARN_DESC"] = "在巨龙补给箱掉落前播放声音并发出警告"

L["MID_ANNOUNCE"] = "至暗之夜 - 播报"
L["MID_ANNOUNCE_DESC"] = "播放声音并播报至暗之夜补给箱"
L["MID_TRACK"] = "至暗之夜 - 追踪"
L["MID_TRACK_DESC"] = "在 /rct 输出中显示至暗之夜补给箱"
L["MID_WARN"] = "至暗之夜 - 警告"
L["MID_WARN_DESC"] = "在至暗之夜补给箱掉落前播放声音并发出警告"

-- Sound Settings
L["WARNING_SOUND"] = "警告音效"
L["WARNING_SOUND_DESC"] = "为补给箱警告启用声音提醒"

-- Background Settings
L["BACKGROUND_COLOR"] = "背景颜色"
L["BACKGROUND_COLOR_DESC"] = "设置框体的背景颜色"

-- Staleness Settings
L["STALENESS"] = "数据过期时间"
L["STALENESS_DESC"] = "数据在移除前可以保留多久（分钟）"
L["ALLOWED_MISSED_TIMERS"] = "允许的漏记计时器次数"
L["VERIFY_SHARD"] = "验证位面"
L["VERIFY_SHARD_DESC"] = "验证补给箱所在的位面 ID"

-- Timer Options
L["CRATE_TIMER_BAR_OPTIONS"] = "补给箱计时条选项"
L["TIMER_OPTIONS"] = "计时器选项"
L["TIMER_OPTIONS_DESC"] = "配置 Hated Crate Tracker 的计时器选项"
L["TIMER_BAR_FONT_SIZE"] = "计时条字号"
L["TIMER_BAR_FONT_SIZE_DESC"] = "设置补给箱计时条的字体大小"

-- Combat Settings
L["COMBAT_DISABLE"] = "战斗中禁用"
L["COMBAT_DISABLE_DESC"] = "战斗中禁用插件功能"

-- TomTom Integration
L["ENABLE_TOMTOM"] = "启用 TomTom"
L["ENABLE_TOMTOM_DESC"] = "启用 TomTom 航路点集成"

-- About Section
L["ABOUT"] = "关于"
L["ABOUT_DESC"] = "关于本插件的信息"
L["SUPPORT_TITLE"] = "加入 Discord 上的支持者"
L["SUPPORT_DESC"] = "Hated Gaming 的月度支持者"
L["SUPPORT_MESSAGE"] = "别做讨厌鬼！！加入社区！- Hated Gaming 的 Curseforge 页面"

-- Command Help
L["HELP_HEADER"] = "Hated Crate Tracker 命令："
L["HELP_SPOT"] = "/rct spot - 手动标记一个补给箱。"
L["HELP_CENTER"] = "/rct center - 将主框体居中。"
L["HELP_HELP"] = "/rct help - 显示此帮助信息。"
L["HELP_RDYZ"] = "/rct rdyz - 向其他用户请求最近的补给箱。"
L["RDYZ"] = "向团队队长请求补给箱计时器。"
L["HELP_SHARE"] = "/rct share - 与其他用户分享插件信息。"

-- Command Responses
L["RDYZ_RESPONSE"] = "你太棒了！这是你的计时器……"

-- Addon Advertisement
L["ADDON_ADVERTISEMENT"] = "Hated Crate Tracker by Rdy @ Hated Gaming：「要被讨厌！不要只是玩，要统治。」追踪补给箱、同步团队、记录计时器，与 Hated Gaming 一起制霸战争模式 - 记住孩子们，如果不是 Hated，就不值得。现已在 Curseforge 上架！"

-- Bounty Hunter Messages
L["BOUNTY_ALLIANCE"] = "Hated Gaming 赏金猎人 - 联盟悬赏出现在你的区域 @ %s，%s"
L["BOUNTY_HORDE"] = "Hated Gaming 赏金猎人 - 部落悬赏出现在你的区域 @ %s，%s"

-- Error Messages
L["ADDON_NOT_FOUND"] = "未找到 RdysCrateTracker 插件。请确保它已加载。"

-- Test Messages
L["TEST_MESSAGE"] = "测试消息"

-- Timer and Status Messages
L["NEXT_CRATE"] = "下一个补给箱：%s - %s，%s 后"
L["WARNING_CRATE_IMMINENT"] = "警告：补给箱即将落地："

-- Font Options
L["FONTS"] = {
    ["Fonts\\FRIZQT__.TTF"] = "Friz Quadrata TT",
    ["Fonts\\ARIALN.TTF"] = "Arial Narrow",
    ["Fonts\\skurri.ttf"] = "Skurri",
    ["Fonts\\MORPHEUS.ttf"] = "Morpheus",
    ["Interface\\AddOns\\RCT\\fonts\\PT_Sans_Narrow_Bold.ttf"] = "PT Sans Narrow Bold",
}

-- Window Labels and Timer Format
L["WINDOW_LABEL"] = "%i. %s - %s - %ix - "
L["WINDOW_TIMER"] = "%s"

-- Communications
L["RAID_TOKEN_NOT_RECEIVED"] = "尝试 %d 次后仍未收到团队令牌；已抑制进一步请求（%d 分钟冷却）。"
L["BROADCASTED_ALERT"] = "已广播区域警报："

-- Debug Messages  
L["ZONE_UPDATE"] = "区域更新：map=%d → normalized=%d"

-- Addon Loading Messages
L["ADDON_LOADED"] = "Hated Crate Tracker 已加载！！"
L["TOGGLE_HELP"] = "使用 /rct toggle 显示/隐藏插件。"

-- Command Responses
L["ADDON"] = "插件"
L["ENABLED"] = "已启用"
L["DISABLED"] = "已禁用"
L["DEVELOPER_MODE"] = "开发者模式"
L["CLEARED_CRATE_DB"] = "已清空补给箱数据库。"
L["CLEARED_ALL_HISTORY"] = "已清空全部历史记录。"
L["MANUALLY_SPOTTED"] = "已手动标记一个补给箱。"
L["CENTERED_PANEL"] = "已居中标题面板。"

-- Help Commands
L["AVAILABLE_COMMANDS"] = "可用命令："
L["HELP_MAIN"] = "/rct - 打开/关闭插件。"
L["HELP_TOGGLE"] = "/rct toggle - 启用/禁用插件。"
L["HELP_DEBUG"] = "/rct debug - 切换调试模式。"
L["HELP_CLEAR"] = "/rct clear - 清空补给箱数据库。"
L["HELP_CLEARALL"] = "/rct clearall - 清空全部历史记录。"
L["HELP_DEL"] = "/rct del <arg> - 删除指定的补给箱。"

-- Frame Messages  
L["UNABLE_DETERMINE_MAP"] = "无法确定当前地图。无法分享位面 ID。"
L["SHARD_ID_MESSAGE"] = "位面 ID：%s（区域：%s，地图 ID：%s）"

-- UI Button Labels
L["MINIMIZE_BUTTON"] = "+/- "
L["OPTIONS_BUTTON"] = "Opt"
L["CLOSE_BUTTON"] = "X"
L["SYNC_BUTTON"] = "同步"
L["SHARE_BUTTON"] = "分享"

-- UI Tooltips
L["CLICK_SHARE_SHARD"] = "点击分享位面 ID"
L["SHARD_CONFIRMED"] = "已在此区域确认"
L["SHARD_UNCONFIRMED"] = "此处尚未确认 - 可能是从其他地方带过来的"
L["CLICK_SYNC_TIMERS"] = "点击同步补给箱计时器"
L["CLICK_SHARE_ADDON"] = "点击分享插件"

-- Options Labels
L["PREDICTION"] = "预测"
L["PREDICTION_DESC"] = "启用或禁用落点预测"
L["BOUNTY_HUNTER"] = "赏金猎人"
L["BOUNTY_HUNTER_DESC"] = "启用或禁用赏金猎人功能"
L["TOMTOM_INTEGRATION"] = "TomTom 集成"
L["TOMTOM_INTEGRATION_DESC"] = "除默认小地图航路点外，还将补给箱航路点加入 TomTom（如已安装），以使用其屏幕箭头"
L["DEVELOPER_MODE_DESC"] = "启用开发者模式以进行测试"
L["DISABLE_PVP"] = "PvP 中禁用"
L["DISABLE_PVP_DESC"] = "在竞技场/战场/地下城/团队副本中停止插件工作"
L["RESET_DESC"] = "将插件设置重置为默认值"
L["TEST"] = "测试"
L["TEST_DESC"] = "测试插件功能"
L["SCALE_UPDATED"] = "Hated Gaming Crate Tracker：缩放已更新"
L["BACKGROUND_COLOR_PICKER_DESC"] = "选择背景颜色"
L["CRATE_TRACKING"] = "补给箱追踪"
L["CRATE_TRACKING_DESC"] = "与补给箱追踪相关的设置"
L["ZONE_MANAGEMENT"] = "区域追踪"
L["ZONE_MANAGEMENT_DESC"] = "添加、移除和调整要监视补给箱的区域"
L["WINDOW_SETTINGS"] = "窗口"
L["WINDOW_SETTINGS_DESC"] = "追踪器窗口的位置和外观"
L["FRAME_STRATA"] = "层级（框体 strata）"
L["FRAME_STRATA_DESC"] = "窗口绘制所在的层级。如果其他框体遮挡追踪器，请提高它；如果追踪器遮挡了你需要的内容，请降低它。"
L["DOCK_EXPAND"] = "显示追踪器"
L["DOCK_COLLAPSE"] = "将追踪器隐藏到屏幕外"
L["HELP_DOCK"] = "/rct dock left|right|top|bottom|off - 将窗口停靠到屏幕边缘。"

-- Dragonflight Options
L["DRAGONFLIGHT_ANNOUNCE"] = "巨龙时代 - 播报"
L["DRAGONFLIGHT_ANNOUNCE_DESC"] = "播放声音并播报巨龙时代补给箱"
L["DRAGONFLIGHT_TRACK"] = "巨龙时代 - 追踪"
L["DRAGONFLIGHT_TRACK_DESC"] = "在 /rct 输出中显示巨龙时代补给箱"
L["DRAGONFLIGHT_WARN"] = "巨龙时代 - 警告"
L["DRAGONFLIGHT_WARN_DESC"] = "在巨龙时代补给箱掉落前播放声音并发出警告"

-- Midnight Options
L["MIDNIGHT_ANNOUNCE"] = "至暗之夜 - 播报"
L["MIDNIGHT_ANNOUNCE_DESC"] = "播放声音并播报至暗之夜补给箱"
L["MIDNIGHT_TRACK"] = "至暗之夜 - 追踪"
L["MIDNIGHT_TRACK_DESC"] = "在 /rct 输出中显示至暗之夜补给箱"
L["MIDNIGHT_WARN"] = "至暗之夜 - 警告"
L["MIDNIGHT_WARN_DESC"] = "在至暗之夜补给箱掉落前播放声音并发出警告"

-- Support and Community
L["SUPPORT_HATEDGAMING"] = "支持 Hated Gaming"
L["SUPPORT_HELP_DESC"] = "支持 Hated Crate Tracker 与 Hated Gaming 的方式"
L["SUPPORT_HATEDGAMING_DESC"] = "支持 Hated Gaming 和 Hated Crate Tracker"
L["DONATE"] = "捐赠"
L["DONATE_DESC"] = "通过捐赠支持 Hated Gaming"
L["JOIN_MY_DISCORD"] = "加入我的 Discord"
L["JOIN_DISCORD_DESC"] = "加入 Hated Gaming/RdyGaming 战团 Discord 社区"
L["COMMUNITY_MESSAGE"] = "别做讨厌鬼！！加入社区！- Hated Gaming 的 Curseforge 页面"
L["JOIN_SUPPORTERS"] = "加入 Discord 上的支持者"
L["MONTHLY_SUPPORTERS_DESC"] = "Hated Gaming 的月度支持者"

-- Crate Farming Guide
L["CRATE_FARMING_HOWTO"] = "刷补给箱：操作指南"
L["OFFICIAL_GUIDELINES"] = "Hated Gaming 官方战争补给箱指南"
L["OFFICIAL_GUIDELINES_DESC"] = "Hated Gaming 官方战争补给箱指南"
L["OFFICIAL_GUIDELINES_SHORT"] = "官方战争补给箱指南。"
-- Data Sharing (drop-point export/import)
L["DATA_SHARING"] = "数据共享"
L["DATA_SHARING_DESC"] = "以字符串形式导出和导入已掌握的补给箱掉落点。"
L["DATA_SHARING_ABOUT"] = "以字符串形式与其他玩家分享你已掌握的补给箱掉落点。导入只会添加你尚未拥有的点 - 绝不会更改或删除你自己掌握的点，重复项会被忽略。"
L["EXPORT"] = "导出"
L["EXPORT_SCOPE"] = "范围"
L["EXPORT_ALL_ZONES"] = "所有区域"
L["EXPORT_THIS_ZONE"] = "仅此区域"
L["EXPORT_MINE_ONLY"] = "仅自己掌握的点"
L["EXPORT_GENERATE"] = "生成导出字符串"
L["EXPORT_READY"] = "导出就绪："
L["EXPORT_NOTHING"] = "没有可导出的内容："
L["EXPORT_STRING"] = "导出字符串 - 点击输入框，Ctrl+A、Ctrl+C（忽略「接受」）"
L["IMPORT"] = "导入"
L["IMPORT_STRING"] = "在此粘贴导出字符串"
L["IMPORT_RUN"] = "导入"
L["IMPORT_FAILED"] = "导入失败："
L["IMPORT_DONE"] = "从 %s 导入：在 %d 个区域新增 %d 个点；%d 个已知%s。"
L["IMPORTED_DATA"] = "已导入数据"
L["IMPORTED_COUNT"] = "当前保存了 %d 个区域的 %d 个导入点。"
L["IMPORTED_WIPE"] = "移除所有导入点"
L["IMPORTED_WIPE_CONFIRM"] = "移除所有导入的掉落点？你自己掌握的点会保留。"
L["IMPORTED_WIPED"] = "已移除 %d 个导入的掉落点。"
L["IMPORT_HELP"] = "粘贴字符串后点击输入框的「接受」按钮（或按回车）即可导入。"
L["CRATE_ETA"] = "补给箱预计落地时间"
L["CRATE_ETA_DESC"] = "当补给箱出现在你的区域时，在追踪器下方显示「约 M:SS 后落地」条。在该区域观察到足够多的落地记录前显示「学习中」。"
L["CRATE_ETA_ANNOUNCE"] = "队长点击播报预计落地时间"
L["CRATE_ETA_ANNOUNCE_DESC"] = "允许队长左键点击预计落地时间条，向团队/小队播报「战争补给箱约 M:SS 后落地」。非队长点击无效。"

-- Hated SVG window
L["TRACKER_TITLE"] = "Hated Crate Tracker"
L["ROLE_SOLO"] = "单人"
L["ROLE_RAID_LEAD"] = "团队队长"
L["ROLE_PARTY_LEAD"] = "小队队长"
L["ROLE_RAID_ASSIST"] = "团队助理"
L["ROLE_RAID_MEMBER"] = "团队成员"
L["ROLE_PARTY_MEMBER"] = "在小队中"
L["ONE_ZONE"] = "1 个区域"
L["N_ZONES"] = "%d 个区域"
L["OPTIONS_TIP"] = "区域、警报、音效、窗口"
L["CLOSE_TIP"] = "输入 /rct 可重新打开"
L["SHARD_CHIP"] = "位面 %s"
L["ASK_BUTTON"] = "请求"
L["ASK_TIP_TITLE"] = "请求计时器"
L["ADD_BUTTON"] = "添加"
L["SUGGEST_ROW"] = "位面日志中有 %s · 位面 %s"
L["N_MISSED"] = "%d 次漏记"
L["SHARD_MISMATCH_TIP"] = "你当前位于位面 %s，此计时器属于位面 %s。"
L["LEARNING"] = "学习中"
L["ETA_ON_GROUND"] = "已落地"
L["ETA_CLICK_RW"] = "点击告知团队"
L["ETA_GRAB_IT"] = "快去拿"
L["ETA_GROUND_IN"] = "落地倒计时"
L["ETA_ANY_SECOND"] = "随时落地"
L["ETA_UNDER_CHUTE"] = "降落伞下方"
L["ETA_FLYING_TO_DROP"] = "正在飞往投放点"
L["ETA_LEARNING_SUB"] = "在此地看到几个补给箱后即可得出时间"
L["ETA_THEN_GROUND"] = "约 %s 后落地"
L["ETA_STILL_FLYING"] = "仍在飞入"
L["ETA_TIP_TITLE"] = "补给箱预计落地时间"
L["ETA_TIP_RW"] = "左键点击：向团队发出团队警告"
L["ETA_TIP_LEADS"] = "队长和助理可点击发出团队警告"
L["ETA_TIP_ENEMIES"] = "右侧数字是在此补给箱处看到的敌对玩家数量。"
L["RAIL_LOG"] = "位面日志"
L["RAIL_LOG_SUB"] = "你或你的公会见过的每个位面"
L["RAIL_LOCKED"] = "仅限团队队长。"
L["RAIL_LOCKED_PRINT"] = "该功能仅供团队队长使用。"
L["RAIL_TOGGLE_HIDE"] = "隐藏图标栏"
L["RAIL_TOGGLE_SHOW"] = "显示图标栏"

-- Honor and Conquest per hour
L["EARN_HONOR_UNIT"] = "荣誉/小时"
L["EARN_CONQUEST_UNIT"] = "征服/小时"
L["EARN_MINUTES"] = "%d 分钟"
L["EARN_HOURS"] = "%dh %dm"
L["EARN_TIP_TITLE"] = "每小时荣誉与征服"
L["EARN_TIP_BASIS"] = "按你最近 %s 的节奏推算一小时可获得多少。"
L["EARN_TIP_EARLY"] = "刚开始。等跑完一整轮补给箱再相信这些数字。"
L["EARN_TIP_HONOR"] = "本次会话荣誉"
L["EARN_TIP_CONQUEST"] = "本次会话征服"
L["EARN_TIP_SESSION"] = "会话时长"
L["EARN_TIP_RESET"] = "右键点击可重新开始。"

-- Addon check
L["CHECK_TITLE"] = "插件检查"
L["CHECK_SUB"] = "查看你的队伍中谁装有 Hated Crate Tracker"
L["CHECK_RAIL_SUB"] = "查看队伍中谁装有此插件"
L["CHECK_AGAIN"] = "再次检查"
L["CHECK_COUNT"] = "%d/%d 已安装"
L["CHECK_PENDING"] = "检查中……"
L["CHECK_MISSING"] = "未安装"
L["CHECK_OLD"] = "旧版本"
L["CHECK_OFF"] = "已关闭"
L["CHECK_OFFLINE"] = "离线"
L["CHECK_SOLO"] = "加入队伍后才能运行检查。"
L["CHECK_ALL"] = "所有人都已安装且为最新版本。"
L["CHECK_N_MISSING"] = "%d 人未安装"
L["CHECK_N_OUTDATED"] = "%d 人版本过旧"
L["CHECK_N_OFF"] = "%d 人已关闭"
L["CHECK_N_OFFLINE"] = "%d 人离线"
L["CHECK_TIP_MISSING"] = "没有回应。可能未安装插件，或该玩家位于副本中。"
L["CHECK_TIP_OLD"] = "装有插件，但版本早于插件检查功能。请对方更新。"
L["CHECK_TIP_OUTDATED"] = "装有插件，但有更新版本。请对方更新。"
L["CHECK_TIP_OFF"] = "装有插件，但用 /rct toggle 关闭了。"
L["CHECK_TIP_OFFLINE"] = "离线，暂时无法检查。"

-- How-to guide
L["HOWTO_TITLE"] = "使用说明"
L["HOWTO_SUB"] = "逐步讲解"
L["HOWTO_RAIL_SUB"] = "追踪器的逐步帮助"
L["HOWTO_SHOW_ME"] = "带我看看"
L["HOWTO_SHOW_ME_TIP"] = "打开该步骤的窗口并用箭头指向对应控件。"
L["HOWTO_BACK"] = "上一步"
L["HOWTO_NEXT"] = "下一步"
L["HOWTO_COUNTER"] = "%d/%d"
L["HOWTO_TIP_PREFIX"] = "提示：%s"
L["HOWTO_NUDGE"] = "第一次使用？输入 /rct guide，或点击追踪器侧栏的书本，查看逐步指南。"
L["HELP_GUIDE"] = "/rct guide - 打开使用指南。"
L["HOWTO_OPEN_TRACKER"] = "打开追踪器"
L["HOWTO_OPEN_OPTIONS"] = "打开设置"
L["HOWTO_OPEN_LOG"] = "打开位面日志"
L["HOWTO_OPEN_ABOUT"] = "打开关于页面"
L["HOWTO_TEST_ALERT"] = "显示测试警报"
L["HOWTO_HINT_DEFAULT"] = "当前没有可指向的内容。"
L["HOWTO_HINT_INSTANCE"] = "你在副本中时追踪器会暂停。"
L["HOWTO_HINT_ROWS"] = "目前还没有计时器。看到补给箱后，或在队伍中点击「请求」后，就会出现一行。"
L["HOWTO_HINT_ETA"] = "只有补给箱在你的区域时才会显示该条。"
L["HOWTO_HINT_PACE"] = "节奏线已关闭。在设置的「计时器」中开启。"
L["HOWTO_HINT_DOCK"] = "只有追踪器处于停靠状态时才显示拉手。请先拖到屏幕边缘。"
L["HOWTO_HINT_LOG"] = "副本中无法打开位面日志。"
L["HOWTO_HINT_LOG_EMPTY"] = "日志目前没有内容。看到补给箱后会显示条目。"
L["HOWTO_HINT_DEVTOOLS"] = "此工具随 Rdy's Dev Tools 一起安装，后者会与追踪器同时安装。请在插件列表中确认它已启用。"
L["HOWTO_HINT_CONTEST_OFF"] = "关闭「标记每个补给箱」时，此设置会隐藏。请先开启它。"

L["HOWTO_START_TITLE"] = "从这里开始"
L["HOWTO_START_INTRO"] = "Hated Crate Tracker 会在你刷的每个战争模式区域为战争补给箱计时。它能自动发现补给箱、为每个区域 countdown 下一次掉落，并与你的队伍共享所见。"
L["HOWTO_START_1"] = "输入 /rct 打开或关闭追踪器。/hct 效果相同。"
L["HOWTO_START_2"] = "每一行是一个区域。时钟 countdown 该区域下一次补给箱。"
L["HOWTO_START_3"] = "左上角的标签是你当前的位面。计时器只在与其位面相同时才有用。"
L["HOWTO_START_4"] = "侧边栏可打开位面日志、本指南和关于页面。团队队长还能在皇冠下获得更多工具。"
L["HOWTO_START_5"] = "齿轮可打开设置。将鼠标悬停在任何元素上可查看其用途。"
L["HOWTO_START_TIP"] = "补给箱只在战争模式的户外世界掉落。进入地下城、团队副本、遨游、战场和竞技场时追踪器会暂停。"

L["HOWTO_TIMERS_TITLE"] = "读懂计时器"
L["HOWTO_TIMERS_INTRO"] = "计时器行上的所有内容，从左到右。"
L["HOWTO_TIMERS_1"] = "彩色条纹和名称代表区域。图钉标记你所处的区域。"
L["HOWTO_TIMERS_2"] = "名称后的小数字是该计时器对应的位面。"
L["HOWTO_TIMERS_3"] = "时钟是距离下一次补给箱的时间。前面的 ~ 表示上一个补给箱是在落地后才被发现的，因此时间接近但不精确。"
L["HOWTO_TIMERS_4"] = "最后 15 秒时，行上会划过红色条纹，标题栏中的徽记会闪烁。"
L["HOWTO_TIMERS_5"] = "「漏记 2 次」表示此后该地已掉落两个补给箱但无人看到。时钟仍根据最后一次目击推算。漏记四次或更多时行会淡出。"
L["HOWTO_TIMERS_6"] = "将鼠标悬停在行上可查看详情。出现的垃圾桶图标可移除计时器，Shift + 右键也可以。"
L["HOWTO_TIMERS_7"] = "左键点击一行可呼叫该区域的下一次补给箱。队长和助理会发送给团队，其他人只在自己的聊天窗口看到。"
L["HOWTO_TIMERS_TIP"] = "时钟大小和区域颜色深浅可在「设置，计时器」中更改。"

L["HOWTO_SHARDS_TITLE"] = "位面"
L["HOWTO_SHARDS_INTRO"] = "战争模式会把每个区域分成称为位面的副本，补给箱只存在于它掉落所在的位面。区域对了、位面错了，就找不到补给箱。"
L["HOWTO_SHARDS_1"] = "标签显示你的位面。绿色对勾表示在此处直接读到；琥珀色沙漏表示数字是从别处带过来的，尚未确认。"
L["HOWTO_SHARDS_2"] = "要确认它，将鼠标悬停在任意 NPC 或生物上，或在几个姓名板旁站一会儿。"
L["HOWTO_SHARDS_3"] = "当你所在区域与某计时器的位面不同时，该行的位面数字会变成琥珀色并带 ! 前缀。"
L["HOWTO_SHARDS_4"] = "「位面不符时警告」会在你所处的位面与该区域计时器对应的位面不一致时提醒你。"
L["HOWTO_SHARDS_5"] = "点击标签可将你的位面发到队伍聊天。"
L["HOWTO_SHARDS_TIP"] = "加入队伍通常会将你转移到队长的位面，所以入队后再看一眼标签。"

L["HOWTO_DROP_TITLE"] = "补给箱掉落时"
L["HOWTO_DROP_INTRO"] = "从补给箱被呼叫那一刻起，你会看到和听到什么。"
L["HOWTO_DROP_1"] = "当补给箱被发现正在飞入时，你会听到警报，呼叫信息显示在屏幕中央。"
L["HOWTO_DROP_2"] = "补给箱在你的区域期间，追踪器下方会展开一条信息条。它会依次显示飞行中、降落伞下方和已落地，以及剩余时间。"
L["HOWTO_DROP_3"] = "在追踪器观察到该区域有几次补给箱落地之前，信息条会显示「学习中」。"
L["HOWTO_DROP_4"] = "开启「预测落点」可在飞机飞向的位置放置地图图钉。"
L["HOWTO_DROP_5"] = "开启后，队长的追踪器还会将预测落点和实际落点发给队伍，每个位置都带有大家可点击的地图图钉。"
L["HOWTO_DROP_6"] = "队长和助理可点击信息条，发出落地时间的团队警告。"
L["HOWTO_DROP_TIP"] = "警报的音效、字体、大小和位置在「设置，警报」中。点击「显示测试警报」可在移动时预览效果。"

L["HOWTO_GROUP_TITLE"] = "组队游玩"
L["HOWTO_GROUP_INTRO"] = "队伍中每个运行追踪器的人都会共享所见，因此一次目击就能传遍整个团队。"
L["HOWTO_GROUP_1"] = "加入队伍后，一旦对方的计时器到达，你的计时器就会切换为队长的。如果队长没装追踪器，你保留自己的。"
L["HOWTO_GROUP_2"] = "点击「请求」可再次向队长索取计时器。"
L["HOWTO_GROUP_3"] = "你担任队长时，旁边的按钮是「同步」，会将你的计时器发给所有人。队员看到的是「分享」，会在队伍中发一条插件信息。"
L["HOWTO_GROUP_4"] = "你们中任何一人发现的补给箱都会出现在所有人的追踪器上。"
L["HOWTO_GROUP_5"] = "队伍聊天中的呼叫只来自队长的追踪器，所以团队不会重复收到五行相同的信息。"
L["HOWTO_GROUP_TIP"] = "副本内插件消息不起作用，因此进入副本后不会同步。"

L["HOWTO_LOG_TITLE"] = "位面日志"
L["HOWTO_LOG_INTRO"] = "位面日志会记住你或你的公会见过补给箱的每个位面及时间。当某个位面暂时没人在追踪时，你可以从这里找回计时器。"
L["HOWTO_LOG_1"] = "从侧栏打开它。"
L["HOWTO_LOG_2"] = "每条记录是一个区域和一个位面，包含该地上次补给箱掉落时间和下次预计时间。"
L["HOWTO_LOG_3"] = "「你在这里」标记的是你当前所处位面的记录。"
L["HOWTO_LOG_4"] = "点击记录上的箭头可将该计时器放到追踪器上。在队伍中只有队长可以，所有人都会收到。"
L["HOWTO_LOG_5"] = "选择区域或输入位面编号可缩小列表范围。"
L["HOWTO_LOG_6"] = "「分享到公会」会将你的日志发给同样运行追踪器的公会成员。游戏过程中它也会自动分享。"
L["HOWTO_LOG_TIP"] = "可以拖动日志把它停放在任意位置。标题栏中的链接按钮会让它回到追踪器旁边。"

L["HOWTO_CONTEST_TITLE"] = "已获得、争夺中、已失去"
L["HOWTO_CONTEST_INTRO"] = "追踪器会统计每个补给箱处的敌对玩家数量，并用结果标记该区域的计时器。"
L["HOWTO_CONTEST_1"] = "当补给箱正在下落或落地后、且你靠近它时，你的游戏能看到的每个敌对玩家都会被计入一次。"
L["HOWTO_CONTEST_2"] = "实时计数显示在落地信息条右侧。"
L["HOWTO_CONTEST_3"] = "「已获得」表示你方拿到了补给箱。「争夺中」表示你方经过战斗后拿到。「已失去」表示对方拿到了。"
L["HOWTO_CONTEST_4"] = "该标记会一直显示在该区域的行上，直到下一次补给箱出现。"
L["HOWTO_CONTEST_5"] = "「争夺人数阈值」设置需要多少敌对玩家才判定为一场战斗。"
L["HOWTO_CONTEST_TIP"] = "你必须靠近补给箱，游戏才能看到敌人。你的队伍会共享各自统计的数量。"

L["HOWTO_PACE_TITLE"] = "荣誉与征服节奏"
L["HOWTO_PACE_INTRO"] = "位面标签下方的行显示按你当前节奏推算一小时可获得多少。"
L["HOWTO_PACE_1"] = "它统计你获得的所有荣誉和征服，不管来源：补给箱、击杀或任务。"
L["HOWTO_PACE_2"] = "将鼠标悬停可查看本次会话的总量和持续时间。"
L["HOWTO_PACE_3"] = "右键点击可重新开始。"
L["HOWTO_PACE_4"] = "计时器折叠后它仍留在屏幕上。「设置，计时器」中的「显示每小时节奏」可将其关闭。"
L["HOWTO_PACE_TIP"] = "补给箱的收益是集中发放的，跑完一整轮再相信这些数字。"

L["HOWTO_DOCK_TITLE"] = "移动与停靠"
L["HOWTO_DOCK_INTRO"] = "把追踪器放在你觉得合适的位置，或贴到屏幕边缘。"
L["HOWTO_DOCK_1"] = "可将追踪器拖到任意位置。拖到屏幕边缘放手即可停靠。"
L["HOWTO_DOCK_2"] = "停靠后的追踪器会出现红色拉手。点击拉手可将追踪器滑出屏幕或滑回。"
L["HOWTO_DOCK_3"] = "将停靠的追踪器拖走即可重新浮动。右键点击追踪器可让它回到上次停靠的边缘。"
L["HOWTO_DOCK_4"] = "标题栏中的箭头可折叠计时器，只留下顶部信息条。"
L["HOWTO_DOCK_5"] = "缩放、层级和背景颜色在「设置，窗口」中。"
L["HOWTO_DOCK_TIP"] = "找不到窗口？/rct center 会把它放回屏幕中央。"

L["HOWTO_ZONES_TITLE"] = "区域"
L["HOWTO_ZONES_INTRO"] = "选择追踪器监视哪些区域，以及每个区域要做什么。"
L["HOWTO_ZONES_1"] = "「设置，区域」中为追踪器监视的每个区域提供一张卡片。"
L["HOWTO_ZONES_2"] = "每张卡片有三个开关。「追踪」显示该区域的计时器。「警告」和「播报」控制该区域的警报与团队呼叫。"
L["HOWTO_ZONES_3"] = "「全部开启」和「全部关闭」可一次性切换所有区域的开关。"
L["HOWTO_ZONES_4"] = "添加、移除和调整区域时间已锁定。请先翻转页面顶部的锁。关闭窗口时它会再次锁定。"
L["HOWTO_ZONES_5"] = "「添加我所在的区域」是添加新区域的快捷方式。"
L["HOWTO_ZONES_TIP"] = "区域的重生时间只是一个起点。游戏中实际观察到的时间优先。"

L["HOWTO_LEAD_TITLE"] = "带领团队"
L["HOWTO_LEAD_INTRO"] = "担任队长时，侧栏皇冠下的工具会解锁。"
L["HOWTO_LEAD_1"] = "团队队长工具：以团队警告呼叫下一个区域、编排轮换并发送、同步计时器，或清除所有人的计时器并发送你的。"
L["HOWTO_LEAD_2"] = "XJump 会将你的团队写入名单，在你跳到另一个位面后邀请所有人回来。"
L["HOWTO_LEAD_3"] = "「地面标记」会打开一排世界标记，用于标注落点。"
L["HOWTO_LEAD_4"] = "「插件检查」列出队伍中谁装了追踪器、谁版本过旧、谁关闭了插件。"
L["HOWTO_LEAD_5"] = "当位面日志知道你所在位面的计时器而追踪器没有时，会出现一条粉色记录。点击「添加」，全队都会收到。"
L["HOWTO_LEAD_6"] = "左键点击计时器行会以团队警告播报该区域的下一次补给箱。助理也可以这样做。"
L["HOWTO_LEAD_TIP"] = "自动呼叫只来自队长的追踪器。如果队长没有安装，就没人能收到。"

L["HOWTO_MORE_TITLE"] = "其他须知"
L["HOWTO_MORE_INTRO"] = "命令、限制以及出现异常时要检查的内容。"
L["HOWTO_MORE_1"] = "/rct 打开和关闭追踪器。/rct options 打开设置。/rct guide 打开本指南。"
L["HOWTO_MORE_2"] = "/rct help 列出所有命令。/rct toggle 可整体关闭和开启插件。"
L["HOWTO_MORE_3"] = "进入副本后不会追踪或共享任何内容。"
L["HOWTO_MORE_4"] = "计时器看起来不对？先检查你的位面。然后在队伍中点击「请求」，或删除该行，让下一次目击重新设定。"
L["HOWTO_MORE_5"] = "「设置，共享」可将你掌握的落点以字符串形式与其他玩家交换。"
L["HOWTO_MORE_6"] = "「设置，配置文件」让你的角色共用一套配置或各自独立。"

-- Contested or owned
L["CONTESTED"] = "争夺中"
L["OWNED"] = "已获得"
L["LOST"] = "已失去"
L["CONTESTED_TIP"] = "我们拿到了上一个补给箱，但经过了战斗：在箱处看到 %d 名敌对玩家。"
L["OWNED_TIP"] = "我们拿到了上一个补给箱：在箱处看到 %d 名敌对玩家。"
L["LOST_TIP"] = "对方拿到了上一个补给箱：在箱处看到 %d 名敌对玩家。"
L["CONTEST_DONE"] = "%s 补给箱被夺取，但有争夺：看到 %d 名敌对玩家。"
L["OWNED_DONE"] = "%s 补给箱已获得：看到 %d 名敌对玩家。"
L["LOST_DONE"] = "%s 补给箱被对方夺得：看到 %d 名敌对玩家。"
L["SHOW_CONTEST"] = "已获得、争夺中或已失去"
L["SHOW_CONTEST_DESC"] = "在补给箱下落和落地期间统计箱处的敌对玩家数量，并标记该区域的计时器：你方拿到时为「已获得」，你方经过战斗拿到时为「争夺中」，对方拿到时为「已失去」。你必须靠近补给箱，客户端才能看到敌人；队伍会共享各自统计的数量。"
L["CONTEST_MIN"] = "争夺人数阈值"
L["CONTEST_MIN_DESC"] = "需要多少名不同的敌对玩家出现，才将该补给箱判定为争夺中，或在对方拿到时判定为已失去。"
