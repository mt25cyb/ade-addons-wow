------------------------------------------------------------
-- 自写极简注册表：行为对齐 LibStub:NewLibrary 的 minor 仲裁。
-- 依据：25:26:z-ref_wow-addons-libs/LibDeflate/LibStub/LibStub.lua（同版/低版静默拒绝）、
--       13:16:z-ref_wow-addons-libs/LibSharedMedia-3.0/LibSharedMedia-3.0/LibSharedMedia-3.0.lua（低版副本退出）、
--       36:41:…/LibStub.lua（silent 软探测）。
-- 两种承载形态共用同一张全局表；差异只在 TOC / Libs.xml 加载清单层。
------------------------------------------------------------
local MAJOR = "ade_AddonFramework"
local MINOR = 1 -- 同步到内置形态时递增；只改本文件，其余库文件零改动

_G.AF_LIBS = _G.AF_LIBS or {}
_G.AF_LIB_MINORS = _G.AF_LIB_MINORS or {}

local function NewLibrary(major, minor)
    local old = _G.AF_LIBS[major]
    local oldMinor = _G.AF_LIB_MINORS[major]
    if old and oldMinor and minor <= oldMinor then
        return old, true
    end
    local lib = old or {}
    _G.AF_LIBS[major] = lib
    _G.AF_LIB_MINORS[major] = minor

    -- 运行环境已有 LibStub 时把同一张表注册进去，便于其它插件静默取用；不依赖其存在。
    if _G.LibStub and _G.LibStub.NewLibrary then
        local ok, stub = pcall(_G.LibStub.NewLibrary, _G.LibStub, major, minor)
        if ok and stub and stub ~= lib then
            for k, v in pairs(lib) do
                if stub[k] == nil then stub[k] = v end
            end
            _G.AF_LIBS[major] = stub
        end
    end
    return _G.AF_LIBS[major], false
end

--- 库文件统一入口。
-- 传 minor：由 Namespace.lua 判定本副本是否为最高版本，并写入 AF_LOAD_ALLOWED。
-- 不传 minor：低版本副本返回 nil，调用方 `if not AF then return end` 整体跳过。
function _G.ResolveNamespace(major, minor)
    major = major or MAJOR
    if minor then
        local lib, isOld = NewLibrary(major, minor)
        _G.AF_LOAD_ALLOWED = not isOld
        return lib
    end
    if _G.AF_LOAD_ALLOWED == false then return nil end
    return _G.AF_LIBS[major]
end

--- 宿主取值：优先 LibStub 静默探测，否则用自带注册表。
function _G.GetFramework(major, silent)
    major = major or MAJOR
    local lib
    if _G.LibStub then
        local ok, found = pcall(function() return _G.LibStub(major, true) end)
        if ok then lib = found end
    end
    lib = lib or _G.AF_LIBS[major]
    if not lib and not silent then
        error("ade_AddonFramework: 库尚未加载", 2)
    end
    return lib
end

local lib = _G.ResolveNamespace(MAJOR, MINOR)
if not _G.AF_LOAD_ALLOWED then return end
lib.MAJOR, lib.MINOR = MAJOR, MINOR
