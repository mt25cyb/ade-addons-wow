-- adeBagPack / Minimap.lua — 小地图按钮（UIKit CreateMinimapButton；计划 §二决策 6，P3）
-- 左键 = 设置页；右键 = 两项上下文菜单（整理背包 / 设置）。
-- 旧 MENU_SELL_JUNK/转移菜单项随出售功能删除/入口收敛（决策 6 定案两项）。
-- 旧版走 AbstractFramework.NewMinimapButton（ade_Commons 依赖）→ 改 UIKit 自绘按钮（零依赖）。
local ABP = _G.adeBagPack
if not ABP then return end
local L = ABP.L
local UIKit = ABP.UIKit

local Minimap = {}
ABP.Minimap = Minimap

local button

function Minimap:OpenMenu(owner)
    -- 12.x Menu 系统（同仓库 Panel.lua:624-626 先例）：无菜单系统时右键退化为直接整理
    if not (MenuUtil and MenuUtil.CreateContextMenu) then
        ABP.Pack:Start("bag")
        return
    end
    MenuUtil.CreateContextMenu(owner, function(_, rootDescription)
        rootDescription:CreateButton(L["MENU_SORT_BAGS"], function()
            ABP.Pack:Start("bag")
        end)
        rootDescription:CreateButton(L["MENU_SETTINGS"], function()
            ABP.OpenSettings()
        end)
    end)
end

function Minimap:Init()
    if button then return end
    if not (UIKit and UIKit.CreateMinimapButton) then
        ABP:ShowMessage(tostring(L["MINIMAP_LIB_MISSING"]), 1, 0, 0)
        return
    end
    local p = ABP:GetProfile()
    if not p or not p.minimap then return end

    local meta = UIKit.GetAddonMeta(ABP.name)
    button = UIKit.CreateMinimapButton({
        name = "AdeBagPackMinimapButton",
        angle = p.minimap.minimapPos,
        -- radius=0 表示「默认半径」（InitDB 语义）；0 在 Lua 为真值，必须转 nil 才能落到 UIKit 默认
        radius = (p.minimap.radius and p.minimap.radius > 0) and p.minimap.radius or nil,
        icon = meta.icon,
        onClick = function(self, mouseButton)
            if mouseButton == "RightButton" then
                Minimap:OpenMenu(self)
            else
                ABP.OpenSettings()
            end
        end,
        -- 拖拽换角即时持久化（设置页 minimapPos 同一存档键）
        onAngleChanged = function(angle)
            p.minimap.minimapPos = angle
        end,
        getShown = function()
            return not p.minimap.hide
        end,
        tooltip = {
            title = ABP.title,
            lines = {
                L["TIP_LEFT"] .. " - " .. L["TIP_LEFT_SETTINGS"],
                L["TIP_RIGHT"] .. " - " .. L["TIP_RIGHT_FUNCS"],
            },
        },
    })
end