----------------------------------------------------------------------------
-- idTipExt 斜杠命令（统一入口）
-- /idtip /idtipext 打开设置页。
-- v1.4.0：/geo /geowatcher 随地理监视面板拆出至 adeMapExt。
----------------------------------------------------------------------------

local addonName = ...
local ns = _G[addonName]

SLASH_IDTIPEXT1 = "/idtip"
SLASH_IDTIPEXT2 = "/idtipext"
SlashCmdList.IDTIPEXT = function()
	ns.OpenSettings()
end
