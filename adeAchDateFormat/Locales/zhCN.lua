-- 简体中文覆盖（仅当客户端语言为 zhCN）。
local ADF = _G.adeAchDateFormat or {}
_G.adeAchDateFormat = ADF
local L = ADF.L or {}
ADF.L = L
if GetLocale() ~= "zhCN" then return end

L.ADDON_TITLE = "adeAchDateFormat"
L.GROUP_FORMAT = "日期格式"
L.GROUP_SCOPE = "生效范围"
L.HEADING_DATE_FORMAT = "成就完成日期格式"
L.HEADING_SCOPE = "生效范围"

L.LABEL_PRESET = "预设格式"
L.LABEL_HIDE_TIME = "不显示 时:分"
L.LABEL_CUSTOM = "自定义格式"
L.LABEL_ENABLE_NATIVE = "暴雪原生成就界面"
L.LABEL_ENABLE_KROWI = "Krowi's Achievement Filter"
L.LABEL_ENABLE_PRAT = "Prat 3.0（聊天成就日期）"

L.PRESET_1 = "日/月/年 24小时"
L.PRESET_2 = "日/月/年 12小时"
L.PRESET_3 = "月/日/年 24小时"
L.PRESET_4 = "月/日/年 12小时"
L.PRESET_5 = "年/月/日 24小时"
L.PRESET_6 = "年/月/日 12小时"
L.PRESET_7 = "本地完整日期"
L.PRESET_CUSTOM = "自定义"

L.NOTE_FORMAT = "预设照搬 Krowi 事件提醒的格式。成就日期只有年月日，因此 %R / %I:%M %p 会显示 00:00 / 12:00 AM——开启「不显示 时:分」可剥除。仅当选择「自定义」时使用下方格式串。"
L.NOTE_FORMAT_TOKENS = "%Y 四位年 | %y 两位年 | %m 月 | %d 日 | %H 小时 | %M 分钟 | %R 时:分 | %I 12小时 | %p 上午/下午 | %B 完整月份 | %b 缩写月份 | %A 完整星期 | %a 缩写星期 | %c 本地日期时间。月份与星期名称取客户端本地化。"
L.NOTE_SCOPE = "直接写文本的格式化对所有语言生效；成就链接 tooltip 的文本改写仅在 zhCN 生效。请停用 Z_AchievementDateFormat，避免两个插件写同一处文本。"
L.NOTE_Z_CONFLICT = "若同时启用 Z_AchievementDateFormat，两个插件可能写同一处日期文本；停用 Z 可保持单一格式。"

L.MSG_RESET = "设置已恢复为默认值。"
L.MSG_NATIVE_HOOKED = "已设置暴雪成就界面的日期格式。"
L.MSG_KROWI_HOOKED = "已设置 Krowi's Achievement Filter 的日期格式。"
L.MSG_PRAT_HOOKED = "已接管 Prat 3.0 聊天成就链接的日期格式。"
L.MSG_PRAT_UNHOOKED = "已恢复 Prat 3.0 聊天成就链接的原始日期。"
L.MSG_LINK_HOOKED = "已设置成就链接 tooltip 的日期格式。"
L.CMD_HELP = "可用命令：/aadf、/aadf reset"

L.DESC_ENABLE_KROWI = "将成就完成日期格式接入 Krowi's Achievement Filter 的列表显示。"
L.DESC_NEED_KROWI = "未检测到 Krowi's Achievement Filter，此选项已禁用。"
L.DESC_ENABLE_PRAT = "将聊天框成就链接的日期格式接入 Prat 3.0。"
L.DESC_NEED_PRAT = "未检测到 Prat 3.0，此选项已禁用。"

