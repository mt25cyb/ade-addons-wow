------------------------------------------------------------
-- 插件 TOC 元数据统一读取（用户 2026-11-18）。
-- 名称/版本/图标只能经 C_AddOns.GetAddOnMetadata 获取；图标两态归一：
-- IconTexture 与 IconAtlas 都声明时用 IconTexture；icon 字段为 UIKit 三态
-- 描述（{texture=FileID|路径} / {atlas=Atlas 名}），可直接传给
-- CreateMinimapButton 的 icon、SetButtonIcon / ApplyIcon。
-- 纯数字的 IconTexture 归一为 FileID number（字符串 FileID 不能直接 SetTexture）。
------------------------------------------------------------
local lib = ResolveBOFNamespace("ade_UIKit")
if not lib then return end

---@param addonName string
---@return table { title, version, iconTexture, iconAtlas, icon }
function lib.GetAddonMeta(addonName)
    local title = C_AddOns.GetAddOnMetadata(addonName, "Title")
    local version = C_AddOns.GetAddOnMetadata(addonName, "Version")
    local texture = C_AddOns.GetAddOnMetadata(addonName, "IconTexture")
    local atlas = C_AddOns.GetAddOnMetadata(addonName, "IconAtlas")
    if texture and texture:match("^%d+$") then texture = tonumber(texture) end
    local icon
    if texture then
        icon = { texture = texture }
    elseif atlas then
        icon = { atlas = atlas }
    end
    return { title = title, version = version, iconTexture = texture, iconAtlas = atlas, icon = icon }
end
