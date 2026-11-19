local _, addon = ...
addon.StatsPanel = addon.StatsPanel or {}
local Panel = addon.StatsPanel
local L = addon.L
local Data = addon.Data

-- 综合统计子面板（开发计划 §二）：
--   左侧两行：第一行重要货币；第二行 重要道具 + 鎏金藏匿物 + 英雄灵魂残片。
--   右侧两行：词缀、玩具（地下堡机器人 7001 型），只显示图标。

-- 尺寸（用户 2026-10-27 指定）：行高 20、行距 4、上下各留 10、左右各留 20、面板高 64。
-- 校验：10 + 20 + 4 + 20 + 10 = 64，与给定的面板高吻合，所以 PANEL_HEIGHT 直接写死。
-- 机器人按钮 42x42；列宽不再均分：晦幽铸币数值可达五位数（截图 22072），前 3 列收窄、第 4 列加宽。
local SLOT_ICON = 14
-- 「值 图标」之间的间距、槽位右侧内缩。
local VALUE_GAP = 3
local SLOT_RIGHT_PADDING = 2
local ROW_HEIGHT = 20
local TOY_SIZE = 42
local ROW_GAP = 4
local TOP_PADDING = 10
-- 左右留白 22（用户 2026-10-28）。
local LEFT_PADDING = 22
local RIGHT_PADDING = 22
local PANEL_HEIGHT = 64
-- 4 列宽度权重：前 3 列 1，第 4 列 1.5（晦幽铸币独占宽列）。
local COLUMN_WEIGHTS = { 1, 1, 1, 1.5 }
-- 列与列之间留 4px（用户 2026-10-27 起先是 2，2026-10-28 再加 2）。
local COLUMN_GAP = 4
-- 整块面板相对宿主下移 8（用户 2026-10-27 起先是 4，2026-10-28 再加 4）。
-- TopBar 现在画在面板内部顶部（4 ~ -22，高 26），统计面板要落到它下方，
-- 否则会和顶栏叠在一起（用户 2026-10-28）。
-- 面板顶部 0~29 是顶栏行（原生 QuestsFrame 的 QuestScrollFrame 也从 -29 起，
-- QuestMapFrame.xml:456），统计面板排在顶栏下方，与内容区同一水平线。
local PANEL_TOP_OFFSET = -6

local function CreateSlot(parent)
    local slot = CreateFrame("Button", nil, parent)
    slot:SetSize(1, ROW_HEIGHT)

    -- 图标照 WQT 奖励图标（WorldQuestTab.xml:64-113）：TexCoord 裁黑边 + MaskTexture 圆角；
    -- 底部再压一条黑色渐变（WQT 的 AmountBG 同款 atlas MapCornerShadow-Left 左右翻转），
    -- 让图标下沿与卡片背景自然过渡，不再是一个生硬方块（用户 2026-10-27 要求「黑色虚影+圆角」）。
    -- 排列顺序是「值 图标」、整体右对齐（用户 2026-10-28）：图标贴列右边缘，
    -- 值右对齐排在图标左侧。
    local icon = slot:CreateTexture(nil, "ARTWORK")
    icon:SetSize(SLOT_ICON, SLOT_ICON)
    icon:SetPoint("RIGHT", slot, "RIGHT", -SLOT_RIGHT_PADDING, 0)
    icon:SetTexCoord(0.06, 0.94, 0.06, 0.94)
    slot.Icon = icon

    local iconMask = slot:CreateMaskTexture(nil, "ARTWORK")
    iconMask:SetTexture("Interface\\Common\\common-iconmask", "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
    iconMask:SetAllPoints(icon)
    icon:AddMaskTexture(iconMask)
    slot.IconMask = iconMask

    local iconShadow = slot:CreateTexture(nil, "ARTWORK")
    iconShadow:SetAtlas("MapCornerShadow-Left", false)
    iconShadow:SetVertexColor(0, 0, 0, 0.7)
    iconShadow:SetTexCoord(0.8, 0.0, 0.0, 1.0)
    iconShadow:SetHeight(6)
    iconShadow:SetPoint("BOTTOMLEFT", icon, "BOTTOMLEFT", -1, 0)
    iconShadow:SetPoint("BOTTOMRIGHT", icon, "BOTTOMRIGHT", 1, 0)
    slot.IconShadow = iconShadow

    -- 值与图标整体右对齐（用户 2026-10-28）。单锚点 + 自动宽度：值变长时向左延伸，
    -- 图标位置不动；宽度上限在 LayoutSlots 里按列宽算，避免长数字越过列左边界。
    local text = slot:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    text:SetPoint("RIGHT", icon, "LEFT", -VALUE_GAP, 0)
    text:SetJustifyH("RIGHT")
    slot.Text = text

    slot:SetScript("OnEnter", function(self)
        -- 货币槽直接用原生货币 tooltip（GameTooltip:SetCurrencyByID），与暴雪货币面板一致：
        -- 图标、名称、持有量、周上限都由游戏填，不再自己拼（用户 2026-10-27 要求）。
        if self.currencyID then
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            if not GameTooltip:SetCurrencyByID(self.currencyID) and self.tooltipTitle then
                GameTooltip:SetText(self.tooltipTitle, 1, 0.82, 0)
            end
            GameTooltip:Show()
            return
        end
        -- 道具槽优先用原生物品 tooltip（之前只设了标题，第二行四个道具全是空的）。
        -- 物品信息还没缓存时 SetItemByID 会返回 nil，这时用 API 名称兜底，
        -- 语言文件里不再硬编码道具名（用户 2026-10-28）。
        if self.itemID then
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            if not GameTooltip:SetItemByID(self.itemID) then
                local name = C_Item and C_Item.GetItemNameByID and C_Item.GetItemNameByID(self.itemID)
                if name then GameTooltip:SetText(name, 1, 0.82, 0) end
            end
            if self.tooltipLines and #self.tooltipLines > 0 then
                GameTooltip:AddLine(" ")
                for _, line in ipairs(self.tooltipLines) do
                    GameTooltip:AddLine(line[1], line[2], line[3], line[4], line[5])
                end
            end
            GameTooltip:Show()
            return
        end
        if not self.tooltipLines or #self.tooltipLines == 0 then return end
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        if self.tooltipTitle then
            GameTooltip:SetText(self.tooltipTitle, 1, 0.82, 0)
        end
        for _, line in ipairs(self.tooltipLines) do
            GameTooltip:AddLine(line[1], line[2], line[3], line[4], line[5])
        end
        GameTooltip:Show()
    end)
    slot:SetScript("OnLeave", function() GameTooltip:Hide() end)

    return slot
end

local function SetItemSlot(slot, itemID, label)
    local icon = C_Item and C_Item.GetItemIconByID and C_Item.GetItemIconByID(itemID) or nil
    slot.Icon:SetTexture(icon or "Interface\\Icons\\INV_Misc_QuestionMark")
    slot.Text:SetText(tostring(addon.Stats:GetItemCount(itemID)))
    slot.itemID = itemID
    slot.currencyID = nil
    slot.tooltipTitle = label
    slot.tooltipLines = {}
end

function Panel:Create(parent)
    local frame = CreateFrame("Frame", nil, parent)
    frame:SetHeight(PANEL_HEIGHT)
    -- 整块面板相对宿主下移 4（用户 2026-10-27）。
    frame:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, PANEL_TOP_OFFSET)
    frame:SetPoint("TOPRIGHT", parent, "TOPRIGHT", 0, PANEL_TOP_OFFSET)

    -- 头两行（货币行、道具行）与右侧机器人按钮视为一个整体，整块铺一张
    -- UI-Journeys-Delve-Card（用户指定 2026-10-27；图集拉伸填满，不按原始尺寸）。
    local background = frame:CreateTexture(nil, "BACKGROUND")
    background:SetAtlas("UI-Journeys-Delve-Card", false)
    background:SetAllPoints(frame)
    frame.Background = background

    -- 机器人按钮：右边距与面板留白一致（20），垂直方向与左侧两行内容居中对齐——
    -- 锚 `RIGHT` 取的就是垂直中心（用户 2026-10-27 要求「与两行内容水平居中对齐」）。
    local right = CreateFrame("Frame", nil, frame)
    right:SetPoint("RIGHT", frame, "RIGHT", -RIGHT_PADDING, 0)
    right:SetSize(TOY_SIZE, TOY_SIZE)

    local left = CreateFrame("Frame", nil, frame)
    left:SetPoint("TOPLEFT", frame, "TOPLEFT", LEFT_PADDING, -TOP_PADDING)
    left:SetPoint("RIGHT", right, "LEFT", -6, 0)
    left:SetHeight(ROW_HEIGHT * 2 + ROW_GAP)
    frame.LeftArea = left

    frame.currencySlots = {}
    for index = 1, 4 do
        frame.currencySlots[index] = CreateSlot(left)
    end

    frame.itemSlots = {}
    for index = 1, 4 do
        frame.itemSlots[index] = CreateSlot(left)
    end

    -- 右侧：机器人按钮。图标裁边 + 圆角遮罩，复刻 WQT 奖励图标的做法
    -- （WorldQuestTab.xml:106-111 用 MaskTexture；通用圆角遮罩文件见
    -- _temp/ProtoformSynthesis_ade-v2/ProtoformSynthesis_ade.xml:312）。
    local toyButton = CreateFrame("Button", nil, right, "SecureActionButtonTemplate")
    toyButton:SetSize(TOY_SIZE, TOY_SIZE)
    toyButton:SetPoint("TOPLEFT", right, "TOPLEFT", 0, 0)
    toyButton:SetAttribute("type1", "macro")
    toyButton:SetAttribute("macrotext1", "/use item:" .. tostring(Data.TOY.itemID))
    -- 12.x 实证（SecureTemplates.xml:4-10）：SecureActionButtonTemplate 同样不自带 RegisterForClicks，
    -- 必须显式注册；down/up 分支由 cvar「ActionButtonUseKeyDown」互斥决定，不会双触发。
    toyButton:RegisterForClicks("AnyDown", "AnyUp")
    local toyIcon = toyButton:CreateTexture(nil, "ARTWORK")
    toyIcon:SetSize(TOY_SIZE - 2, TOY_SIZE - 2)
    toyIcon:SetPoint("CENTER", 0, 0)
    toyIcon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    local spellIcon = C_Spell and C_Spell.GetSpellTexture and C_Spell.GetSpellTexture(Data.TOY.spellID) or nil
    toyIcon:SetTexture(spellIcon or (C_Item and C_Item.GetItemIconByID and C_Item.GetItemIconByID(Data.TOY.itemID)) or "Interface\\Icons\\INV_Misc_QuestionMark")
    toyButton.Icon = toyIcon

    local iconMask = toyButton:CreateMaskTexture(nil, "ARTWORK")
    iconMask:SetTexture("Interface\\Common\\common-iconmask", "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
    iconMask:SetAllPoints(toyIcon)
    toyIcon:AddMaskTexture(iconMask)
    toyButton.IconMask = iconMask

    local toyHighlight = toyButton:CreateTexture(nil, "HIGHLIGHT")
    toyHighlight:SetAllPoints(toyIcon)
    toyHighlight:SetColorTexture(1, 1, 1, 0.15)

    local cooldown = CreateFrame("Cooldown", nil, toyButton, "CooldownFrameTemplate")
    cooldown:SetAllPoints(toyIcon)
    toyButton.Cooldown = cooldown

    toyButton:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        -- SetItemByID 本身就会给出玩具名，后面不必再加一行名称。
        -- 信息没缓存时退到 API：C_ToyBox.GetToyInfo → C_Item.GetItemNameByID（用户 2026-10-28）。
        if not GameTooltip:SetItemByID(Data.TOY.itemID) then
            local toyName
            if C_ToyBox and C_ToyBox.GetToyInfo then
                local _, name = C_ToyBox.GetToyInfo(Data.TOY.itemID)
                toyName = name
            end
            if not toyName and C_Item and C_Item.GetItemNameByID then
                toyName = C_Item.GetItemNameByID(Data.TOY.itemID)
            end
            if toyName then GameTooltip:SetText(toyName, 1, 0.82, 0) end
        end
        GameTooltip:Show()
    end)
    toyButton:SetScript("OnLeave", function() GameTooltip:Hide() end)
    frame.toyButton = toyButton

    frame:SetScript("OnShow", function() Panel:Update(frame) end)
    return frame
end

--- 按权重排 4 列：面板宽度要等 OnSizeChanged 后才有值，所以每次刷新都重排一次。
-- 第 4 列（晦幽铸币）拿 1.5 倍宽度，前 3 列相应收窄（用户 2026-10-27 反馈：
-- 晦幽铸币五位数显示不全，其余三列反而空）。
local function LayoutSlots(frame)
    local left = frame.LeftArea
    if not left then return end
    local width = left:GetWidth()
    if not width or width <= 0 then return end

    local totalWeight = 0
    for _, weight in ipairs(COLUMN_WEIGHTS) do totalWeight = totalWeight + weight end
    -- 列间距：3 个间隔 × 2px，先从总宽里扣掉再按权重分，否则最后一列会被挤出容器。
    local unit = (width - COLUMN_GAP * (#COLUMN_WEIGHTS - 1)) / totalWeight

    local rows = {
        { slots = frame.currencySlots, y = 0 },
        { slots = frame.itemSlots, y = -(ROW_HEIGHT + ROW_GAP) },
    }
    for _, row in ipairs(rows) do
        local x = 0
        for index, slot in ipairs(row.slots) do
            local slotWidth = unit * (COLUMN_WEIGHTS[index] or 1)
            slot:ClearAllPoints()
            slot:SetPoint("TOPLEFT", left, "TOPLEFT", x, row.y)
            slot:SetWidth(slotWidth)
            -- 文字宽度上限 = 列宽 - 图标 - 间距 - 右内缩；配合右对齐，长数字只会往左伸展，
            -- 不会越过列左边界压到前一列。
            slot.Text:SetWidth(math.max(1, slotWidth - SLOT_ICON - VALUE_GAP - SLOT_RIGHT_PADDING))
            x = x + slotWidth + COLUMN_GAP
        end
    end
end

local function UpdateCurrencySlot(slot, currencyID)
    local info = addon.Stats:GetCurrency(currencyID)
    if not info then
        slot:Hide()
        return
    end
    -- 第二阶段 9.1.2：未激活货币（discovered == false）不再隐藏，按 0 显示、图标不灰化。
    -- GetCurrency 对未激活货币仍返回 icon/name（来自货币静态数据），直接照常渲染即可。
    slot:Show()
    slot.Icon:SetTexture(info.icon or "Interface\\Icons\\INV_Misc_QuestionMark")
    slot.Text:SetText(tostring(info.quantity or 0))
    slot.currencyID = currencyID
    slot.itemID = nil
    slot.tooltipTitle = info.name
    local lines = { { string.format("%d", info.quantity or 0), 1, 1, 1 } }
    if info.maxWeekly > 0 then
        lines[#lines + 1] = { string.format("%d/%d", info.earnedThisWeek or 0, info.maxWeekly), 0.7, 0.7, 0.7 }
    end
    slot.tooltipLines = lines
end

-- 每个鎏金藏匿物含 5 个 Myth Crests（DelveCompanion Config.lua:129）。
local GILDED_CRESTS_PER_STASH = 5

--- 鎏金藏匿物的 tooltip 照 DelveCompanion 的 GildedStashFrame.lua:78-98：
-- 先游戏给的 spellInfo.tooltip（API），再空行，再每周纹章上限，最后一句「仅出现在丰裕地下堡」。
-- 名称同样走 API，不在语言文件里硬编码。
local function UpdateGildedSlot(slot)
    local collected, total = addon.Stats:GetGildedStash()
    -- 图标用 5872049（用户指定，2026-10-27）。
    slot.Icon:SetTexture(5872049)
    slot.Text:SetText((collected and total) and string.format("%d/%d", collected, total) or "-")
    slot.itemID = nil
    slot.currencyID = nil
    slot.tooltipTitle = addon.Stats:GetGildedStashName()

    local lines = {}
    local desc = addon.Stats:GetGildedStashTooltip()
    if desc then
        lines[#lines + 1] = { desc, 1, 1, 1, true }
    end
    if total and total > 0 then
        lines[#lines + 1] = { " ", nil, nil, nil }
        lines[#lines + 1] = {
            string.format(L["GILDED_CRESTS_NOTE"], GILDED_CRESTS_PER_STASH, total * GILDED_CRESTS_PER_STASH),
            1, 1, 1, true,
        }
    end
    lines[#lines + 1] = { L["GILDED_BOUNTIFUL_NOTE"], 1, 1, 1, true }
    slot.tooltipLines = lines
end

function Panel:Update(frame)
    if not frame then return end

    LayoutSlots(frame)

    local c = Data.CURRENCIES
    UpdateCurrencySlot(frame.currencySlots[1], c.shards)
    UpdateCurrencySlot(frame.currencySlots[2], c.keys)
    UpdateCurrencySlot(frame.currencySlots[3], c.manaCrystal)
    -- 晦幽铸币放第 4 列（宽位），与「未被污染的法力水晶」对调——它是五位数，挤在窄列显示不全。
    UpdateCurrencySlot(frame.currencySlots[4], c.resonance)

    -- 第二行：两个道具 + 英雄灵魂残片 + 鎏金藏匿物。
    -- 三个道具都不传名称：tooltip 用 SetItemByID 让游戏自己出名称。
    SetItemSlot(frame.itemSlots[1], Data.ITEMS.bountyMap, nil)
    SetItemSlot(frame.itemSlots[2], Data.ITEMS.nemesisLure, nil)
    SetItemSlot(frame.itemSlots[3], Data.ITEMS.heroicSoulFragment, nil)

    UpdateGildedSlot(frame.itemSlots[4])

    -- 玩具冷却
    local start, duration = addon.Stats:GetToyCooldown()
    if start and duration and duration > 0 then
        frame.toyButton.Cooldown:SetCooldown(start, duration)
    else
        frame.toyButton.Cooldown:Clear()
    end
    if addon.Stats:HasToy() then
        frame.toyButton.Icon:SetVertexColor(1, 1, 1)
    else
        frame.toyButton.Icon:SetVertexColor(0.4, 0.4, 0.4)
    end
end
