--[[
adeMapMark - Commands（/amm 总入口）
定位：唯一斜杠命令，子命令 io / debug / config；无参为快捷标记
体系：ADE v6.5
计划：_docs/plans/adeMapMark-dev-plan.md §4.5
]]

local ns = _G.adeMapMark
local L = ns.L

local function printLine(s)
    ns.Print(tostring(s))
end

local function cmdDebug(sub)
    local subCmd = strlower(sub or "")
    if subCmd == "on" or subCmd == "off" then
        ns.debugEnabled = subCmd == "on"
        printLine("Debug: " .. (ns.debugEnabled and "ON" or "OFF"))
    elseif subCmd == "" or subCmd == "providers" then
        local list = ns:GetProviderList()
        printLine(string.format("Providers: %d", #list))
        for _, p in ipairs(list) do
            printLine(string.format("  [%s] %s v%s - %d marks (enabled=%s)",
                p.name, p.title, tostring(p.version), p.count,
                tostring(p.db and p.db.enabled ~= false)))
            -- mapID 分布：确认外挂数据是否覆盖当前地图
            local dist = {}
            local marks = ns.safecall(function()
                for _, prov in ipairs(ns.markProviders) do
                    if prov.name == p.name then return prov:GetMarks() end
                end
            end)
            if type(marks) == "table" then
                for _, m in ipairs(marks) do
                    if m and m.mapID then dist[m.mapID] = (dist[m.mapID] or 0) + 1 end
                end
            end
            local parts = {}
            for mapID, count in pairs(dist) do parts[#parts + 1] = mapID .. ":" .. count end
            table.sort(parts)
            if #parts > 0 then printLine("    mapID -> " .. table.concat(parts, "  ")) end
        end
        local curMap = WorldMapFrame and WorldMapFrame.GetMapID and WorldMapFrame:GetMapID()
        printLine("Current world map: " .. tostring(curMap))
    elseif subCmd == "env" then
        printLine("WorldMapTab: " .. tostring(LibStub("LibWorldMapTabs", true) ~= nil))
        printLine("HBD: " .. tostring(LibStub("HereBeDragons-2.0", true) ~= nil))
        printLine("TomTom: " .. tostring(C_AddOns.IsAddOnLoaded("TomTom")))
    elseif subCmd == "db" then
        local db = ns.db()
        printLine(string.format("DB: %d markers", #(db.markers or {})))
    elseif subCmd == "marks" then
        for _, m in ipairs(ns:GetProviderMarkers()) do
            printLine(string.format("  [%s] %s (%s)", m.mapID, m.title, tostring(m.coord)))
        end
    else
        printLine(L.COMMAND_USAGE)
    end
end

SlashCmdList["ADEMAPMARK"] = function(msg)
    local text = strtrim(msg or "")
    local cmd, rest = text:match("^(%S+)%s*(.*)$")
    if not cmd then
        ns.QuickMark("")
        return
    end
    cmd = strlower(cmd)
    if cmd == "io" then
        if ns.ShowIOFrame then ns.ShowIOFrame() end
    elseif cmd == "config" then
        if ns.OpenSettingsPanel then ns.OpenSettingsPanel() end
    elseif cmd == "debug" then
        cmdDebug(rest)
    else
        -- 非子命令视为标记标题（快捷标记）
        ns.QuickMark(text)
    end
end
SLASH_ADEMAPMARK1 = "/amm"
