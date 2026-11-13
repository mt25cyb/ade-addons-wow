----------------------------------------------------------------------------
-- idTipExt 斜杠命令（统一入口）
-- /idtip /idtipext 打开设置页；/geo /geowatcher 控制地理监视面板。
----------------------------------------------------------------------------

local addonName = ...
local ns = _G[addonName]

SLASH_IDTIPEXT1 = "/idtip"
SLASH_IDTIPEXT2 = "/idtipext"
SlashCmdList.IDTIPEXT = function()
	ns.OpenSettings()
end

SLASH_IDTIPGEO1 = "/geowatcher"
SLASH_IDTIPGEO2 = "/geo"
SlashCmdList.IDTIPGEO = function(msg)
	local cmd = string.lower(string.match(msg or "", "^%s*(.-)%s*$") or "")
	local geo = ns.GeoCmd
	if not geo then return end

	if cmd == "" or cmd == "toggle" then
		geo.Toggle()
	elseif cmd == "show" then
		geo.Show()
	elseif cmd == "hide" then
		geo.Hide()
	elseif cmd == "reset" then
		geo.Reset()
	elseif cmd == "clear" then
		geo.Clear()
	elseif cmd == "hex" then
		geo.Hex()
	elseif cmd == "dec" then
		geo.Dec()
	elseif cmd == "lock" then
		geo.Lock()
	elseif cmd == "config" or cmd == "options" or cmd == "settings" then
		geo.Config()
	elseif cmd == "debug" then
		geo.Debug()
	else
		ns.PrintPanelMsg("/geo | /geo show|hide|reset|clear|hex|dec|lock|config|debug | /idtip 设置")
	end
end
