--[==[ adePerfGuard / Core.lua
性能护栏：EUI「Performance Reminder」（EllesmereUI.lua:4783-4826）的脱库移植。
进入副本时检查两个悄悄拖累战斗性能的调试 CVar：
  · taintLog     —— 抓 bug 报告后经常忘记关；
  · scriptProfile —— 给每个插件的每次调用加统计开销，只在 reload 后生效。
三条件齐备才弹一次窗：功能开关开 + 人在副本 + 本会话未提醒过（/reload 重置）。
确认「禁用并重载」：原生 C_CVar.SetCVar 写回 0 后 ReloadUI——不经任何包装，
这是玩家自己的修复，卸载/重装本插件都不应回滚。
开关：/adeperfguard（别名 /adeperf）on|off 持久化；无参显示状态。 ]==]
local _, addon = ...
local L = addon.L
local PREFIX = "|cff00AAFF[ADE]|r"

-- 引擎标准确认对话框（脱库替代 EUI 的 ShowConfirmPopup）：text 用 %s 接动态消息。
StaticPopupDialogs["ADE_PERF_GUARD"] = {
	text = "%s",
	button1 = L["PERF_POPUP_CONFIRM"],
	button2 = L["PERF_POPUP_IGNORE"],
	OnAccept = function()
		pcall(C_CVar.SetCVar, "taintLog", "0")
		pcall(C_CVar.SetCVar, "scriptProfile", "0")
		ReloadUI()
	end,
	OnCancel = function() end, -- 忽略/Esc：本会话保持安静（popupShown 已在显示前置位）
	timeout = 0,
	whileDead = 1,
	hideOnEscape = 1,
	preferredIndex = 3, -- 避开 1/2 号槽位，减少与系统对话框的重叠互换
}

-- 会话级一次性标志（非存档）：/reload 后重新允许一次提醒（对齐 EUI perfPromptShown）
local popupShown = false

local function CvarOn(name)
	return (tonumber(GetCVar(name) or 0) or 0) > 0
end

local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:SetScript("OnEvent", function(_, event, arg1)
	if event == "ADDON_LOADED" and arg1 == "adePerfGuard" then
		addon.InitDB()
		frame:UnregisterEvent("ADDON_LOADED")
		return
	end
	if event ~= "PLAYER_ENTERING_WORLD" then return end
	addon.InitDB() -- 兜底幂等（ADDON_LOADED 必先于首个 PLAYER_ENTERING_WORLD，此处仅为保险）
	local db = ADEDB_PERF_GUARD
	if not db.settings.enabled then return end
	-- 调试 CVar 只在战斗场景才真正拖帧数：野外不弹（对齐 EUI 的 IsInInstance 短路）
	if popupShown or not IsInInstance() then return end
	local taintOn = CvarOn("taintLog")
	local profOn = CvarOn("scriptProfile")
	if not (taintOn or profOn) then return end
	popupShown = true
	local which = (taintOn and profOn and L["PERF_POPUP_BOTH"])
		or (taintOn and L["PERF_POPUP_TAINT"])
		or L["PERF_POPUP_PROFILE"]
	StaticPopup_Show("ADE_PERF_GUARD", which .. " " .. L["PERF_POPUP_DESC"])
end)

------ 命令：/adeperfguard（别名 /adeperf）
SLASH_ADEPERFGUARD1 = "/adeperfguard"
SLASH_ADEPERFGUARD2 = "/adeperf"
SlashCmdList["ADEPERFGUARD"] = function(msg)
	addon.InitDB()
	local db = ADEDB_PERF_GUARD
	msg = strtrim((msg or ""):lower())
	if msg == "on" or msg == "off" then
		db.settings.enabled = (msg == "on")
		print(PREFIX, msg == "on" and L["PERF_CMD_ENABLED"] or L["PERF_CMD_DISABLED"])
		return
	end
	-- 无参（或非法参数）= 显示启用状态与当前 CVar 值
	print(PREFIX, L["PERF_STATE_" .. (db.settings.enabled and "ON" or "OFF")], L["PERF_CMD_CVARS"]:format(
		GetCVar("taintLog") or "?", GetCVar("scriptProfile") or "?"))
	if msg ~= "" then
		print(PREFIX, L["PERF_CMD_USAGE"])
	end
end
