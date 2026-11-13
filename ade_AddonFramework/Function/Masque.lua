-- Masque 软探测：按 addonName + groupKey 分组，含 RemoveButton 生命周期。
-- 分组底本 166:180:z-ref_retail_Interface_AddOns/HidingBar/HidingBar.lua；RemoveButton 373:388:_temp/EQoLPlus/API.lua
local AF = ResolveNamespace("ade_AddonFramework")
if not AF then return end
AF.Masque = {}

function AF.Masque.Available()
    return type(LibStub) == "table" and LibStub("Masque", true) ~= nil
end

function AF.Masque.Group(addonName, groupKey)
    local m = type(LibStub) == "table" and LibStub("Masque", true)
    if not m or not m.Group then return nil end
    return m:Group(addonName, groupKey)
end

--- 生命周期：不覆盖 group 自带方法，避免递归；优先用原生 RemoveButton。
function AF.Masque.RemoveButton(group, btn)
    if not group then return end
    if group.RemoveButton then
        group:RemoveButton(btn)
    elseif group.RemoveButtonEx then
        group:RemoveButtonEx(btn)
    elseif btn and btn.__MSQ_NormalTexture then
        btn.__MSQ_NormalTexture = nil
    end
end
