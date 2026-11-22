-- adeMapMark - 繁體中文
local addonName = ...
if GetLocale() ~= "zhTW" then return end
local ns = _G.adeMapMark
local L = ns.L

L.ADDON_TAG = "ADE"

L.MARK_TITLE = "標題"
L.MARK_NOTE = "備註"
L.MARK_COORDS = "座標"
L.MARK_SIZE = "尺寸"
L.MARK_COLOR = "顏色"
L.MARK_GRAYSCALE = "灰階"
L.MARK_FAVORITE = "收藏"
L.MARK_ADD = "新增標記"
L.MARK_UPDATE = "更新"
L.MARK_DELETE = "刪除"
L.MARK_EDIT = "編輯標記"
L.MARK_GOTO = "導航"
L.MARK_BIG_EDITOR = "大型編輯器"
L.MARK_FAVORITES = "收藏列表"
L.MARK_ALL = "全部標記"
L.MARK_NO_MARKS = "目前地圖沒有標記。"
L.MARK_HINT_CLICK = "點擊地圖拾取座標"
L.MARK_DEFAULT_TITLE = "新標記"

L.PROVIDER_SOURCE = "外掛來源"
L.RESET_PROVIDER_OVERRIDE = "還原為資料包內建資料（立即生效，無需再點「更新標記」）"
L.PROVIDER_SECTION = "外掛數據包"
L.PROVIDER_ENABLE = "啟用數據包"
L.PROVIDER_EXPAND = "展開"
L.PROVIDER_MARKS = "%d 個標記"
L.PROVIDER_NO_MARKS = "未註冊任何外掛數據包。"

L.SETTINGS = "設定"
L.SETTINGS_GENERAL = "一般"
L.SETTINGS_MARKERS = "標記"
L.SETTINGS_TOMTOM = "使用 TomTom 導航"
L.SETTINGS_LEFT_CLICK = "左鍵開啟編輯器"
L.SETTINGS_MINIMAP = "在小地圖上顯示標記"
L.SETTINGS_ARROW = "顯示玩家箭頭"
L.SETTINGS_PROVIDERS = "外掛數據包"
L.SETTINGS_CLOSE = "關閉"

L.COMMAND_USAGE = "用法：/amm [io|debug|config]"
L.IMPORT_TITLE = "匯入 / 匯出"
L.IMPORT_PROMPT = "貼上資料"
L.EXPORT_TITLE = "匯出資料（Ctrl+C）"
L.IMPORT_OK = "匯入完成：%d 個標記"
L.IMPORT_FAIL = "資料格式無效"

-- 主面板
L.PANEL_TITLE = "地圖標記"
L.MARK_ICON_SIZE = "圖示大小"
L.MARK_TEXT_SIZE = "文字字體"
L.SIZE_LOW = "小"
L.SIZE_HIGH = "大"
L.COORD_HINT = "留空取當前位置"
L.MARK_COLOR_LABEL = "調色"
L.MARK_GRAYSCALE_BTN = "灰階化"
L.MARK_ADD_POINT = "添加點位"
L.MARK_UPDATE_EXTERNAL = "更新標記"
L.MARK_UPDATE_POINT = "更新點位"
L.MARK_UNNAMED = "未命名"
L.EMPTY_LIST_TEXT = "暫無收藏的點位\n使用上方表單添加，點星星可收藏\n\n當前座標快捷添加：/amm"

-- 備註大編輯框
L.BIGNOTE_TITLE = "詳細資訊編輯（支援顏色代碼）"
L.BIGNOTE_TITLE_LABEL = "標題 (最多2行)："
L.BIGNOTE_NOTE_LABEL = "備註："
L.BIGNOTE_OK = "儲存並關閉（仍需確認更新）"

-- 提示與錯誤
L.ERR_NAV_UNSUPPORTED = "當前地圖不支援導航"
L.ERR_NO_POSITION = "無法獲取當前位置，請手動輸入座標"
L.ERR_COORD_FORMAT = "座標格式錯誤，應為：50 50 或 0.50 0.50"
L.ERR_NO_SELECTION = "沒有選中的點位"
L.ERR_QUICKMARK_FAIL = "快捷標記失敗，當前環境無法自動獲取座標"
L.QUICKMARK_OK = "快捷標記成功：[%s] (%.0f, %.0f)"
L.MINIMAP_ARROW_CHECK = "使用插件版玩家箭頭以顯示在標記上層（需重載）"

-- 匯入 / 匯出
L.IO_TITLE = "[ADE]標記資料  匯出 / 匯入"
L.IO_HINT = "【匯出】複製下方代碼。\n【匯入】覆蓋原文本，貼上他人代碼後點擊匯入。"
L.IO_IMPORT_BTN = "匯入 (跳過已存在)"
L.IO_REFRESH_EXPORT = "重新整理匯出代碼"
L.IO_ERR_FORMAT = "匯入失敗：資料格式錯誤或代碼為空"
L.IO_DONE = "匯入完畢！新增點位:|cffffd100%d|r個，新增圖示:|cffffd100%d|r個。"
L.IO_NO_NEW = "匯入完成，但沒有發現新的點位或圖示（已跳過重複項）"

-- 圖示選擇器
L.ICON_LABEL = "圖示"
L.ICON_SELECTOR_TITLE = "圖示選擇器"
L.ICON_SELECTOR_HELP = "\n【左鍵】彈出下拉列表\n【右鍵】取消當前的圖示選擇\n\n【紅色小把手】旋轉圖示。右擊把手回正\n【滾輪】縮放以裁切顯示區域\n\n【雙擊】手動輸入 ID 添加提取圖示\n【拖拽】將物品/法術拖到此處直接添加\n\n <遊戲內提取>  列表裡的圖示可右鍵刪除"
L.ICON_EXTRACT_OK = "成功提取遊戲內圖示：%s"
L.ICON_EXTRACT_FAIL = "提取失敗：請輸入正確的 ID！"
L.ICON_DELETE_FORBID = "只能刪除自己提取的圖示哦"

-- 資料包註冊
L.ERR_PROVIDER_NO_NAME = "RegisterMarkProvider 失敗：provider 缺少 name 欄位"
L.PROVIDER_REGISTERED = "已註冊外掛座標包：%s"

-- 雜項兜底文案
L.CROSS_MAP = "跨地圖"
L.ICON_ITEM = "物品"
L.ICON_SPELL = "法術"
L.ICON_MACRO = "巨集"
