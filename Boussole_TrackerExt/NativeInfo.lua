-- 原生「罗盘信息」（名称 / 距离 / 路线进度条）条件性上移
-- 行为：仅当追踪扩展信息块（Emphasis，刻度下方）会与原生名水平重叠时，才把原生信息
-- 上移到罗盘图标上方给本块让位；其余时候原生信息留在宿主默认位置（三角下方）。
-- 不做成选项：由 Emphasis 每帧算出的 trackedInfo.nativeOverlap 驱动。
--
-- 宿主 applyDisplayMode 会重设锚点，故上移采用「锚点漂移检测」（GetPoint 与期望逐项比对）
-- 而不是每帧无谓 ClearAllPoints；还原时按首次上移前捕获的宿主锚点恢复。
local _, ns = ...
local Addon = ns.Addon

local NativeInfo = {}
Addon.NativeInfo = NativeInfo

NativeInfo.movedUp = false
NativeInfo.hostAnchors = nil

-- 罗盘图标带顶边（刻度带顶 + 余量）：原生信息上移时贴此之上（刚好在图钉带 13..49 之上）
local function tapeTopY(CI)
	local CONFIG = CI.CONFIG
	local ticks = CONFIG and CONFIG.ticks
	local positionY = (CI.compactMode and CONFIG.modeReduit and CONFIG.modeReduit.ticksPositionY)
		or (ticks and ticks.positionY) or 5
	local hauteur = (ticks and ticks.hauteurSupport) or 44
	return positionY + hauteur
end

local FIELDS = { "TrackedName", "TrackedDistance", "RouteProgress" }

local function captureHostAnchors(CI)
	local anchors = {}
	local frame = CI.frame
	for _, key in ipairs(FIELDS) do
		local f = frame[key]
		if f and f:GetNumPoints() > 0 then
			local p, rt, rp, x, y = f:GetPoint(1)
			anchors[key] = { p = p, rt = rt, rp = rp, x = x, y = y }
		end
	end
	return anchors
end

local function restoreHostAnchors(CI, anchors)
	local frame = CI.frame
	for _, key in ipairs(FIELDS) do
		local f = frame[key]
		if f then
			local a = anchors and anchors[key]
			f:ClearAllPoints()
			if a then f:SetPoint(a.p, a.rt, a.rp, a.x, a.y) end
		end
	end
end

-- 上移：名称 BOTTOM→frame BOTTOM, tapeTopY+4（多行向远离罗盘方向生长）；
-- 距离 / 进度条依次 BOTTOM→上一个 TOP 向上叠。漂移检测逐项比对，避免每帧 ClearAllPoints。
local function anchorAbove(CI)
	local frame = CI.frame
	local suivi = (CI.CONFIG and CI.CONFIG.suivi) or {}
	local top = tapeTopY(CI) + 4

	local name = frame.TrackedName
	if name then
		local p, _, rp, x, y = name:GetPoint(1)
		if p ~= "BOTTOM" or rp ~= "BOTTOM" or math.abs(x or 0) > 0.5 or math.abs((y or 0) - top) > 0.5 then
			name:ClearAllPoints()
			name:SetPoint("BOTTOM", frame, "BOTTOM", 0, top)
		end
	end

	local espace = suivi.espaceDistanceY or 0
	local distance = frame.TrackedDistance
	if distance then
		local p, _, rp, x, y = distance:GetPoint(1)
		if p ~= "BOTTOM" or rp ~= "TOP" or math.abs(x or 0) > 0.5 or math.abs((y or 0) - espace) > 0.5 then
			distance:ClearAllPoints()
			distance:SetPoint("BOTTOM", name, "TOP", 0, espace)
		end
	end

	local espace2 = suivi.espaceSousDistance or 0
	local progress = frame.RouteProgress
	if progress then
		local p, _, rp, x, y = progress:GetPoint(1)
		if p ~= "BOTTOM" or rp ~= "TOP" or math.abs(x or 0) > 0.5 or math.abs((y or 0) - espace2) > 0.5 then
			progress:ClearAllPoints()
			progress:SetPoint("BOTTOM", distance, "TOP", 0, espace2)
		end
	end
end

function NativeInfo:Apply(trackedInfo)
	local CI = Addon.CI
	if not CI or not CI.frame then return end

	-- 仅当本块与原生信息水平重叠时上移让位；否则回到宿主默认（三角下方）
	local above = trackedInfo and trackedInfo.nativeOverlap or false
	if above then
		if not self.movedUp then
			self.hostAnchors = captureHostAnchors(CI)
			self.movedUp = true
		end
		anchorAbove(CI)
	else
		if self.movedUp then
			restoreHostAnchors(CI, self.hostAnchors)
			self.movedUp = false
		end
	end
end

return NativeInfo
