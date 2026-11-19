------------------------------------------------------------
-- 配置导入/导出字符串 API（b019）
-- 方案照 MiliUI_Tooltip/Options/Tab_Share.lua：C_EncodingUtil
--   SerializeCBOR → CompressString → EncodeBase64，前缀带插件自报的标识。
-- 只做「表 ⇄ 字符串」的纯编解码与结构校验，不碰任何插件存档、不 ReloadUI；
-- 校验回调 decodeValidate(payload) 由宿主提供（比对 schemaVersion / profile 结构）。
-- 每步 pcall，失败返回 nil, err（err 为本地化 key，宿主自行 L[] 转换）。
------------------------------------------------------------
local lib = ResolveBOFNamespace("ade_UIKit")
if not lib then return end

local Share = {}
lib.ShareString = Share

--- 把 payload 编成可分享字符串。
---@param prefix string 宿主前缀（如 "ADEMA!"），用于识别来源，导出串必以此开头
---@param payload table 需含 schemaVersion(number)；其余字段由宿主 validate 自行约定
---@return string|nil str 成功返回 prefix..base64
---@return string|nil err 失败的本地化 key
function Share.Encode(prefix, payload)
    if type(prefix) ~= "string" or prefix == "" then return nil, "SHARE_BAD_PREFIX" end
    if type(payload) ~= "table" or type(payload.schemaVersion) ~= "number" then
        return nil, "SHARE_BAD_PAYLOAD"
    end
    if not (C_EncodingUtil and C_EncodingUtil.SerializeCBOR) then
        return nil, "SHARE_NO_CODEC"
    end
    local ok, cbor = pcall(C_EncodingUtil.SerializeCBOR, payload)
    if not ok or not cbor then return nil, "SHARE_SERIALIZE_FAILED" end
    local ok2, compressed = pcall(C_EncodingUtil.CompressString, cbor)
    if not ok2 or not compressed then return nil, "SHARE_COMPRESS_FAILED" end
    local ok3, base64 = pcall(C_EncodingUtil.EncodeBase64, compressed)
    if not ok3 or not base64 then return nil, "SHARE_ENCODE_FAILED" end
    return prefix .. base64
end

--- 把字符串解回 payload。
---@param text string 分享字符串
---@param prefix string 期望前缀
---@param validate fun(payload:table):boolean|nil 可选，宿主结构/版本校验，返回 false 视为非法
---@return table|nil payload
---@return string|nil err 失败的本地化 key
function Share.Decode(text, prefix, validate)
    if type(text) ~= "string" then return nil, "SHARE_EMPTY" end
    text = text:gsub("%s+", "")
    if text == "" then return nil, "SHARE_EMPTY" end
    if type(prefix) ~= "string" or text:sub(1, #prefix) ~= prefix then
        return nil, "SHARE_BAD_PREFIX"
    end
    if not (C_EncodingUtil and C_EncodingUtil.DecodeBase64) then
        return nil, "SHARE_NO_CODEC"
    end
    local body = text:sub(#prefix + 1)
    local ok, compressed = pcall(C_EncodingUtil.DecodeBase64, body)
    if not ok or not compressed then return nil, "SHARE_DECODE_FAILED" end
    local ok2, cbor = pcall(C_EncodingUtil.DecompressString, compressed)
    if not ok2 or not cbor then return nil, "SHARE_DECOMPRESS_FAILED" end
    local ok3, data = pcall(C_EncodingUtil.DeserializeCBOR, cbor)
    if not ok3 or type(data) ~= "table" then return nil, "SHARE_DESERIALIZE_FAILED" end
    if type(data.schemaVersion) ~= "number" then
        return nil, "SHARE_BAD_PAYLOAD"
    end
    if validate and validate(data) == false then return nil, "SHARE_VALIDATE_FAILED" end
    return data
end

--- 只过滤到默认值里存在的两层键（顶层 + unit 类），避免导入串带入假键。
--- 供宿主构造 validate / 清洗 profile 使用；不修改传入表。
---@param profile table 待清洗的配置
---@param defaults table 默认值表
---@param nestedKey string|nil 需做第二层白名单的键（如 "unit"）
---@return table cleaned
function Share.Sanitize(profile, defaults, nestedKey)
    local out = {}
    if type(profile) ~= "table" or type(defaults) ~= "table" then return out end
    for k, v in pairs(defaults) do
        if profile[k] ~= nil then out[k] = profile[k] end
    end
    if nestedKey and type(out[nestedKey]) == "table" and type(defaults[nestedKey]) == "table" then
        local allowed = {}
        for k, v in pairs(defaults[nestedKey]) do
            if type(v) == "table" then allowed[k] = true end
        end
        local sub = {}
        for k, v in pairs(out[nestedKey]) do
            if allowed[k] and type(v) == "table" then sub[k] = v end
        end
        out[nestedKey] = sub
    end
    return out
end
