local addonName, ns = ...
local L = ns
setmetatable(L, { __index = function(_, key) return key end })

local Data = {
    tabProperties = {
    active = {
        highlightTopLeft = {"TOPLEFT", 0, 0},
        highlightBottomRight = {"BOTTOMRIGHT", -1, 5},
        highlightTexCoord = {0, 1, 0.8125, 0.9609375},
        textCenter = {"CENTER", 0, 1},
        textCenterDown = {"CENTER", 0, -1},
        textColor = {1, 1, 1},
        leftTexCoord = {0, 0.15625, 0, 0.28125},
        rightTexCoord = {0.84375, 1, 0, 0.28125},
        midTexCoord = {0.15625, 0.84375, 0, 0.28125},
    },
    inactive = {
        highlightTopLeft = {"TOPLEFT", 0, 0},
        highlightBottomRight = {"BOTTOMRIGHT", -1, 12},
        highlightTexCoord = {0, 1, 0.8125, 0.9609375},
        textCenter = {"CENTER", 0, 5},
        textCenterDown = {"CENTER", 0, 3},
        textColor = {1, 0.82, 0},
        leftTexCoord = {0, 0.15625, 0.5, 0.78125},
        rightTexCoord = {0.84375, 1, 0.5, 0.78125},
        midTexCoord = {0.15625, 0.84375, 0.5, 0.78125},
    },
},

-- 按页签（1=宠物，2=坐骑）和 itemID 索引；itemName 等字段在 GatherButtonData 中生成
    data = {
    [1] = {
        [189369] = {speciesID=3179,moteCost=300,glimmerID=189157,latticeID=189146}, -- Archetype of Animation
        [189380] = {speciesID=3207,moteCost=300,glimmerID=189158,latticeID=189155}, -- Archetype of Cunning
        [187795] = {speciesID=3174,moteCost=300,glimmerID=189159,latticeID=189156}, -- Archetype of Discovery
        [187713] = {speciesID=3169,moteCost=300,glimmerID=189160,latticeID=189153}, -- Archetype of Focus
        [189383] = {speciesID=3211,moteCost=300,glimmerID=189161,latticeID=189154}, -- Archetype of Malice
        [187928] = {speciesID=3197,moteCost=300,glimmerID=189162,latticeID=187634}, -- Archetype of Metamorphosis
        [187803] = {speciesID=3178,moteCost=300,glimmerID=189163,latticeID=189149}, -- Archetype of Motion
        [189375] = {speciesID=3189,moteCost=300,glimmerID=189164,latticeID=189147}, -- Archetype of Multiplicity
        [189381] = {speciesID=3201,moteCost=300,glimmerID=189165,latticeID=189152}, -- Archetype of Predation
        [189371] = {speciesID=3229,moteCost=300,glimmerID=189166,latticeID=187636}, -- Archetype of Renewal
        [189367] = {speciesID=3220,moteCost=300,glimmerID=189167,latticeID=189148}, -- Archetype of Satisfaction
        [189382] = {speciesID=3181,moteCost=300,glimmerID=189168,latticeID=187633}, -- Archetype of Serenity
        [189364] = {speciesID=3204,moteCost=300,glimmerID=189169,latticeID=189151}, -- Archetype of Survival
        [189377] = {speciesID=3233,moteCost=300,glimmerID=189170,latticeID=189145}, -- Archetype of Vigilance
        [189363] = {speciesID=3223,questID=65327,moteCost=250,glimmerID=189160,latticeID=187634}, -- Ambystan Darter
        [189365] = {speciesID=3224,questID=65332,moteCost=400,glimmerID=189163,latticeID=189151}, -- Fierce Scarabid
        [189374] = {speciesID=3232,questID=65357,moteCost=250,glimmerID=189166,latticeID=189147}, -- Leaping Leporid
        [189376] = {speciesID=3235,questID=65358,moteCost=150,glimmerID=189167,latticeID=189145}, -- Microlicid
        [189368] = {speciesID=3226,questID=65333,moteCost=350,glimmerID=189164,latticeID=189148}, -- Multichicken
        [187734] = {speciesID=3171,questID=65348,moteCost=350,glimmerID=189157,latticeID=189153}, -- Omnipotential Core
        [189373] = {speciesID=3231,questID=65354,moteCost=450,glimmerID=189159,latticeID=187636}, -- Prototickles
        [187733] = {speciesID=3170,questID=65351,moteCost=250,glimmerID=189169,latticeID=189153}, -- Resonant Echo
        [189378] = {speciesID=3222,questID=65359,moteCost=450,glimmerID=189168,latticeID=189145}, -- Shelly
        [189370] = {speciesID=3227,questID=65336,moteCost=400,glimmerID=189162,latticeID=189146}, -- Stabilized Geomental
        [189372] = {speciesID=3230,questID=65355,moteCost=400,glimmerID=189165,latticeID=187636}, -- Terror Jelly
        [187798] = {speciesID=3176,questID=65361,moteCost=350,glimmerID=189158,latticeID=189156}, -- Tunnel Vombata
        [189366] = {speciesID=3225,questID=65334,moteCost=200,glimmerID=189161,latticeID=189148}, -- Violent Poultrid
        [189379] = {speciesID=3234,questID=65360,moteCost=150,glimmerID=189170,latticeID=189155}, -- Viperid Menace
    },
    [2] = {
        [187632] = {mountID=1525,questID=65401,moteCost=450,glimmerID=189174,latticeID=189156}, -- Adorned Vombata
        [187670] = {mountID=1538,questID=65385,moteCost=400,glimmerID=189179,latticeID=189145}, -- Bronze Helicid
        [187663] = {mountID=1535,questID=65396,moteCost=350,glimmerID=189179,latticeID=189154}, -- Bronzewing Vespoid
        [187665] = {mountID=1534,questID=65397,moteCost=500,glimmerID=189176,latticeID=189154}, -- Buzz
        [187630] = {mountID=1523,questID=65399,moteCost=400,glimmerID=189172,latticeID=189156}, -- Curious Crystalsniffer
        [187631] = {mountID=1524,questID=65400,moteCost=450,glimmerID=189175,latticeID=189156}, -- Darekened Vombata
        [187638] = {mountID=1526,questID=65380,moteCost=450,glimmerID=189178,latticeID=187635}, -- Deathrunner
        [187666] = {mountID=1430,questID=65381,moteCost=400,glimmerID=189180,latticeID=189150}, -- Desertwing Hunter
        [187664] = {mountID=1533,questID=65398,moteCost=450,glimmerID=189173,latticeID=189154}, -- Forged Spiteflyer
        [187677] = {mountID=1541,questID=65388,moteCost=400,glimmerID=189171,latticeID=189152}, -- Genesis Crawler
        [187683] = {mountID=1547,questID=65391,moteCost=400,glimmerID=189171,latticeID=187633}, -- Goldenplate Bufonid
        [190580] = {mountID=1580,questID=65680,moteCost=500,glimmerID=189172,latticeID=190388}, -- Heartbound Lupine
        [187679] = {mountID=1543,questID=65390,moteCost=500,glimmerID=189176,latticeID=189152}, -- Ineffable Skitterer
        [187667] = {mountID=1536,questID=65382,moteCost=350,glimmerID=189175,latticeID=189150}, -- Mawdapted Raptora
        [187639] = {mountID=1431,achievementID=15402,moteCost=400,glimmerID=189176,latticeID=187635}, -- Pale Regal Cervid
        [188809] = {mountID=1570,questID=65393,moteCost=350,glimmerID=189178,latticeID=187633}, -- Prototype Leaper
        [187668] = {mountID=1537,questID=65383,moteCost=450,glimmerID=189173,latticeID=189150}, -- Raptora Swooper
        [188810] = {mountID=1571,questID=65394,moteCost=350,glimmerID=189174,latticeID=187633}, -- Russet Bufonid
        [187672] = {mountID=1540,questID=65387,moteCost=350,glimmerID=189177,latticeID=189145}, -- Scarlet Helicid
        [187669] = {mountID=1448,questID=65384,moteCost=500,glimmerID=189172,latticeID=189145}, -- Serenade
        [187641] = {mountID=1528,questID=65379,moteCost=300,glimmerID=189175,latticeID=187635}, -- Reins of the Sundered Zerethsteed
        [187678] = {mountID=1542,questID=65389,moteCost=450,glimmerID=189177,latticeID=189152}, -- Tarachnid Creeper
        [187671] = {mountID=1539,questID=65386,moteCost=300,glimmerID=189178,latticeID=189145}, -- Unsuccessful Prototype Fleetpod
        [187660] = {mountID=1433,questID=65395,moteCost=400,glimmerID=189180,latticeID=189154}, -- Vespoid Flutterer
    },
    [3] = {},
},

    settingsList = {
    {text=L["Settings"],isHeader=true},
    {var="lockWindowPosition",text=L["Prevent this window from being moved unless Shift is held"]},
    {var="lockWindowSize",text=L["Prevent this window from being resized"]},
    {var="showReagentTooltips",text=L["Show reagent tooltips when the mouse is over a reagent"]},
    {var="showMinimapButton",text=L["Show a minimap button to summon or dismiss this window"]},
    {var="showCraftableAlerts",text=L["Show craftable alerts"]},
    {var="hideCollectedPets",text=L["Hide pets that have been collected in the journal"]},
    {var="hideCollectedMounts",text=L["Hide mounts that have been collected in the journal"]},
    {var="hideUnknownPetSchematics",text=L["Hide pet schematics that aren't known on this character"]},
    {var="hideUnknownMountSchematics",text=L["Hide mount schematics that aren't known on this character"]},
    {var="shareWindowPosition",text=L["Use same window size and position across all characters"]},
    {text=GAMEMENU_HELP,isHeader=true},
    {text=L["To resize this window, drag the resize grip in the lower right corner of this window."]},
    {text=L["A \124TInterface\\AddOns\\ProtoformSynthesisJournal\\assets\\owned-known:0\124t beside a pet or mount name means it's been collected in the journal."]},
    {text=L["A number like [1] beside a pet or mount name is how many of those you can make."]},
    {text=GAME_VERSION_LABEL.." "..(C_AddOns.GetAddOnMetadata(addonName, "Version") or "")},
},

    list = {}
}

ns.Data = Data
