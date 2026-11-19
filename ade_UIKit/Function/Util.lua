------------------------------------------------------------
-- 通用纯函数：从 ade_apis 与 ade_AddonFramework 提取的无副作用部分。
-- 底本：
--   GetPath/SetPath  ade_apis/Core/Util.lua:150-172
--   Clamp/Round/SnapValue/Reindex/SortByOrder/IndexOf  ade_apis/Function/Validate.lua:9-55
--   HexToRGB/RGBToHex/ToArray/ToStored  ade_apis/Function/Color.lua:7-67
--   AccentHex 形态  ade_AddonFramework/Core/Theme.lua:102-105
--   DeepCopy/MergeDefaults  ade_apis/Function/DB.lua:15-54
------------------------------------------------------------
local lib = ResolveBOFNamespace("ade_UIKit")
if not lib then return end

local type, pairs, ipairs, tonumber = type, pairs, ipairs, tonumber
local floor = math.floor

local function SplitKey(key)
    return key:match("^([^%.]+)%.(.+)$")
end

function lib.GetPath(tbl, key)
    if type(tbl) ~= "table" or type(key) ~= "string" then return nil end
    local first, rest = SplitKey(key)
    if rest then
        return type(tbl[first]) == "table" and lib.GetPath(tbl[first], rest) or nil
    end
    return tbl[key]
end

function lib.SetPath(tbl, key, value)
    if type(tbl) ~= "table" or type(key) ~= "string" then return end
    local first, rest = SplitKey(key)
    if rest then
        if type(tbl[first]) ~= "table" then tbl[first] = {} end
        lib.SetPath(tbl[first], rest, value)
    else
        tbl[key] = value
    end
end

function lib.Clamp(value, lo, hi)
    if math.clamp then return math.clamp(value, lo, hi) end
    if value < lo then return lo end
    if value > hi then return hi end
    return value
end

function lib.Clamp01(value)
    return lib.Clamp(value, 0, 1)
end

function lib.Round(value)
    return floor((tonumber(value) or 0) + 0.5)
end

function lib.SnapValue(value, step)
    if not step or step <= 0 then return value end
    return floor(value / step + 0.5) * step
end

function lib.Reindex(list, step, key)
    step = step or 10
    key = key or "order"
    for i, item in ipairs(list or {}) do
        if type(item) == "table" then item[key] = i * step end
    end
    return list
end

function lib.SortByOrder(list, key)
    key = key or "order"
    table.sort(list, function(a, b) return (a[key] or 0) < (b[key] or 0) end)
    return list
end

function lib.IndexOf(list, value)
    for i, item in ipairs(list or {}) do
        if item == value then return i end
    end
    return nil
end

lib.ColorUtil = lib.ColorUtil or {}
local C = lib.ColorUtil

function C.HexToRGB(hex)
    if type(hex) ~= "string" then return nil end
    hex = hex:gsub("#", "")
    if #hex == 8 then hex = hex:sub(1, 6) end
    if #hex ~= 6 then return nil end
    return tonumber(hex:sub(1, 2), 16) / 255,
           tonumber(hex:sub(3, 4), 16) / 255,
           tonumber(hex:sub(5, 6), 16) / 255
end

function C.RGBToHex(r, g, b)
    return string.format("%02x%02x%02x",
        floor((r or 0) * 255 + 0.5),
        floor((g or 0) * 255 + 0.5),
        floor((b or 0) * 255 + 0.5))
end

function C.ToArray(color)
    if type(color) ~= "table" then return { 1, 1, 1, 1 } end
    if color.GetRGBA then
        local r, g, b, a = color:GetRGBA()
        return { r, g, b, a or 1 }
    end
    return {
        color.red or color[1] or 1,
        color.green or color[2] or 1,
        color.blue or color[3] or 1,
        color.alpha or color[4] or 1,
    }
end

function C.ToStored(color)
    local c = C.ToArray(color)
    return { red = c[1], green = c[2], blue = c[3] }
end

function C.Lighten(c, k)
    local r, g, b = c[1] or 0, c[2] or 0, c[3] or 0
    return { r + (1 - r) * k, g + (1 - g) * k, b + (1 - b) * k, c[4] or 1 }
end

function C.Darken(c, k)
    local r, g, b = c[1] or 0, c[2] or 0, c[3] or 0
    return { r * (1 - k), g * (1 - k), b * (1 - k), c[4] or 1 }
end

function C.WithAlpha(c, a)
    return { c[1] or 0, c[2] or 0, c[3] or 0, a }
end

function C.Mix(a, b, t)
    return {
        (a[1] or 0) + ((b[1] or 0) - (a[1] or 0)) * t,
        (a[2] or 0) + ((b[2] or 0) - (a[2] or 0)) * t,
        (a[3] or 0) + ((b[3] or 0) - (a[3] or 0)) * t,
        (a[4] or 1) + ((b[4] or 1) - (a[4] or 1)) * t,
    }
end

--- 颜色转聊天框前缀（AF.AccentHex 的通用形态）。
function lib.ColorHex(r, g, b)
    if type(r) == "table" then r, g, b = C.ToArray(r) end
    return string.format("|cff%02X%02X%02X", lib.Round((r or 1) * 255),
        lib.Round((g or 1) * 255), lib.Round((b or 1) * 255))
end

lib.DB = lib.DB or {}

function lib.DB.DeepCopy(t)
    local o = {}
    for k, v in pairs(t) do
        o[k] = type(v) == "table" and lib.DB.DeepCopy(v) or v
    end
    return o
end

--- nil-merge：只补缺键，不动使用者已有值（含 false）。
function lib.DB.MergeDefaults(dst, src, opts)
    local userSized = opts and opts.userSized
    local atomic = opts and opts.atomic
    local keepScalar = opts and opts.keepScalar
    for k, v in pairs(src) do
        local cur = dst[k]
        if type(v) == "table" then
            if userSized and userSized[k] and type(cur) == "table" and cur[1] ~= nil then
                for i = 1, #cur do
                    if type(cur[i]) == "table" and type(v[i]) == "table" then
                        lib.DB.MergeDefaults(cur[i], v[i], opts)
                    end
                end
            elseif cur == nil then
                dst[k] = lib.DB.DeepCopy(v)
            elseif type(cur) == "table" then
                if not (atomic and atomic[v]) then lib.DB.MergeDefaults(cur, v, opts) end
            elseif not keepScalar then
                dst[k] = lib.DB.DeepCopy(v)
            end
        elseif cur == nil then
            dst[k] = v
        end
    end
    return dst
end
