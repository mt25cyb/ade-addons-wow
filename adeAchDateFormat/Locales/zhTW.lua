-- 繁體中文覆蓋（僅當客戶端語言為 zhTW）。
local ADF = _G.adeAchDateFormat or {}
_G.adeAchDateFormat = ADF
local L = ADF.L or {}
ADF.L = L
if GetLocale() ~= "zhTW" then return end

L.ADDON_TITLE = "adeAchDateFormat"
L.GROUP_FORMAT = "日期格式"
L.GROUP_SCOPE = "生效範圍"
L.HEADING_DATE_FORMAT = "成就完成日期格式"
L.HEADING_SCOPE = "生效範圍"

L.LABEL_PRESET = "預設格式"
L.LABEL_HIDE_TIME = "不顯示 時:分"
L.LABEL_CUSTOM = "自訂格式"
L.LABEL_ENABLE_NATIVE = "暴雪原生成就介面"
L.LABEL_ENABLE_KROWI = "Krowi's Achievement Filter"
L.LABEL_ENABLE_PRAT = "Prat 3.0（聊天成就日期）"

L.PRESET_1 = "日/月/年 24小時"
L.PRESET_2 = "日/月/年 12小時"
L.PRESET_3 = "月/日/年 24小時"
L.PRESET_4 = "月/日/年 12小時"
L.PRESET_5 = "年/月/日 24小時"
L.PRESET_6 = "年/月/日 12小時"
L.PRESET_7 = "本地完整日期"
L.PRESET_CUSTOM = "自訂"

L.NOTE_FORMAT = "預設照搬 Krowi 事件提醒的格式。成就日期只有年月日，因此 %R / %I:%M %p 會顯示 00:00 / 12:00 AM——開啟「不顯示 時:分」可剝除。僅當選擇「自訂」時使用下方格式串。"
L.NOTE_FORMAT_TOKENS = "%Y 四位年 | %y 兩位年 | %m 月 | %d 日 | %H 小時 | %M 分鐘 | %R 時:分 | %I 12小時 | %p 上午/下午 | %B 完整月份 | %b 縮寫月份 | %A 完整星期 | %a 縮寫星期 | %c 本地日期時間。月份與星期名稱取客戶端本地化。"
L.NOTE_SCOPE = "直接寫文字的格式化對所有語言生效；成就連結 tooltip 的文字改寫僅在 zhCN 生效。請停用 Z_AchievementDateFormat，避免兩個插件寫同一處文字。"
L.NOTE_Z_CONFLICT = "若同時啟用 Z_AchievementDateFormat，兩個插件可能寫同一處日期文字；停用 Z 可保持單一格式。"

L.MSG_RESET = "設定已恢復為預設值。"
L.MSG_NATIVE_HOOKED = "已設定暴雪成就介面的日期格式。"
L.MSG_KROWI_HOOKED = "已設定 Krowi's Achievement Filter 的日期格式。"
L.MSG_PRAT_HOOKED = "已接管 Prat 3.0 聊天成就連結的日期格式。"
L.MSG_PRAT_UNHOOKED = "已恢復 Prat 3.0 聊天成就連結的原始日期。"
L.MSG_LINK_HOOKED = "已設定成就連結 tooltip 的日期格式。"
L.CMD_HELP = "可用指令：/aadf、/aadf reset"

L.DESC_ENABLE_KROWI = "將成就完成日期格式接入 Krowi's Achievement Filter 的列表顯示。"
L.DESC_NEED_KROWI = "未偵測到 Krowi's Achievement Filter，此選項已停用。"
L.DESC_ENABLE_PRAT = "將聊天框成就連結的日期格式接入 Prat 3.0。"
L.DESC_NEED_PRAT = "未偵測到 Prat 3.0，此選項已停用。"

