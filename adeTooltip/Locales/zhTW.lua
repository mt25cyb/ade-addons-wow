local ADT = _G.adeTooltip or {}
_G.adeTooltip = ADT
local L = ADT.L or {}
ADT.L = L

L.ADDON_TITLE = "adeTooltip"
L.TAB_SETTINGS = "設定"
L.TAB_MINIMAP = "小地圖"
L.TAB_PREVIEW = "預覽"
L.TAB_ABOUT = "關於"

L.HEADING_GENERAL = "通用"
L.LABEL_USE_NEW_LAYOUT = "使用新版排版"
L.NOTE_USE_NEW_LAYOUT = "開啟後改用重繪面板（後續階段）；關閉則使用經典路線（原地修飾原生提示）。"
L.LABEL_SCALE = "整體縮放"
L.LABEL_THEME_COLOR = "主題色"

L.HEADING_MINIMAP = "小地圖"
L.LABEL_MINIMAP_SHOWN = "顯示小地圖按鈕"
L.LABEL_MINIMAP_ANGLE = "小地圖按鈕角度"

L.PREVIEW_NOTE = "點擊下方按鈕，在獨立提示框中預覽樣例（經典路線落地後將即時反映修飾效果）。"
L.PREVIEW_BTN_UNIT = "預覽：玩家單位"
L.PREVIEW_BTN_ITEM = "預覽：物品"
L.PREVIEW_BTN_SPELL = "預覽：法術"

L.MSG_MINIMAP_SHOWN = "小地圖按鈕已顯示。"
L.MSG_MINIMAP_HIDDEN = "小地圖按鈕已隱藏。輸入 /adt minimap 再次顯示。"
L.CMD_HELP = "指令：/adt, /adt about, /adt minimap"

L.ABOUT_DESC_1 = "adeTooltip：魔獸世界提示框增強（經典路線優先）。"
L.ABOUT_FEATURE_1_LABEL = "經典路線"
L.ABOUT_FEATURE_1 = "原地修飾原生提示（職業色 / 反應色 / 裝等 / 血條等），逐項實機落地。"
L.ABOUT_FEATURE_2_LABEL = "新版排版"
L.ABOUT_FEATURE_2 = "可選的重繪面板（後續階段，目前僅預留介面）。"
L.ABOUT_AUTHOR = "ade"
L.ABOUT_LICENSE = "License: MIT"
L.ABOUT_COMMANDS = "/adt, /adt about, /adt minimap"
