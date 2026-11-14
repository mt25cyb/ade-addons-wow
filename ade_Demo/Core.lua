-- ade_Demo 命名空间、存档与主题色初始化。
-- 库与宿主各自有独立的 ... 私有命名空间；库的公共接口一律通过 GetFramework() 取。
local _, DEMO = ...

local AF = GetFramework("ade_AddonFramework", true, "ade_Demo")
if not AF then return end
DEMO.AF = AF
DEMO.L = setmetatable({}, { __index = function(_, key) return key end })

local defaults = {
    schemaVersion = 1,
    settings = {
        globalColor = { red = 238 / 255, green = 228 / 255, blue = 174 / 255 },
        demo = {
            volume = 0.5,
            enabled = true,
            choice = "a",
            text = "ade_Demo",
            numbers = { 10, 50, 90 },
        },
    },
}

ade_DemoDB = ade_DemoDB or {}
AF.DB.Init(ade_DemoDB, defaults, { version = 1 })
DEMO.db = ade_DemoDB
AF.ApplyAccent(ade_DemoDB.settings.globalColor)

--- 改主题色时同步写回存档并广播。
function DEMO.SetGlobalColor(color)
    local c = AF.ApplyAccent(color)
    if not c then return end
    ade_DemoDB.settings.globalColor = c
end

--- 双形态自检：独立形态与内置形态同时存在时，两者应返回同一张表且取最高 MINOR。
function DEMO.VerifyDualForm()
    local viaStub = (type(LibStub) == "table") and LibStub("ade_AddonFramework", true) or nil
    local viaGlobal = _G.AF_LIBS and _G.AF_LIBS["ade_AddonFramework"] or nil
    local same = viaStub == viaGlobal and viaGlobal == AF
    AF.Printf("MAJOR=%s MINOR=%s standalone=table registry=%s libstub=%s same=%s",
        tostring(AF.MAJOR), tostring(AF.MINOR), tostring(viaGlobal == AF),
        tostring(viaStub ~= nil), tostring(same))
    return same
end
