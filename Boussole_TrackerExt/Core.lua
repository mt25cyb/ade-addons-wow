local _, ns = ...
local Addon = ns.Addon
local L = Addon.L

Addon.version = C_AddOns and C_AddOns.GetAddOnMetadata
	and C_AddOns.GetAddOnMetadata(Addon.name, "Version") or "1.0.0"

Addon.settings = nil
Addon.Capabilities = {
	api = false,           -- BoussoleAPI v1 兼容
	compass = false,       -- Boussole.modules.Compass 存在
	internal = false,      -- Compass._internal 关键字段齐全
	nativeMapPins = false, -- NativeMapPins.GetPositionOnMap 可用
	navigation = false,    -- C_Navigation.GetNextWaypointForMap 可用
	crossMap = false,      -- Compass._internal.getCrossMapBearingAndDistance 可用
}
Addon.Compass = nil
Addon.CI = nil
Addon.NativeMapPins = nil
Addon.Tracked = nil    -- 当前超追踪目标描述（Sources 产出）
Addon.dirty = true
Addon.lastResolveAt = 0

local function applyDefaults(target, defaults)
	for key, value in pairs(defaults) do
		if type(value) == "table" then
			target[key] = type(target[key]) == "table" and target[key] or {}
			applyDefaults(target[key], value)
		elseif target[key] == nil then
			target[key] = value
		end
	end
end

function Addon:InitSettings()
	BoussoleTrackerExtDB = BoussoleTrackerExtDB or {}
	BoussoleTrackerExtDB.settings = BoussoleTrackerExtDB.settings or {}
	applyDefaults(BoussoleTrackerExtDB.settings, self.DEFAULTS.settings)
	self.settings = BoussoleTrackerExtDB.settings
end

-- P0 能力探测：官方 API 层 + 内部层关键字段逐一核验，缺失即降级
function Addon:ProbeCapabilities()
	local caps = self.Capabilities

	local API = _G.BoussoleAPI
	caps.api = API ~= nil and type(API.IsCompatible) == "function" and API:IsCompatible(1) or false

	local hostOK = type(_G.Boussole) == "table" and type(_G.Boussole.modules) == "table"
	caps.compass = hostOK and type(_G.Boussole.modules.Compass) == "table"
	self.Compass = caps.compass and _G.Boussole.modules.Compass or nil

	local CI = self.Compass and self.Compass._internal or nil
	caps.internal = CI ~= nil
		and type(CI.getHeadingDegrees) == "function"
		and type(CI.getDisplayValues) == "function"
		and type(CI.normalizeAngle) == "function"
		and type(CI.getPlayerMapPosition) == "function"
		and type(CI.getBearingAndDistance) == "function"
		and type(CI.getMapWorldDimensions) == "function"
		and type(CI.pinFrames) == "table"
		and type(CI.CONFIG) == "table"
	self.CI = caps.internal and CI or nil

	local nmp = hostOK and _G.Boussole.NativeMapPins or nil
	caps.nativeMapPins = nmp ~= nil and type(nmp.GetPositionOnMap) == "function"
	self.NativeMapPins = caps.nativeMapPins and nmp or nil

	caps.navigation = type(_G.C_Navigation) == "table"
		and type(_G.C_Navigation.GetNextWaypointForMap) == "function"
	caps.crossMap = CI ~= nil and type(CI.getCrossMapBearingAndDistance) == "function"

	if not caps.internal then
		print(L.INCOMPATIBLE)
	end
end

-- mapID 上溯 parentMapID 至大陆级（底本 CompassHUD.lua:793-806 getContinentMapID）
function Addon:GetContinentMapID(mapID)
	mapID = tonumber(mapID)
	if not mapID or not C_Map or not C_Map.GetMapInfo then return nil end
	for _ = 1, 20 do
		local ok, info = pcall(C_Map.GetMapInfo, mapID)
		if not ok or not info then return nil end
		if info.mapType == nil or info.mapType <= Enum.UIMapType.Continent then
			return mapID
		end
		local parent = tonumber(info.parentMapID)
		if not parent or parent == 0 then return nil end
		mapID = parent
	end
	return nil
end

-- 目标相对朝向角与距离（复用 Boussole 内部同源数学，保证与原生图钉对齐）
-- 返回 bearing（度）、distance（码），不可达（不同世界实例）返回 nil
function Addon:ComputeBearing(res)
	local CI = self.CI
	if not CI or not res then return nil end

	-- 主插件「选定图钉」：主插件已算好 bearing/distance，直接沿用，避免二次换算偏差
	if res.bearing ~= nil then
		return res.bearing, res.distance
	end

	local playerMapID, px, py = CI.getPlayerMapPosition()
	if not playerMapID then return nil end

	if res.mapID == playerMapID or not res.mapID then
		res.transited = nil
		local mapWidth, mapHeight = CI.getMapWorldDimensions(playerMapID)
		return CI.getBearingAndDistance(px, py, res.x, res.y, mapWidth, mapHeight)
	end

	-- 跨图 1：「使用地图转换」开启时优先指向系统建议的转换点（传送门 / 入口），
	-- 与 CompassHUD 的 Options.UseCurrentMap 同一策略、同一 API
	if self.settings.useCurrentMap and self.Capabilities.navigation then
		local ok, wx, wy, desc = pcall(_G.C_Navigation.GetNextWaypointForMap, playerMapID)
		if ok and wx and wy then
			res.transitionDesc = desc
			res.transited = true
			local mapWidth, mapHeight = CI.getMapWorldDimensions(playerMapID)
			return CI.getBearingAndDistance(px, py, wx, wy, mapWidth, mapHeight)
		end
	end

	-- 跨图 2：主插件自带的世界坐标换算（同一 UiMap 实例内可直接得出真实方向，
	-- CompassHUD 亦以世界坐标跨图计算，故此处与它同源）
	if type(CI.getCrossMapBearingAndDistance) == "function" then
		local bearing, distance = CI.getCrossMapBearingAndDistance(res.mapID, res.x, res.y)
		if bearing then
			res.transited = nil
			return bearing, distance
		end
	end

	-- 跨图 3：把目标坐标投影到玩家地图（限同一实例）
	if self.NativeMapPins then
		local projectedX, projectedY = self.NativeMapPins:GetPositionOnMap(res.mapID, res.x, res.y, playerMapID)
		if projectedX and projectedY then
			res.transited = nil
			local mapWidth, mapHeight = CI.getMapWorldDimensions(playerMapID)
			return CI.getBearingAndDistance(px, py, projectedX, projectedY, mapWidth, mapHeight)
		end
	end

	return nil -- 不同世界实例且无法换算：目标不可达
end

-- 主插件「选定图钉」→ 追踪目标（仅在无超追踪目标时使用；两者冲突以超追踪为准）
function Addon:ResolveSelectedPin()
	local CI = self.CI
	if not CI or CI.selectedPinKey == nil or type(CI.pinFrames) ~= "table" then return nil end
	local key = CI.selectedPinKey
	local count = tonumber(CI.activePinCount) or #CI.pinFrames
	for index = 1, count do
		local pin = CI.pinFrames[index]
		if pin and pin.ItemKey == key and pin.TargetBearing ~= nil then
			local atlas = pin.Icon and pin.Icon.BoussoleAtlasName
			if (not atlas or atlas == "") and pin.IconLayerTextures then
				for _, layer in ipairs(pin.IconLayerTextures) do
					local data = layer and layer.BoussoleLayerData
					if data and data.atlas then
						atlas = data.atlas
						break
					end
				end
			end
			return {
				kind = "selectedPin",
				id = key,
				name = pin.Name or "",
				atlas = atlas,
				icon = self.Sources.AtlasIconSpec(atlas),
				bearing = pin.TargetBearing,
				distance = pin.TargetDistance,
				completed = false,
			}
		end
	end
	return nil
end

-- 任务所属地图（GetQuestZoneID / GetMapForQuestPOIs 无结果时的兜底，思路同 CompassHUD.lua getMapId，
-- 但把扫描范围限制在玩家所在大陆，避免每帧全表遍历）
function Addon:FindQuestMapID(questID)
	if not (questID and C_Map and C_Map.GetMapChildrenInfo
		and C_QuestLog and C_QuestLog.GetQuestsOnMap) then
		return nil
	end
	local now = GetTime and GetTime() or 0
	self.questMapScanCache = self.questMapScanCache or {}
	local cached = self.questMapScanCache[questID]
	if cached and (now - cached.at) < 30 then
		return cached.mapID
	end

	local playerMapID = C_Map.GetBestMapForUnit and C_Map.GetBestMapForUnit("player")
	local continent = self:GetContinentMapID(playerMapID) or playerMapID
	local found
	if continent then
		local ok, children = pcall(C_Map.GetMapChildrenInfo, continent, Enum.UIMapType.Zone, true)
		if ok and children then
			for _, info in ipairs(children) do
				if info and info.mapID then
					local ok2, quests = pcall(C_QuestLog.GetQuestsOnMap, info.mapID)
					if ok2 and quests then
						for _, quest in pairs(quests) do
							if quest and quest.questID == questID then
								found = info.mapID
								break
							end
						end
					end
				end
				if found then break end
			end
		end
	end

	self.questMapScanCache[questID] = { at = now, mapID = found }
	return found
end

function Addon:HideAllLayers()
	if self.Emphasis then self.Emphasis:HideAll() end
	if self.Overlay then self.Overlay:Hide() end
	if self.Scale then self.Scale:HideAll() end
end

-- 主更新循环（OnUpdate 节流调用）
function Addon:Update()
	local CI = self.CI
	if not CI then return end

	local frame = CI.frame
	if not frame or not frame:IsShown() then
		self:HideAllLayers()
		return
	end

	local now = GetTime and GetTime() or 0
	if self.dirty or (now - self.lastResolveAt) >= 1.0 then
		self.lastResolveAt = now
		self.dirty = false
		self.Tracked = self.Sources:ResolveCurrent()
	end

	local res = self.Tracked
	if res and (not self.settings.enabled
		or (res.kind == "userWaypoint" and not self.settings.trackUserWaypoint)) then
		res = nil
	end
	if res and self.settings.hideFar then
		local playerMapID = C_Map and C_Map.GetBestMapForUnit and C_Map.GetBestMapForUnit("player")
		local playerContinent = self:GetContinentMapID(playerMapID)
		local targetContinent = self:GetContinentMapID(res.mapID)
		if playerContinent and targetContinent and playerContinent ~= targetContinent then
			res = nil
		end
	end
	-- 回退到主插件「选定图钉」仅当【确实没有任何超追踪候选】时（GetHighestPrioritySuperTrackingType 为 nil）。
	-- 不能用 IsSuperTrackingAnything()：某些超追踪态（如 QuestOffer）下该接口返回 false，
	-- 会导致回退照样触发、旧图钉 persistent 显示（即「切换追踪也失效」，见开发计划 §7.12）。
	-- 有候选就不回退，保留「彻底无候选」时的手动选中图钉功能。
	local hasTrackingCandidate = false
	if _G.C_SuperTrack and type(_G.C_SuperTrack.GetHighestPrioritySuperTrackingType) == "function" then
		local ok, t = pcall(_G.C_SuperTrack.GetHighestPrioritySuperTrackingType)
		hasTrackingCandidate = ok and t ~= nil
	end
	if not res and self.settings.enabled and not hasTrackingCandidate then
		res = self:ResolveSelectedPin()
	end

	local trackedInfo = self.Pins:Update(res)
	self.Emphasis:Update(res, trackedInfo)
	self.Overlay:Update(res, trackedInfo)
	-- 原生「罗盘信息」条件性上移（仅当本块与其重叠时由 NativeInfo 让位）
	if self.NativeInfo then self.NativeInfo:Apply(trackedInfo) end
end

-- 每帧平滑重定位：只用已解析的 bearing + 当前朝向重算屏幕 X，消除「转向卡顿」
-- （解析与内容重建走 Update 的 0.12s 节流，位置每帧刷新）
function Addon:PositionTick()
	if not self.CI or not self.CI.frame or not self.CI.frame:IsShown() then return end
	self.Emphasis:PositionTick(self.Emphasis.trackedInfo)
	self.Overlay:Position(self.Emphasis.trackedInfo)
	if self.Scale then self.Scale:PositionTick() end
end

-- 诊断输出：逐项打印超追踪类型与解析结果，便于定位「某些追踪不显示」的具体环节
function Addon:PrintDebug()
	self:ProbeCapabilities()
	local caps = self.Capabilities
	local function flag(value) return tostring(value and true or false) end
	local addonTitle = (C_AddOns and C_AddOns.GetAddOnMetadata)
		and C_AddOns.GetAddOnMetadata(Addon.name, "Title") or Addon.name
	local addonVersion = (C_AddOns and C_AddOns.GetAddOnMetadata)
		and C_AddOns.GetAddOnMetadata(Addon.name, "Version") or (Addon.version or "?")
	print(string.format("|cff33ff99BTE|r %s |cffffff00v%s|r — 状态：api=%s 罗盘=%s 内部层=%s 导航=%s crossMap=%s nmp=%s",
		tostring(addonTitle), tostring(addonVersion),
		flag(caps.api), flag(caps.compass), flag(caps.internal), flag(caps.navigation),
		flag(caps.crossMap), flag(caps.nativeMapPins)))

	local function call(fn, ...)
		if type(fn) ~= "function" then return nil end
		local ok, a, b = pcall(fn, ...)
		if ok then return a, b end
		return nil
	end
	local function enumName(enumTable, value)
		if value == nil then return "nil" end
		if enumTable then
			for key, enumValue in pairs(enumTable) do
				if type(key) == "string" and enumValue == value then return key end
			end
		end
		return tostring(value)
	end

	local trackingType = call(C_SuperTrack and C_SuperTrack.GetHighestPrioritySuperTrackingType)
	local typeName = enumName(Enum and Enum.SuperTrackingType, trackingType)

	local questID = call(C_SuperTrack and C_SuperTrack.GetSuperTrackedQuestID)
	local pinType, pinID = call(C_SuperTrack and C_SuperTrack.GetSuperTrackedMapPin)
	local vignette = call(C_SuperTrack and C_SuperTrack.GetSuperTrackedVignette)

	print(string.format("|cff33ff99BTE|r type=%s quest=%s pinType=%s pinID=%s vignette=%s",
		typeName, tostring(questID),
		enumName(Enum and Enum.SuperTrackingMapPinType, pinType),
		tostring(pinID), tostring(vignette)))

	local playerMapID = C_Map and C_Map.GetBestMapForUnit and C_Map.GetBestMapForUnit("player")
	local wx, wy
	if C_Navigation and C_Navigation.GetNextWaypointForMap and playerMapID then
		local ok, x, y = pcall(C_Navigation.GetNextWaypointForMap, playerMapID)
		if ok then wx, wy = x, y end
	end
	print(string.format("|cff33ff99BTE|r playerMap=%s waypointOnMap=(%s, %s)",
		tostring(playerMapID), tostring(wx), tostring(wy)))

	local res = self.Sources:ResolveCurrent()
	if not res then
		print("|cff33ff99BTE|r 解析结果: nil（无可显示目标）")
	else
		local icon = res.icon or {}
		print(string.format("|cff33ff99BTE|r 解析结果: kind=%s name=%s mapID=%s pos=(%.4f, %.4f) icon=%s rotate=%s circle=%s",
			tostring(res.kind), tostring(res.name), tostring(res.mapID),
			tonumber(res.x) or -1, tonumber(res.y) or -1,
			tostring(icon.texture or icon.atlas or res.atlas),
			tostring(icon.rotate == true), tostring(icon.circle == true)))
		if res.bearing ~= nil then
			print(string.format("|cff33ff99BTE|r 主插件选定图钉: bearing=%s distance=%s",
				tostring(res.bearing), tostring(res.distance)))
		else
			local bearing, distance = self:ComputeBearing(res)
			print(string.format("|cff33ff99BTE|r 计算: bearing=%s distance=%s transited=%s",
				tostring(bearing), tostring(distance), tostring(res.transited)))
		end
	end

	local pin = self:ResolveSelectedPin()
	print(string.format("|cff33ff99BTE|r 主插件选定图钉: %s",
		pin and (tostring(pin.name) .. " bearing=" .. tostring(pin.bearing)) or "无"))
end

-- 节流帧驱动：每帧做平滑重定位（消除转向卡顿），每 0.12s 做一次目标解析与内容重建
local tickFrame = CreateFrame("Frame")
local tickElapsed = 0
tickFrame:SetScript("OnUpdate", function(_, elapsed)
	if Addon.CI then
		Addon:PositionTick()
	end
	tickElapsed = tickElapsed + (elapsed or 0)
	if tickElapsed < 0.12 then return end
	tickElapsed = 0
	Addon:Update()
end)
tickFrame:Hide()

local eventFrame = CreateFrame("Frame")
local gameEvents = {
	"SUPER_TRACKING_CHANGED",
	"SUPER_TRACKING_PATH_UPDATED",
	"USER_WAYPOINT_UPDATED",
	"QUEST_POI_UPDATE",
	"QUEST_LOG_UPDATE",
	"QUEST_TURNED_IN",
	"QUEST_ACCEPTED",          -- 接任务后状态变化，需立即重解析
	"WAYPOINT_UPDATE",         -- 航点坐标变化
	"PLAYER_ENTERING_WORLD",   -- 加载 / 切负载后重解析
	"PLAYER_MAP_CHANGED",
	"ZONE_CHANGED",
	"ZONE_CHANGED_NEW_AREA",
}
for _, event in ipairs(gameEvents) do
	eventFrame:RegisterEvent(event)
end

eventFrame:SetScript("OnEvent", function(_, event, arg1)
	if event == "ADDON_LOADED" then
		if arg1 == Addon.name then
			Addon:InitSettings()
			if SlashCmdList then
				SlashCmdList["BOUSSOLE_TRACKEREXT"] = function(msg)
					msg = tostring(msg or ""):lower()
					if msg == "options" or msg == "设置" then
						if Addon.Options then Addon.Options:Open() end
						return
					end
					if msg == "debug" or msg == "调试" then
						Addon:PrintDebug()
						return
					end
					Addon:ProbeCapabilities()
					local caps = Addon.Capabilities
					local flag = function(value) return tostring(value and true or false) end
					print(string.format(L.STATUS_LINE,
						flag(caps.api), flag(caps.compass), flag(caps.internal), flag(caps.navigation)))
				end
				_G.SLASH_BOUSSOLE_TRACKEREXT1 = "/bte"
			end
			if Addon.Options then Addon.Options:Init() end
		end
		return
	elseif event == "PLAYER_LOGIN" then
		Addon:ProbeCapabilities()
		Addon.dirty = true
		tickFrame:Show()
		return
	end
	Addon.dirty = true
end)
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("PLAYER_LOGIN")
