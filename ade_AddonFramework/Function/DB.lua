-- SavedVariables 默认值合并与版本迁移链（settings.* 结构，颜色 {red,green,blue}）。
-- 语义底本：35:185:z-ref_retail_Interface_AddOns/MiliUI_AuraEnhance/Libs/MiliUIDB.lua。
local AF = ResolveNamespace("ade_AddonFramework")
if not AF then return end

local DB = {}
AF.DB = DB

function DB.DeepCopy(t)
    local o = {}
    for k, v in pairs(t) do
        o[k] = type(v) == "table" and DB.DeepCopy(v) or v
    end
    return o
end

--- nil-merge：只补缺键，不动用户已有值（含 false）。
function DB.MergeDefaults(dst, src, opts)
    local userSized = opts and opts.userSized
    local atomic = opts and opts.atomic
    local keepScalar = opts and opts.keepScalar
    for k, v in pairs(src) do
        local cur = dst[k]
        if type(v) == "table" then
            if userSized and userSized[k] and type(cur) == "table" and cur[1] ~= nil then
                for i = 1, #cur do
                    if type(cur[i]) == "table" and type(v[i]) == "table" then
                        DB.MergeDefaults(cur[i], v[i], opts)
                    end
                end
            elseif cur == nil then
                dst[k] = DB.DeepCopy(v)
            elseif type(cur) == "table" then
                if not (atomic and atomic[v]) then DB.MergeDefaults(cur, v, opts) end
            elseif not keepScalar then
                dst[k] = DB.DeepCopy(v)
            end
        elseif cur == nil then
            dst[k] = v
        end
    end
    return dst
end

local function Report(version, err, onError)
    if onError then onError(version, err); return end
    local handler = geterrorhandler and geterrorhandler()
    if handler then handler("ade_AddonFramework DB migrate " .. tostring(version) .. ": " .. tostring(err)) end
end

--- steps = { [version] = function(store) end }，逐版跑、每版 pcall 隔离、幂等。
function DB.Init(store, defaults, opts)
    opts = opts or {}
    local version = opts.version or 1
    if store.schemaVersion == nil then
        DB.MergeDefaults(store, defaults, opts)
        store.schemaVersion = version
    elseif store.schemaVersion < version then
        for v = store.schemaVersion + 1, version do
            local step = opts.steps and opts.steps[v]
            if step then
                local ok, err = pcall(step, store)
                if not ok then Report(v, err, opts.onError) end
            end
        end
        DB.MergeDefaults(store, defaults, opts)
        store.schemaVersion = version
    end
    -- 存档版本较新：不回退、不覆盖，原样返回
    return store
end

function DB.Reset(store, defaults, opts)
    for k in pairs(store) do store[k] = nil end
    return DB.Init(store, defaults, opts)
end

--- 配置档导出/导入用的序列化：支持 table/string/number/boolean/nil，循环引用会报错（配置档不会循环）。
-- 键名用 [=x] 形式避免特殊字符；文本用 %q 转义。导入走 Deserialize。
function DB.Serialize(t)
    local function S(v, seen)
        local tk = type(v)
        if tk == "nil" or tk == "boolean" or tk == "number" then
            return tostring(v)
        elseif tk == "string" then
            return string.format("%q", v)
        elseif tk == "table" then
            if seen[v] then error("circular reference") end
            seen[v] = true
            local parts, n = {}, 0
            local asArray = true
            for k in pairs(v) do
                if type(k) ~= "number" or k < 1 or math.floor(k) ~= k then asArray = false; break end
            end
            if asArray then
                for i = 1, #v do n = n + 1; parts[n] = S(v[i], seen) end
            else
                local keys = {}
                for k in pairs(v) do keys[#keys + 1] = k end
                table.sort(keys, function(a, b) return tostring(a) < tostring(b) end)
                for _, k in ipairs(keys) do
                    n = n + 1
                    parts[n] = "[" .. S(k, seen) .. "]=" .. S(v[k], seen)
                end
            end
            seen[v] = nil
            return "{" .. table.concat(parts, ",") .. "}"
        end
        error("unsupported type: " .. tk)
    end
    return "return " .. S(t, {})
end

function DB.Deserialize(s)
    if type(s) ~= "string" or s == "" then return nil end
    local loader = _G.loadstring or _G.load
    local fn, err = loader("return " .. s)
    if not fn then fn, err = loader(s) end
    if not fn then return nil, err end
    local ok, data = pcall(fn)
    if not ok or type(data) ~= "table" then return nil, data end
    return data
end

--- 配置档导出/导入的线格式：C_EncodingUtil SerializeCBOR → CompressString → EncodeBase64，
-- 前缀带版本（对齐 20:39:z-ref_retail_Interface_AddOns/MiliUI_Tooltip/Options/Tab_Share.lua，
-- 每步 pcall）。导出即是一个可分享字符串，不是明文配置（2026-11-14 用户要求）。
local WIRE_PREFIX = "ADEAF!1!"
local WIRE_VERSION = 1

function DB.Encode(t)
    if not (C_EncodingUtil and C_EncodingUtil.SerializeCBOR) then
        -- 客户端没有 C_EncodingUtil 时退回 Lua 序列化（仍是字符串，可与 Decode 互通）
        return WIRE_PREFIX .. "LUA!" .. DB.Serialize(t)
    end
    local ok, cbor = pcall(C_EncodingUtil.SerializeCBOR, { schemaVersion = WIRE_VERSION, profile = t })
    if not ok or not cbor then return nil, "serialization failed" end
    local ok2, compressed = pcall(C_EncodingUtil.CompressString, cbor)
    if not ok2 or not compressed then return nil, "compression failed" end
    local ok3, base64 = pcall(C_EncodingUtil.EncodeBase64, compressed)
    if not ok3 or not base64 then return nil, "encoding failed" end
    return WIRE_PREFIX .. base64
end

function DB.Decode(text)
    if type(text) ~= "string" then return nil, "empty string" end
    text = text:gsub("%s+", "")
    if text == "" then return nil, "empty string" end
    if text:sub(1, #WIRE_PREFIX) ~= WIRE_PREFIX then return nil, "wrong prefix" end
    local payload = text:sub(#WIRE_PREFIX + 1)
    if payload:sub(1, 4) == "LUA!" then
        return DB.Deserialize(payload:sub(5))
    end
    if not (C_EncodingUtil and C_EncodingUtil.DecodeBase64) then return nil, "no C_EncodingUtil" end
    local ok, compressed = pcall(C_EncodingUtil.DecodeBase64, payload)
    if not ok or not compressed then return nil, "base64 decode failed" end
    local ok2, cbor = pcall(C_EncodingUtil.DecompressString, compressed)
    if not ok2 or not cbor then return nil, "decompression failed" end
    local ok3, data = pcall(C_EncodingUtil.DeserializeCBOR, cbor)
    if not ok3 or type(data) ~= "table" or type(data.profile) ~= "table" then
        return nil, "deserialization failed"
    end
    if type(data.schemaVersion) ~= "number" or data.schemaVersion > WIRE_VERSION then
        return nil, "unsupported version"
    end
    return data.profile
end
