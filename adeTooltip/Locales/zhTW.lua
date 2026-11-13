-- 繁體中文覆蓋（僅當客戶端語言為 zhTW）。
local ADT = _G.adeTooltip or {}
_G.adeTooltip = ADT
local L = ADT.L or {}
ADT.L = L
if GetLocale() ~= "zhTW" then return end

L.ADDON_TITLE = "adeTooltip"
L.TAB_GENERAL = "常規"
L.TAB_UNIT = "單位"
L.TAB_ITEM = "物品"
L.TAB_SPELL = "法術"
L.TAB_OTHER = "其他"
L.TAB_ANCHOR = "錨點"
L.TAB_CONFIG = "配置管理"
L.TAB_ABOUT = "關於"

L.HEADING_LAYOUT = "排版"
L.HEADING_APPEARANCE = "外觀"
L.HEADING_ITEM = "物品"

L.LABEL_USE_PRETTY = "使用新版排版"
L.NOTE_USE_PRETTY = "開啟：PrettyTooltip 風格面板；關閉：MiliUI 經典排版（修改原生行）。關閉時，僅對新版排版生效的選項會置為停用。"
L.LABEL_SCALE = "整體縮放"
L.LABEL_THEME_COLOR = "主題色"
L.NOTE_THEME_COLOR = "點擊修改主題色（預設黃色）"
L.LABEL_TWO_STAGE = "兩段式呈現（物品/法術）"
L.NOTE_TWO_STAGE = "把原生 tooltip 整體拆成兩段，其他插件的資訊併入下面那段。僅對新版排版生效。"
L.NOTE_PENDING = "本頁選項將在後續階段接入（見開發計劃 P2–P7）。"
L.LABEL_MINIMAP_SHOWN = "顯示小地圖按鈕"

L.PREVIEW_TITLE = "預覽區"
L.PREVIEW_NOTE = "真實分類樣例（含點擊定位設定項）將在 P7 接入，目前為骨架佔位。"
L.PREVIEW_PAGE = "當前頁：%s"

L.TT_LEFT = "左鍵：開啟設定介面"
L.TT_DRAG = "拖曳：調整按鈕位置"

L.RESET_CONFIRM = "將 adeTooltip 當前配置檔的全部設定恢復為預設？"
L.MSG_RESET = "設定已恢復為預設值。"
L.MSG_MINIMAP_SHOWN = "小地圖按鈕已顯示。"
L.MSG_MINIMAP_HIDDEN = "小地圖按鈕已隱藏，可用 /atip minimap 重新顯示。"
L.MSG_CONFLICT = "偵測到 MiliUI_Tooltip 已載入，不建議同時執行兩個 tooltip 插件。"
L.CMD_HELP = "可用命令：/adeTooltip、/atip、/adeTooltip about、/adeTooltip minimap、/adeTooltip reset"

-- 關於頁正文：結構化 ABOUT_* 鍵，由 AF.Template.AboutPage.Build 消費。
L.ABOUT_CMD_LABEL = "命令"
L.ABOUT_AUTHOR_LABEL = "作者"
L.ABOUT_DESC_1 = "ADE v6 工具提示美化：以 MiliUI_Tooltip 為藍本，新版排版採用 PrettyTooltip 觀感，並吸收 PrimeTooltip 的增量能力。"
L.ABOUT_FEATURE_1_LABEL = "雙排版"
L.ABOUT_FEATURE_1 = "Pretty 風格新版面板 / MiliUI 經典排版（修改原生行），由「使用新版排版」一鍵切換。"
L.ABOUT_FEATURE_2_LABEL = "兩段式"
L.ABOUT_FEATURE_2 = "物品/法術 tooltip 原生整體拆兩段，其他插件的資訊併入下面那段。"
L.ABOUT_FEATURE_3_LABEL = "設定"
L.ABOUT_FEATURE_3 = "多選項頁 8 頁佈局、配置檔管理與可停靠預覽組件。"
L.ABOUT_COMMANDS = "/adeTooltip  —  開啟/關閉設定介面\n/atip  —  與 /adeTooltip 等效\n/adeTooltip about  —  開啟本頁\n/adeTooltip minimap  —  顯示/隱藏小地圖按鈕\n/adeTooltip reset  —  恢復當前配置檔預設（確認彈窗）"
L.ABOUT_AUTHOR = "ADE"
L.ABOUT_CREDITS_TITLE = "致謝"
L.ABOUT_CREDITS = "藍本 MiliUI_Tooltip；新版觀感與修飾鍵 PrettyTooltip；增量能力 PrimeTooltip。"
L.ABOUT_LICENSE = "以 MIT 許可證發佈。"
L.ABOUT_NOTES = "基於 ade_AddonFramework（b010）構建。b001 為 P0/P1 骨架，渲染管線按 P2–P9 推進。"
