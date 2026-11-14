local ADT = _G.adeTooltip or {}
_G.adeTooltip = ADT
local L = ADT.L or {}
ADT.L = L

L.ADDON_TITLE = "adeTooltip"
L.TAB_SETTINGS = "设置"
L.TAB_MINIMAP = "小地图"
L.TAB_PREVIEW = "预览"
L.TAB_ABOUT = "关于"

L.HEADING_GENERAL = "通用"
L.LABEL_USE_NEW_LAYOUT = "使用新版排版"
L.NOTE_USE_NEW_LAYOUT = "开启后改用重绘面板（后续阶段）；关闭则使用经典路线（原地修饰原生提示）。"
L.LABEL_SCALE = "整体缩放"
L.LABEL_THEME_COLOR = "主题色"

L.HEADING_MINIMAP = "小地图"
L.LABEL_MINIMAP_SHOWN = "显示小地图按钮"
L.LABEL_MINIMAP_ANGLE = "小地图按钮角度"

L.PREVIEW_NOTE = "点击下方按钮，在独立提示框中预览样例（经典路线落地后将实时反映修饰效果）。"
L.PREVIEW_BTN_UNIT = "预览：玩家单位"
L.PREVIEW_BTN_ITEM = "预览：物品"
L.PREVIEW_BTN_SPELL = "预览：法术"

L.MSG_MINIMAP_SHOWN = "小地图按钮已显示。"
L.MSG_MINIMAP_HIDDEN = "小地图按钮已隐藏。输入 /adt minimap 再次显示。"
L.CMD_HELP = "命令：/adt, /adt about, /adt minimap"

L.ABOUT_DESC_1 = "adeTooltip：魔兽世界提示框增强（经典路线优先）。"
L.ABOUT_FEATURE_1_LABEL = "经典路线"
L.ABOUT_FEATURE_1 = "原地修饰原生提示（职业色 / 反应色 / 装等 / 血条等），逐项实机落地。"
L.ABOUT_FEATURE_2_LABEL = "新版排版"
L.ABOUT_FEATURE_2 = "可选的重绘面板（后续阶段，当前仅预留接口）。"
L.ABOUT_AUTHOR = "ade"
L.ABOUT_LICENSE = "License: MIT"
L.ABOUT_COMMANDS = "/adt, /adt about, /adt minimap"
