--[==[ adeTimerHUD / Modules/Clock.lua — v11 单面板六元素布局（规划 §十五~十八）
单一 Frame（唯一边框/背景），8 个 FontString：时间(HH)/冒号/分钟/前缀/闹钟/附加上/下左/下右，
按文本实测自动撑开；定位存档 x = 时间中心偏移、comp = 面板中心 - 时间中心。
v9（§十五）：单面板五元素；v9.1（§十六）：前缀独立 FS；
v10（§十七）：附加区宽度回填「附加上」、9 种日期格式、年份开关反转、星期样式；
v11（§十八）：格式化（时钟/日期/星期）统一收拢到 TimeFormat.lua，闹钟逻辑独立到
  AlarmClock.lua（原生 CVar 时间源 + 颜色分级 + 到期闪烁），本文件只做布局与调度。
v12（§二十六）：主时间拆 HH/:/MM 三段——冒号 FS 字体随时间组、颜色随 AM/PM 组
  （font.meridiem，含 useClassColor 职业色联动），12/24 制一致。
v13（§二十七）：定位重构（r031，参考 CompassHUD ResetPosition）——存档改绝对坐标
  （x=时间文本中心 X、y=面板顶边 Y，UIParent 坐标，不存锚点），定位恒
  BOTTOMLEFT；居中/重置按钮按 UIParent 实际尺寸重算坐标，与当前位置无关。
]==]
local addonName = ...
local ns = _G.adeTimerHUD or {}
_G.adeTimerHUD = ns

local Clock = {}
ns.Clock = Clock

local L = ns.L or {}

local frame, textButton
local deltaTime = 0
local layoutComp = 0        -- 面板中心相对时间中心的 X 偏移（定位补偿）
local lastComp = 0          -- 仅在布局变化时重定位，避免打断拖动
local lastH = 0             -- 上次面板高度（变化时需重定位保持顶边）

local TIME_SIZE = 64
local EXTRA_BASE_SIZE = 20
local PADX, PADY = 6, 8         -- 面板内边距（减小以紧贴）
local GAPX, GAPY, FULLGAP = 2, 4, 8

local fs = {}

--- 8 位 hex（AARRGGBB）→ r,g,b,a
local function HexToRGBA(hex)
    hex = tostring(hex or ""):gsub("#", "")
    if #hex == 6 then hex = "ff" .. hex end
    if #hex ~= 8 then return 0, 0, 0, 1 end
    local a = tonumber(hex:sub(1, 2), 16) or 255
    local r = tonumber(hex:sub(3, 4), 16) or 0
    local g = tonumber(hex:sub(5, 6), 16) or 0
    local b = tonumber(hex:sub(7, 8), 16) or 0
    return r / 255, g / 255, b / 255, a / 255
end

local function Settings()
    return ns.db and ns.db.settings or nil
end

local function GetServerTime() return GetGameTime() end
local function GetLocalTime() return tonumber(date("%H")) or 0, tonumber(date("%M")) or 0 end

-- 格式化统一在 TimeFormat；保留两个别名供 Options 预览调用（避免外部调用点断裂）
Clock.FormatDateText = function(...) return ns.TimeFormat.FormatDateText(...) end
Clock.FormatWeekday = function(style) return ns.TimeFormat.FormatWeekday(style) end

local function ExtraFontSize()
    local s = Settings()
    local off = s and tonumber(s.childFontOffset) or 0
    if off < -8 then off = -8 elseif off > 8 then off = 8 end
    return EXTRA_BASE_SIZE + off
end

local function ApplyFontTo(target, group, size)
    if not target or type(group) ~= "table" then return end
    local path = ns.Media.FontPath(group.face)
    target:SetFont(path, size, ns.Media.OutlineFlags(group.outline))
    -- color 缺省时不动颜色：闹钟组无固定色，由 AlarmClock 分级设置
    if group.useClassColor == true then
        local _, class = UnitClass("player")
        local r, g, b = GetClassColor(class)
        if r then target:SetTextColor(r, g, b, 1); return end
    end
    if group.color ~= nil then
        local r, g, b, a = HexToRGBA(group.color)
        target:SetTextColor(r, g, b, a)
    end
end

--- AM/PM 组颜色（含职业色）：主时间冒号与 AM/PM 标记共用（r029）
local function ApplyMeridiemColor(target, group)
    if not target or type(group) ~= "table" then return end
    if group.useClassColor == true then
        local _, class = UnitClass("player")
        local r, g, b = GetClassColor(class)
        if r then target:SetTextColor(r, g, b, 1); return end
    end
    if group.color ~= nil then
        local r, g, b, a = HexToRGBA(group.color)
        target:SetTextColor(r, g, b, a)
    end
end

local function ApplyFonts()
    local s = Settings()
    if not s then return end
    ApplyFontTo(fs.time, s.font and s.font.time, TIME_SIZE)
    ApplyFontTo(fs.timeRight, s.font and s.font.time, TIME_SIZE)
    -- 冒号：字体/描边/颜色先随时间组，再由 AM/PM 组颜色覆盖（r029）
    ApplyFontTo(fs.timeColon, s.font and s.font.time, TIME_SIZE)
    ApplyMeridiemColor(fs.timeColon, s.font and s.font.meridiem)
    -- 闹钟字体/描边由 AlarmClock.Refresh 应用，颜色固定由分级决定
end

-- 前向声明：RefreshLayout 尾部调用；若等到后部 local function 定义再引用，
-- 词法作用域会把它解析为全局 nil（r015 崩溃 Clock.lua:250 的根因）。
local ApplyPosition

--- 全量刷新：决定附加内容 → 实测尺寸 → 锚点 → 定位补偿
local function RefreshLayout()
    local s = Settings()
    if not frame or not s then return end

    -- 时间（单选源）；前缀缩写独立 FS 显示，不再拼接进时间文本
    local src = s.timeSource or "SERVER"
    local h, m
    if src == "LOCAL" then h, m = GetLocalTime() else h, m = GetServerTime() end
    local use24 = s.use24 == true
    local prefix = s.showPrefix and ((src == "LOCAL") and "[L]" or "[S]") or ""
    -- r029：时间拆为 HH/:/MM 三段，冒号独立 FS 以便随 AM/PM 组着色（含职业色）；
    -- 拆分失败（异常文本）时整体回退到 fs.time、冒号/分钟段为空文本
    local timeText = ns.TimeFormat.ClockText(h, m, use24)
    local hh, mm = timeText:match("^(%d+):(%d+)$")
    fs.time:SetText(hh or timeText)
    fs.timeColon:SetText(hh and ":" or "")
    fs.timeRight:SetText(hh and mm or "")
    fs.prefix:SetText(prefix)
    if prefix ~= "" then fs.prefix:Show() else fs.prefix:Hide() end

    -- 闹钟：目标时刻取原生 CVar 缓存，颜色分级与到期闪烁由 AlarmClock 负责
    ns.AlarmClock.Refresh(fs.alarm, s, ApplyFontTo)
    local showAlarm = fs.alarm:IsShown()

    -- 附加元素内容（12h/24h × dateMode 映射见规划 §十五）
    local dm = s.dateMode or "NONE"
    local dateText = ns.TimeFormat.FormatDateText(s.dateFormat, not s.dateHideYear)
    local weekText = ns.TimeFormat.FormatWeekday(s.weekdayStyle)
    local topText, blText, brText = "", "", ""
    local topIsDate, blIsDate, blIsMeridiem = false, false, false
    if not use24 then
        if ns.TimeFormat then
            local style = ns.TimeFormat.EffectiveStyle(s.meridiemStyle, s.forceChineseMeridiem)
            blText = ns.TimeFormat.Format(h, m, style)
            blIsMeridiem = true
        end
        if dm == "DATE" or dm == "BOTH" then
            topText, topIsDate = dateText, true
            if dm == "BOTH" then brText = weekText end
        elseif dm == "WEEKDAY" then
            topText = weekText
        end
    else
        -- 24h：DATE→下左日期；WEEKDAY→下左星期；
        --      BOTH→「附加上」日期 +「附加下左」星期；「附加下右」留空
        if dm == "DATE" then
            blText, blIsDate = dateText, true
        elseif dm == "WEEKDAY" then
            blText = weekText
        elseif dm == "BOTH" then
            topText, topIsDate = dateText, true
            blText = weekText
        end
    end
    fs.top:SetText(topText)
    fs.bl:SetText(blText)
    fs.br:SetText(brText)

    -- 附加元素字体组跟随内容（日期用 date 组，星期/标记用 weekday 组）
    local f = (Settings() or {}).font or {}
    local csize = ExtraFontSize()
    ApplyFontTo(fs.time, f.time, TIME_SIZE)
    ApplyFontTo(fs.timeRight, f.time, TIME_SIZE)
    -- 冒号：字体/描边随时间组，颜色由 AM/PM 组（含职业色）覆盖
    ApplyFontTo(fs.timeColon, f.time, TIME_SIZE)
    ApplyMeridiemColor(fs.timeColon, f.meridiem)
    ApplyFontTo(fs.prefix, f.prefix, csize)
    ApplyFontTo(fs.top, topIsDate and (f.date or f.weekday) or (f.weekday or f.date), csize)
    -- AM/PM 用独立 meridiem 组；24h 的日期/星期仍走 date/weekday 组
    local blGroup = blIsMeridiem and (f.meridiem or f.weekday)
        or (blIsDate and (f.date or f.weekday) or (f.weekday or f.date))
    ApplyFontTo(fs.bl, blGroup, csize)
    ApplyFontTo(fs.br, f.weekday or f.date, csize)

    -- 实测尺寸（时间 = HH + : + MM 三段之和，口径与单 FS 一致）
    local hhW = fs.time:GetStringWidth() or 0
    local colonW = fs.timeColon:GetStringWidth() or 0
    local mmW = fs.timeRight:GetStringWidth() or 0
    local timeW = hhW + colonW + mmW
    local timeH = fs.time:GetStringHeight() or TIME_SIZE
    local prefixW = 0
    if prefix ~= "" then prefixW = fs.prefix:GetStringWidth() or 0 end
    local alarmH = 0
    if showAlarm then alarmH = fs.alarm:GetStringHeight() or 10 end
    local function TextW(fsRef, text)
        return (text ~= "" and (fsRef:GetStringWidth() or 0)) or 0
    end
    local topW = TextW(fs.top, topText)
    local blW = TextW(fs.bl, blText)
    local brW = TextW(fs.br, brText)
    local extraW = math.max(topW, blW + ((brW > 0) and (FULLGAP + brW) or 0))
    local extraH = ((topW > 0) and (csize + GAPY) or 0) + ((blW > 0) and csize or 0)
    local timeBlockH = timeH + (showAlarm and (GAPY + alarmH) or 0)
    local contentH = math.max(timeBlockH, extraH)
    local timeLeft = PADX + prefixW + ((prefixW > 0) and GAPX or 0)
    local totalW = timeLeft + timeW + ((extraW > 0) and (GAPX + extraW) or 0) + PADX
    local totalH = PADY + contentH + PADY
    frame:SetSize(math.max(80, totalW), math.max(40, totalH))

    -- 时间：在内容区垂直居中，X 从 timeLeft 起（前缀占位后）；冒号/分钟段右接
    local timeY = -PADY - (contentH - timeBlockH) / 2
    fs.time:ClearAllPoints()
    fs.time:SetPoint("TOPLEFT", frame, "TOPLEFT", timeLeft, timeY)
    fs.timeColon:ClearAllPoints()
    fs.timeColon:SetPoint("TOPLEFT", fs.time, "TOPRIGHT", 0, 0)
    fs.timeRight:ClearAllPoints()
    fs.timeRight:SetPoint("TOPLEFT", fs.timeColon, "TOPRIGHT", 0, 0)
    -- 前缀：右上对齐时间左侧中（TOPRIGHT → 时间 LEFT，向左留 GAPX）
    if prefixW > 0 then
        fs.prefix:ClearAllPoints()
        fs.prefix:SetPoint("TOPRIGHT", fs.time, "LEFT", -GAPX, 0)
    end
    -- 闹钟：X 中心对齐整个时间串（HH+:MM）——TOP 锚 x 相对参考点中心，
    -- 以 fs.timeRight 为参考需左移 (hhW+colonW)/2（推导见 DevPlan §二十六）
    if showAlarm then
        fs.alarm:ClearAllPoints()
        fs.alarm:SetPoint("TOP", fs.timeRight, "BOTTOM", -(hhW + colonW) / 2, -GAPY)
    end
    -- 附加上：左下对齐时间右中（整个时间串右缘 = timeRight RIGHT）
    if topW > 0 then
        fs.top:ClearAllPoints()
        fs.top:SetPoint("BOTTOMLEFT", fs.timeRight, "RIGHT", GAPX, 0)
        fs.top:SetWidth(extraW)
        fs.top:SetJustifyH(brW > 0 and "RIGHT" or "LEFT")
    end
    if blW > 0 then
        fs.bl:ClearAllPoints()
        fs.bl:SetPoint("TOPLEFT", fs.timeRight, "RIGHT", GAPX, -GAPY)
    end
    -- 附加下右：右上对齐「附加上」右下；右对齐使文本右侧与附加上齐平
    if brW > 0 then
        fs.br:SetJustifyH("RIGHT")
        fs.br:ClearAllPoints()
        fs.br:SetPoint("TOPRIGHT", fs.top, "BOTTOMRIGHT", 0, -GAPY)
    end

    -- 定位补偿：layoutComp = 面板中心 - 时间中心（本地单位，ApplyPosition 换算用）
    layoutComp = frame:GetWidth() / 2 - (timeLeft + timeW / 2)
    -- 尺寸/补偿变化时重定位（保持存档的时间中心与顶边）；防抖避免打断拖动
    if math.abs(layoutComp - lastComp) > 0.5 or math.abs(frame:GetHeight() - lastH) > 0.5 then
        lastComp = layoutComp
        lastH = frame:GetHeight()
        ApplyPosition()
    end
end

local function ApplyAppearance()
    local s = Settings()
    if not frame or not s then return end
    frame:SetMovable(not s.frameLocked)
    local ar, ag, ab = HexToRGBA(s.frameColor)
    frame:SetBackdropColor(ar, ag, ab, tonumber(s.frameAlpha) or 1)
    local br, bg, bb = HexToRGBA(s.borderColor)
    if s.showBorder then
        frame:SetBackdropBorderColor(br, bg, bb, 1)
    else
        frame:SetBackdropBorderColor(0, 0, 0, 0)
    end
    local panelAlpha = tonumber(s.panelAlpha)
    if panelAlpha == nil then panelAlpha = 1 end
    if panelAlpha < 0 then panelAlpha = 0 elseif panelAlpha > 1 then panelAlpha = 1 end
    frame:SetAlpha(panelAlpha)
    frame:SetShown(s.shown == true)
end

local function ApplyScale()
    local s = Settings()
    if not frame or not s then return end
    local scale = tonumber(s.panelScale) or 1
    if scale < 0.5 then scale = 0.5 elseif scale > 2 then scale = 2 end
    frame:SetScale(scale)
end

-- r031 定位（参考 CompassHUD ResetPosition，_temp/CompassHUD_1.6.4f_zhCN/CompassHUD.lua:5029）：
-- 存档为绝对坐标（UIParent 坐标系），**不存锚点**——拖动后 WoW 会改写 GetPoint 的锚点，
-- 旧的 point+offset 机制因此失效（居中/重置落在错误基准）。
--   position.x = 时间文本中心 X；position.y = 面板顶边 Y（均为 UIParent 坐标）
-- 定位恒 SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", offset)；offset 由存档值
-- 除以 ratio（frame eff ÷ UIParent eff，r032 修正：不能直接用 effectiveScale，
-- 否则含 UIScale 会被重复换算，面板飞出屏幕）后减去面板内对应偏移。
-- r032 换算系数：SetPoint offset 相对父（UIParent）坐标的缩放比 = frame eff ÷ parent eff。
-- 不能直接用 frame:GetEffectiveScale()——它含 UIParent 的 UIScale，多除一次会让
-- 显示位置 = 存档值 ÷ UIScale，UIScale<1（1080p 默认 ≈0.71）时面板飞出屏幕顶。
local function ParentRatio()
    local eff, parent = frame:GetEffectiveScale(), UIParent:GetEffectiveScale()
    if not eff or not parent or parent <= 0 then return 1 end
    return eff / parent
end

--- 默认位置：时间文本中心 = 屏幕水平中线；面板顶边距屏幕顶边 10（UIParent 坐标单位）
local function DefaultPosition()
    return {
        x = UIParent:GetWidth() / 2,
        y = UIParent:GetHeight() - 10,
    }
end

ApplyPosition = function()
    local s = Settings()
    if not frame or not s then return end
    local pos = s.position
    if type(pos) ~= "table" then pos = {}; s.position = pos end
    -- 老档防御：残留 point 字段（旧锚点语义）或 x/y 缺失 → 落默认位（r006 不迁移）
    if pos.point ~= nil or not tonumber(pos.x) or not tonumber(pos.y) then
        pos.point = nil
        local d = DefaultPosition()
        pos.x, pos.y = d.x, d.y
    end
    local ratio = ParentRatio()
    local localX = pos.x / ratio - (frame:GetWidth() / 2 - layoutComp)  -- 左缘 = 时间中心 - 时间中心本地偏移
    local localY = pos.y / ratio - frame:GetHeight()                    -- 底缘 = 顶边 - 高度
    frame:ClearAllPoints()
    frame:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", localX, localY)
end

local function SavePosition()
    local s = Settings()
    if not s or not frame then return end
    local pos = s.position
    if type(pos) ~= "table" then pos = {}; s.position = pos end
    local ratio = ParentRatio()
    pos.point = nil  -- 清老档标记
    -- 时间中心（UIParent 坐标）= 面板左缘 + 时间中心本地偏移 × ratio；顶边直接取 GetTop
    pos.x = frame:GetLeft() + (frame:GetWidth() / 2 - layoutComp) * ratio
    pos.y = frame:GetTop()
end

--- 「水平居中 - 时间」：时间文本中心 X = 屏幕中线（按 UIParent 实际宽度重算，
--- 与当前位置无关，拖到屏幕最左/最右也能回来），不动 Y（r031）
function Clock.CenterHorizontally()
    local s = Settings()
    if not s or not frame then return end
    s.position.x = UIParent:GetWidth() / 2
    ApplyPosition()
end

--- 「水平居中 - 面板」：面板整体中心 X = 屏幕中线。
--- 面板中心 = 时间中心 + layoutComp×ratio（UIParent 坐标）→ 时间中心需左移该量
function Clock.CenterPanelHorizontally()
    local s = Settings()
    if not s or not frame then return end
    s.position.x = UIParent:GetWidth() / 2 - layoutComp * ParentRatio()
    ApplyPosition()
end

function Clock.ApplyAll()
    ApplyAppearance()
    ApplyScale()
    ApplyPosition()
    ApplyFonts()
    RefreshLayout()  -- 内部在 layoutComp 定稿后再 ApplyPosition
end

function Clock.ResetPosition()
    local s = Settings()
    if not s or not frame then return end
    s.panelScale = ns.defaults.settings.panelScale
    ApplyScale()  -- 先复位缩放，eff 变化后再按当前尺寸计算默认坐标
    if type(s.position) ~= "table" then s.position = {} end
    local d = DefaultPosition()
    s.position.point = nil
    s.position.x, s.position.y = d.x, d.y
    ApplyPosition()
end

local function NewBackdrop()
    return {
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 },
    }
end

local function BuildFrame()
    -- 单一面板（唯一边框/背景），所有文本直接挂在其上
    frame = CreateFrame("Frame", "AdeTimerHUDFrame", UIParent, "BackdropTemplate")
    frame:SetFrameStrata("LOW")
    frame:SetToplevel(true)
    frame:SetMovable(true)
    frame:SetBackdrop(NewBackdrop())

    textButton = CreateFrame("Button", nil, frame)
    textButton:SetPoint("TOPLEFT")
    textButton:SetPoint("BOTTOMRIGHT")
    textButton:SetScript("OnMouseDown", function(_, button)
        local s = Settings()
        if button == "LeftButton" and s and not s.frameLocked then
            frame:StartMoving()
        end
    end)
    textButton:SetScript("OnMouseUp", function(_, button)
        if button == "LeftButton" then
            frame:StopMovingOrSizing()
            SavePosition()
        end
    end)

    fs.time = textButton:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    fs.timeColon = textButton:CreateFontString(nil, "ARTWORK", "GameFontNormal")  -- r029 冒号独立段
    fs.timeRight = textButton:CreateFontString(nil, "ARTWORK", "GameFontNormal")  -- r029 分钟段
    fs.prefix = textButton:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    fs.alarm = textButton:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    fs.top = textButton:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    fs.bl = textButton:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    fs.br = textButton:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    for _, f in pairs(fs) do
        f:SetJustifyV("TOP")
        f:SetJustifyH("LEFT")
    end

    frame:SetScript("OnUpdate", function(_, elapsed)
        ns.AlarmClock.UpdateFlash(fs.alarm, Settings())
        deltaTime = deltaTime + elapsed
        if deltaTime > 1.0 then
            RefreshLayout()
            deltaTime = 0
        end
    end)

    ns.clockFrame = frame
end

function Clock.Init()
    if frame then return end
    ns.AlarmClock.Init()
    BuildFrame()
    Clock.ApplyAll()
end
