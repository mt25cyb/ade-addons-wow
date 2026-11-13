-- 简体中文覆盖（仅当客户端语言为 zhCN）。
local ACM = _G.adeChatMod or {}
_G.adeChatMod = ACM
local L = ACM.L or {}
ACM.L = L
if GetLocale() ~= "zhCN" then return end

L.ADDON_TITLE = "adeChatMod"
L.TAB_SETTINGS = "设置"
L.TAB_CONFIG = "配置管理"
L.TAB_ABOUT = "关于"

L.HEADING_APPEARANCE = "外观"
L.HEADING_THEME = "主题色"
L.HEADING_CHANNELS = "频道"
L.HEADING_POSITION = "位置"
L.HEADING_FALLBACK = "备用位置"
L.HEADING_MINIMAP = "小地图按钮"

L.LABEL_COLOR_SCHEME = "按钮配色"
L.LABEL_BTN_SIZE = "按钮大小"
L.LABEL_BTN_GAP = "按钮间距"
L.LABEL_FONT_SIZE = "字号"
L.LABEL_WORLD_CHANNEL = "世界频道名称"
L.LABEL_TRADE_CHANNEL = "交易频道名称"
L.LABEL_AUTO_JOIN = "自动加入世界频道"
L.LABEL_AUTO_JOIN_DELAY = "自动加入延迟"
L.LABEL_ATTACH_TARGET = "吸附框体（全局名称）"
L.LABEL_ATTACH_POINT = "快捷条锚点"
L.LABEL_ATTACH_RELATIVE_POINT = "目标锚点"
L.LABEL_ATTACH_X = "水平偏移"
L.LABEL_ATTACH_Y = "垂直偏移"
L.LABEL_FALLBACK_X = "备用水平偏移"
L.LABEL_FALLBACK_Y = "备用垂直偏移"
L.LABEL_BAR_SHOWN = "显示快捷条"
L.LABEL_MINIMAP_SHOWN = "显示小地图按钮"
L.LABEL_RESET_MINIMAP_POS = "重置按钮位置"
L.LABEL_THEME_COLOR = "主题色"
L.NOTE_THEME_COLOR = "点击修改主题色（默认黄色）"

L.CHOICE_COLORFUL = "彩色"
L.CHOICE_DEFAULT = "默认金色"

L.NOTE_APPEARANCE = "修改即时生效。按钮配色在彩色方案与单色金色方案之间切换。"
L.NOTE_CHANNELS = "频道名称通过 GetChannelName 匹配。自动加入仅在真正登录时执行，/reload 不触发。"
L.NOTE_POSITION = "吸附框体填全局帧名（例如 ChatFrame1EditBox）；不存在或隐藏时使用备用位置。"
L.NOTE_FALLBACK = "备用偏移相对于 UIParent 的 BOTTOMLEFT 角。"
L.NOTE_MINIMAP = "小地图按钮：左键显示/隐藏快捷条，右键打开设置界面，拖拽沿圆周移动。按钮隐藏后可用 /acm minimap 找回。"

L.TT_LEFT = "左键：显示/隐藏快捷条"
L.TT_RIGHT = "右键：打开设置界面"
L.TT_DRAG = "拖拽：调整按钮位置"

L.RESET_CONFIRM = "将 adeChatMod 的全部设置恢复为默认？"
L.MSG_RESET = "设置已恢复为默认值。"
L.MSG_MINIMAP_SHOWN = "小地图按钮已显示。"
L.MSG_MINIMAP_HIDDEN = "小地图按钮已隐藏，可用 /acm minimap 重新显示。"
L.CMD_HELP = "可用命令：/acm、/acm about、/acm minimap、/acm reset"
L.STATUS_ATTACH_OK = "已找到吸附框体，快捷条正吸附在其上。"
L.STATUS_ATTACH_MISSING = "吸附框体不存在或处于隐藏状态，正在使用备用位置。"
L.STATUS_ATTACH_EMPTY = "吸附框体为空，正在使用备用位置。"

-- 关于页正文：结构化 ABOUT_* 键，由 AF.Template.AboutPage.Build 消费（库 Template/AboutPage.lua 规格）。
-- 颜色由 AF.AccentHex() 生成，普通文本行禁止写死 |cff...|r 转义。
L.ABOUT_DESC_1 = "紧凑的聊天频道快捷条，附带频道名缩写、小地图按钮与设置界面。"
L.ABOUT_FEATURE_1_LABEL = "频道快捷条"
L.ABOUT_FEATURE_1 = "12 个频道/功能按钮；可吸附到任意全局框体并带偏移，目标缺失时使用备用位置。"
L.ABOUT_FEATURE_2_LABEL = "频道名缩写"
L.ABOUT_FEATURE_2 = "Hook ChatFrameN.AddMessage，把频道名显示为短标签（如 [世界]）。"
L.ABOUT_FEATURE_3_LABEL = "设置"
L.ABOUT_FEATURE_3 = "设置即时生效，按账号保存在 adeChatModDB。"
L.ABOUT_COMMANDS = "/acm  —  打开/关闭设置界面\n/acm about  —  打开本页\n/acm minimap  —  显示/隐藏小地图按钮\n/acm reset  —  恢复默认设置（确认弹窗）\n/adechatmod 与 /acm 等效。"
L.ABOUT_AUTHOR = "ADE"
L.ABOUT_CREDITS_TITLE = "致谢"
L.ABOUT_CREDITS = "ChannelBar 作者 CHANGEEN（MIT）；设置界面与小地图按钮基于 PrimeTooltip（PrimeCraze）。"
L.ABOUT_LICENSE = "以 MIT 许可证发布。"
L.ABOUT_NOTES = "基于 ade_AddonFramework 构建：窗口、表单行、关于页与主题色均来自库模板。"
