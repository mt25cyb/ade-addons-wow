-- zhTW（庫自身可見文本；缺譯文時回顯 key）
local lib = ResolveBOFNamespace("ade_UIKit")
if not lib then return end
if GetLocale() ~= "zhTW" then return end
lib.L = lib.L or setmetatable({}, { __index = function(_, key) return key end })
local L = lib.L

L["BOF_SETTINGS"] = "設定"
L["BOF_CLOSE"] = "關閉"
L["BOF_DEFAULTS"] = "回復預設"
L["BOF_YES"] = "是"
L["BOF_CANCEL"] = "取消"
L["BOF_RESET_CONFIRM"] = "將「%s」中的所有選項回復為預設值？"
L["BOF_CHANGED_COUNT"] = "已變更 %d 項"
L["BOF_NEEDS_RELOAD"] = "需要重新載入"
L["BOF_RELOAD_NOW"] = "立即重新載入"
L["BOF_RESET_OPTION"] = "回復此選項的預設值"
L["BOF_SEARCH"] = "搜尋"
L["BOF_NO_RESULTS"] = "找不到結果。"
L["BOF_ADD"] = "新增"
L["BOF_REMOVE"] = "移除"
L["BOF_MOVE_UP"] = "上移"
L["BOF_MOVE_DOWN"] = "下移"
L["BOF_UNDO"] = "復原"
L["BOF_NOT_BOUND"] = "未綁定"
L["BOF_PRESS_A_KEY"] = "請按鍵"
L["BOF_OVERVIEW"] = "概觀"
L["BOF_LIST_EMPTY"] = "尚無項目。"
L["BOF_DETAILS"] = "詳細說明"
L["BOF_ALL"] = "全部"
L["BOF_NONE"] = "無"
L["BOF_SEARCH_RESULTS"] = "搜尋結果"
L["BOF_SEARCH_ALL"] = "搜尋全部分頁"
L["BOF_SEARCH_BROAD"] = "搜尋描述"
L["BOF_RESET_SECTION"] = "將「%s」中的所有選項回復為預設值？"
L["BOF_RELOAD_TEXT"] = "部分變更在重新載入後生效"
L["BOF_DEFAULT"] = "預設值：%s"
