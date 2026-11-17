local _, ns = ...
local Addon = ns.Addon

local Overlay = {}
Addon.Overlay = Overlay

local arrowFrame, arrowTexture

-- 贴边箭头 atlas 的「原生朝向」基准角（弧度，0 = 朝上）。
-- bag-arrow 原生朝左：宿主罗盘中心标 `marqueCentrale.atlas = "bag-arrow"` + `rotation = -90`
-- 才渲染成朝上的三角（Compass/Core.lua:42-48），而 SetRotation 正值是逆时针，反推其 0 度朝左。
-- 因此 bag-arrow 指向右侧需要 180°、左侧 0°，即在「朝上」公式上再加 -PI/2。
local STAY_ATLAS_BASE_ROTATION = {
	["bag-arrow"] = -math.pi / 2,
}

-- 贴边方向箭头：只用于「材质本身不是方向箭头」的情况（世界任务奖励图标、POI atlas 等），
-- 与 CompassHUD 的 StayArrow 分支一致（CompassHUD.lua:3796-3804：材质是方向箭头时改转材质本体，
-- 不是方向箭头时才在材质外侧补一个小箭头）。
-- 父级挂 I.frame 而非 ScaleViewport：ScaleViewport 有 SetClipsChildren(true)，框底以下的箭头会被裁掉。
local function ensureArrowFrame()
	local CI = Addon.CI
	if not CI or not CI.frame then return nil end
	if arrowFrame then return arrowFrame end
	arrowFrame = CreateFrame("Frame", "BoussoleTrackerExtEdgeArrow", CI.frame)
	arrowFrame:SetSize(1, 1)
	arrowTexture = arrowFrame:CreateTexture(nil, "OVERLAY")
	arrowTexture:SetPoint("CENTER")
	arrowFrame:SetFrameLevel((CI.frame:GetFrameLevel() or 1) + 41)
	return arrowFrame
end

function Overlay:Update(res, trackedInfo)
	local CI = Addon.CI
	if not ensureArrowFrame() then return end

	local side = trackedInfo and trackedInfo.arrowSide or 0
	if not res or not trackedInfo or trackedInfo.mode ~= "below" or side == 0 then
		arrowFrame:Hide() -- 目标在可视范围内，或材质本身已是方向箭头，或未开启「指针保持在罗盘上」
		return
	end

	local iconSize = trackedInfo.iconSize or 16
	local arrowSize = iconSize * 0.85

	local atlas = Addon.settings.stayAtlas or "NPE_ArrowUp"

	-- 与追踪目标图标共用同一套 atlas 处理，避免两张图标出现不一致的变形 / 空白
	Addon.Emphasis.ApplyIcon(arrowTexture, atlas, arrowSize)

	-- NPE_ArrowUp / Navigation-Tracked-Arrow 在 rotation 0 时朝上；WoW 的 SetRotation 正值是逆时针，
	-- 故「指向右侧」= -PI/2，「指向左侧」= +PI/2。与 CompassHUD.lua:3803 `PI/2 * side * -1` 同式。
	-- 原生朝向不是「朝上」的 atlas（如 bag-arrow 朝左）先叠加基准角。
	arrowTexture:SetRotation((STAY_ATLAS_BASE_ROTATION[atlas] or 0) - side * (math.pi / 2))

	local color = Addon.settings.highlightColor or {}
	arrowTexture:SetVertexColor(tonumber(color.red) or 1, tonumber(color.green) or 0.86, tonumber(color.blue) or 0.34, 1)

	arrowFrame:Show()
	self:Position(trackedInfo)
end

-- 每帧重定位边缘箭头（由 Addon:PositionTick 调用），复用已算好的 blockX / side
function Overlay:Position(trackedInfo)
	if not arrowFrame or not arrowFrame:IsShown() then return end
	local CI = Addon.CI
	if not CI or not CI.frame then return end
	local side = trackedInfo and trackedInfo.arrowSide or 0
	if side == 0 then return end
	local iconSize = trackedInfo.iconSize or 16
	local arrowSize = iconSize * 0.85
	arrowFrame:ClearAllPoints()
	arrowFrame:SetPoint(
		"CENTER",
		CI.frame,
		"BOTTOM",
		(trackedInfo.blockX or 0) + side * (iconSize * 0.5 + arrowSize * 0.5 + 2),
		trackedInfo.iconCenterY or 0
	)
end

function Overlay:Hide()
	if arrowFrame then arrowFrame:Hide() end
end
