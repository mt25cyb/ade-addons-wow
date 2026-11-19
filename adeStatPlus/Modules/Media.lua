--[==[ adeStatPlus / Modules/Media.lua — ADE v6.5 介质表（内置 + 可选 LSM）
v6.5 内置表（零硬依赖）：
- 字体清单按 LSM-3.0 的默认注册表逐项转录（东亚 locale 一组、西方 locale 一组），
  路径与 key 完全一致，旧存档里的 face key 无需迁移；
- 材质只保留本插件两款（自带 atrocity.tga + 原生 Raid-Bar-Hp-Fill）。
LSM 支持（用户 2026-11-17：字体/材质下拉恢复列出第三方介质）：
- 可选接入：环境里有 LibSharedMedia-3.0（任何携带它的插件注册）就合并其介质清单、
  存档 key 命中时走 LSM:Fetch；没有则行为与纯内置表完全一致；
- 本地已转录的 LSM 默认 key 不重复列出；LSM:Fetch 的第三参 silent 保证未知 key 静默回退；
- **LSM 引用每次调用时即时取（用户 2026-11-18 实测修正：加载期缓存导致只读到部分介质）**：
  本插件按字母序先于多数携带 LSM 的插件加载，文件加载期往往连 LibStub 都尚未由
  任何插件创建（缓存住 nil 即永久 miss），介质注册又集中在各插件 INIT/登录期；
  下拉 items 现由 Options.lua 传函数式 items（UIKit b025），每次行渲染求值，
  实时合并当前已注册介质。
]==]
-- ADE v6.5：ns 统一走全局私有表
local addonName = ...
local ns = _G.adeStatPlus or {}
_G.adeStatPlus = ns

local Media = {}
ns.Media = Media

-- 材质 key：沿用旧 Bars 常量名，存档无需迁移
Media.NOODLE = "adeStatPlus Noodle"
Media.MARKS = "adeStatPlus Marks"

local TEXTURES = {
    [Media.NOODLE] = "Interface\\AddOns\\adeStatPlus\\Media\\atrocity.tga",
    [Media.MARKS] = "Interface\\RaidFrame\\Raid-Bar-Hp-Fill",
}

--- 即时取 LSM 实例（不缓存：见头注释；LibStub 同 major 共享同一实例表，
--- 即时取保证拿到当前注册进度；缺失返回 nil，路径不受影响）。
local function GetLSM()
    return LibStub and LibStub("LibSharedMedia-3.0", true) or nil
end

--- 状态条材质下拉数据源：内置两款 + LSM statusbar（去重）。
--- b(adeStatPlus-r007)：改返回**有序数组** {value,text}——旧哈希表经 pairs 展开乱序
--- （用户实测材质下拉乱序；DBM 无此问题因 LSM:List 有序 + 单一构造器）。
--- 内置两款置顶，其余按显示名排序（localecmp 保证中西文混合可预期）。
local function SortedList(items)
    table.sort(items, function(a, b) return a.text < b.text end)
end

function Media.TextureItems()
    local seen = {}
    local out = {}
    for _, key in ipairs({ Media.NOODLE, Media.MARKS }) do
        seen[key] = true
        out[#out + 1] = { value = key, text = key }
    end
    local rest = {}
    local LSM = GetLSM()
    if LSM then
        for _, key in ipairs(LSM:List("statusbar")) do
            if not seen[key] then seen[key] = true; rest[#rest + 1] = { value = key, text = key } end
        end
    end
    SortedList(rest)
    for _, entry in ipairs(rest) do out[#out + 1] = entry end
    return out
end

--- 取材质路径；内置未命中时走 LSM，仍无则回退 MARKS。
function Media.TexturePath(key)
    local path = TEXTURES[key]
    if not path then
        local LSM = GetLSM()
        if LSM then
            path = LSM:Fetch("statusbar", key, true) -- silent：未知 key 不报警
        end
    end
    return path or TEXTURES[Media.MARKS]
end

-- 字体名 → 路径：逐项转录 LSM-3.0 默认注册表（LibSharedMedia-3.0.lua:160-190）。
-- 东亚客户端（zhCN/zhTW/koKR）与西方客户端的 Friz Quadrata 路径不同，按 GetLocale 分支。
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

-- 「游戏默认字体」：存档 key 固定为英文（跨 locale 稳定），下拉显示文案走三语 L 表。
-- 路径取 GameFontNormal:GetFont()（zhCN/zhTW 客户端即 ARKai_T，西方客户端即 FRIZQT__），
-- 旧存档指向未知 key 时也回退同一路径（FontPath），因此升级默认值对老存档无副作用。
Media.GAME_DEFAULT = "Game Default"

--- 字体下拉数据源；「游戏默认」固定排第一，其余内置 8 款 + LSM font（去重）按名排序。
--- b(adeStatPlus-r007)：改返回有序数组（旧哈希表经 pairs 展开乱序）。
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

--- 取字体路径；内置未命中时走 LSM，仍无则回退当前客户端默认字体。
function Media.FontPath(key)
    if key == Media.GAME_DEFAULT then return DEFAULT_FONT_PATH end
    local path = FONT_TABLE[key]
    if not path then
        local LSM = GetLSM()
        if LSM then
            path = LSM:Fetch("font", key, true) -- silent：未知 key 不报警
        end
    end
    return path or DEFAULT_FONT_PATH
end
