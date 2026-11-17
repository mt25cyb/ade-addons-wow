-- 繁體中文覆蓋（僅當客戶端語言為 zhTW）。
local ACB = _G.adeChatBar or {}
_G.adeChatBar = ACB
local L = ACB.L or {}
ACB.L = L
if GetLocale() ~= "zhTW" then return end

L.ADDON_TITLE = "adeChatBar"
L.GROUP_UI = "介面"
L.GROUP_LAYOUT = "位置與小地圖"

L.HEADING_APPEARANCE = "外觀"
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

L.CHOICE_COLORFUL = "彩色"
L.CHOICE_DEFAULT = "預設金色"

L.NOTE_APPEARANCE = "修改即時生效。按鈕配色在彩色方案與單色金色方案之間切換。"
L.NOTE_CHANNELS = "頻道名稱透過 GetChannelName 比對。自動加入僅在真正登入時執行，/reload 不觸發。"
L.NOTE_POSITION = "吸附框體填全域幀名（例如 ChatFrame1EditBox）；不存在或隱藏時使用備用位置。"
L.NOTE_FALLBACK = "備用偏移相對於 UIParent 的 BOTTOMLEFT 角。"
L.NOTE_MINIMAP = "小地圖按鈕：左鍵顯示/隱藏快捷條，右鍵開啟設定介面，拖曳沿圓周移動。按鈕隱藏後可用 /acb minimap 找回。"

L.TT_LEFT = "左鍵：顯示/隱藏快捷條"
L.TT_RIGHT = "右鍵：開啟設定介面"
L.TT_DRAG = "拖曳：調整按鈕位置"

L.MSG_RESET = "設定已恢復為預設值。"
L.MSG_MINIMAP_SHOWN = "小地圖按鈕已顯示。"
L.MSG_MINIMAP_HIDDEN = "小地圖按鈕已隱藏，可用 /acb minimap 重新顯示。"
L.CMD_HELP = "可用指令：/acb、/acb minimap、/acb reset"
L.STATUS_ATTACH_OK = "已找到吸附框體，快捷條正吸附在其上。"
L.STATUS_ATTACH_MISSING = "吸附框體不存在或處於隱藏狀態，正在使用備用位置。"
L.STATUS_ATTACH_EMPTY = "吸附框體為空，正在使用備用位置。"
