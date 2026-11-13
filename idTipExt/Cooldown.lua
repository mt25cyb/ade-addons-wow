----------------------------------------------------------------------------
-- idTipExt 冷却ID模块（12.x 重写）
-- 挂载点依据：Gethe/wow-ui-source:Interface/AddOns/Blizzard_CooldownViewer/CooldownViewerItemData.lua
--   :181 GetCooldownID() 返回 self.cooldownID（冷却管理器条目）
--   :1007 RefreshTooltip() 在 OnEnter 与法术数据加载完成后调用
-- 直接读条目数据，无需遍历 owner 字段
----------------------------------------------------------------------------

local addonName = ...
local ns = _G[addonName]

local hooked = false

local function hookCooldownViewer()
	if hooked or not CooldownViewerItemDataMixin then return end
	hooked = true
	ns.hook(CooldownViewerItemDataMixin, "RefreshTooltip", function(self)
		if not ns.isEnabled("cooldown") then return end
		local cooldownID = self.GetCooldownID and self:GetCooldownID()
		if cooldownID and type(cooldownID) == "number" then
			ns.add(GameTooltip, cooldownID, "cooldown")
		end
	end)
end

-- Blizzard_CooldownViewer 启动即载；若按需加载则兜底挂一次
hookCooldownViewer()
ns.RegisterOnAddonLoaded(function(addon)
	if addon == "Blizzard_CooldownViewer" then
		hookCooldownViewer()
	end
end)
