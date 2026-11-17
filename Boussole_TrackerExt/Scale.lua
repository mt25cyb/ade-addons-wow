local _, ns = ...
local Addon = ns.Addon

-- 罗盘刻度数字（仿 CompassHUD）：复用宿主「degree -> 屏幕 X」投影，每帧重算。
--   投影公式与宿主刻度完全一致（Compass/Render.lua:13-21）：
--     x = -normalizeAngle(degree - heading) * pixelsPerDegree
--     pixelsPerDegree = displayWidth / (displayField * 2)
-- 数字落在主插件的 ScaleViewport 内（同宿主刻度，受 SetClipsChildren 裁剪），
-- 因此只在罗盘可视宽度内可见，与宿主原生刻度对齐。
local Scale = {}
Addon.Scale = Scale

local pool = {}
local STEP = 30            -- 每 30° 一个读数
-- 宿主已在 0/90/180/270 显示中文方位字（北/西/南/东），这些度数跳过，避免重复
local SKIP_CARDINAL = true

local function getLabel(index, viewport)
	local fs = pool[index]
	if not fs then
		fs = viewport:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
		fs:SetJustifyH("CENTER")
		fs:SetJustifyV("BOTTOM")
		fs:SetTextColor(1, 0.86, 0.34, 0.82)
		fs:SetScale(0.85)
		pool[index] = fs
	end
	return fs
end

function Scale:PositionTick()
	local CI = Addon.CI
	if not CI or not CI.frame or not CI.frame.ScaleViewport then return end
	if Addon.settings.showScale == false or CI.compactMode then
		for i = 1, #pool do pool[i]:Hide() end
		return
	end

	local viewport = CI.frame.ScaleViewport
	local heading = CI.getHeadingDegrees()
	local displayWidth, _, _, displayField = CI.getDisplayValues()
	local pixelsPerDegree = displayWidth / (displayField * 2)
	local ticks = CI.CONFIG.ticks or {}
	local visible = displayField + (tonumber(ticks.margeChamp) or 2)
	local y = (tonumber(ticks.hauteurSupport) or 44) + 2

	local used = 0
	for deg = 0, 359, STEP do
		if SKIP_CARDINAL and (deg % 90 == 0) then
			-- 宿主已显示中文方位字，跳过数字读数
		else
			local relative = CI.normalizeAngle(deg - heading)
			if math.abs(relative) <= visible then
				used = used + 1
				local fs = getLabel(used, viewport)
				fs:SetText(tostring(deg))
				fs:ClearAllPoints()
				fs:SetPoint("BOTTOM", viewport, "BOTTOM", -relative * pixelsPerDegree, y)
				fs:Show()
			end
		end
	end
	for i = used + 1, #pool do
		pool[i]:Hide()
	end
end

function Scale:HideAll()
	for i = 1, #pool do pool[i]:Hide() end
end
