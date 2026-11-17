------------------------------------------------------------
-- 單位行文法（Classic 路線 · C1）
--
-- 把暴雪的單位 tooltip 行重寫成設定裡的版面。這是插件**唯一**會寫暴雪 line FontString 的地方；
-- 讀行文字前一律先確認不是秘密字串（秘密字串不能 find/gsub）。
------------------------------------------------------------
local ns = _G.adeTooltip or {}
_G.adeTooltip = ns

local S = ns.Secret
local L = ns.L or {}
local Skin = ns.Skin
local Colors = ns.Colors
local UnitInfo = ns.UnitInfo

local strfind = string.find
local strgsub = string.gsub
local strmatch = string.match

local LEVEL, PVP = LEVEL, PVP
local FACTION_ALLIANCE, FACTION_HORDE = FACTION_ALLIANCE, FACTION_HORDE

ns.Lines = {}
local Lines = ns.Lines

ns.UnitLines = {}
local UnitLines = ns.UnitLines

------------------------------------------------------------
-- 行工具
------------------------------------------------------------
function Lines.Get(tip, number)
    if S.IsForbiddenObject(tip) then return end
    local ok, num = pcall(tip.NumLines, tip)
    if not ok or S.IsSecret(num) then num = 0 end
    num = tonumber(num) or 0
    if number > num then
        pcall(tip.AddLine, tip, " ")
        return Lines.Get(tip, num + 1)
    end
    local name = tip:GetName()
    return _G[name .. "TextLeft" .. number], _G[name .. "TextRight" .. number]
end

function Lines.Find(tip, keyword)
    if S.IsForbiddenObject(tip) then return end
    local name = tip:GetName()
    local ok, num = pcall(tip.NumLines, tip)
    num = (ok and not S.IsSecret(num)) and (tonumber(num) or 0) or 0
    for i = 2, num do
        local line = _G[name .. "TextLeft" .. i]
        if line then
            local value = S.PlainText(line:GetText())
            if value and value ~= "" and strfind(value, keyword) then
                return line, i, _G[name .. "TextRight" .. i]
            end
        end
    end
end

function Lines.Hide(tip, keyword)
    if S.IsForbiddenObject(tip) then return end
    local name = tip:GetName()
    local ok, num = pcall(tip.NumLines, tip)
    num = (ok and not S.IsSecret(num)) and (tonumber(num) or 0) or 0
    for i = 2, num do
        local line = _G[name .. "TextLeft" .. i]
        if line then
            local value = S.PlainText(line:GetText())
            if value and value ~= "" and strfind(value, keyword) then
                pcall(line.SetText, line, nil)
                break
            end
        end
    end
end

function Lines.HideRange(tip, from, to)
    if S.IsForbiddenObject(tip) then return end
    to = to or 999
    local name = tip:GetName()
    local ok, num = pcall(tip.NumLines, tip)
    num = (ok and not S.IsSecret(num)) and (tonumber(num) or 0) or 0
    for i = from, num do
        if i <= to then
            local line = _G[name .. "TextLeft" .. i]
            if line then pcall(line.SetText, line, nil) end
        end
    end
end

function Lines.StripText(text)
    local plain = S.PlainText(text)
    if not plain then return end
    local s = strgsub(plain, "|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")
    s = strmatch(s, "^%s*(.-)%s*$")
    if not s or s == "" then return end
    return s
end

------------------------------------------------------------
-- 邊框 / 背景上色（分量可能是秘密 → 全走 Skin 的 SetVertexColor 管線）
------------------------------------------------------------
local function HexToRGB(hex)
    local r = tonumber(hex:sub(1, 2), 16) or 255
    local g = tonumber(hex:sub(3, 4), 16) or 255
    local b = tonumber(hex:sub(5, 6), 16) or 255
    return r / 255, g / 255, b / 255
end

local function ColorBorder(tip, config, unit)
    local token = config and config.coloredBorder
    if token == "class" then
        local r, g, b = Colors.UnitColor(unit)
        if r then Skin.SetBorderColor(tip, r, g, b, 1) end
    elseif token == "reaction" then
        local r, g, b = Colors.ReactionColor(unit)
        if r then Skin.SetBorderColor(tip, r, g, b, 1) end
    elseif type(token) == "string" and token:match("^%x%x%x%x%x%x$") then
        local r, g, b = HexToRGB(token)
        Skin.SetBorderColor(tip, r, g, b, 1)
    end
    -- default：維持 ResetColors 的全域邊框色
end
UnitLines.ColorBorder = ColorBorder

local function ColorBackground(tip, config)
    local bg = config and config.background
    if not bg then return end
    if bg.colorfunc == "default" or bg.colorfunc == "" or bg.colorfunc == "inherit" or not bg.colorfunc then
        local c = ns.settings.general.background
        Skin.SetBackgroundColor(tip, c.r, c.g, c.b, c.a)
        return
    end
    if bg.colorfunc == "class" then
        local r, g, b = Colors.UnitColor(Skin.Get(tip).unit)
        if r then Skin.SetBackgroundColor(tip, r, g, b, bg.alpha or 0.8) end
    elseif bg.colorfunc == "reaction" then
        local r, g, b = Colors.ReactionColor(Skin.Get(tip).unit)
        if r then Skin.SetBackgroundColor(tip, r, g, b, bg.alpha or 0.8) end
    elseif type(bg.colorfunc) == "string" and bg.colorfunc:match("^%x%x%x%x%x%x$") then
        local r, g, b = HexToRGB(bg.colorfunc)
        Skin.SetBackgroundColor(tip, r, g, b, bg.alpha or 0.8)
    end
end
UnitLines.ColorBackground = ColorBackground

local function GrayForDead(tip, config, unit)
    if not config or not config.grayForDead then return end
    if not S.SafeBool(UnitIsDeadOrGhost, unit) then return end
    Skin.SetBorderColor(tip, 0.6, 0.6, 0.6, 1)
    Skin.SetBackgroundColor(tip, 0.1, 0.1, 0.1, 1)
    if S.IsForbiddenObject(tip) then return end
    local name = tip:GetName()
    local ok, num = pcall(tip.NumLines, tip)
    num = (ok and not S.IsSecret(num)) and (tonumber(num) or 0) or 0
    for i = 1, num do
        local line = _G[name .. "TextLeft" .. i]
        if line then
            pcall(line.SetTextColor, line, 0.7, 0.7, 0.7)
            local text = S.PlainText(line:GetText())
            if text then
                pcall(line.SetText, line, strgsub(text, "|cff%x%x%x%x%x%x", "|cffaaaaaa"))
            end
        end
    end
end

------------------------------------------------------------
-- 組行：把欄位拼進 seg 陣列，最後用空格 join
------------------------------------------------------------
-- ⚠ 不可用 table.concat：秘密字串（12.1 的 UnitClass／UnitName／GetGuildInfo…）
--   喂進 C 函式會失敗 ⇒ 任何一個欄位是秘密值就整列消失且不報錯
--   （對照 MiliUI UnitInfo.lua:924-954 的玩家實錄教訓）。
--   秘密值可以串接、可以 format，只是不能讀 —— 逐段 format + pcall，
--   失效粒度從「整列」縮到「那一個欄位」。秘密數字禁止 tostring，一律 format。
local function SafeJoin(list, sep)
    if type(list) ~= "table" then return "" end
    sep = sep or " "
    local res
    for i = 1, #list do
        local v = list[i]
        local vt = type(v)          -- type() 對秘密值合法
        if vt == "string" or vt == "number" then
            local ok, piece = pcall(string.format, "%s", v)
            if ok and piece ~= nil then
                if res == nil then
                    res = piece
                else
                    local ok2, joined = pcall(string.format, "%s%s%s", res, sep, piece)
                    if ok2 and joined ~= nil then res = joined end
                end
            end
        end
    end
    return res or ""
end

------------------------------------------------------------
-- 玩家：職業行（暴雪原生會顯示「專精 職業」，抓出來當 className 用）
------------------------------------------------------------
local function GetOriginalSpecLine(tip, className)
    className = S.PlainText(className)
    if not className or className == "" then return end
    if S.IsForbiddenObject(tip) then return end
    local best, bestLen
    local name = tip:GetName()
    local ok, num = pcall(tip.NumLines, tip)
    num = (ok and not S.IsSecret(num)) and (tonumber(num) or 0) or 0
    for i = 2, num do
        local line = _G[name .. "TextLeft" .. i]
        local stripped = Lines.StripText(line and line:GetText())
        if stripped and not stripped:find("^%d") and not stripped:find("^<")
            and stripped:find(className, 1, true)
            -- 等級行若帶職業名（「等級 90 夜精靈 死亡騎士」）會被當成最短那一行，
            -- 整句塞進職業欄 —— 排除以等級開頭的行（對照 MiliUI UnitLines.lua:156-158）
            and not (LEVEL and stripped:find("^" .. LEVEL, 1, true)) then
            local len = #stripped
            if not bestLen or len < bestLen then
                best, bestLen = stripped, len
            end
        end
    end
    return best
end

local function HideOriginalSpecLine(tip, target)
    if not target or target == "" then return end
    if S.IsForbiddenObject(tip) then return end
    local name = tip:GetName()
    local ok, num = pcall(tip.NumLines, tip)
    num = (ok and not S.IsSecret(num)) and (tonumber(num) or 0) or 0
    for i = 2, num do
        local line = _G[name .. "TextLeft" .. i]
        local stripped = Lines.StripText(line and line:GetText())
        if stripped and stripped == target then
            pcall(line.SetText, line, nil)
            pcall(line.Show, line)
        end
    end
end

local function classColoredName(unit, token)
    local plain = S.PlainText(token)
    if not plain then return nil end
    if type(unit) == "string" then
        local r, g, b = Colors.UnitColor(unit)
        if r then
            return string.format("|cff%02x%02x%02x%s|r", r * 255, g * 255, b * 255, plain)
        end
    end
    return plain
end

------------------------------------------------------------
-- 玩家
------------------------------------------------------------
local function ApplyPlayer(tip, state, unit, config, raw)
    local el = config.elements or {}
    local rows = {}

    local unitGuid = S.SafeValue(S.SafeCall(UnitGUID, unit))
    -- ⚠ 專精行只准在第一輪（post-call，行保證是暴雪剛填好的）去掃。
    -- 重畫（relayout：觀察／成就資料到貨）時提示框上已經是我們寫過的行，暴雪那行
    -- 專精第一輪就清掉了 —— 這時再掃會把「自己排的職業列」當成專精名塞回職業欄，
    -- 畫面上那一列重複一次（對照 MiliUI UnitLines.lua:221-238 的玩家實錄教訓）。
    local specLine = not relayout and GetOriginalSpecLine(tip, raw.className) or nil
    if specLine then
        raw.className = specLine
        HideOriginalSpecLine(tip, specLine)
        if unitGuid then
            state.specGuid = unitGuid
            state.specLine = specLine
        end
    elseif unitGuid and state.specGuid == unitGuid and type(state.specLine) == "string" then
        raw.className = state.specLine
    end

    -- 行 1：名稱 + 狀態 + 頭銜(PVP 名)
    local r1 = {}
    if raw.name then table.insert(r1, raw.name) end
    if el.status ~= false then
        if raw.statusAFK then table.insert(r1, L.AFK) end
        if raw.statusDND then table.insert(r1, L.DND) end
        if raw.statusDC then table.insert(r1, L.DC) end
    end
    if el.title ~= false and raw.pvpName and raw.pvpName ~= raw.name then
        table.insert(r1, raw.pvpName)
    end
    rows[1] = SafeJoin(r1, " ")

    -- 行 2：等級 + 種族 + 職業(職業色) + 性別
    local r2 = {}
    if el.level ~= false and raw.level ~= nil then
        local lv = S.PlainNumber(raw.level)
        if lv ~= nil then
            if raw.classColoredLevel then
                local r, g, b = Colors.UnitColor(unit)
                if r then
                    table.insert(r2, string.format("|cff%02x%02x%02x%d|r", r * 255, g * 255, b * 255, lv))
                else
                    table.insert(r2, tostring(lv))
                end
            else
                table.insert(r2, tostring(lv))
            end
        end
    end
    if el.race ~= false and raw.race then table.insert(r2, S.PlainText(raw.race) or "") end
    if el.className ~= false and raw.className then
        table.insert(r2, classColoredName(unit, raw.className))
    end
    -- 性別：C1 未暴露開關，預設不顯示（參考源 gender enable=false）；
    -- 之前無守衛把 UnitSex 的裸數字（2/3）漏進行2（實機截圖實錄：「3」）
    if el.gender == true and raw.gender ~= nil then
        table.insert(r2, UnitInfo.GetGender(raw.gender) or raw.gender)
    end
    rows[2] = SafeJoin(r2, " ")

    -- 行 3：公會
    if el.guild ~= false and raw.guild then
        local g = raw.guild
        if raw.guildRank then g = g .. " <" .. raw.guildRank .. ">" end
        rows[3] = g
    end

    -- 先隱藏暴雪原生行，避免與我們重寫的行並存（對照 MiliUI UnitLines.lua:252-256）。
    Lines.HideRange(tip, 2, 3)
    if LEVEL then Lines.Hide(tip, "^" .. LEVEL) end
    if FACTION_ALLIANCE then Lines.Hide(tip, "^" .. FACTION_ALLIANCE) end
    if FACTION_HORDE then Lines.Hide(tip, "^" .. FACTION_HORDE) end
    if PVP then Lines.Hide(tip, "^" .. PVP) end

    -- 寫入行
    for i = 1, #rows do
        local line = Lines.Get(tip, i)
        if line then pcall(line.SetText, line, rows[i]) end
    end

    -- 名稱行按職業色
    local line1 = Lines.Get(tip, 1)
    if line1 and el.className ~= false then
        local r, g, b = Colors.UnitColor(unit)
        if r then pcall(line1.SetTextColor, line1, r, g, b) end
    end
end

------------------------------------------------------------
-- NPC
------------------------------------------------------------
local function classifText(token)
    local plain = S.PlainText(token)
    if not plain then return nil end
    if plain == "worldboss" then return L.CLASSIFICATION_WORLDBOSS or "Boss" end
    if plain == "elite" then return L.CLASSIFICATION_ELITE or "Elite" end
    if plain == "rare" then return L.CLASSIFICATION_RARE or "Rare" end
    if plain == "rareelite" then return (L.CLASSIFICATION_RARE or "Rare") .. " " .. (L.CLASSIFICATION_ELITE or "Elite") end
    return nil
end

local function ApplyNpc(tip, state, unit, config, raw)
    local el = config.elements or {}
    local rows = {}

    local r1 = {}
    if raw.name then table.insert(r1, raw.name) end
    if el.status ~= false then
        if raw.statusAFK then table.insert(r1, L.AFK) end
        if raw.statusDND then table.insert(r1, L.DND) end
        if raw.statusDC then table.insert(r1, L.DC) end
    end
    rows[1] = SafeJoin(r1, " ")

    local r2 = {}
    if el.level ~= false and raw.level ~= nil then
        local lv = S.PlainNumber(raw.level)
        if lv ~= nil then
            if raw.classColoredLevel then
                local r, g, b = Colors.UnitColor(unit)
                if r then
                    table.insert(r2, string.format("|cff%02x%02x%02x%d|r", r * 255, g * 255, b * 255, lv))
                else
                    table.insert(r2, tostring(lv))
                end
            else
                table.insert(r2, tostring(lv))
            end
        end
    end
    if el.race ~= false and raw.race then table.insert(r2, S.PlainText(raw.race) or "") end
    if el.className ~= false and raw.className then
        table.insert(r2, classColoredName(unit, raw.className))
    end
    local ct = classifText(raw.classif)
    if ct then table.insert(r2, ct) end
    if el.title ~= false and raw.npcTitle then table.insert(r2, raw.npcTitle) end
    rows[2] = SafeJoin(r2, " ")

    for i = 1, #rows do
        local line = Lines.Get(tip, i)
        if line then pcall(line.SetText, line, rows[i]) end
    end

    -- 隱藏原生等級 / PVP 行（對照 MiliUI UnitLines.lua:316-317）
    if LEVEL then Lines.Hide(tip, "^" .. LEVEL) end
    if PVP then Lines.Hide(tip, "^" .. PVP) end

    local line1 = Lines.Get(tip, 1)
    if line1 then
        local r, g, b = Colors.ReactionColor(unit)
        if r then pcall(line1.SetTextColor, line1, r, g, b) end
    end
end

------------------------------------------------------------
-- 右鍵提示移除
------------------------------------------------------------
function UnitLines.RemoveRightClickHint(tip)
    if not ns.db or not ns.settings.general.hideUnitFrameHint then return end
    if S.IsForbiddenObject(tip) then return end
    if not UNIT_POPUP_RIGHT_CLICK then return end
    local name = tip:GetName()
    local ok, num = pcall(tip.NumLines, tip)
    num = (ok and not S.IsSecret(num)) and (tonumber(num) or 0) or 0
    for i = 2, num do
        local line = _G[name .. "TextLeft" .. i]
        local stripped = Lines.StripText(line and line:GetText())
        if stripped and stripped == UNIT_POPUP_RIGHT_CLICK then
            pcall(line.SetText, line, "")
        end
    end
end

------------------------------------------------------------
-- 主入口
------------------------------------------------------------
function UnitLines.Apply(tip, state, unit, relayout)
    if not ns.db or not unit then return end

    local exists = S.SafeCall(UnitExists, unit)
    if exists ~= nil and not S.IsSecret(exists) and not exists then return end

    local guid = S.SafeCall(UnitGUID, unit)
    if state.unitGuid ~= nil and guid ~= nil and not (state.unitGuid == guid) then
        state.specGuid, state.specLine = nil, nil
    end
    state.unit = unit
    state.unitGuid = guid
    state.isUnitTip = true

    local isPlayer = S.SafeBool(UnitIsPlayer, unit)
    local kind = isPlayer and "player" or "npc"
    local config = isPlayer and ns.settings.unit.player or ns.settings.unit.npc
    local raw = UnitInfo.GetUnitInfo(unit, kind)

    if isPlayer then
        ApplyPlayer(tip, state, unit, config, raw)
    else
        ApplyNpc(tip, state, unit, config, raw)
    end

    ColorBorder(tip, config, unit)
    ColorBackground(tip, config)
    GrayForDead(tip, config, unit)
    if config.elements and config.elements.factionBig then
        Skin.SetFactionBig(tip, raw.faction)
    else
        Skin.SetFactionBig(tip, nil)
    end
    UnitLines.RemoveRightClickHint(tip)

    if relayout and not S.IsForbiddenObject(tip) then
        local ok, shown = pcall(tip.IsShown, tip)
        if ok and shown then pcall(tip.Show, tip) end
    end
    return config, raw
end
