local addonName, ns = ...
local L = ns

local alerts = {}
ns.Alerts = alerts

local seen = {}
local primed = false
local toast

local function BuildToast()
    toast = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
    toast:SetSize(320, 48)
    toast:SetPoint("CENTER", 0, 200)
    toast:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true, tileSize = 16, edgeSize = 16,
        insets = {left = 6, right = 6, top = 6, bottom = 6},
    })
    toast:SetBackdropColor(0.1, 0.1, 0.1, 0.9)
    toast:EnableMouse(true)
    toast:SetMovable(true)
    toast:RegisterForDrag("LeftButton")
    toast:SetScript("OnDragStart", function(self) self:StartMoving() end)
    toast:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)

    local text = toast:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    text:SetWidth(300)
    text:SetPoint("CENTER")
    toast.Text = text
    toast:Hide()
end

local function ShowToast(itemID)
    if not toast then
        BuildToast()
    end
    toast.Text:SetText(format(L["Craftable now: %s"], C_Item.GetItemInfo(itemID) or ("#"..itemID)))
    toast:Show()
    C_Timer.After(8, function() toast:Hide() end)
end

local function Scan(fn)
    local psj = ProtoformSynthesisJournal
    local motes = psj:GetItemCount(188957)
    for tab = 1, 2 do
        for itemID, info in pairs(psj.data[tab]) do
            local craftable = min(floor(motes / info.moteCost), psj:GetItemCount(info.glimmerID), psj:GetItemCount(info.latticeID))
            if craftable > 0 and not psj:IsSchematicUnknown(itemID) then
                fn(itemID)
            end
        end
    end
end

function alerts.Prime()
    wipe(seen)
    Scan(function(itemID) seen[itemID] = true end)
    primed = true
end

function alerts.Check()
    if not primed or ProtoformSynthesisJournalSettings.showCraftableAlerts == false then
        return
    end
    Scan(function(itemID)
        if not seen[itemID] then
            seen[itemID] = true
            ShowToast(itemID)
        end
    end)
end

local frame = CreateFrame("Frame")
local started = false

local function Start()
    if started then
        return
    end
    started = true
    C_Timer.After(6, alerts.Prime)
    frame:RegisterEvent("BAG_UPDATE_DELAYED")
    frame:RegisterEvent("QUEST_TURNED_IN")
    frame:RegisterEvent("QUEST_LOG_UPDATE")
    frame:RegisterEvent("PLAYERBANKSLOTS_CHANGED")
    frame:RegisterEvent("PLAYER_ACCOUNT_BANK_TAB_SLOTS_CHANGED")
end

frame:RegisterEvent("PLAYER_LOGIN")
frame:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_LOGIN" then
        Start()
    else
        alerts.Check()
    end
end)

if UnitExists("player") then
    Start()
end
