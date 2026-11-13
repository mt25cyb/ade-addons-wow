-- 简体中文覆盖（仅当客户端语言为 zhCN）。
local ADT = _G.adeTooltip or {}
_G.adeTooltip = ADT
local L = ADT.L or {}
ADT.L = L
if GetLocale() ~= "zhCN" then return end

L.ADDON_TITLE = "adeTooltip"
L.TAB_GENERAL = "常规"
L.TAB_UNIT = "单位"
L.TAB_ITEM = "物品"
L.TAB_SPELL = "法术"
L.TAB_OTHER = "其他"
L.TAB_ANCHOR = "锚点"
L.TAB_CONFIG = "配置管理"
L.TAB_ABOUT = "关于"

L.HEADING_LAYOUT = "排版"
L.HEADING_APPEARANCE = "外观"
L.HEADING_ITEM = "物品"

L.LABEL_USE_PRETTY = "使用新版排版"
L.NOTE_USE_PRETTY = "开启：PrettyTooltip 风格面板；关闭：MiliUI 经典排版（修改原生行）。关闭时，仅对新版排版生效的选项会置为禁用。"
L.LABEL_SCALE = "整体缩放"
L.LABEL_THEME_COLOR = "主题色"
L.NOTE_THEME_COLOR = "点击修改主题色（默认黄色）"
L.LABEL_TWO_STAGE = "两段式呈现（物品/法术）"
L.NOTE_TWO_STAGE = "把原生 tooltip 整体拆成两段，其他插件的信息并入下面那段。仅对新版排版生效。"
L.NOTE_PENDING = "本页选项将在后续阶段接入（见开发计划 P2–P7）。"
L.LABEL_MINIMAP_SHOWN = "显示小地图按钮"

L.PREVIEW_TITLE = "预览区"
L.PREVIEW_NOTE = "真实分类样例（含点击定位设置项）将在 P7 接入，当前为骨架占位。"
L.PREVIEW_PAGE = "当前页：%s"

L.TT_LEFT = "左键：打开设置界面"
L.TT_DRAG = "拖拽：调整按钮位置"

L.RESET_CONFIRM = "将 adeTooltip 当前配置档的全部设置恢复为默认？"
L.MSG_RESET = "设置已恢复为默认值。"
L.MSG_MINIMAP_SHOWN = "小地图按钮已显示。"
L.MSG_MINIMAP_HIDDEN = "小地图按钮已隐藏，可用 /atip minimap 重新显示。"
L.MSG_CONFLICT = "检测到 MiliUI_Tooltip 已加载，不建议同时运行两个 tooltip 插件。"
L.CMD_HELP = "可用命令：/adeTooltip、/atip、/adeTooltip about、/adeTooltip minimap、/adeTooltip reset"

-- 关于页正文：结构化 ABOUT_* 键，由 AF.Template.AboutPage.Build 消费。
L.ABOUT_CMD_LABEL = "命令"
L.ABOUT_AUTHOR_LABEL = "作者"
L.ABOUT_DESC_1 = "ADE v6 工具提示美化：以 MiliUI_Tooltip 为蓝本，新版排版采用 PrettyTooltip 观感，并吸收 PrimeTooltip 的增量能力。"
L.ABOUT_FEATURE_1_LABEL = "双排版"
L.ABOUT_FEATURE_1 = "Pretty 风格新版面板 / MiliUI 经典排版（修改原生行），由「使用新版排版」一键切换。"
L.ABOUT_FEATURE_2_LABEL = "两段式"
L.ABOUT_FEATURE_2 = "物品/法术 tooltip 原生整体拆两段，其他插件的信息并入下面那段。"
L.ABOUT_FEATURE_3_LABEL = "设置"
L.ABOUT_FEATURE_3 = "多选项页 8 页布局、配置档管理与可停靠预览组件。"
L.ABOUT_COMMANDS = "/adeTooltip  —  打开/关闭设置界面\n/atip  —  与 /adeTooltip 等效\n/adeTooltip about  —  打开本页\n/adeTooltip minimap  —  显示/隐藏小地图按钮\n/adeTooltip reset  —  恢复当前配置档默认（确认弹窗）"
L.ABOUT_AUTHOR = "ADE"
L.ABOUT_CREDITS_TITLE = "致谢"
L.ABOUT_CREDITS = "蓝本 MiliUI_Tooltip；新版观感与修饰键 PrettyTooltip；增量能力 PrimeTooltip。"
L.ABOUT_LICENSE = "以 MIT 许可证发布。"
L.ABOUT_NOTES = "基于 ade_AddonFramework（b010）构建。b001 为 P0/P1 骨架，渲染管线按 P2–P9 推进。"
