-- English is the fallback for all non-Chinese clients.
local _, addon = ...
addon.L = {}
local L = addon.L
L["PERF_STATE_ON"] = "Enabled"
L["PERF_STATE_OFF"] = "Disabled"
L["PERF_CMD_ENABLED"] = "adePerfGuard enabled: checks once per session when you zone into an instance."
L["PERF_CMD_DISABLED"] = "adePerfGuard disabled: no reminder will be shown."
L["PERF_CMD_USAGE"] = "Usage: /adeperfguard on|off"
L["PERF_CMD_CVARS"] = "taintLog=%s, scriptProfile=%s"
L["PERF_POPUP_TAINT"] = "The taintLog CVar is enabled."
L["PERF_POPUP_PROFILE"] = "The scriptProfile CVar is enabled."
L["PERF_POPUP_BOTH"] = "The taintLog and scriptProfile CVars are enabled."
L["PERF_POPUP_DESC"] = "It reduces performance and should be off unless you are capturing a bug report."
L["PERF_POPUP_CONFIRM"] = "Disable and Reload"
L["PERF_POPUP_IGNORE"] = "Ignore"
