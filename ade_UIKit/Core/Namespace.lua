------------------------------------------------------------
-- 自写极简注册表：行为对齐 LibStub:NewLibrary 的 minor 仲裁。
-- 依据：AF/Core/Namespace.lua 的写法；本库不依赖 AF，也不覆盖 AF 的全局 ResolveNamespace。
-- 因此函数名带 BOF 前缀，避免两个库同时加载时互相改写全局入口。
------------------------------------------------------------
local MAJOR = "ade_UIKit"
local MINOR = 2 -- v6.5 从 KAF 复刻重写；同步到宿主内置形态时递增，只改本文件

_G.BOF_LIBS = _G.BOF_LIBS or {}
_G.BOF_LIB_MINORS = _G.BOF_LIB_MINORS or {}

local function NewLibrary(major, minor)
    local old = _G.BOF_LIBS[major]
    local oldMinor = _G.BOF_LIB_MINORS[major]
    if old and oldMinor and minor <= oldMinor then
        return old, true
    end
    local lib = old or {}
    _G.BOF_LIBS[major] = lib
    _G.BOF_LIB_MINORS[major] = minor
    -- 运行环境已有 LibStub 时把同一张表注册进去，便于生态共存；不构成依赖。
    if _G.LibStub and _G.LibStub.NewLibrary then
        local ok, stub = pcall(_G.LibStub.NewLibrary, _G.LibStub, major, minor)
        if ok and stub and stub ~= lib then
            for k, v in pairs(lib) do
                if stub[k] == nil then stub[k] = v end
            end
            _G.BOF_LIBS[major] = stub
        end
    end
    return _G.BOF_LIBS[major], false
end

--- 库文件统一入口。传 minor 判定本副本是否为最高版本；不传则低版本副本返回 nil。
function _G.ResolveBOFNamespace(major, minor)
    major = major or MAJOR
    if minor then
        local lib, isOld = NewLibrary(major, minor)
        _G.BOF_LOAD_ALLOWED = not isOld
        return lib
    end
    if _G.BOF_LOAD_ALLOWED == false then return nil end
    return _G.BOF_LIBS[major]
end

--- 宿主取值：优先 LibStub 静默探测，否则用自带注册表。
function _G.GetBlizzOptionsFrame(major, silent)
    major = major or MAJOR
    local lib
    if _G.LibStub then
        local ok, found = pcall(function() return _G.LibStub(major, true) end)
        if ok then lib = found end
    end
    lib = lib or _G.BOF_LIBS[major]
    if not lib and not silent then
        error("ade_UIKit: 库尚未加载", 2)
    end
    return lib
end

local lib = _G.ResolveBOFNamespace(MAJOR, MINOR)
if not _G.BOF_LOAD_ALLOWED then return end

lib.MAJOR, lib.MINOR = MAJOR, MINOR
lib.WindowName = "AdeBlizzOptionsFrame_Window"
lib.L = lib.L or setmetatable({}, { __index = function(_, key) return key end })
lib.Internal = lib.Internal or {}
lib.Internal.Tabs = lib.Internal.Tabs or {}
lib.Internal.Build = lib.Internal.Build or {}
lib.Internal.Mixins = lib.Internal.Mixins or {}
-- 窗口 mixin 聚合点：所有窗口文件都向这张表追加方法（KAF WindowMixin.lua:44）。
lib.Internal.Mixins.Window = lib.Internal.Mixins.Window or {}
lib.Internal.Kinds = lib.Internal.Kinds or {}

-- 三个标记与 KAF 同源（84:86 段见开发计划 §九），供选项行与富描述共用。
lib.Markup = {
    Changed = "|TInterface\\Buttons\\WHITE8X8:12:3:0:0:8:8:0:8:0:8:255:209:0|t",
    Reload = "|TInterface\\Buttons\\UI-RefreshButton:12:12|t",
    Reset = "|A:common-icon-undo:12:12|a",
}
