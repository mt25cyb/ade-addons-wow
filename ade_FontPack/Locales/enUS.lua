local _, addon = ...
addon.L = setmetatable({
    ["NO_CHINESE"]        = " (No CN)",
    ["FONT_DIABLO"]       = "Diable",
    ["FONT_GENSHIN"]      = "Genshin",
    ["FONT_OVERWATCH"]    = "Overwatch",
    ["FONT_TARISLAND"]    = "TARISLAND",
    ["FONT_FZCY_GBK"]     = "FZCY_GBK",
    ["FONT_FZKT_GBK"]     = "FZKT_GBK",
    ["FONT_WDYQH"]        = "WDYQH",
    ["FONT_GENKAIMINCHO"] = "Genkai Mincho"
}, { __index = function(t, i)
    t[i] = i
    return i
end})
