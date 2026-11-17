-- MapPinEnhanced_FixTrackerPatch — Core (v2)
-- 修复 MapPinEnhanced 追踪器重载（/reload、重新登录）后位置偏移。
--
-- v2 相对 v1 的变化：不再依赖 MPE 的 Mixin 全局表（用户环境中该全局缺失会导致
-- v1 的 hooksecurefunc 抛错、整个 Core.lua 中断、快照永远为空）。改为：
--   * 按 MPE 固定帧名 _G.MapPinEnhancedTrackerPosition 解析位置宿主框
--     （modules/tracker/tracker.lua:13-14，登录事件 + 短周期重试直到惰性创建完成）；
--   * 实例级 hooksecurefunc(f, "SetPoint") 万能回放钩子：MPE/LibWindow 任何
--     路径（RestoreFrame / ApplyTrackerScale / 迁移 / 松手重锚定）的重新锚定
--     之后统一回放快照，对 MPE 小版本的方法重命名免疫；
--   * 拖动结束捕获挂在拖拽区 header 的 OnMouseUp / OnHide（MPE StopDragging
--     的 HookScript 先注册、先执行，本插件后挂回调拿到的是最终落点）；
--   * 1s 周期巡检：捕捉不经过 SetPoint 的位移（如引擎 clamp）。
--
-- 坐标换算依据（真实源码）：
--   * GetLeft()/GetTop() 返回自身缩放坐标，×GetScale() = 相对 UIParent 的坐标。
--     原生同款用法：z-ref_wow-dev-git/wow-ui-source/Interface/AddOns/
--     Blizzard_SharedTalentFrame.lua:35-39；
--   * SetPoint 偏移 ×自身 GetScale() = UIParent 坐标（与 LibWindow 存/取链路及
--     实测 y 值跨重载不变的行为一致）。
--   * 回放带失败计数：连续多次回放后偏差仍未收敛则自动停用（防止单位语义
--     不符时的持续抖动），可用 /mpefixpos status 查看、/mpefixpos reset 重置。

local _, ns = ...
local L = ns.currentL

MapPinEnhancedFixTrackerPatchDB = MapPinEnhancedFixTrackerPatchDB or {}

local DEVIATION_EPS = 0.25      -- 回放判定阈值（UIParent 单位）
local TICKER_INTERVAL = 1.0     -- 巡检周期
local SETUP_RETRY_INTERVAL = 0.5
local SETUP_RETRY_MAX = 120     -- 重试 60s 放弃
local ENFORCE_FAILURE_LIMIT = 5

local positionFrame = nil
local header = nil
local hooksInstalled = false
local headerHooked = false
local applying = false          -- 本插件自身 SetPoint 的重入保护
local dragging = false          -- 用户正在拖动
local justCaptured = false      -- 刚捕获过，跳过紧接着的一次回放
local enforceEnabled = true
local enforceFailures = 0
local lastDeviation = nil

local function GetSnapshot()
	return MapPinEnhancedFixTrackerPatchDB.tracker
end

--- 当前位置换算为 UIParent 单位
local function GetCurrentUnits()
	if not positionFrame then return nil end
	local left, top = positionFrame:GetLeft(), positionFrame:GetTop()
	if not left or not top then return nil end
	local scale = positionFrame:GetScale() or 1
	if scale <= 0 then scale = 1 end
	return left * scale, top * scale
end

--- 捕获当前位置为快照（拖动结束 / 无快照时的基线）
local function CapturePosition()
	local x, y = GetCurrentUnits()
	if not x then return end
	MapPinEnhancedFixTrackerPatchDB.tracker = { x = x, y = y }
	justCaptured = true
	enforceFailures = 0
	lastDeviation = nil
end

--- 回放快照：UIParent 单位 → SetPoint 偏移（÷ 自身 GetScale）
local function ApplySavedPosition()
	local snap = GetSnapshot()
	if not snap or not snap.x or not snap.y or not positionFrame then return false end
	local scale = positionFrame:GetScale() or 1
	if scale <= 0 then scale = 1 end
	applying = true
	positionFrame:ClearAllPoints()
	positionFrame:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", snap.x / scale, snap.y / scale)
	applying = false
	return true
end

--- 回放判定：有偏差则重锚定为快照位置；连续未收敛则自动停用
local function EnforcePosition()
	if not enforceEnabled or applying or not hooksInstalled then return end
	if dragging or not positionFrame or not positionFrame:IsVisible() then return end

	if not GetSnapshot() then
		-- 基线：无快照时以 MPE 还原后的当前位置为准（装好补丁后拖动一次即生效）
		CapturePosition()
		return
	end
	if justCaptured then
		justCaptured = false
		return
	end

	local x, y = GetCurrentUnits()
	if not x then return end
	local dx, dy = x - GetSnapshot().x, y - GetSnapshot().y
	local dev = math.sqrt(dx * dx + dy * dy)
	if dev < DEVIATION_EPS then
		enforceFailures = 0
		lastDeviation = nil
		return
	end

	if lastDeviation and (lastDeviation - dev) < DEVIATION_EPS then
		enforceFailures = enforceFailures + 1
		if enforceFailures >= ENFORCE_FAILURE_LIMIT then
			enforceEnabled = false
			return
		end
	end
	lastDeviation = dev
	ApplySavedPosition()
end

--- 拖动结束捕获：header 是 MPE 注册的拖拽区（Tracker.lua:198），
--- StopDragging（core/frame.lua:22-33）在其 OnMouseUp / OnHide 内完成
--- StopMovingOrSizing + LibWindow.SavePosition；后挂回调拿到最终落点。
local function SetupHeaderHooks()
	if headerHooked or not positionFrame then return end
	local display = positionFrame.display
	header = display and display.header
	if not header then return end
	headerHooked = true
	header:HookScript("OnMouseDown", function()
		dragging = true
	end)
	header:HookScript("OnMouseUp", function()
		dragging = false
		CapturePosition()
	end)
	header:HookScript("OnHide", function()
		dragging = false
		CapturePosition()
	end)
end

local function TrySetup()
	if hooksInstalled then return true end
	local f = _G.MapPinEnhancedTrackerPosition
	if not f then return false end
	positionFrame = f
	hooksInstalled = true

	-- 万能回放钩子：任何路径的重新锚定之后统一回放快照
	hooksecurefunc(f, "SetPoint", function()
		if applying then return end
		C_Timer.After(0, EnforcePosition)
	end)

	SetupHeaderHooks()
	return true
end

-- 位置宿主框由 MPE 惰性创建：登录事件兜底 + 短周期重试直到找到
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:SetScript("OnEvent", function()
	TrySetup()
end)

local setupRetries = 0
C_Timer.NewTicker(SETUP_RETRY_INTERVAL, function(timer)
	if hooksInstalled then
		timer:Cancel()
		return
	end
	setupRetries = setupRetries + 1
	if setupRetries > SETUP_RETRY_MAX then
		timer:Cancel()
		return
	end
	if TrySetup() then
		-- display/header 理论上随宿主框同建，延迟补挂一次以防未就绪
		C_Timer.After(1, SetupHeaderHooks)
	end
end)

-- 周期巡检：捕捉不经过 SetPoint 的位移（如 clampedToScreen 的引擎侧修正）
C_Timer.NewTicker(TICKER_INTERVAL, EnforcePosition)

-- /mpefixpos reset|status
SLASH_MPEFIXPOS1 = "/mpefixpos"
SLASH_MPEFIXPOS2 = "/mpefixtrackerpos"
SlashCmdList.MPEFIXPOS = function(msg)
	msg = (msg or ""):lower():gsub("^%s+", ""):gsub("%s+$", "")
	if msg == "reset" then
		MapPinEnhancedFixTrackerPatchDB.tracker = nil
		justCaptured = false
		enforceEnabled = true
		enforceFailures = 0
		lastDeviation = nil
		print(L.resetDone)
	elseif msg == "status" then
		local mpeVersion = L.unknown
		if C_AddOns and C_AddOns.GetAddOnMetadata then
			mpeVersion = C_AddOns.GetAddOnMetadata("MapPinEnhanced", "Version") or mpeVersion
		end
		local snap = GetSnapshot()
		local devText = L.unknown
		if positionFrame and snap then
			local x, y = GetCurrentUnits()
			if x then
				local dx, dy = x - snap.x, y - snap.y
				devText = ("%.2f"):format(math.sqrt(dx * dx + dy * dy))
			end
		end
		print("|cffffd100" .. L.addonTag .. "|r " .. L.statusMpe:format(mpeVersion))
		print("|cffffd100" .. L.addonTag .. "|r " ..
			L.statusFrame:format(positionFrame and L.found or L.missing))
		print("|cffffd100" .. L.addonTag .. "|r " .. L.statusHooks:format(
			hooksInstalled and L.installed or L.notInstalled,
			headerHooked and L.installed or L.notInstalled,
			enforceEnabled and L.enforceOn or L.enforceOff,
			enforceFailures))
		print("|cffffd100" .. L.addonTag .. "|r " .. L.statusSnapshot:format(
			snap and ("x=%.2f, y=%.2f"):format(snap.x, snap.y) or L.snapshotNone))
		print("|cffffd100" .. L.addonTag .. "|r " .. L.statusDeviation:format(devText))
	else
		print(L.usage)
	end
end
