local _, addon = ...

-- 家宅传送。移植自 AstralGate Services/Housing.lua。
--
-- ⚠ 房屋列表是异步回来的（C_Housing.GetPlayerOwnedHouses 触发
-- PLAYER_HOUSE_LIST_UPDATED），绝不能在回调里直接传送：受保护的动作必须由玩家
-- 的下一次点击触发，所以这里只把参数写进按钮的安全属性。
--
-- 12.x 实证：
--   C_Housing.TeleportHome / C_Housing.ReturnAfterVisitingHouse
--     —— SecureTemplates.lua 的 SECURE_ACTIONS.teleporthome / returnhome
--   SECURE_ACTIONS.teleporthome 读 house-neighborhood-guid / house-guid / house-plot-id
--     —— SecureTemplates.lua:626-646
addon.Housing = {}
local Housing = addon.Housing
local houses = {}
-- 社区所在地图决定阵营：2352 联盟、2351 部落（AstralGate Housing.lua:8）。
local mapFactions = { [2352] = "Alliance", [2351] = "Horde" }

--- 此刻点下去是「返回原地」而不是「传送回家」吗。
function Housing.CanReturn(faction)
	local house = houses[faction]
	return house ~= nil and C_HousingNeighborhood and C_HousingNeighborhood.CanReturnAfterVisitingHouse
		and C_HousingNeighborhood.CanReturnAfterVisitingHouse()
		and C_Housing.GetCurrentNeighborhoodGUID() == house.neighborhoodGUID or false
end

--- 该阵营的家宅是否可用（有房 + API 在）。
function Housing.IsAvailable(faction)
	return C_Housing and C_Housing.TeleportHome and C_Housing.ReturnAfterVisitingHouse
		and houses[faction] ~= nil or false
end

--- 把左键动作写进按钮。战斗中不能改安全属性，直接放弃本次配置。
function Housing.ConfigureButton(button, faction)
	if InCombatLockdown() then return end
	button:SetAttribute("type1", nil)
	if not Housing.IsAvailable(faction) then return end
	if Housing.CanReturn(faction) then
		button:SetAttribute("type1", "returnhome")
	else
		local house = houses[faction]
		button:SetAttribute("house-neighborhood-guid1", house.neighborhoodGUID)
		button:SetAttribute("house-guid1", house.houseGUID)
		button:SetAttribute("house-plot-id1", house.plotID)
		button:SetAttribute("type1", "teleporthome")
	end
end

if C_Housing and C_Housing.GetPlayerOwnedHouses then
	local frame = CreateFrame("Frame")
	-- 12.x 强制：先挂载脚本再注册事件，避免插件安装的 handler 不生效。
	frame:SetScript("OnEvent", function(_, event, houseInfos)
		if event == "PLAYER_ENTERING_WORLD" then
			C_Housing.GetPlayerOwnedHouses()
		else
			houses = {}
			for _, house in ipairs(houseInfos or {}) do
				if house.neighborhoodGUID and house.houseGUID and house.plotID then
					local faction = mapFactions[C_Housing.GetUIMapIDForNeighborhood(house.neighborhoodGUID)]
					if faction then houses[faction] = house end
				end
			end
			-- 列表到了才刷新，让条目从「不可用」变成可用、标题切到「离家归来」。
			if addon.MapPanel and addon.MapPanel.Refresh then addon.MapPanel.Refresh() end
		end
	end)
	frame:RegisterEvent("PLAYER_ENTERING_WORLD")
	frame:RegisterEvent("PLAYER_HOUSE_LIST_UPDATED")
end
