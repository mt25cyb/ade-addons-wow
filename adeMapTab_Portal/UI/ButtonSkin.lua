local _, addon = ...
addon.ButtonSkin = addon.ButtonSkin or {}
local Skin = addon.ButtonSkin
local L = addon.L

-- 传送按钮的外观。
--
-- 默认外观走 MiliUI 套组的「1px 纯色直角边框」风格；装了 Masque 时把按钮注册进
-- **本插件自己的 Masque 组**，玩家就能在 Masque 里为 adePortalTab 单独设置，
-- 而不必跟随 Masque 的全局设置（MiliUI_AuraEnhance 正是缺了这一步，用户实测）。
--
-- 风格来源：MiliUI_AuraEnhance Modules\Skin.lua（其第三代做法）—— 一張 1px 邊框貼圖
-- 錨在 Icon 四周、疊在下層，純色直角；只建自己的區塊、只呼叫純 setter，
-- 不藏 / 不搬 / 不鏡射暴雪的東西，所以 12.x 的秘密值與污染都安全。
-- 注册方式来源：ExtraQuestButton button.lua —— Masque:Group(addonName, addonName):AddButton(...)。
-- 多组 + 本地化组名 + 禁用开关：参考 HidingBar.lua:150-181 / HidingBar_Options/Main.lua:1963-1971。
--
-- 规范全文见 _docs/DevSpec-ButtonSkin-Masque-Manual.md。

local BORDER_COLOR = { 0, 0, 0 }
-- Masque:Group(Addon, Group, StaticID)：第一个参数是插件标识（决定 Masque 界面里的
-- Addon 节点，必须放着自己的组织名下），第二个参数是组名（可用本地化文案），
-- 第三个参数省略时用组名生成 ID（Masque/Core/Groups.lua:40-55）。
local MASQUE_ADDON = "adePortalTab"

-- 各按钮类型在 Masque 里的组标识：玩家可分别为它们单独设置外观。
Skin.GROUP_LIST = "List Teleports"   -- 世界地图清单里的传送图标（行按钮图标 / 紧凑图标）
Skin.GROUP_ZONE = "Zone Teleports"   -- 屏幕上的区域传送按钮

-- 组标识 -> 显示在 Masque 界面里的本地化组名（多语言）。
local GROUP_LOCALE_KEY = {
	[Skin.GROUP_LIST] = "MASQUE_GROUP_LIST",
	[Skin.GROUP_ZONE] = "MASQUE_GROUP_ZONE",
}

local borders = {}
local borderMasks = {}
local groups = {} -- groupKey -> Masque group 对象
local masqueInstance
-- 按钮会被池化复用、随时可能不再显示，用弱键免得它们回收不掉。
local registered = setmetatable({}, { __mode = "k" })

-- 运行时才取：Masque 可能在本插件之后才加载（延迟加载），文件加载时取容易拿到 nil。
-- 取不到时不把「暂时没有」当成「没有」，下次再问时重试。
local function GetMasque()
	if masqueInstance == nil or masqueInstance == false then
		masqueInstance = (LibStub and LibStub("Masque", true)) or false
	end
	if masqueInstance == false then return nil end
	return masqueInstance
end

--- 禁用 Masque 皮肤开关（用户 2026-10-30）：打开后所有按钮只用自带 1px 边框。
local function MasqueDisabled()
	return addon.db and addon.db["portalDisableMasque"] == true
end

--- **Masque 组必须在文件加载时就创建**，这是能不能在 Masque 设置界面里看到的关键。
--- Masque 的选项树是在它自己的初始化时一次性遍历现存的组来搭建的
--- （Masque/Options/Skins.lua:490-501 只遍历全局 SubList 各一层）。
--- 若等到按钮创建时才建组，本插件的节点永远不会出现在 Masque 界面里
--- （2026-10-30 实测：用户看不到 adePortalTab）。
local function EnsureGroups()
	local msq = GetMasque()
	if not msq then return end
	for key, localeKey in pairs(GROUP_LOCALE_KEY) do
		if not groups[key] then
			groups[key] = msq:Group(MASQUE_ADDON, L[localeKey] or key)
		end
	end
	if not groups[MASQUE_ADDON] then
		-- 默认组（Addon 级节点，供 Skin:Apply 使用）
		groups[MASQUE_ADDON] = msq:Group(MASQUE_ADDON)
	end
end

-- 加载即建组（HidingBar.lua:150-181 的同款写法）
EnsureGroups()

--- 无 Masque 时的默认外观：Icon 四周 1px 纯色直角边框，垫在 Icon 下层。
function Skin:ApplyDefaultBorder(button)
	local icon = button.Icon
	if not icon then return end
	-- 基座 ADE.CreateStyledButton 已提供暗色边缘虚影（button.EdgeShadow）时不再叠自带描边，避免重影。
	if button.EdgeShadow then return end
	local border = borders[button]
	if not border then
		-- 垫在 BACKGROUND 的 -1 层（Icon 在 0 层），不跟暴雪抢层。
		-- 不开像素贴齐：1px 换算后往往不是整数框架单位，贴齐会被捨入成 0 或 2px
		-- （MiliUI Skin.lua 的同款坑）。
		border = button:CreateTexture(nil, "BACKGROUND", nil, -1)
		borders[button] = border
	end
	border:ClearAllPoints()
	border:SetPoint("TOPLEFT", icon, "TOPLEFT", -1, 1)
	border:SetPoint("BOTTOMRIGHT", icon, "BOTTOMRIGHT", 1, -1)
	border:SetColorTexture(BORDER_COLOR[1], BORDER_COLOR[2], BORDER_COLOR[3])
	-- 圆形外观时给背景描边也套同形状遮罩，避免方形边框压在圆形图标外（照 EQoLPlusMapExt）。
	local maskTex = (button.shape == "circle")
		and "Interface/Common/commonmaskcircle"
		or "Interface/Common/common-iconmask"
	local mask = borderMasks[button]
	if not mask then
		mask = button:CreateMaskTexture()
		border:AddMaskTexture(mask)
		borderMasks[button] = mask
	end
	mask:SetTexture(maskTex, "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
	mask:SetAllPoints(border)
	border:Show()
end

function Skin:HideDefaultBorder(button)
	local border = borders[button]
	if border then border:Hide() end
end

--- 把按钮注册进指定的 Masque 组；Masque 不可用、或用户禁用了 Masque 皮肤时，
--- 回退到自带 1px 边框（此时按钮不进 Masque，Masque 界面里的组仍是空的，这是预期行为）。
--- @param button Frame 需要有 Icon；cooldownFrame / 高亮纹理会自动作为 region 传过去。
--- @param groupKey string|nil Masque 组标识（Skin.GROUP_LIST / Skin.GROUP_ZONE）；
---   省略时用 Addon 级默认组。
function Skin:ApplyGroup(button, groupKey)
	if not button or not button.Icon then return end
	EnsureGroups()
	local msq = GetMasque()
	-- 圆形外观强制走自带圆形描边，避免 Masque 方形皮肤与圆形裁切冲突（照 EQoLPlusMapExt）。
	if not msq or MasqueDisabled() or button.shape == "circle" then
		self:ApplyDefaultBorder(button)
		return
	end
	local group = groups[groupKey or MASQUE_ADDON]
	if not group then
		self:ApplyDefaultBorder(button)
		return
	end
	local regions = { Icon = button.Icon }
	if button.cooldownFrame then regions.Cooldown = button.cooldownFrame end
	local hl = button.GetHighlightTexture and button:GetHighlightTexture()
	if hl then regions.Highlight = hl end
	group:AddButton(button, regions)
	registered[button] = groupKey or MASQUE_ADDON
	self:HideDefaultBorder(button)
end

--- 给按钮套外观（默认组）：Masque 可用则注册并隐藏自带边框，否则用自带 1px 边框。
--- @param allowMasque boolean|nil 默认 true。**「图标 + 文字」的行按钮必须传 false**：
---   Masque 按标准图标按钮重排 region，会把左侧小图标拉伸到整行并盖住文字（实测）。
function Skin:Apply(button, allowMasque)
	if not button or not button.Icon then return end
	if allowMasque == false then
		self:ApplyDefaultBorder(button)
		return
	end
	self:ApplyGroup(button, MASQUE_ADDON)
end

--- 切换「禁用 Masque 皮肤」后刷新已注册的按钮：退组 / 重新入组，无需 reload。
--- HidingBar 的做法是改完弹重载提示（HidingBar_Options/Main.lua:1963-1971），
--- 这里因为按钮是池化的、开关也可随时切，所以直接在这
--- SetSkin(id)/RemoveButton(button) 之间热切换。
function Skin:RefreshAll()
	EnsureGroups()
	local msq = GetMasque()
	if not msq then
		-- Masque 不在：确保按钮至少有自己的边框
		for button in pairs(registered) do
			self:ApplyDefaultBorder(button)
		end
		return
	end
	if MasqueDisabled() then
		for button, groupKey in pairs(registered) do
			local group = groups[groupKey or MASQUE_ADDON]
			if group and group.RemoveButton then group:RemoveButton(button) end
			self:ApplyDefaultBorder(button)
		end
	else
		local seen = {}
		for button, groupKey in pairs(registered) do
			seen[button] = groupKey
		end
		for button, groupKey in pairs(seen) do
			self:ApplyGroup(button, groupKey)
		end
	end
end
