-- adeMacroAssistant / Locales / zhTW.lua
-- ADE v6.5：私有 locale 表（不再經 ADE:RegisterLocale / AceLocale）。
local AM = _G.adeMacroAssistant or {}
_G.adeMacroAssistant = AM
AM.Loc = AM.Loc or {}
AM.Loc.zhTW = {
    MACRO_ASSISTANT = "巨集助手",

    -- ---- Settings 視窗 ----
    SETTINGS_SUFFIX = " 設定",
    BTN_CLOSE = "關閉",
    ENABLE_AUTOMACRO = "啟用自動巨集",
    SECTION_PREFIX = "巨集名前綴",
    ENABLE_PREFIX = "啟用巨集名前綴",
    PREFIX_CHAR = "前綴字元（如 ' ）",
    HINT_PREFIX = "前綴與基名分離儲存：最終巨集名 = 前綴字元 + (自訂基名 或 類型預設名)。\n改動後點「立即重新整理巨集」生效。",
    ENABLE_PREFIX_DESC = "為巨集名加前綴可避免與其他插件或手動巨集重名衝突。",
    SECTION_TYPES = "巨集類型設定",
    SPELLTYPE_CLEANSE = "淨化（友方）",
    SPELLTYPE_PURGE = "清除（敵方）",
    SPELLTYPE_DISPEL = "驅散（友/敵雙方）",
    SPELLTYPE_INTERRUPT = "打斷",
    SPELLTYPE_RESURRECTION = "戰復 / 復活",
    SPELLTYPE_SPRINT = "疾跑 / 加速",
    SPELLTYPE_TAUNT = "嘲諷",
    ENABLE = "啟用",
    BASE_NAME = "自訂基名（留空用預設）",
    MACRO_BODY = "巨集體（每行一條指令）",
    SECTION_RESIZE = "巨集介面尺寸調整",
    ENABLE_RESIZE = "啟用介面尺寸調整",
    RESIZE_COLS = "每行巨集數",
    RESIZE_ROWS = "圖示列數",
    RESIZE_TEXT = "文字區額外高度（垂直版面）",
    RESIZE_RIGHTW = "文字區寬度（水平版面）",
    RESIZE_RIGHTW_DESC = "水平版面下巨集內容區域寬度（%d–%d，步進 %d，預設 %d）。垂直版面下巨集內容區寬度由視窗尺寸決定，此項不起作用，故切換到垂直版面時會反灰。",
    -- 兩項的取值在兩種版面下不同，故描述同時列出兩種（標題不再寫值，避免隨版面失效）
    RESIZE_COLS_DESC = "巨集面板每行排布的巨集數量：垂直版面 %d–%d（預設 %d），水平版面 %d–%d（預設 %d）；兩種版面各自獨立儲存。",
    RESIZE_ROWS_DESC = "巨集面板顯示的圖示列數：垂直版面 %d–%d（預設 %d），水平版面 %d–%d（預設 %d）；兩種版面各自獨立儲存。",
    RESIZE_TEXT_DESC = "文字區在圖示下方的額外高度（%d–%d，步進 %d，預設 %d）。水平版面的內容區高度由「圖示列數」撐滿，此項不起作用，故切換到水平版面時會反灰。",
    HINT_RESIZE = "調整僅在巨集介面（Macro Frame）打開時即時預覽；關閉後還原。",
    BTN_REFRESH = "立即重新整理巨集",
    BTN_APPLY_RESIZE = "套用介面尺寸",
    BTN_RESET_LAYOUT = "重設目前版面",
    BTN_RESET_NATIVE = "重設為原生巨集介面",

    -- ---- 布局模式 / 搜尋列 ----
    RESIZE_LAYOUT = "版面模式",
    LAYOUT_VERTICAL = "垂直（巨集按鈕在上，巨集內容在下）",
    LAYOUT_HORIZONTAL = "水平（巨集按鈕在左，巨集內容在右）",
    SECTION_SEARCH = "搜尋列",
    SEARCH_ENABLE = "啟用搜尋列",
    SEARCH_BODY = "同時搜尋巨集內容",
    SWITCH_TO_HORIZONTAL = "切換到水平版面",
    SWITCH_TO_VERTICAL = "切換到垂直版面",
    OPEN_SETTINGS = "開啟設定",
    SEARCH_HINT = "依名稱過濾巨集清單；搜尋列位於標籤下方、巨集按鈕上方。戰鬥中停用輸入。",
    SEARCH_NO_RESULT = "找不到符合的巨集",

    -- ---- AutoMacro 訊息 ----
    MSG_MACRO_UPDATED = "已更新巨集 '%s'（%s）",
    MSG_MACRO_CREATED = "已建立巨集 '%s'（%s）",
    MSG_IN_COMBAT = "戰鬥中：前綴變更將在退戰後套用",
    MSG_PREFIX_ENABLED = "自動巨集前綴已啟用",
    MSG_PREFIX_DISABLED = "自動巨集前綴已停用",
    MSG_PREFIX_CHAR_UPDATED = "自動巨集前綴字元已更新",

    -- ---- 預設巨集名稱 ----
    DEFAULT_NAME_CLEANSE = "淨化",
    DEFAULT_NAME_PURGE = "清除",
    DEFAULT_NAME_DISPEL = "驅散",
    DEFAULT_NAME_INTERRUPT = "打斷",
    DEFAULT_NAME_RESURRECTION = "戰復",
    DEFAULT_NAME_SPRINT = "疾跑",
    DEFAULT_NAME_TAUNT = "嘲諷",

    -- ---- Tab 標籤 ----
    TAB_AUTOMACRO = "自動巨集",
    TAB_RESIZE = "巨集介面",
    TAB_IMPORTEXPORT = "匯入/匯出巨集",
    TAB_CONFIG = "設定管理",   -- 与 adeBackpack 对齐；v5 設定管理頁 = 基座 BuildConfigPage

    -- ---- 標題欄 / 關於視窗 ----
    UI_SCALE = "縮放",
    ABOUT_TITLE = "關於",
    ABOUT_AUTHOR = "作者",
    ABOUT_VERSION = "版本",
    ABOUT_TRANSLATOR = "翻譯",
    ABOUT_TRANSLATOR_DESC = "繁體中文 由 Martin Good (mt25cyb) 提供",
    ABOUT_NOTES = "簡介",
    ABOUT_COMMANDS = "指令",
    ABOUT_COMMANDS_DESC = "/adeMacroAssistant 或 /adema 打開本視窗",
    UNKNOWN = "未知",

    -- 佔位符 -> 實際法術含義說明（按類型展示於設定介面）
    TOKEN_CLEANSE_SPELL = "友方驅散法術",
    TOKEN_PURGE_SPELL = "敵方進攻驅散法術",
    TOKEN_INTERRUPT_SPELL = "打斷法術",
    TOKEN_RESURRECTION_SPELL = "戰復 / 復活法術",
    TOKEN_SPRINT_SPELL = "疾跑 / 加速法術",
    TOKEN_TAUNT_SPELL = "嘲諷法術",
    HINT_TOKEN_ONE = "使用 %s 作為實際 %s 名稱的佔位符。",

    -- ---- 各類型格式化標籤（%s 填入類型名）----
    ENABLE_TYPE = "啟用%s",
    NAME_TYPE = "巨集名稱",
    BODY_TYPE = "巨集體",
    DESC_TYPE = "%s 巨集",

    -- ---- 匯入 / 匯出巨集（僅自動巨集的巨集名稱與巨集體） ----
    SECTION_EXPORT = "匯出自動巨集",
    EXPORT_HINT = "點擊下方按鈕產生分享字串（僅含自動巨集的巨集名稱與巨集體），再按 Ctrl+C 複製。",
    SECTION_IMPORT = "匯入自動巨集",
    IMPORT_HINT = "將分享字串貼到下方，解析成功後「匯入巨集」按鈕才會啟用；僅更新自動巨集。",
    BTN_EXPORT = "匯出",
    BTN_IMPORT = "匯入",
    BTN_EXPORT_GEN = "產生匯出字串",
    BTN_IMPORT_DO = "匯入巨集",
    EXPORT_OK = "匯出字串已產生（Ctrl+C 複製）。",
    IMPORT_BOX_LABEL = "匯入字串",
    IMPORT_VALID = "字串有效",
    IMPORT_INVALID = "無效字串",
    SHARE_NO_CODEC = "目前用戶端不支援 C_EncodingUtil",
    SHARE_BAD_PREFIX = "前綴錯誤（非 ADE 匯出字串）",
    SHARE_BAD_PAYLOAD = "資料結構錯誤",
    SHARE_EMPTY = "字串為空",
    SHARE_SERIALIZE_FAILED = "序列化失敗",
    SHARE_COMPRESS_FAILED = "壓縮失敗",
    SHARE_ENCODE_FAILED = "編碼失敗",
    SHARE_DECODE_FAILED = "Base64 解碼失敗",
    SHARE_DECOMPRESS_FAILED = "解壓失敗",
    SHARE_DESERIALIZE_FAILED = "反序列化失敗",
    SHARE_VALIDATE_FAILED = "字串內容無效",
    MSG_IMPORT_OK = "自動巨集已匯入。",
    MSG_IMPORT_ERR = "自動巨集匯入失敗。",

    -- ---- 巨集介面佈局標籤（b018 修復） ----
    RESIZE_COLS_V = "每行巨集數（垂直佈局）",
    RESIZE_ROWS_V = "圖示行數（垂直佈局）",
    RESIZE_COLS_H = "每行巨集數（水平佈局）",
    RESIZE_ROWS_H = "圖示行數（水平佈局）",

    -- 小地圖
    MENU_SETTINGS = "設定",
    MENU_REFRESH = "立即重新整理巨集",
    TIP_LEFT = "左鍵",
    TIP_RIGHT = "右鍵",
    TIP_LEFT_SETTINGS = "打開設定",
    TIP_RIGHT_FUNCS = "功能選單",
    MINIMAP_LIB_MISSING = "LibDBIcon/LibDataBroker 不可用。",
}
