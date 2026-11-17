local _, ns = ...

local fallback = ns.Locales.enUS
local selected = ns.Locales[GetLocale and GetLocale() or "enUS"] or fallback

local L = ns.Addon.L
for key, value in pairs(fallback) do L[key] = value end
for key, value in pairs(selected) do L[key] = value end
