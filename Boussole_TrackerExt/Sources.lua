local _, ns = ...
local Addon = ns.Addon
local L = Addon.L

local Sources = {}
Addon.Sources = Sources

-- 任务类兜底图标：CompassHUD 默认纹理预设的 Normal 指针（CompassHUD.lua:316 MiniMap-QuestArrow）。
-- 不用原生 SuperTrackedFrame 的 Navigation-Tracked-Icon（SuperTrackedFrame.lua:218）——那是棱形图标，
-- 与世界任务奖励图标的观感差距大，CompassHUD 也已改用指针预设。
local QUEST_ATLAS = "MiniMap-QuestArrow"
local WAYPOINT_ATLAS = "Waypoint-MapPin-Tracked"

local function typeEnum(name)
	return Enum and Enum.SuperTrackingType and Enum.SuperTrackingType[name]
end

local function pinTypeEnum(name)
	return Enum and Enum.SuperTrackingMapPinType and Enum.SuperTrackingMapPinType[name]
end

-- 统一 pcall 取值：WoW 这些接口在异常输入下会抛错，任何一处抛错都不应让整个解析链中断
local function call(fn, ...)
	if type(fn) ~= "function" then return nil end
	local ok, a, b, c = pcall(fn, ...)
	if ok then return a, b, c end
	return nil
end

local function getPlayerMapID()
	return call(C_Map and C_Map.GetBestMapForUnit, "player")
end

-- 与游戏绘制「超级追踪航点」pin 使用同一 API
-- （Blizzard_SharedMapDataProviders/SuperTrackWaypointDataProvider.lua 调用 C_SuperTrack.GetNextWaypointForMap，
--   12.x 中该函数已改道 C_Navigation.GetNextWaypointForMap，两者等价）
local function getWaypointOnMap(mapID)
	if not mapID then return nil end
	local x, y, text = call(C_Navigation and C_Navigation.GetNextWaypointForMap, mapID)
	if x and y then return x, y, text end
	return nil
end

local function superTrackedQuestID()
	local questID = call(C_SuperTrack and C_SuperTrack.GetSuperTrackedQuestID)
	if questID and questID > 0 then return questID end
	return nil
end

local function superTrackedMapPin()
	return call(C_SuperTrack and C_SuperTrack.GetSuperTrackedMapPin)
end

local function superTrackedVignette()
	return call(C_SuperTrack and C_SuperTrack.GetSuperTrackedVignette)
end

-- 任意超追踪类型的名称（任务物品 / 内容追踪等没有专门取名的接口时兜底）
local function superTrackedItemName()
	local name = call(C_SuperTrack and C_SuperTrack.GetSuperTrackedItemName)
	if type(name) == "string" and name ~= "" then return name end
	return nil
end

local function questComplete(questID)
	if not questID then return false end
	return call(C_QuestLog and C_QuestLog.IsComplete, questID) == true
end

local function questClassification(questID)
	if not questID then return nil end
	return call(C_QuestInfoSystem and C_QuestInfoSystem.GetQuestClassification, questID)
end

-- 世界任务 / 奖励目标（CompassHUD.lua:3527 isTask）
local function isTaskQuest(questID)
	local classification = questClassification(questID)
	if not classification or not Enum or not Enum.QuestClassification then return false end
	return classification == Enum.QuestClassification.BonusObjective
		or classification == Enum.QuestClassification.WorldQuest
end

-- CompassHUD「Modern」纹理预设（CompassHUD.lua:484-570），只保留本插件需要的字段：
-- atlas = 进行中图标；turnin = 可交付图标；rotate = 该图标本身是方向箭头，贴边时可原地旋转
local MODERN_POINTERS
local function modernPointers()
	if MODERN_POINTERS ~= nil then return MODERN_POINTERS or nil end
	local Q = Enum and Enum.QuestClassification
	local F = Enum and Enum.QuestFrequency
	if not (Q and F) then return nil end
	local function arrow(atlas, turnin)
		return { atlas = atlas, turnin = turnin or atlas, rotate = true }
	end
	MODERN_POINTERS = {
		[Q.Important] = arrow("MiniMap-QuestArrow", "quest-important-turnin"),
		[Q.Legendary] = arrow("MiniMap-QuestArrow", "quest-legendary-turnin"),
		[Q.Campaign] = arrow("MiniMap-QuestArrow", "Quest-Campaign-TurnIn"),
		[Q.Calling] = arrow("MiniMap-QuestArrow", "callings-turnin"),
		[Q.Meta] = arrow("MiniMap-QuestArrow", "quest-wrapper-turnin"),
		[Q.Normal] = arrow("MiniMap-QuestArrow", "QuestTurnin"),
		[Q.Questline] = arrow("MiniMap-QuestArrow", "QuestTurnin"),
		[Q.WorldQuest] = arrow("Rotating-MinimapGuideArrow"),
		[Q.BonusObjective] = arrow("Rotating-MinimapGuideArrow"),
		[Q.Threat] = arrow("Rotating-MinimapGuideArrow"),
		-- 可重复任务按频率区分（CompassHUD getPointerCategory 把 Recurring 换成 frequency + 100）
		[F.Daily + 100] = arrow("MiniMap-VignetteArrow", "quest-recurring-turnin"),
		[F.Weekly + 100] = arrow("MiniMap-VignetteArrow", "quest-recurring-turnin"),
		[F.ResetByScheduler + 100] = arrow("MiniMap-VignetteArrow", "quest-recurring-turnin"),
	}
	return MODERN_POINTERS
end

-- 任务分类（CompassHUD.lua:3507 getPointerCategory 同序）
local function questCategory(questID)
	local classification = questClassification(questID)
	if not classification then return nil end
	local Q = Enum and Enum.QuestClassification
	if Q and classification == Q.Recurring then
		local index = call(C_QuestLog and C_QuestLog.GetLogIndexForQuestID, questID)
		local info = index and call(C_QuestLog and C_QuestLog.GetInfo, index)
		classification = (info and info.frequency and (info.frequency + 100)) or classification
	end
	return classification
end

-- 世界任务 / 奖励目标奖励图标（CompassHUD.lua:3534 getWQicon 同序）
-- 返回贴图（fileID 或路径）：有金币奖励用金币，否则取奖励物品 / 货币图标
local function worldQuestRewardTexture(questID)
	if not questID then return nil end
	if C_TaskQuest and C_TaskQuest.RequestPreloadRewardData then
		pcall(C_TaskQuest.RequestPreloadRewardData, questID)
	end
	local gold = call(_G.GetQuestLogRewardMoney, questID)
	if gold and gold > 0 then
		return [[Interface\Icons\INV_Misc_Coin_02]]
	end
	local _, itemTexture = call(_G.GetQuestLogRewardInfo, 1, questID)
	if itemTexture then return itemTexture end
	local reward = call(C_QuestLog and C_QuestLog.GetQuestRewardCurrencyInfo, questID, 1, false)
	return reward and reward.texture or nil
end

-- 追踪扩展信息图标规格（供 Emphasis 渲染）：
--   icon.texture  奖励贴图（世界任务），优先于 atlas
--   icon.atlas    暴雪原生 atlas
--   icon.rotate   该图标是方向箭头，贴边时可原地旋转（CompassHUD textureRotate）
--   icon.circle   圆形容器（圆形遮罩 + 头像边框，CompassHUD circle 分支）
local function questIconSpec(questID, completed)
	if isTaskQuest(questID) and Addon.settings and Addon.settings.useRewardIcon ~= false then
		local texture = worldQuestRewardTexture(questID)
		if texture then
			return { texture = texture, rotate = false, circle = true }
		end
	end

	local presets = modernPointers()
	local preset = presets and presets[questCategory(questID) or -1]
	if preset then
		return {
			atlas = completed and preset.turnin or preset.atlas,
			rotate = (not completed) and preset.rotate == true,
		}
	end
	return { atlas = QUEST_ATLAS, rotate = true }
end

local function atlasIconSpec(atlas, rotate)
	return { atlas = atlas or QUEST_ATLAS, rotate = rotate == true }
end
Sources.AtlasIconSpec = atlasIconSpec

-- 任务在「指定地图」上的坐标（CompassHUD.lua:3228 getQuestPOIInfo 同序）
local function questPositionOnMap(questID, mapID)
	if not (questID and mapID) then return nil end
	local x, y = call(C_QuestLog and C_QuestLog.GetNextWaypointForMap, questID, mapID)
	if x and y then return x, y end
	local quests = call(C_QuestLog and C_QuestLog.GetQuestsOnMap, mapID)
	if quests then
		for _, quest in pairs(quests) do
			if quest and quest.questID == questID and quest.x and quest.y then
				return quest.x, quest.y
			end
		end
	end
	return nil
end

-- 任务自身地图与坐标（CompassHUD.lua:3228 getQuestPOIInfo）
local function questOwnPosition(questID)
	if not questID then return nil end
	local mapID, x, y = call(C_QuestLog and C_QuestLog.GetNextWaypoint, questID)
	if mapID and mapID > 0 and x and y then return mapID, x, y end

	mapID = call(C_QuestLog and C_QuestLog.GetQuestAdditionalHighlights, questID)
	if mapID and mapID > 0 then
		x, y = questPositionOnMap(questID, mapID)
		if x and y then return mapID, x, y end
	end
	return nil
end

-- 任务实际位置：世界任务/奖励目标走 C_TaskQuest，其余走任务航点（CompassHUD.lua updateQuest 同序）
local function questPosition(questID)
	if isTaskQuest(questID) then
		local mapID = call(C_TaskQuest and C_TaskQuest.GetQuestZoneID, questID)
		if not mapID or mapID == 0 then
			mapID = call(C_QuestLog and C_QuestLog.GetMapForQuestPOIs)
		end
		if not mapID or mapID == 0 then
			mapID = Addon:FindQuestMapID(questID)
		end
		if mapID and mapID > 0 then
			local x, y = call(C_TaskQuest and C_TaskQuest.GetQuestLocation, questID, mapID)
			if x and y then return mapID, x, y end
			x, y = questPositionOnMap(questID, mapID)
			if x and y then return mapID, x, y end
		end
	end
	return questOwnPosition(questID)
end

local function buildQuest(playerMapID, wx, wy, overrideQuestID)
	local questID = overrideQuestID or superTrackedQuestID()
	if not questID then return nil end

	local mapID, x, y
	-- 优先用「玩家所在地图上的系统航点坐标」，与罗盘刻线上的原生航点 pin 完全一致
	if playerMapID and wx and wy then
		mapID, x, y = playerMapID, wx, wy
	else
		mapID, x, y = questPosition(questID)
	end
	if not (mapID and x and y) then return nil end

	local name = call(C_QuestLog and C_QuestLog.GetTitleForQuestID, questID)
	if not name or name == "" then name = superTrackedItemName() end

	local completed = questComplete(questID)
	local icon = questIconSpec(questID, completed)
	return {
		kind = "quest",
		id = questID,
		mapID = mapID,
		x = x,
		y = y,
		name = name,
		completed = completed,
		icon = icon,
		atlas = icon.texture or icon.atlas,
	}
end

-- 兜底：当超追踪候选不可解析（如未接受的可接任务 QuestOffer 被顶在超追踪位、玩家点其它目标也切不掉）时，
-- 退而显示用户真正在追踪（tracked）的任务，避免扩展信息持久失效（见开发计划 §7.12）。
-- 仅读取、不修改游戏状态；API 返回格式不确定时静默返回 nil（不影响其它路径）。
local function resolveTrackedQuest(playerMapID, wx, wy)
	if not (C_QuestLog and type(C_QuestLog.GetTrackedQuests) == "function") then return nil end
	local ok, tracked = pcall(C_QuestLog.GetTrackedQuests)
	if not (ok and tracked) then return nil end
	for _, entry in ipairs(tracked) do
		local questID = tonumber(entry)
		if questID and questID > 0 then
			local q = buildQuest(playerMapID, wx, wy, questID)
			if q then return q end
		end
	end
	return nil
end

local function buildUserWaypoint(playerMapID, wx, wy)
	local mapID, x, y = playerMapID, wx, wy
	if not (x and y) then
		local point = call(C_Map and C_Map.GetUserWaypoint)
		if point and point.position then
			mapID = point.uiMapID
			x, y = point.position.x, point.position.y
		end
	end
	if not (mapID and x and y) then return nil end
	return {
		kind = "userWaypoint",
		id = "userWaypoint",
		mapID = mapID,
		x = x,
		y = y,
		name = L.USER_WAYPOINT,
		atlas = WAYPOINT_ATLAS,
		icon = atlasIconSpec(WAYPOINT_ATLAS),
		completed = false,
	}
end

local function taxiNodesForMap(mapID)
	if not mapID then return nil end
	return call(C_TaxiMap and C_TaxiMap.GetTaxiNodesForMap, mapID)
end

local function makeMapPin(mapID, x, y, name, atlas, subKind, typeID)
	if not (mapID and x and y) then return nil end
	return {
		kind = "mapPin",
		id = typeID or 0,
		subKind = subKind,
		mapID = mapID,
		x = x,
		y = y,
		name = name or L.AREA_PIN,
		atlas = atlas,
		icon = atlasIconSpec(atlas),
		completed = false,
	}
end

local function buildMapPin(playerMapID, wx, wy)
	local pinType, typeID = superTrackedMapPin()
	if not (typeID and pinType) then return nil end

	local uiMapID = playerMapID or getPlayerMapID()

	-- 区域 POI（鸟点、事件、洞窟入口等）
	if pinType == pinTypeEnum("AreaPOI") then
		local poi, poiMapID
		if uiMapID then
			poi = call(C_AreaPoiInfo and C_AreaPoiInfo.GetAreaPOIInfo, uiMapID, typeID)
			if poi then poiMapID = uiMapID end
		end
		if not poi then
			-- uiMapID 为 nil 时回落到「当前地图」查询；此时坐标不可信，位置另走系统航点
			poi = call(C_AreaPoiInfo and C_AreaPoiInfo.GetAreaPOIInfo, nil, typeID)
		end
		if poi then
			if poiMapID and poi.position and poi.position.x and poi.position.y then
				return makeMapPin(poiMapID, poi.position.x, poi.position.y,
					poi.name, poi.atlasName, "areaPOI", typeID)
			end
			local res = makeMapPin(uiMapID, wx, wy, poi.name, poi.atlasName, "areaPOI", typeID)
			if res then return res end
		end
	end

	-- 可接任务（未接受）：真实坐标在 C_TaskQuest.GetQuestZoneID → GetQuestLocation（
	-- 用户实测 94790 有效；暴雪 WorldQuestDataProvider.lua:505 同款；CompassHUD OnEvent L4860-4869 同源）。
	-- typeID 即 questID；未接受任务 classification 未必可靠，故不套 isTaskQuest 门控、直接试 task API。
	if pinType == pinTypeEnum("QuestOffer") then
		local name = call(C_QuestLog and C_QuestLog.GetTitleForQuestID, typeID)
		local mapID, x, y
		-- ① 首选：C_TaskQuest task 源坐标
		local taskMapID = call(C_TaskQuest and C_TaskQuest.GetQuestZoneID, typeID)
		if taskMapID and taskMapID > 0 then
			x, y = call(C_TaskQuest and C_TaskQuest.GetQuestLocation, typeID, taskMapID)
			if x and y then mapID = taskMapID end
		end
		-- ② C_QuestLine 任务线坐标（对 questline 源 offer 有效）
		if not (mapID and x and y) and C_QuestLine and C_QuestLine.GetQuestLineInfo then
			local info = call(C_QuestLine.GetQuestLineInfo, typeID, uiMapID)
			if info and info.x and info.y then mapID, x, y = uiMapID, info.x, info.y end
			if not (mapID and x and y) then
				info = call(C_QuestLine.GetQuestLineInfo, typeID)
				if info and info.x and info.y then
					x, y = info.x, info.y
					mapID = (info.startMapID and info.startMapID > 0) and info.startMapID or uiMapID
				end
			end
		end
		-- ③ 兜底：任务通用位置（含 task 分支与 questOwnPosition）
		if not (mapID and x and y) then
			mapID, x, y = questPosition(typeID)
		end
		if mapID and x and y then
			return makeMapPin(mapID, x, y, name, nil, "questOffer", typeID)
		end
		return nil
	end

	-- 飞行点：从玩家地图逐级向上找，命中即为该节点的真实坐标
	if pinType == pinTypeEnum("TaxiNode") then
		local mapID = uiMapID
		for _ = 1, 4 do
			local taxis = taxiNodesForMap(mapID)
			if taxis then
				for _, taxi in pairs(taxis) do
					if taxi and taxi.nodeID == typeID and taxi.position then
						return makeMapPin(mapID, taxi.position.x, taxi.position.y,
							taxi.name, taxi.atlasName, "taxi", typeID)
					end
				end
			end
			local info = call(C_Map and C_Map.GetMapInfo, mapID)
			mapID = info and tonumber(info.parentMapID)
			if not mapID or mapID == 0 then break end
		end
	end

	-- 兜底：系统给出的航点位置（传送点/入口），名称取超追踪条目名
	return makeMapPin(uiMapID, wx, wy, superTrackedItemName(), nil, "waypoint", typeID)
end

local function buildVignette(playerMapID, wx, wy)
	local guid = superTrackedVignette()
	if not guid then return nil end
	local uiMapID = playerMapID or getPlayerMapID()
	if not uiMapID then return nil end

	local name, atlasName
	local info = call(C_VignetteInfo and C_VignetteInfo.GetVignetteInfo, guid)
	if info then name, atlasName = info.name, info.atlasName end

	local x, y = wx, wy
	local position = call(C_VignetteInfo and C_VignetteInfo.GetVignettePosition, guid, uiMapID)
	if position and position.GetXY then x, y = position:GetXY() end
	if not (x and y) then
		local res = makeMapPin(uiMapID, wx, wy, name or superTrackedItemName(), atlasName, "vignette", guid)
		if res then
			res.kind = "vignette"
			res.id = guid
		end
		return res
	end
	return {
		kind = "vignette",
		id = guid,
		mapID = uiMapID,
		x = x,
		y = y,
		name = name or superTrackedItemName(),
		atlas = atlasName,
		icon = atlasIconSpec(atlasName),
		completed = false,
	}
end

local function buildGeneric(playerMapID, wx, wy, waypointText)
	if not (playerMapID and wx and wy) then return nil end
	local name = waypointText
	if not name or name == "" then name = superTrackedItemName() or L.AREA_PIN end
	return {
		kind = "generic",
		id = 0,
		mapID = playerMapID,
		x = wx,
		y = wy,
		name = name,
		atlas = QUEST_ATLAS,
		icon = atlasIconSpec(QUEST_ATLAS, true),
		completed = false,
	}
end

function Sources:ResolveCurrent()
	if not (C_SuperTrack and C_SuperTrack.GetHighestPrioritySuperTrackingType) then return nil end
	-- 没有任何超追踪内容时直接返回，避免把残留航点当成目标显示
	local trackingType = call(C_SuperTrack.GetHighestPrioritySuperTrackingType)
	if trackingType == nil then return nil end

	local playerMapID = getPlayerMapID()
	local wx, wy, waypointText = getWaypointOnMap(playerMapID)

	local res
	if trackingType == typeEnum("Quest") then
		res = buildQuest(playerMapID, wx, wy)
	elseif trackingType == typeEnum("UserWaypoint") then
		res = buildUserWaypoint(playerMapID, wx, wy)
	elseif trackingType == typeEnum("MapPin") then
		res = buildMapPin(playerMapID, wx, wy)
	elseif trackingType == typeEnum("Vignette") then
		res = buildVignette(playerMapID, wx, wy)
	end

	-- 已知类型（Quest/UserWaypoint/MapPin/Vignette）解析失败（如可接任务 QuestOffer 未接受、无坐标）：
	-- 与 CompassHUD 一致【不显示】，绝不用系统航点（buildGeneric）顶替成错误目标。
	-- 仅「未列出的新类型」（Content / Corpse / PartyMember 等）才兜底走系统航点。
	local listed = trackingType == typeEnum("Quest")
		or trackingType == typeEnum("UserWaypoint")
		or trackingType == typeEnum("MapPin")
		or trackingType == typeEnum("Vignette")
	if not res and not listed then
		res = buildGeneric(playerMapID, wx, wy, waypointText)
	end
	-- 已知类型解析失败（如某类超追踪候选无坐标）时，退而显示用户真正在追踪（tracked）的任务，
	-- 避免扩展信息空白（见开发计划 §7.13）。trackingType 至此必非 nil（开头已 return）。
	if not res then
		res = resolveTrackedQuest(playerMapID, wx, wy)
	end
	return res
end
