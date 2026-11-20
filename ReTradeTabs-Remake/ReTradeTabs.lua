-- ReTradeTabs-Remake (v1.1.0)
-- 12.x remake of ReTradeTabs (tardmrr, Shadowhand).
--
-- v1.1.0 changes (appearance / click fix, ATT alignment):
--   * Click-to-switch now uses C_TradeSkillUI.OpenTradeSkill(skillLine) like
--     ProfessionSideTabs (SecureActionButton spell casting did not switch).
--   * Tabs are built with the Blizzard core template QuestLogTabButtonTemplate
--     (43x55, atlas common-sidetab) -- the exact same template AllTheThings uses
--     for its profession tab (AllTheThings_Tab inherits it) -> 1:1 appearance.
--   * Tabs are parented to the shared side bar ProfessionsFrameTabSideBar that
--     hugs the right edge of ProfessionsFrame (no more gap), and align with the
--     ATT tab (see RTT_ATT_Ext.lua).
--   * Old spellbook-texture / rotated / checked-texture visuals removed.

local ADDON_NAME = ...

local frame = CreateFrame("Frame", "ReTradeTabsRemakeFrame")

local initialized = false
local pendingRebuild = false
local tabs = {}
local lastSpellListKey = nil

-- Shared side bar convention (established by AllTheThings, reused by several addons):
-- a 1px-wide frame hugging the right edge of ProfessionsFrame. Tabs parented to it
-- automatically follow when ATT moves the bar next to its own window.
local function EnsureSideBar()
    if ProfessionsFrameTabSideBar then
        return ProfessionsFrameTabSideBar
    end
    local sidebar = CreateFrame("Frame", nil, ProfessionsFrame, "")
    sidebar:SetWidth(1)
    sidebar:SetPoint("TOPLEFT", ProfessionsFrame, "TOPRIGHT")
    sidebar:SetPoint("BOTTOMLEFT", ProfessionsFrame, "BOTTOMRIGHT")
    sidebar.Tabs = {}
    sidebar.selTab = 0
    ProfessionsFrameTabSideBar = sidebar
    return sidebar
end

local function IsOwnTab(f)
    for _, tab in ipairs(tabs) do
        if tab == f then
            return true
        end
    end
    return false
end

local whitelist = {
    [171] = true, -- Alchemy
    [164] = true, -- Blacksmithing
    [185] = true, -- Cooking
    [333] = true, -- Enchanting
    [202] = true, -- Engineering
    [129] = true, -- First Aid
    [356] = true, -- Fishing
    [182] = true, -- Herbalism
    [773] = true, -- Inscription
    [755] = true, -- Jewelcrafting
    [165] = true, -- Leatherworking
    [186] = true, -- Mining
    [393] = true, -- Skinning
    [197] = true, -- Tailoring
}

-- professions whose spellbook holds multiple production abilities; only one tab each
local onlyPrimary = {
    [171] = true, -- Alchemy
    [202] = true, -- Engineering
}

local function buildSpellList()
    local p1, p2, arch, fishing, cooking = GetProfessions()
    local profs = { p1, p2, cooking, fishing }
    local entries = {}
    local extras = 0

    for _, prof in pairs(profs) do
        if prof then
            local _, _, _, _, abilities, offset, skillLine = GetProfessionInfo(prof)
            if whitelist[skillLine] then
                if onlyPrimary[skillLine] then
                    abilities = 1
                end
                for i = 1, abilities do
                    if not C_Spell.IsSpellPassive(i + offset) then
                        local entry = { slot = i + offset, skillLine = skillLine }
                        if i > 1 then
                            tinsert(entries, entry)
                            extras = extras + 1
                        else
                            -- keep the first ability of every profession in the leading group
                            tinsert(entries, #entries + 1 - extras, entry)
                        end
                    end
                end
            end
        end
    end

    return entries
end

local function RefreshSelection()
    for _, tab in ipairs(tabs) do
        local checked = C_Spell.IsCurrentSpell(tab.spellID) or false
        tab:SetChecked(checked)
        -- SetChecked rewrites the icon via activeAtlas/inactiveAtlas KeyValues; restore
        -- the plain spell icon afterwards exactly like AllTheThings does.
        tab.Icon:SetTexture(tab.icon)
        tab.Icon:SetSize(24, 24)
    end
end

local function CreateTab(index, parent, entry)
    local tab = CreateFrame("Frame", "ReTradeTabsRemakeTab" .. index, parent, "QuestLogTabButtonTemplate")
    tab.spellID = entry.spellID
    tab.skillLine = entry.skillLine
    tab.icon = entry.icon
    tab.tooltipText = entry.name
    tab.Icon:SetTexture(entry.icon)
    tab.Icon:SetSize(24, 24)
    -- ProfessionSideTabs-style click: open the profession by its skill line
    tab:SetCustomOnMouseUpHandler(function(self)
        C_TradeSkillUI.OpenTradeSkill(self.skillLine)
    end)
    return tab
end

local function WipeTabs()
    for _, tab in ipairs(tabs) do
        tab:ClearAllPoints()
        tab:SetParent(nil)
        tab:Hide()
    end
    wipe(tabs)
end

local function Rebuild()
    if not initialized or not ProfessionsFrame then
        return
    end

    if InCombatLockdown() then
        pendingRebuild = true
        frame:RegisterEvent("PLAYER_REGEN_ENABLED")
        return
    end

    local entries = buildSpellList()
    local list = {}
    local keyParts = {}
    for _, e in ipairs(entries) do
        local info = C_SpellBook.GetSpellBookItemInfo(e.slot, Enum.SpellBookSpellBank.Player)
        if info and info.spellID then
            local si = C_Spell.GetSpellInfo(info.spellID)
            if si and si.name and si.iconID then
                list[#list + 1] = {
                    spellID = info.spellID,
                    skillLine = e.skillLine,
                    name = si.name,
                    icon = si.iconID,
                }
                keyParts[#keyParts + 1] = tostring(info.spellID)
            end
        end
    end

    local key = table.concat(keyParts, ",")
    if key == lastSpellListKey then
        RefreshSelection()
        return
    end
    lastSpellListKey = key

    WipeTabs()

    local sidebar = EnsureSideBar()
    -- ATT's tab (if present) occupies sidebar.Tabs[1]; stack ours below it
    local attTab = sidebar.Tabs and sidebar.Tabs[1]
    if attTab and IsOwnTab(attTab) then
        attTab = nil
    end

    local prev
    for i, entry in ipairs(list) do
        local tab = CreateTab(i, sidebar, entry)
        if i == 1 then
            if attTab then
                -- official QuestLog side-tab stacking: 3px below the previous tab
                tab:SetPoint("TOP", attTab, "BOTTOM", 0, -3)
            else
                -- same spot AllTheThings uses when it owns the side bar alone
                tab:SetPoint("TOPLEFT", sidebar, "TOPRIGHT", -2, -52)
            end
        else
            tab:SetPoint("TOP", prev, "BOTTOM", 0, -3)
        end
        prev = tab
        tabs[#tabs + 1] = tab
    end

    RefreshSelection()
end

local function SafeRebuild()
    if InCombatLockdown() then
        pendingRebuild = true
        frame:RegisterEvent("PLAYER_REGEN_ENABLED")
    else
        Rebuild()
    end
end

local function TryInit()
    if initialized then
        return true
    end
    -- Blizzard_Professions may be load-on-demand; ProfessionsFrame won't exist until then
    if not ProfessionsFrame then
        return false
    end
    initialized = true
    SafeRebuild()
    return true
end

frame:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" then
        if arg1 == ADDON_NAME then
            if RTTAnchorPoint == nil then
                RTTAnchorPoint = "right"
            end
            self:UnregisterEvent("ADDON_LOADED")
            self:RegisterEvent("PLAYER_LOGIN")
        end
    elseif event == "PLAYER_LOGIN" then
        self:UnregisterEvent("PLAYER_LOGIN")
        TryInit()
    elseif event == "TRADE_SKILL_SHOW" then
        -- also the init path for load-on-demand Blizzard_Professions
        TryInit()
        SafeRebuild()
        RefreshSelection()
    elseif event == "SKILL_LINES_CHANGED" or event == "SPELLS_CHANGED" then
        if initialized then
            lastSpellListKey = nil -- force full rebuild; profession spells may have changed
            SafeRebuild()
        end
    elseif event == "PLAYER_REGEN_ENABLED" then
        if pendingRebuild then
            pendingRebuild = false
            self:UnregisterEvent("PLAYER_REGEN_ENABLED")
            Rebuild()
        end
    end
end)

frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("TRADE_SKILL_SHOW")
frame:RegisterEvent("SKILL_LINES_CHANGED")
frame:RegisterEvent("SPELLS_CHANGED")

SLASH_RTT1 = "/rtt"

SlashCmdList.RTT = function(msg)
    msg = (msg or ""):lower():match("^%s*(.-)%s*$")
    if msg == "refresh" or msg == "reload" then
        lastSpellListKey = nil
        SafeRebuild()
        print("|cff33ff99ReTradeTabs-Remake|r: tabs rebuilt.")
    elseif msg == "top" then
        print("|cff33ff99ReTradeTabs-Remake|r: the top layout is no longer supported;")
        print("  tabs now use the official QuestLog side-tab look and always sit on the right,")
        print("  aligned with the AllTheThings profession tab when that addon is loaded.")
    else
        print("|cff33ff99ReTradeTabs-Remake|r commands:")
        print("  /rtt refresh  - rebuild tabs now")
        print("  /rtt top      - (removed) tabs are always on the right side")
    end
end

-- Public API for RTT_ATT_Ext.lua (plain global table; files of this addon do not
-- share a custom environment, so cross-file access goes through _G)
ReTradeTabsRemakeAPI = {
    IsOwnTab = IsOwnTab,
    ForceRebuild = function()
        lastSpellListKey = nil
        SafeRebuild()
    end,
}
