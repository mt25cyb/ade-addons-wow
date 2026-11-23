-- Handynotes Worldmap Button by fuba

local AddOnName, AddOn = ...

local IsAddOnLoaded = C_AddOns and C_AddOns.IsAddOnLoaded or IsAddOnLoaded
if not IsAddOnLoaded('HandyNotes') then return end

local WorldMapTooltip = WorldMapTooltip or GameTooltip;
-- local buildver = select(4,GetBuildInfo())
-- local isClassicWow = buildver < 20000
-- local isTBCC = (buildver > 20000) and (buildver < 30000)
-- local isWOTLKC = (buildver > 30000) and (buildver < 40000)
-- local isCATA = (buildver > 40000) and (buildver < 50000)
-- local isMOP = (buildver > 50000) and (buildver < 60000)
-- local isWOD = (buildver > 60000) and (buildver < 70000)
-- local isLEGION = (buildver > 60000) and (buildver < 70000)
-- local isBFA = (buildver > 70000) and (buildver < 80000)
-- local isSL = (buildver > 80000) and (buildver < 90000)
-- local isRetail = (buildver >= 110000)

local isRetail = WOW_PROJECT_ID == WOW_PROJECT_MAINLINE
local isClassicEra = WOW_PROJECT_ID == WOW_PROJECT_CLASSIC
local isForever = WOW_PROJECT_ID == WOW_PROJECT_CAMELOT

local isTBC = WOW_PROJECT_ID == WOW_PROJECT_BURNING_CRUSADE_CLASSIC
local isWOTLK = WOW_PROJECT_ID == WOW_PROJECT_WRATH_CLASSIC
local isCATA = WOW_PROJECT_ID == WOW_PROJECT_CATACLYSM_CLASSIC
local isMOP = WOW_PROJECT_ID == WOW_PROJECT_MISTS_CLASSIC


local L = LibStub("AceLocale-3.0"):GetLocale("HandyNotes_WorldMapButton_fork", false);

local iconDefault = [[Interface\AddOns\]] .. AddOnName .. [[\Buttons\Default]];
local iconDisabled = [[Interface\AddOns\]] .. AddOnName .. [[\Buttons\Disabled]];

-- Create the Button for WorldMap Border
-- fork：全局帧名随 fork 改名，避免与原版插件同时安装时复用同一帧。
local ButtonName = "HandyNotesWorldMapButton_fork"
local btn = _G[ButtonName] or CreateFrame("Button", ButtonName, WorldMapFrame, "UIPanelButtonTemplate");
btn:RegisterForClicks("AnyUp");
btn:SetText("");

local function SetIconTexture()
	local btn = _G[ButtonName]
	if not btn then return end
	if HandyNotes:IsEnabled() then
		btn:SetNormalTexture(iconDefault);
	else
		btn:SetNormalTexture(iconDisabled);
	end
end

local function SetIconTooltip(ShowTooltip)
	local btn = _G[ButtonName]
	if not btn then return end
	if not WorldMapTooltip then return end
	WorldMapTooltip:Hide();
	WorldMapTooltip:SetOwner(btn, "ANCHOR_BOTTOMLEFT");
	if HandyNotes:IsEnabled() then
		WorldMapTooltip:AddLine(L["TEXT_TOOLTIP_HIDE_ICONS"], nil, nil, nil, nil, 1 );
	else
		WorldMapTooltip:AddLine(L["TEXT_TOOLTIP_SHOW_ICONS"], nil, nil, nil, nil, 1 );
	end
	if ShowTooltip then
		WorldMapTooltip:Show();
	end
end

local function btnOnEnter(self, motion)
	SetIconTexture();
	SetIconTooltip(true);
end

local function btnOnLeave(self, motion)
	SetIconTexture();
	if WorldMapTooltip then
		WorldMapTooltip:Hide();
	end
end

local function IsHandyNotesEnabled()
	return HandyNotes:IsEnabled()
end

local function ToggleHandyNotes(button, ShowTooltip)
	if not HandyNotes then return end
	local db = LibStub("AceDB-3.0"):New("HandyNotesDB", defaults);
	if not db then return end
	local profile = db.profile;
	if not profile then return end


	if button == "LeftButton" then
		if HandyNotes:IsEnabled() then
			profile.enabled = false
			HandyNotes:Disable();
		else
			profile.enabled = true
			HandyNotes:Enable();
		end
	elseif button == "RightButton" then
		LibStub("AceConfigDialog-3.0"):Open("HandyNotes")
	end

	SetIconTexture();
	SetIconTooltip(ShowTooltip);
end

local function btnOnClick(self, button)
	ToggleHandyNotes(button, true)
end

hooksecurefunc(HandyNotes, "OnEnable", function(self)
	SetIconTexture()
end)

hooksecurefunc(HandyNotes, "OnDisable", function(self)
	SetIconTexture()
end)

btn:SetScript("OnClick", btnOnClick);
btn:SetScript("OnEnter", btnOnEnter);
btn:SetScript("OnLeave", btnOnLeave);

-- Hook "WorldMapFrame, OnShow" to set the Button's Position

-- fork（2026-11-23，重写 Leatrix 适配）：
-- 原版判断键 LeaMapsDB["UseDefaultMap"] 已从 Leatrix Maps 移除（当前 12.x 主文件全文检索 0 命中），
-- 判断永远不成立，retail 分支从未生效。按 Leatrix 当前真实存档键重写（SavedVariables 全局，
-- Leatrix_Maps.toc LoadSavedVariablesFirst 早加载；Leatrix_Maps.lua:8640 LoadVarChk / :8784 保存）：
--   LeaMapsDB["SimpleMapFrame"] == "On"      使用简易地图框体（Leatrix_Maps.lua:339 运行判据；切换需 /reload）
--   LeaMapsDB["ShowDiscoveryAreas"] == "On"  显示探索按钮（Leatrix_Maps.lua:8674，默认 "On"）
-- 简易框体保留世界地图最大化按钮（Leatrix_Maps.lua:369/:443，20×20），并把探索按钮（discBtn）
-- 锚在最大化按钮左侧（PlaceDiscBtn，Leatrix_Maps.lua:6873-6914）：
--   RIGHT to MaximizeMinimizeFrame LEFT, dx, 0；dx = -14，任务日志打开时按标题栏内
--   搜索框/设置按钮的位置动态左移（:6885-6891）。
-- fork r004（用户 2026-11-23 拍板简化）：r003 的探测方案在部分环境不生效，不再探测、不再跟随
-- 「显示探索按钮」切换——简易框体下把本按钮**固定**在探索按钮左侧的位置（即探索按钮 Show 时的
-- 左边缘再留 2px 间隙）：RIGHT to MaximizeMinimizeFrame LEFT, (dx - size - 2), 0。
-- 探索按钮隐藏（不勾「显示探索按钮」/区域全探索锁定）时该位置空着，本按钮固定占据，位置不跳动；
-- 「显示探索按钮」是即时选项（无需 reload），勾/取消后本按钮位置不变（用户拍板行为）。
-- 任务日志开合导致的 dx 变化由 QuestMapFrame OnShow/OnHide 钩子同步（见下）。
-- secret 防护与 Leatrix_Maps.lua:5976-5977（IsSecret 包装 issecretvalue）同款思路。
local function IsSecretNum(...)
	if not issecretvalue then return true end
	for i = 1, select("#", ...) do
		local v = select(i, ...)
		if type(v) == "number" and issecretvalue(v) then return false end
	end
	return true
end

local function PositionInLeatrixSimpleFrame(btn)
	if not LeaMapsDB then return false end
	local maxButton = _G.WorldMapFrame.BorderFrame and _G.WorldMapFrame.BorderFrame.MaximizeMinimizeFrame
	if not (maxButton and maxButton:IsVisible()) then return false end
	-- 与 PlaceDiscBtn 同款：探索按钮 Show 时的尺寸 = 最大化按钮高度（Leatrix_Maps.lua:6878-6880）
	local size = maxButton:GetHeight()
	if type(size) ~= "number" or not IsSecretNum(size) or size < 12 or size > 32 then size = 22 end
	-- 与 PlaceDiscBtn 同款：任务日志打开时的动态 dx（Leatrix_Maps.lua:6885-6891）
	local dx = -14
	local container = _G.WorldMapFrame.ScrollContainer
	if QuestMapFrame and QuestMapFrame:IsShown() and container then
		local right, mLeft = container:GetRight(), maxButton:GetLeft()
		local cScale, mScale, bScale = container:GetEffectiveScale(), maxButton:GetEffectiveScale(), btn:GetEffectiveScale()
		if right and mLeft and cScale and mScale and bScale and bScale > 0
			and IsSecretNum(right, mLeft, cScale, mScale, bScale) then
			local d = (right * cScale - mLeft * mScale) / bScale - 4
			if d < -14 then dx = d end
		end
	end
	-- 固定在探索按钮左侧（用户拍板，r004）：不管「显示探索按钮」勾/取消，位置不变。
	btn:ClearAllPoints()
	btn:SetPoint("RIGHT", maxButton, "LEFT", dx - size - 2, 0)
	-- 与 PlaceDiscBtn 同款层级处理（Leatrix_Maps.lua:6894-6897：同 strata、高一级）
	btn:SetFrameStrata(maxButton:GetFrameStrata())
	local level = maxButton:GetFrameLevel()
	btn:SetFrameLevel((level and not IsSecretNum(level) and level or 10) + 1)
	return true
end

local function UpdateButtonPosition()
	local btn = _G[ButtonName]
	if not btn then return end

	local alignmentFrame = _G.WorldMapFrame
	local parent = _G.WorldMapFrame
	local x, y = 0, 0

	-- Set different Values for different Expansions (Client Versions)
	if isClassicWow then
		alignmentFrame = _G.WorldMapFrame.MaximizeMinimizeFrame or _G.WorldMapFrameCloseButton or _G.WorldMapFrame;
		parent = alignmentFrame:GetParent();
		x = 0;
		y = 0;
	elseif isTBCC then
		alignmentFrame = _G.WorldMapFrame.MaximizeMinimizeFrame or _G.WorldMapFrameCloseButton or _G.WorldMapFrame;
		--parent = alignmentFrame:GetParent();
		parent = _G.WorldMapFrame
		x = 0;
		y = 0;
	elseif isWOTLKC then
		alignmentFrame = _G.WorldMapFrame.MaximizeMinimizeFrame or _G.WorldMapFrameCloseButton or _G.WorldMapFrame;
		parent = alignmentFrame:GetParent();
		x = 0;
		y = 0;
	elseif isCATA then
		alignmentFrame = _G.WorldMapFrame.MaximizeMinimizeFrame.MinimizeButton or _G.WorldMapFrameCloseButton or _G.WorldMapFrame;
		parent = alignmentFrame:GetParent();
		x = 0;
		y = 0;
	elseif isForever then
		--WorldMapFrame.BorderFrame.MaximizeMinimizeFrame.MaximizeButton
		alignmentFrame = _G.WorldMapFrame.BorderFrame.MaximizeMinimizeFrame or _G.WorldMapFrame;
		parent = alignmentFrame:GetParent();
		x = -2;
		y = 0;
	else
		alignmentFrame = _G.WorldMapFrame.BorderFrame.MaximizeMinimizeFrame or _G.WorldMapFrame;
		parent = alignmentFrame:GetParent();
		x = -2;
		y = 0;
	end
	if (not alignmentFrame) or (not parent) then return end

	-- Set the Button for the WorldMap Border or Create it it

	btn:ClearAllPoints();
	btn:SetPoint("RIGHT", alignmentFrame, "LEFT", x, y);
	btn:SetFrameStrata("HIGH");
	btn:SetSize(16, 16);

	-- fork：retail 的 Leatrix 适配走新逻辑（简易框体判断 + 探索按钮定位）。
	-- 经典版分支按原样移除（原判断键 "UseDefaultMap" 已从 Leatrix 移除，恒不触发，本就从未生效）。
	if IsAddOnLoaded('Leatrix_Maps') and isRetail then
		PositionInLeatrixSimpleFrame(btn)
	end

	SetIconTexture();
	SetIconTooltip(false);

	btn:Show();
end

WorldMapFrame:HookScript("OnShow", function(self)
	UpdateButtonPosition()
end)

-- fork：简易框体下任务日志开合（QuestMapFrame Show/Hide）会改变探索按钮的动态 dx
-- （Leatrix_Maps.lua:6885-6891），本按钮同步重定位，保持与探索按钮体系一致。
if QuestMapFrame then
	QuestMapFrame:HookScript("OnShow", function()
		if WorldMapFrame:IsShown() then UpdateButtonPosition() end
	end)
	QuestMapFrame:HookScript("OnHide", function()
		if WorldMapFrame:IsShown() then UpdateButtonPosition() end
	end)
end

---------------------------------------------------------------------
-- Add Worldmap Filter Button if Client is Retail
----------------------------------------------------------------------

local function AddButtonToWorldMapMenu()
	if (not Menu) then return end
	if (not MenuUtil) then return end

	-- Create checkbox entry
	local button = MenuUtil.CreateCheckbox(L["TEXT_TOOLTIP_SHOW_ICONS"], IsHandyNotesEnabled, function()
		if not HandyNotes then return end
		local db = LibStub("AceDB-3.0"):New("HandyNotesDB", defaults);
		if not db then return end
		local profile = db.profile;
		if not profile then return end;


		if HandyNotes:IsEnabled() then
			profile.enabled = false
			HandyNotes:Disable();
		else
			profile.enabled = true
			HandyNotes:Enable();
		end

	end)

	-- Add tooltip to menu button
	--local function OnTooltipShow(tooltipFrame, elementDescription)
		--GameTooltip_SetTitle(tooltipFrame, L["TEXT_TOOLTIP_TOGGLE_ICONS"])
	--end
	--button:SetTooltip(OnTooltipShow)

	-- Insert button to menu
	Menu.ModifyMenu("MENU_WORLD_MAP_TRACKING", function(ownerRegion, rootDescription, contextData)
		rootDescription:CreateDivider()
		rootDescription:CreateTitle("Handynotes: WorldmapButton")
		rootDescription:Insert(button)
	end)

end

if isRetail then
	AddButtonToWorldMapMenu()
end
