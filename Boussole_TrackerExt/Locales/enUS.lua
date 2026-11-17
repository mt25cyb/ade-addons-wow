local _, ns = ...
ns.Locales.enUS = {
	ADDON_NAME = "Compass TrackerExt",

	SECTIONS_SOURCE = "Target sources",
	SECTIONS_EDGE = "Edge pointer",
	SECTIONS_EMPHASIS = "Emphasis",
	SECTIONS_LAYOUT = "Compass layout",

	SETTINGS_ENABLE_SOURCE = "Track map / ObjectiveTracker targets",
	SETTINGS_ENABLE_SOURCE_TIP = "Shows every supertracked target (quests, waypoints, map pins, vignettes) — the same set CompassHUD displays. Falls back to the host's selected pin when nothing is supertracked; supertracking wins on conflict.",
	SETTINGS_USER_WAYPOINT = "Track user waypoints",
	SETTINGS_USER_WAYPOINT_TIP = "Show the map user waypoint on the compass when it is supertracked.",

	SETTINGS_POINTER_STAY = "Pointer stays on compass",
	SETTINGS_POINTER_STAY_TIP = "When the tracked target leaves the visible compass field, the tracker info stays pinned at the edge with a directional arrow just outside it.",
	SETTINGS_STAY_ATLAS = "Edge arrow texture",
	STAY_ATLAS_NPE = "Standard arrow",
	STAY_ATLAS_NAV = "Navigation tracked arrow",
	STAY_ATLAS_BAG = "Triangle arrow",
	SETTINGS_HIDE_FAR = "Hide pointers on other continents",
	SETTINGS_HIDE_FAR_TIP = "Hides the tracker when the target is located on another continent.",
	SETTINGS_USE_CURRENT_MAP = "Use map transitions",
	SETTINGS_USE_CURRENT_MAP_TIP = "Points to the suggested transition (portal, entrance) instead of the raw target when it lies on another map.",

	SETTINGS_SCALE = "Tracked target scale",
	SETTINGS_HIGHLIGHT_COLOR = "Highlight color",
	SETTINGS_GLOW_ALPHA = "Glow opacity",
	SETTINGS_REWARD_ICON = "Use world quest reward icons",
	SETTINGS_REWARD_ICON_TIP = "World quests and bonus objectives use their reward item or currency icon (on by default in CompassHUD). Turn off to use the pointer icon of the quest classification.",
	SETTINGS_SHOW_SCALE = "Show compass degree scale",
	SETTINGS_SHOW_SCALE_TIP = "Overlay CompassHUD-style degree numbers every 30 degrees (reusing the host compass tick projection; the host itself only draws tick lines).",

	INCOMPATIBLE = "Compass internal structure is not compatible; enhanced layers are disabled.",
	USER_WAYPOINT = "User waypoint",
	AREA_PIN = "Map pin",
	STATUS_LINE = "|cffabd473Compass TrackerExt|r status: API %s, compass %s, internal layers %s, navigation %s",
}
