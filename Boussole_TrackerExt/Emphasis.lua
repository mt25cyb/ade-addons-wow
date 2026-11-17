local _, ns = ...
local Addon = ns.Addon

local Emphasis = {}
Addon.Emphasis = Emphasis

local belowFrame, belowIcon, belowHalo, belowLabel, belowDistance
local belowMask, belowBorder

local DEFAULT_ATLAS = "MiniMap-QuestArrow" -- CompassHUD 默认纹理预设的 Normal 指针（CompassHUD.lua:316）
local CIRCLE_MASK = "Interface/Masks/CircleMaskScalable" -- CompassHUD.lua:3577
local CIRCLE_BORDER = "ui-frame-genericplayerchoice-portrait-border" -- CompassHUD.lua:3584

local function getHighlightColor()
	local color = Addon.settings.highlightColor or {}
	return tonumber(color.red) or 1, tonumber(color.green) or 0.85, tonumber(color.blue) or 0.35
end

local function getAtlasInfo(atlas)
	if type(atlas) ~= "string" or atlas == "" then return nil end
	if not (C_Texture and C_Texture.GetAtlasInfo) then return nil end
	local ok, info = pcall(C_Texture.GetAtlasInfo, atlas)
	if not ok then return nil end
	return info
end

-- 设置图标。spec 可以是 atlas 字符串，也可以是 { texture=, atlas= } 表：
--   texture = 奖励贴图（世界任务奖励图标，CompassHUD getWQicon）→ 直接 SetTexture 铺满正方形；
--   atlas   = 暴雪原生 atlas → 近似正方形按原始宽高比等比缩放，明显长条的铺满正方形。
-- 不再做 texcoord 居中裁切：atlas 的 texcoord 是整张贴图内的区域，按宽高比反推裁切容易取到相邻图素，
-- 表现为「半个图标 + 一条杂边」（截图中的异常裁切）。原生 SuperTrackedFrame.lua:237 也是
-- SetAtlas(atlas, true) 直接用 atlas 自身尺寸，不做裁切。
local function applyIcon(texture, spec, targetSize)
	if type(spec) ~= "table" then spec = { atlas = spec } end

	local atlas = spec.atlas
	local file = spec.texture
	-- 兼容直接传 fileID / 贴图路径（宿主 Compass/Core.lua:325 的判据：GetAtlasInfo 取不到即当贴图）
	if not file and type(atlas) ~= "string" then file = atlas end

	local key = tostring(file or atlas or DEFAULT_ATLAS) .. "|" .. tostring(targetSize)
	if texture.bteKey == key then return end
	texture.bteKey = key

	if file then
		texture:SetTexture(tonumber(file) or file)
		texture:SetTexCoord(0, 1, 0, 1)
		texture:SetSize(targetSize, targetSize)
		return
	end

	if not atlas or atlas == "" then atlas = DEFAULT_ATLAS end
	local info = getAtlasInfo(atlas)
	if not info then
		texture:SetTexture(tonumber(atlas) or atlas)
		texture:SetTexCoord(0, 1, 0, 1)
		texture:SetSize(targetSize, targetSize)
		return
	end

	texture:SetAtlas(atlas, false)
	local w, h = tonumber(info.width), tonumber(info.height)
	if not (w and h and w > 0 and h > 0) then
		texture:SetSize(targetSize, targetSize)
		return
	end
	if math.min(w, h) / math.max(w, h) >= 0.75 then
		local scale = targetSize / math.max(w, h)
		texture:SetSize(w * scale, h * scale)
	else
		texture:SetSize(targetSize, targetSize)
	end
end

Emphasis.ApplyIcon = applyIcon

-- 圆形容器（世界任务奖励图标用圆形遮罩 + 头像边框，CompassHUD.lua:3575-3587 同款）
local function applyCircle(circle)
	if not (belowFrame and belowIcon) then return end
	if circle then
		if not belowMask then
			belowMask = belowFrame:CreateMaskTexture()
			belowMask:SetTexture(CIRCLE_MASK, "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
			belowMask:SetAllPoints(belowIcon)
		end
		belowIcon:AddMaskTexture(belowMask)
		belowMask:Show()
		if not belowBorder then
			belowBorder = belowFrame:CreateTexture(nil, "OVERLAY", nil, 1)
			belowBorder:SetAtlas(CIRCLE_BORDER)
			belowBorder:SetAllPoints(belowIcon)
		end
		belowBorder:Show()
	else
		if belowMask then
			belowIcon:RemoveMaskTexture(belowMask)
			belowMask:Hide()
		end
		if belowBorder then belowBorder:Hide() end
	end
end

-- 版式几何（相对 I.frame 底边的 Y 轴坐标，向上为正）
-- nearCenterY：贴合罗盘刻线（与主插件三角同位），本块的默认纵向锚点
function Emphasis:GetLayout()
	local CI = Addon.CI
	if not CI then return nil end
	local compact = CI.compactMode
	local iconSize = (compact and CI.CONFIG.modeReduit.tailleIconeEpingle or CI.CONFIG.epingles.tailleIcone)
		* math.clamp(tonumber(Addon.settings.scaleMultiplier) or 1.0, 0.8, 2.5)

	local positionY = (compact and CI.CONFIG.modeReduit and CI.CONFIG.modeReduit.barrePositionY)
		or (CI.CONFIG.barre and CI.CONFIG.barre.positionY) or 4
	local nearCenterY = positionY - iconSize * 0.5 - 1

	return {
		iconSize = iconSize,
		nearCenterY = nearCenterY,
		compact = compact,
	}
end

local function ensureBelowFrame()
	if belowFrame or not (Addon.CI and Addon.CI.frame) then return belowFrame end
	local CI = Addon.CI
	-- 父级挂 I.frame：ScaleViewport 有 SetClipsChildren(true)（Compass/Frame.lua:22），越出框底会被裁剪
	belowFrame = CreateFrame("Frame", "BoussoleTrackerExtBelowPin", CI.frame)

	belowHalo = belowFrame:CreateTexture(nil, "BACKGROUND", nil, -1) -- 与原生 Glow 同层级（Compass/Pins.lua:37-44）
	belowHalo:SetPoint("CENTER")
	belowHalo:SetAtlas(CI.CONFIG.selection.atlasHalo, false)
	belowHalo:SetBlendMode("ADD")

	belowIcon = belowFrame:CreateTexture(nil, "ARTWORK")
	belowIcon:SetPoint("CENTER")

	-- 文本锚在材质下方（材质是贴边主体，见 Overlay 的贴边箭头）
	belowLabel = belowFrame:CreateFontString(nil, "OVERLAY", CI.CONFIG.suivi.policeNom)
	belowLabel:SetPoint("TOP", belowFrame, "BOTTOM", 0, -2)
	belowLabel:SetJustifyH("CENTER")

	belowDistance = belowFrame:CreateFontString(nil, "OVERLAY", CI.CONFIG.suivi.policeDistance)
	belowDistance:SetPoint("TOP", belowLabel, "BOTTOM", 0, CI.CONFIG.suivi.espaceDistanceY)
	belowDistance:SetJustifyH("CENTER")

	return belowFrame
end

local function applyFontString(fontString, size, color)
	local font, _, flags = fontString:GetFont()
	if font then fontString:SetFont(font, size, flags or "") end
	fontString:SetTextColor(color[1] or 1, color[2] or 1, color[3] or 1, color[4] or 1)
end

local function formatDistance(distance)
	local CI = Addon.CI
	if CI and type(CI.formatDistance) == "function" then
		return CI.formatDistance(distance)
	end
	distance = tonumber(distance) or 0
	if distance >= 1000 then return string.format("%.1f km", distance / 1000) end
	return string.format("%d m", math.floor(distance + 0.5))
end

local function hideBelow()
	if belowFrame then belowFrame:Hide() end
	Emphasis.active = false
	-- 块隐藏即不重叠：清掉让位标志，避免原生信息卡在上移态
	if Emphasis.trackedInfo then Emphasis.trackedInfo.nativeOverlap = false end
end

-- 追踪扩展信息（刻度下方追踪层）
-- 版式要求：
--  1) 默认贴近罗盘刻线（与主插件三角同层）；
--  2) 与原生「罗盘信息」水平重叠时，由 NativeInfo 把原生信息条件性上移到罗盘图标上方让位，本块不动；
--  3) 超出可视范围时保持显示（指针保持在罗盘上）：**材质贴边**，文本与材质同心锚在其下方。
-- 每帧重定位（消除转向卡顿）：只用已解析的 bearing + 当前朝向重算屏幕 X，
-- 不再依赖 0.12s 的解析节流；内容（图标/文本）只在 Addon:Update 里重建。
local function positionBelow(trackedInfo, cachedLayout)
	local CI = Addon.CI
	trackedInfo.nativeOverlap = false -- 每帧重算；仅下方重叠分支会置 true
	-- 仅判断 frame 是否存在；【不】判断 IsShown()：
	-- hideBelow() 会把 belowFrame 隐藏，若此处要求已显示则会死锁——res 重新有效后永远走不到下方的 Show()，
	-- 导致「点可接任务（res=nil 触发隐藏）后再点其它目标（res 有效）扩展块不再显示」的回归（见开发计划 §7.14）。
	if not belowFrame then return end
	local bearing = trackedInfo.bearing
	if bearing == nil then return end

	local heading = CI.getHeadingDegrees()
	local relative = CI.normalizeAngle(bearing - heading)
	local displayWidth, _, _, displayField = CI.getDisplayValues()
	local pixelsPerDegree = displayWidth / (displayField * 2)
	local layout = cachedLayout or Emphasis:GetLayout()
	if not layout then return end
	local iconSize = layout.iconSize
	local marge = (CI.CONFIG.selection and tonumber(CI.CONFIG.selection.margeBord)) or 18
	local onScreen = math.abs(relative) <= displayField
	local rawX = -relative * pixelsPerDegree

	local icon = trackedInfo.icon or {}
	local blockX, arrowSide = rawX, 0
	if not onScreen then
		if not Addon.settings.pointerStay then
			hideBelow()
			return
		end
		-- 材质贴边（与 CompassHUD.lua:3806 一致：钳到 ±(displayWidth/2 - margeBord)）
		local side = rawX >= 0 and 1 or -1
		blockX = side * (displayWidth * 0.5 - marge)
		-- 方向箭头 atlas（icon.rotate = false 时）：由 Overlay 画在材质外侧
		if not icon.rotate then arrowSide = side end
	end

	-- 与原生「罗盘信息」水平重叠判定（供 NativeInfo 条件性上移让位）：
	-- 仅当本块会压住原生名时置位，侧向目标不受影响；本块自身不动。
	local centerY = layout.nearCenterY
	local overlap = false
	if not layout.compact then
		local trackedName = CI.frame and CI.frame.TrackedName
		if trackedName and trackedName:IsShown() then
			local nativeHalf = (trackedName:GetStringWidth() or 0) * 0.5
			if math.abs(blockX) < (nativeHalf + iconSize * 0.5) then
				overlap = true
			end
		end
	end
	trackedInfo.nativeOverlap = overlap

	-- 方向箭头 atlas 本体在贴边时原地旋转（CompassHUD textureRotate 分支）
	if not onScreen and icon.rotate then
		local side = blockX >= 0 and 1 or -1
		-- 与 CompassHUD.lua:3795 同式：up 箭头按 PI/2 * side * -1 旋转后指向目标一侧
		belowIcon:SetRotation(-side * (math.pi / 2))
	else
		belowIcon:SetRotation(0)
	end

	-- 高亮光晕（自绘，颜色可配；原生 OBJFX_Glow 同源）
	local r, g, b = getHighlightColor()
	belowHalo:SetSize(iconSize * 1.5, iconSize * 1.5)
	belowHalo:SetVertexColor(r, g, b, 1)
	belowHalo:SetAlpha(math.clamp(tonumber(Addon.settings.glowAlpha) or 0.6, 0, 1))
	belowHalo:SetShown(true)

	-- 边缘淡出（对齐原生图钉 fonduBordDegres，Compass/Render.lua:100）
	-- 开启「指针保持在罗盘上」时不淡化：信息一路滑到边缘再贴边常显，避免淡出后又在边缘「跳」出来
	local alpha = 1
	if onScreen and not Addon.settings.pointerStay then
		alpha = math.min(1,
			(displayField - math.abs(relative)) / math.max(0.001, CI.CONFIG.epingles.fonduBordDegres))
	end
	belowFrame:SetAlpha(alpha)

	belowFrame:ClearAllPoints()
	belowFrame:SetPoint("CENTER", CI.frame, "BOTTOM", blockX, centerY)
	belowFrame:SetFrameLevel(CI.frame:GetFrameLevel() + 10) -- 高于图钉池帧（+8，Compass/Pins.lua:17）
	belowFrame:Show()

	trackedInfo.onScreen = onScreen
	trackedInfo.blockX = blockX
	trackedInfo.iconCenterY = centerY
	trackedInfo.iconSize = iconSize
	trackedInfo.iconRotate = icon.rotate == true
	trackedInfo.arrowSide = arrowSide
end

-- 追踪扩展信息（刻度下方追踪层）；默认贴近罗盘刻线（与主插件三角同层），
-- 超出可视范围时保持显示（指针保持在罗盘上）：**材质贴边**，文本与材质同心锚在其下方。
local function updateBelow(res, trackedInfo)
	local CI = Addon.CI
	if not ensureBelowFrame() then return end
	if not res then hideBelow(); return end

	local bearing, distance = Addon:ComputeBearing(res)
	if not bearing then hideBelow(); return end

	local icon = res.icon
	if type(icon) ~= "table" then icon = { atlas = res.atlas } end
	trackedInfo.icon = icon
	trackedInfo.bearing = bearing
	trackedInfo.distance = distance

	local layout = Emphasis:GetLayout()
	if not layout then hideBelow(); return end
	local iconSize = layout.iconSize

	-- 图标：材质为主体（世界任务奖励贴图 / 对应的暴雪原生 atlas）
	applyIcon(belowIcon, icon, iconSize)
	applyCircle(icon.circle)
	belowFrame:SetSize(iconSize, iconSize)

	-- 名称 / 距离标签（文本与材质水平居中对齐，贴边时同心不内缩）
	local name = res.name or ""
	if res.transited and res.transitionDesc and res.transitionDesc ~= "" then
		name = string.format("%s (%s)", name, res.transitionDesc)
	end
	local displayWidth = select(1, CI.getDisplayValues())
	local labelWidth = math.min(displayWidth, 260) -- 限宽并自动换行，避免超长名称溢出罗盘
	applyFontString(belowLabel, CI.CONFIG.suivi.tailleNom or 15, CI.CONFIG.suivi.couleurNom or { 1, 0.9, 0.45, 1 })
	belowLabel:SetText(name)
	belowLabel:SetWidth(labelWidth)
	belowLabel:SetWordWrap(true)
	belowLabel:ClearAllPoints()
	belowLabel:SetPoint("TOP", belowFrame, "BOTTOM", 0, -2)

	applyFontString(belowDistance, CI.CONFIG.suivi.tailleDistance or 11, CI.CONFIG.suivi.couleurDistance or { 1, 1, 1, 1 })
	belowDistance:SetText(formatDistance(distance))
	belowDistance:SetWidth(labelWidth)
	belowDistance:ClearAllPoints()
	belowDistance:SetPoint("TOP", belowLabel, "BOTTOM", 0, CI.CONFIG.suivi.espaceDistanceY)

	Emphasis.active = true
	positionBelow(trackedInfo, layout)
end

function Emphasis:Update(res, trackedInfo)
	local CI = Addon.CI
	if not CI then return end
	self.trackedInfo = trackedInfo
	if res and trackedInfo and trackedInfo.mode == "below" then
		updateBelow(res, trackedInfo)
	else
		hideBelow()
	end
end

-- 每帧平滑重定位（由 Addon:PositionTick 调用），仅在 below 模式且当前确有有效目标时生效
function Emphasis:PositionTick(trackedInfo)
	if not trackedInfo or not Emphasis.active or trackedInfo.mode ~= "below" then return end
	positionBelow(trackedInfo)
end

function Emphasis:HideAll()
	hideBelow()
end
