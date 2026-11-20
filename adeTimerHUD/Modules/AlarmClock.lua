--[==[ adeTimerHUD / Modules/AlarmClock.lua — 闹钟显示（v11，规划 §十八）
目标时刻不再由本插件设置，改为读取暴雪原生「时钟设置选项」的 CVar：
  · timeMgrAlarmEnabled  == "1"  → 原生闹钟已启用（即用户已设提醒时间）
  · timeMgrAlarmTime             → 当天分钟数 0–1439（12:00 = 720）
  · timeMgrUseLocalTime          → 时间基准（本地 / 服务器）
实证 Blizzard_TimeManager.lua:46-50 / :104-122、GameTimeUtil.lua:87-90。
缓存只在 Init 与 CVAR_UPDATE（上述三个 CVar）时重读（用户口径：只有重载或
重设提醒时间才重新刷新闹钟信息）；倒计时/颜色每秒基于缓存目标计算。
颜色固定不取 font.alarm.color：>10 分绿、n<剩余<=10 橙、<=n 红。
]==]
local addonName = ...
local ns = _G.adeTimerHUD or {}
_G.adeTimerHUD = ns

local AlarmClock = {}
ns.AlarmClock = AlarmClock

local CVAR_ALARM_TIME = "timeMgrAlarmTime"
local CVAR_ALARM_ENABLED = "timeMgrAlarmEnabled"
local CVAR_LOCAL_TIME = "timeMgrUseLocalTime"

local ALARM_SIZE = 10
local FLASH_ALPHA_LOW, FLASH_ALPHA_HIGH = 0.3, 1

local cache = { enabled = false, target = nil, localTime = false }
local flashActive = false

local GREEN = { 0.25, 1.0, 0.35 }
local ORANGE = { 1.0, 0.65, 0.1 }
local RED = { 1.0, 0.25, 0.25 }

local function GetCVarValue(name)
    if C_CVar and C_CVar.GetCVar then return C_CVar.GetCVar(name) end
    return GetCVar and GetCVar(name) or nil
end

local function GetCVarFlag(name)
    if C_CVar and C_CVar.GetCVarBool then return C_CVar.GetCVarBool(name) == true end
    return GetCVarBool and GetCVarBool(name) == true
end

--- 仅在 Init / CVAR_UPDATE 时调用：重读原生闹钟配置到缓存
function AlarmClock.RefreshCache()
    cache.enabled = (GetCVarValue(CVAR_ALARM_ENABLED) == "1")
    local minutes = tonumber(GetCVarValue(CVAR_ALARM_TIME))
    cache.target = (minutes and minutes >= 0 and minutes <= 1439) and math.floor(minutes) or nil
    cache.localTime = GetCVarFlag(CVAR_LOCAL_TIME)
end

local function NowMinutes()
    if cache.localTime then
        local t = date("*t")
        return (tonumber(t.hour) or 0) * 60 + (tonumber(t.min) or 0)
    end
    local h, m = GetGameTime()
    return (tonumber(h) or 0) * 60 + (tonumber(m) or 0)
end

--- 返回 (剩余分钟, 原始差值)；原始差值 <=0 表示已到期，用于闪烁判定
local function Remaining()
    if not cache.target then return nil, nil end
    local raw = cache.target - NowMinutes()
    return raw % 1440, raw
end

--- 设置页变更「显示闹钟」等选项后由 Clock.ApplyAll 间接触发
function AlarmClock.Refresh(fs, s, applyFontTo)
    if not fs then return end
    local a = (s and s.alarm) or {}
    local canShow = (a.show == true and cache.enabled and cache.target ~= nil)
    if not canShow then
        fs:SetText("")
        fs:SetAlpha(1)
        fs:Hide()
        flashActive = false
        return
    end

    local remain, raw = Remaining()
    local threshold = tonumber(a.warnMinutes) or 1
    if threshold < 1 then threshold = 1 elseif threshold > 5 then threshold = 5 end

    applyFontTo(fs, (s.font or {}).alarm, ALARM_SIZE)
    local color = (remain > 10 and GREEN) or (remain > threshold and ORANGE) or RED
    fs:SetTextColor(color[1], color[2], color[3], 1)
    -- 显示原生设定的闹钟时间（绝对 HH:MM），不是剩余倒计时
    fs:SetText(format("● %02d:%02d", math.floor(cache.target / 60), cache.target % 60))
    fs:Show()

    -- 到期：原始差值 <= 0 且不超过 1 分钟（整分钟粒度下容差 1）
    flashActive = (a.flash == true and raw ~= nil and raw <= 0 and raw >= -1)
    if not flashActive then fs:SetAlpha(1) end
end

--- 每帧调用，仅做 alpha 切换，不重读 CVar、不改文本
function AlarmClock.UpdateFlash(fs, s)
    if not fs then return end
    if flashActive and s and s.alarm and s.alarm.flash == true then
        fs:SetAlpha(fs:GetAlpha() > 0.6 and FLASH_ALPHA_LOW or FLASH_ALPHA_HIGH)
    elseif fs:GetAlpha() ~= 1 then
        fs:SetAlpha(1)
    end
end

--- 注册 CVAR_UPDATE：仅原生闹钟三个 CVar 变化时重读并让 Clock 重排
function AlarmClock.Init()
    AlarmClock.RefreshCache()
    local events = CreateFrame("Frame")
    events:RegisterEvent("CVAR_UPDATE")
    events:SetScript("OnEvent", function(_, event, cvar)
        if cvar ~= CVAR_ALARM_TIME and cvar ~= CVAR_ALARM_ENABLED and cvar ~= CVAR_LOCAL_TIME then
            return
        end
        AlarmClock.RefreshCache()
        if ns.Clock and ns.Clock.ApplyAll then ns.Clock.ApplyAll() end
    end)
    AlarmClock.events = events
end

return AlarmClock
