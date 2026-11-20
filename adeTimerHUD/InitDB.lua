--[==[ adeTimerHUD / InitDB.lua — 默认配置（唯一来源）
ADE v6.5：存档 ADEDB_TIMERHUD.settings.*，缺失键经 ade_UIKit.DB.MergeDefaults 补全。
颜色沿用 UIKit kind="color" 的 8 位 hex（AARRGGBB，实证 ade_UIKit/Widget/OptionRow.lua:174-185；
面板背景 alpha 由独立 frameAlpha 控制，字体颜色用自己的 alpha 位）。

默认值与设置页（Options.lua sections.clock）逐项对应，按界面分组：
【内容】shown / timeSource(SERVER|LOCAL) / showPrefix / use24 /
        meridiemStyle(INTERNATIONAL|CHINESE|ANCIENT) / forceChineseMeridiem（非 CJK 端才显示）/
        dateMode(NONE|DATE|WEEKDAY|BOTH) / dateFormat(9 种预设) / dateHideYear /
        weekdayStyle(LOCAL_FULL|LOCAL_SHORT|EN_FULL|EN_SHORT) /
        alarm.show / alarm.warnMinutes(1~5, step 0.5) / alarm.flash
【外观】frameLocked / showBorder / frameColor / frameAlpha（仅背景） / panelAlpha（整个面板） /
        borderColor / panelScale / panelAlpha / childFontOffset（附加字号基础 20 ± 8）
【字体】font.{time,alarm,date,weekday,meridiem,prefix}.{face,outline}；
        除 alarm 外各有 color——闹钟颜色固定按剩余时间分级，设置页不暴露 color 行；
        字号不进设置（时间 64、闹钟 10、附加区 20±8）。
【位置】position（x/y 绝对坐标）不由选项行编辑，由拖动与三个 execute 按钮维护；
        x = 时间文本中心 X、y = 面板顶边 Y（均 UIParent 坐标，不存锚点——r031 参考
        CompassHUD：拖动后 WoW 会改写 GetPoint 锚点，point+offset 机制不可靠）；
        nil = 未定位，Clock 按默认落位（时间居屏幕中线、顶边距屏幕顶 10px）并写回。

r006：用户明确**不考虑老存档**——本文件只提供默认值，不做任何旧档迁移
（Core.EnsureSettings 仅调 MergeDefaults 补全缺失键）。
r019+：dateShowYear → dateHideYear；新增 weekdayStyle；dateFormat 默认按 locale。
r021+：闹钟改读原生 timeMgrAlarm* CVar（删 alarm.hour/minute）；删 font.alarm.color；
       附加字号基础 24 → 20（r022）。
r024：字体默认描边/颜色——时间 粗描边+#FFFFFF、闹钟 描边（颜色仍固定分级）、
       日期与星期 描边+#A0A0A0、AM/PM 与前缀 描边+#66BBFF。
r025：AM/PM 与前缀新增 useClassColor（默认 true，用玩家职业色覆盖 color）；
       设置页为「显示职业颜色」开关 + 同行色块（ade_UIKit b051）。
r026：新增 panelAlpha（整个面板透明度，默认 100%）。
r027：scale → panelScale；面板透明度选项移到面板缩放之后。
r028：默认位置改锚屏幕上方 TOP（y=-10）、x=0 时间文本居屏幕水平中线（删 defaultCenterY）。
r031：position 改绝对坐标（x=时间中心 X / y=面板顶边 Y，UIParent 坐标，不存锚点），
       默认 nil 首次落位；老档 point 字段残留时清掉并落默认。 ]==]
local addonName = ...
local ns = _G.adeTimerHUD or {}
_G.adeTimerHUD = ns
ns.L = ns.Loc and (ns.Loc[GetLocale()] or ns.Loc.enUS) or {}

-- 日期格式默认按客户端 locale：zh 用「年月日」，其余用「月全称 日, 年」
-- （%B 由 Clock.FormatDateText 替换为暴雪本地化月份全称，不依赖 OS locale）。
local defaultDateFormat = "%Y年%m月%d日"
if GetLocale() ~= "zhCN" and GetLocale() ~= "zhTW" then
    defaultDateFormat = "%B %d, %Y"
end

local function defaultFont(outline, color)
    return {
        face = "Game Default",                -- 字体 key（Modules/Media.lua 的 GAME_DEFAULT）
        outline = outline or "NONE",          -- NONE / OUTLINE / THICKOUTLINE
        color = color or "ffffffff",          -- 8 位 hex AARRGGBB（此处 alpha 位有效，SetTextColor 4 参）
    }
end

-- 带「使用职业色」的字体组：默认启用；关闭时用该组 color（职业色优先）
local function classFont(outline, color)
    local f = defaultFont(outline, color)
    f.useClassColor = true
    return f
end

-- r028 默认锚点：屏幕上方 TOP，面板顶边下移 10px；x=0 即时间文本中心落在屏幕水平中线
-- （r013 定位口径：存档 x = 时间文本中心偏移，ApplyPosition 用 layoutComp 反推面板中心）

ns.defaults = {
    settings = {
        shown = true,                 -- 显示时钟
        use24 = false,                -- 24 小时制
        frameLocked = false,          -- 锁定位置（仅锁定移动；缩放由 panelScale 设置项控制）
        showBorder = false,           -- 显示边框（r010 默认关；唯一边框由主帧绘制覆盖两区）
        frameColor = "ff000000",    -- 背景色 AARRGGBB（单面板背景）
        frameAlpha = 0.2,             -- 背景不透明度（r012 默认 0.2；color 行的 alpha 位忽略）
        borderColor = "ffffb200",   -- 边框色（showBorder 开启时生效）
        panelScale = 1.0,             -- 面板缩放比例（100%），滑条 0.5~2.0；整体缩放
        panelAlpha = 1.0,             -- 整个面板不透明度（含文字/边框/背景；默认 100%）
        timeSource = "LOCAL",         -- 时间源：SERVER / LOCAL（单选）
        meridiemStyle = "INTERNATIONAL",  -- 时段标记：INTERNATIONAL / CHINESE / ANCIENT（仅 12h 用）
        forceChineseMeridiem = false,     -- 非 CJK 专用：开启后中文/古代格式才可选且生效
        showPrefix = false,           -- 显示缩写前缀 [S]/[L]（只保留缩写，无全称）
        dateMode = "BOTH",            -- 附加区显示内容：NONE / DATE / WEEKDAY / BOTH
        dateFormat = defaultDateFormat,   -- Lua date() 格式串（设置页预设可选）
        dateHideYear = true,          -- 日期不显示年份（默认剥离年份，保持既有外观）
        weekdayStyle = "LOCAL_SHORT", -- 星期文本：LOCAL_FULL / LOCAL_SHORT / EN_FULL / EN_SHORT
        childFontOffset = 0,          -- 子面板字号微调：基础 20 ± 8（日期/星期/时段标记/前缀）
        alarm = {
            show = false,             -- 显示闹钟（仍须原生 timeMgrAlarmEnabled=1 且有 timeMgrAlarmTime）
            warnMinutes = 1,          -- 紧急阈值（分钟）：<=n 红、n<剩余<=10 橙、>10 绿；1~5 step 0.5
            flash = false,            -- 到期时闹钟信息闪烁
        },
        font = {
            time = defaultFont("THICKOUTLINE", "ffffffff"),     -- 时间（固定 64；粗描边 / 白）
            alarm = { face = "Game Default", outline = "OUTLINE" },  -- 闹钟（固定 10；描边；颜色固定分级，无 color 行）
            date = defaultFont("OUTLINE", "ffa0a0a0"),          -- 日期（附加字号 20±8；描边 / 灰）
            weekday = defaultFont("OUTLINE", "ffa0a0a0"),       -- 星期（附加字号 20±8；描边 / 灰）
            meridiem = classFont("OUTLINE", "ff66bbff"),       -- AM/PM（独立组；默认职业色，关掉用蓝）
            prefix = classFont("OUTLINE", "ff66bbff"),         -- 缩写前缀 [S]/[L]（独立组；默认职业色，关掉用蓝）
        },
        position = {
            x = nil,  -- 时间文本中心 X（UIParent 坐标）；nil = 未定位，Clock 首次按默认落位并写回
            y = nil,  -- 面板顶边 Y（UIParent 坐标）；默认 = 距屏幕顶边 10px（r031 绝对坐标，不存锚点）
        },
    },
}
