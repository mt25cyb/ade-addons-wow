local _, ns = ...
ns.Locales.zhTW = {
	ADDON_NAME = "羅盤追蹤擴展",

	SECTIONS_SOURCE = "追蹤目標來源",
	SECTIONS_EDGE = "貼邊指針",
	SECTIONS_EMPHASIS = "追蹤強調",
	SECTIONS_LAYOUT = "羅盤版式",

	SETTINGS_ENABLE_SOURCE = "追蹤地圖 / 任務追蹤窗目標",
	SETTINGS_ENABLE_SOURCE_TIP = "顯示超級追蹤目標（任務、航點、地圖標記、事件），與 CompassHUD 顯示的目標一致；無超級追蹤時顯示主插件選定的圖釘，兩者衝突以超級追蹤為準。",
	SETTINGS_USER_WAYPOINT = "追蹤使用者航點",
	SETTINGS_USER_WAYPOINT_TIP = "地圖手放航點處於超級追蹤時顯示到羅盤上。",

	SETTINGS_POINTER_STAY = "指針保持在羅盤上",
	SETTINGS_POINTER_STAY_TIP = "追蹤目標超出羅盤可視範圍時，追蹤擴展資訊保持在邊緣顯示，並在其外側顯示方向箭頭。",
	SETTINGS_STAY_ATLAS = "貼邊箭頭樣式",
	STAY_ATLAS_NPE = "標準箭頭",
	STAY_ATLAS_NAV = "導航追蹤箭頭",
	STAY_ATLAS_BAG = "三角箭頭",
	SETTINGS_HIDE_FAR = "隱藏指向其他大陸的指針",
	SETTINGS_HIDE_FAR_TIP = "目標位於其他大陸時隱藏追蹤指示。",
	SETTINGS_USE_CURRENT_MAP = "使用地圖轉換",
	SETTINGS_USE_CURRENT_MAP_TIP = "目標在其他地圖時，指向系統建議的轉換點（傳送門、入口）而非原始座標。",

	SETTINGS_SCALE = "追蹤目標放大比例",
	SETTINGS_HIGHLIGHT_COLOR = "高亮顏色",
	SETTINGS_GLOW_ALPHA = "光暈透明度",
	SETTINGS_REWARD_ICON = "使用世界任務獎勵圖示",
	SETTINGS_REWARD_ICON_TIP = "世界任務 / 獎勵目標使用獎勵物品或貨幣圖示（CompassHUD 預設開啟），關閉則用對應任務分類的指針圖示。",
	SETTINGS_SHOW_SCALE = "顯示羅盤刻度數字",
	SETTINGS_SHOW_SCALE_TIP = "仿 CompassHUD 在羅盤上疊加 30° 間隔的方位讀數（復用主插件刻度投影，主插件本身只顯示刻度線）。",

	INCOMPATIBLE = "Compass 內部結構不相容，增強層已停用。",
	USER_WAYPOINT = "使用者航點",
	AREA_PIN = "地圖標記",
	STATUS_LINE = "|cffabd473Compass TrackerExt|r 狀態：API %s，羅盤 %s，內部層 %s，導航 %s",
}
