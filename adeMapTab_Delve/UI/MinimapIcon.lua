--[==[ adeMapTab_Delve / UI / MinimapIcon.lua — ADE v6.5
小地图图标改走 ade_UIKit 自绘按钮（零依赖，lib.CreateMinimapButton）：
- 位置/显隐持久化仍用旧存档字段 addon.db.minimap = { hide, minimapPos, radius }
  （minimapPos 即角度，radius=0 表示用库默认环半径，v6.5 存档无需迁移）；
- 单一入口不变（用户 2026-11-10 要求）：点击打开战团统计窗口（RosterWindow:Toggle）；
- 图标走 UIKit GetAddonMeta（b024）：TOC ## IconTexture 优先于 ## IconAtlas，icon 为
  三态 spec 直传 CreateMinimapButton。
显示开关 showMinimapIcon 与 minimap.hide 联动，ApplyShown 即时生效（SettingsPanel 调用）。 ]==]
local addonName, addon = ...

local MinimapIcon = addon.MinimapIcon
local btn -- UIKit 自绘按钮实例

local function GetOF()
    local lib = GetBlizzOptionsFrame and GetBlizzOptionsFrame("ade_UIKit", true)
    if lib then return lib end
    return BOF_LIBS and BOF_LIBS["ade_UIKit"]
end

--- 单一入口：打开 / 关闭战团角色统计窗口。
local function OnClick()
    if addon.RosterWindow and addon.RosterWindow.Toggle then
        addon.RosterWindow:Toggle()
    end
end

function MinimapIcon:Init()
    if btn then return end
    local lib = GetOF()
    if not (lib and lib.CreateMinimapButton) then return end
    local minimap = addon.db and addon.db.minimap
    if not minimap then return end

    -- 名称/图标统一经 UIKit GetAddonMeta 取 TOC 元数据（b024；图标 IconTexture
    -- 优先于 IconAtlas，icon 为三态 spec 直传）。
    local meta = lib.GetAddonMeta(addonName)
    btn = lib.CreateMinimapButton({
        name = "adeMapTabDelveMinimapButton",
        icon = meta.icon,
        angle = minimap.minimapPos,
        radius = (minimap.radius and minimap.radius > 0) and minimap.radius or nil,
        getShown = function() return not addon.db.minimap.hide end,
        setShown = function(shown) addon.db.minimap.hide = not shown end,
        onAngleChanged = function(angle) addon.db.minimap.minimapPos = angle end,
        onClick = OnClick,
        tooltip = {
            title = meta.title,
            lines = { addon.L["MINIMAP_TIP_LEFT_ACTION"] },
        },
    })
    MinimapIcon:ApplyShown()
end

--- 设置项「显示小地图图标」切换：与 profile.minimap.hide 联动，免重载即时生效。
function MinimapIcon:ApplyShown()
    if not btn then return end
    addon.db.minimap.hide = addon.db.showMinimapIcon == false
    btn:RefreshShown()
end

--- 保留旧接口（v6.5 无 profile 切换，按钮闭包动态读 addon.db，无需重传引用）。
function MinimapIcon:RefreshDB()
    MinimapIcon:ApplyShown()
end
