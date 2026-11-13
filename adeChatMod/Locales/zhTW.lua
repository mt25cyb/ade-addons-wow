-- 繁體中文覆蓋（僅當客戶端語言為 zhTW）。
local ACM = _G.adeChatMod or {}
_G.adeChatMod = ACM
local L = ACM.L or {}
ACM.L = L
if GetLocale() ~= "zhTW" then return end

L.ADDON_TITLE = "adeChatMod"
L.TAB_SETTINGS = "設定"
L.TAB_CONFIG = "配置管理"
L.TAB_ABOUT = "關於"

L.HEADING_APPEARANCE = "外觀"
L.HEADING_THEME = "主題顏色"
L.HEADING_CHANNELS = "頻道"
L.HEADING_POSITION = "位置"
L.HEADING_FALLBACK = "備用位置"
L.HEADING_MINIMAP = "小地圖按鈕"

L.LABEL_COLOR_SCHEME = "按鈕配色"
L.LABEL_BTN_SIZE = "按鈕大小"
L.LABEL_BTN_GAP = "按鈕間距"
L.LABEL_FONT_SIZE = "字級"
L.LABEL_WORLD_CHANNEL = "世界頻道名稱"
L.LABEL_TRADE_CHANNEL = "交易頻道名稱"
L.LABEL_AUTO_JOIN = "自動加入世界頻道"
L.LABEL_AUTO_JOIN_DELAY = "自動加入延遲"
L.LABEL_ATTACH_TARGET = "吸附框體（全域名稱）"
L.LABEL_ATTACH_POINT = "快捷條錨點"
L.LABEL_ATTACH_RELATIVE_POINT = "目標錨點"
L.LABEL_ATTACH_X = "水平偏移"
L.LABEL_ATTACH_Y = "垂直偏移"
L.LABEL_FALLBACK_X = "備用水平偏移"
L.LABEL_FALLBACK_Y = "備用垂直偏移"
L.LABEL_BAR_SHOWN = "顯示快捷條"
L.LABEL_MINIMAP_SHOWN = "顯示小地圖按鈕"
L.LABEL_RESET_MINIMAP_POS = "重設按鈕位置"
L.LABEL_THEME_COLOR = "主題顏色"
L.NOTE_THEME_COLOR = "點擊修改主題顏色（預設黃色）"

L.CHOICE_COLORFUL = "彩色"
L.CHOICE_DEFAULT = "預設金色"

L.NOTE_APPEARANCE = "修改即時生效。按鈕配色在彩色方案與單色金色方案之間切換。"
L.NOTE_CHANNELS = "頻道名稱透過 GetChannelName 比對。自動加入僅在真正登入時執行，/reload 不觸發。"
L.NOTE_POSITION = "吸附框體填全域幀名（例如 ChatFrame1EditBox）；不存在或隱藏時使用備用位置。"
L.NOTE_FALLBACK = "備用偏移相對於 UIParent 的 BOTTOMLEFT 角。"
L.NOTE_MINIMAP = "小地圖按鈕：左鍵顯示/隱藏快捷條，右鍵開啟設定介面，拖曳沿圓周移動。按鈕隱藏後可用 /acm minimap 找回。"

L.TT_LEFT = "左鍵：顯示/隱藏快捷條"
L.TT_RIGHT = "右鍵：開啟設定介面"
L.TT_DRAG = "拖曳：調整按鈕位置"

L.RESET_CONFIRM = "將 adeChatMod 的全部設定恢復為預設？"
L.MSG_RESET = "設定已恢復為預設值。"
L.MSG_MINIMAP_SHOWN = "小地圖按鈕已顯示。"
L.MSG_MINIMAP_HIDDEN = "小地圖按鈕已隱藏，可用 /acm minimap 重新顯示。"
L.CMD_HELP = "可用指令：/acm、/acm about、/acm minimap、/acm reset"
L.STATUS_ATTACH_OK = "已找到吸附框體，快捷條正吸附在其上。"
L.STATUS_ATTACH_MISSING = "吸附框體不存在或處於隱藏狀態，正在使用備用位置。"
L.STATUS_ATTACH_EMPTY = "吸附框體為空，正在使用備用位置。"

-- 關於頁正文：結構化 ABOUT_* 鍵，由 AF.Template.AboutPage.Build 消費（庫 Template/AboutPage.lua 規格）。
-- 顏色由 AF.AccentHex() 生成，普通文字行禁止寫死 |cff...|r 轉義。
L.ABOUT_DESC_1 = "精簡的聊天頻道快捷條，附帶頻道名稱縮寫、小地圖按鈕與設定介面。"
L.ABOUT_FEATURE_1_LABEL = "頻道快捷條"
L.ABOUT_FEATURE_1 = "12 個頻道/功能按鈕；可吸附到任意全域框體並帶偏移，目標缺失時使用備用位置。"
L.ABOUT_FEATURE_2_LABEL = "頻道名稱縮寫"
L.ABOUT_FEATURE_2 = "Hook ChatFrameN.AddMessage，把頻道名稱顯示為短標籤（如 [世界]）。"
L.ABOUT_FEATURE_3_LABEL = "設定"
L.ABOUT_FEATURE_3 = "設定即時生效，依帳號保存在 adeChatModDB。"
L.ABOUT_COMMANDS = "/acm  —  開啟/關閉設定介面\n/acm about  —  開啟本頁\n/acm minimap  —  顯示/隱藏小地圖按鈕\n/acm reset  —  恢復預設設定（確認彈窗）\n/adechatmod 與 /acm 等效。"
L.ABOUT_AUTHOR = "ADE"
L.ABOUT_CREDITS_TITLE = "致謝"
L.ABOUT_CREDITS = "ChannelBar 作者 CHANGEEN（MIT）；設定介面與小地圖按鈕基於 PrimeTooltip（PrimeCraze）。"
L.ABOUT_LICENSE = "以 MIT 授權條款發布。"
L.ABOUT_NOTES = "基於 ade_AddonFramework 建構：視窗、表單列、關於頁與主題顏色均來自程式庫範本。"
