--[==[ adeTimerHUD / Modules/Media.lua — 字体介质表（内置 + 可选 LSM）
范式复用 adeStatPlus/Modules/Media.lua（实证 :33-37 即时取 LSM、:78-141 内置字体表与解析）：
· 字体清单按 LSM-3.0 默认注册表逐项转录（东亚/西方两组路径），key 完全一致；
· LSM 可选接入：环境有 LibSharedMedia-3.0 时合并其清单、key 命中走 LSM:Fetch；
· LSM 引用每次调用即时取（加载期缓存会读到 nil，因字体注册多在其它插件 INIT 期）；
· 下拉 items 由 Options 传函数式（UIKit b025），每次行渲染实时合并。
]==]
local addonName = ...
local ns = _G.adeTimerHUD or {}
_G.adeTimerHUD = ns

local Media = {}
ns.Media = Media

local function GetLSM()
    return LibStub and LibStub("LibSharedMedia-3.0", true) or nil
end

-- 内置字体：逐项转录 LSM-3.0 默认注册表（路径实证 adeStatPlus/Modules/Media.lua:81-100）
local CJK_LOCALES = { zhCN = true, zhTW = true, koKR = true }
local fontCJK = {
    ["AR ZhongkaiGBK Medium (Combat)"] = "Fonts\\ARKai_C.TTF",
    ["AR ZhongkaiGBK Medium"] = "Fonts\\ARKai_T.TTF",
    ["Arial Narrow"] = "Fonts\\ARIALN.TTF",
    ["Friz Quadrata TT"] = "Fonts\\FRIZQT___CYR.TTF",
    ["MoK"] = "Fonts\\K_Pagetext.TTF",
    ["Morpheus"] = "Fonts\\MORPHEUS_CYR.TTF",
    ["Nimrod MT"] = "Fonts\\NIM_____.ttf",
    ["Skurri"] = "Fonts\\SKURRI_CYR.TTF",
}
local fontWest = {
    ["AR ZhongkaiGBK Medium (Combat)"] = "Fonts\\ARKai_C.TTF",
    ["AR ZhongkaiGBK Medium"] = "Fonts\\ARKai_T.TTF",
    ["Arial Narrow"] = "Fonts\\ARIALN.TTF",
    ["Friz Quadrata TT"] = "Fonts\\FRIZQT__.TTF",
    ["MoK"] = "Fonts\\K_Pagetext.TTF",
    ["Morpheus"] = "Fonts\\MORPHEUS_CYR.TTF",
    ["Nimrod MT"] = "Fonts\\NIM_____.ttf",
    ["Skurri"] = "Fonts\\SKURRI_CYR.TTF",
}
local FONT_TABLE = CJK_LOCALES[GetLocale()] and fontCJK or fontWest
local DEFAULT_FONT_PATH = GameFontNormal and GameFontNormal:GetFont() or "Fonts\\FRIZQT__.TTF"

Media.GAME_DEFAULT = "Game Default"

--- 字体下拉数据源：游戏默认置顶 + 内置 8 款 + LSM font 去重合并，按显示名排序。
function Media.FontItems()
    local out = {}
    out[#out + 1] = { value = Media.GAME_DEFAULT, text = (ns.L and ns.L["FONT_GAME_DEFAULT"]) or Media.GAME_DEFAULT }
    local seen = { [Media.GAME_DEFAULT] = true }
    local rest = {}
    for key in pairs(FONT_TABLE) do
        if not seen[key] then seen[key] = true; rest[#rest + 1] = { value = key, text = key } end
    end
    local LSM = GetLSM()
    if LSM then
        for _, key in ipairs(LSM:List("font")) do
            if not seen[key] then seen[key] = true; rest[#rest + 1] = { value = key, text = key } end
        end
    end
    table.sort(rest, function(a, b) return a.text < b.text end)
    for _, entry in ipairs(rest) do out[#out + 1] = entry end
    return out
end

--- 字体 key → 路径；游戏默认取 GameFontNormal:GetFont()，内置未命中走 LSM:Fetch，兜底默认。
function Media.FontPath(key)
    if key == Media.GAME_DEFAULT then return DEFAULT_FONT_PATH end
    local path = FONT_TABLE[key]
    if not path then
        local LSM = GetLSM()
        if LSM then path = LSM:Fetch("font", key, true) end
    end
    return path or DEFAULT_FONT_PATH
end

--- 描边 key → SetFont flags（实证 adeStatPlus/Modules/Panel.lua:50-57）
function Media.OutlineFlags(key)
    if key == "THICKOUTLINE" then return "THICKOUTLINE" end
    if key == "NONE" then return "" end
    return "OUTLINE"
end
