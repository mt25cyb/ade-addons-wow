------------------------------------------------------------
-- 可滚动标签条（独立 API，b028 自 WindowMixin.lua 的 b027 顶栏改造提炼）。
-- 用法：
--   local strip = lib.CreateScrollableTabStrip(parent, {
--       top = -27, height = 37, left = 14,
--       right = -178,             -- 右箭头右缘 x 偏移（相对 parent 右缘，负值向内；
--                                 --   UIKit 设置窗 = BodyRight(-18) - SearchWidth(160)）
--       step = 60,                -- 单次滚动步长
--       template = "MinimalTabTemplate",
--       onSelect = function(button, id) end,   -- 点击标签回调
--   })
--   strip:SetTabs({ { id = X, text = "..." }, ... })   -- 按索引复用按钮，重建重排
--   strip:SetSelected(id)
-- 行为：标签区限定在左右箭头之间；内容超宽时显示两侧箭头（点击步进 + 标签区滚轮），
-- 已滚到端点该侧置 disabled 态，未超宽时箭头隐藏。标签按钮直接挂 clip 容器
-- （SetClipsChildren 递归裁剪按层 rect 求交，不得插入 0×0 中间层——实证教训）；
-- 滚动偏移设在首钮锚点上（官方 ScrollableTabsContainer Update():227 同款）。
-- 箭头四态 atlas shop-header-arrow / -hover / -pressed / -disabled（默认箭头向左，
-- 右钮 SetTexCoord(1,0,0,1) 镜像，CatalogShop Elements.lua:82-87 官方同款翻转）。
------------------------------------------------------------
local lib = ResolveBOFNamespace("ade_UIKit")
if not lib then return end

local Internal = lib.Internal
local mixins = Internal.Mixins
mixins.TabStrip = mixins.TabStrip or {}
local TabStripMixin = mixins.TabStrip

local TAB_TOP, TAB_HEIGHT = -28, 37
-- ARROW_LEFT=14：左箭头向左偏移贴窗口左缘。
-- ARROW_Y_NUDGE=6：MinimalTab 模板的 tab 可见图形锚 BOTTOMLEFT/BOTTOMRIGHT + UseAtlasSize （MinimalTab.xml），内容贴按钮底、按钮上部留空——箭头若按按钮几何中心放，视觉上整体
-- 偏上（2026-11-18 截图实证：箭头中线比标签文字中线高约 6~8px）。
-- 此补偿把箭头中心下移到可见内容中线；数值按实机观感微调。
local ARROW_LEFT, ARROW_SIZE, ARROW_GAP, SAFE_GAP = 14, 22, 4, 12
local ARROW_Y_NUDGE = 6
local SCROLL_STEP = 60
local TAB_SPACING = 4

-- 未超出限定宽度时箭头隐藏；已滚到端点时该侧箭头置 disabled 态（-disabled atlas）
local function MakeArrow(strip, name, direction)
    local button = CreateFrame("Button", nil, strip)
    button:SetSize(ARROW_SIZE, ARROW_SIZE)
    -- 注：RegisterForMouseWheel 对 Button 不可用（12.x 已整体移除，实证 _debug.log），
    -- 滚轮只挂 clip；箭头按钮走点击
    local flipped = direction == "right"
    local uvL, uvR = flipped and 1 or 0, flipped and 0 or 1
    local function MakeAtlas(atlas)
        local tex = button:CreateTexture(nil, "ARTWORK")
        tex:SetAllPoints(true)
        tex:SetAtlas(atlas, true)
        tex:SetTexCoord(uvL, uvR, 0, 1)
        return tex
    end
    button:SetNormalTexture(MakeAtlas("shop-header-arrow"))
    button:SetPushedTexture(MakeAtlas("shop-header-arrow-pressed"))
    button:SetHighlightTexture(MakeAtlas("shop-header-arrow-hover"))
    button:SetDisabledTexture(MakeAtlas("shop-header-arrow-disabled"))
    button:SetScript("OnClick", function()
        PlaySound(SOUNDKIT.IG_SPELLBOOK_OPEN)
        strip:Scroll(direction == "right" and strip.Step or -strip.Step)
    end)
    button[name] = true
    strip[name] = button
    return button
end

function TabStripMixin:Scroll(delta)
    self.Offset = math.max(0, math.min(self.MaxOffset or 0, (self.Offset or 0) + delta))
    if self.Buttons[1] then
        self.Buttons[1]:SetPoint("TOPLEFT", self.Clip, "TOPLEFT", -(self.Offset), 0)
    end
    self:UpdateArrows()
end

function TabStripMixin:UpdateArrows()
    local scrollable = (self.MaxOffset or 0) > 0
    self.ArrowLeft:SetShown(scrollable)
    self.ArrowRight:SetShown(scrollable)
    self.ArrowLeft:SetEnabled((self.Offset or 0) > 0)
    self.ArrowRight:SetEnabled((self.Offset or 0) < (self.MaxOffset or 0))
end

--- 重建/刷新标签：list = { { id, text } }。按钮按索引复用（文本/宽度重设）。
function TabStripMixin:SetTabs(list)
    local buttons = self.Buttons
    for i, tab in ipairs(list) do
        local button = buttons[i]
        if not button then
            button = CreateFrame("Button", nil, self.Clip, self.Template)
            button:SetHeight(self.Height)
            if i == 1 then button:SetPoint("TOPLEFT", self.Clip, "TOPLEFT", 0, 0)
            else button:SetPoint("TOPLEFT", buttons[i - 1], "TOPRIGHT", TAB_SPACING, 0) end
            button:SetScript("OnClick", function(clicked)
                self.OnSelect(clicked, clicked.id)
            end)
            buttons[i] = button
        end
        button.id = tab.id
        button.Text:SetText(tab.text)
        button:SetWidth(button.Text:GetStringWidth() + 40)
        button:Show()
    end
    for i = #list + 1, #buttons do buttons[i]:Hide() end
    -- 手动累加内容宽（窗口隐藏时 GetRight 不可靠），更新滚动上限与箭头
    local contentW = 0
    for i, b in ipairs(buttons) do
        if i > 1 then contentW = contentW + TAB_SPACING end
        contentW = contentW + b:GetWidth()
    end
    self.MaxOffset = math.max(0, math.ceil(contentW - self.Clip:GetWidth()))
    self.Offset = math.min(self.Offset or 0, self.MaxOffset)
    if buttons[1] then
        buttons[1]:SetPoint("TOPLEFT", self.Clip, "TOPLEFT", -(self.Offset), 0)
    end
    self:UpdateArrows()
end

--- 设置选中态（current 为当前选中的 id；按钮选中态由模板的 SetSelected 绘制）。
function TabStripMixin:SetSelected(current)
    for _, button in ipairs(self.Buttons) do
        if button.SetSelected then button:SetSelected(button.id == current) end
    end
end

--- 创建标签条。parent 为宿主 frame；opts 见文件头注释。
function lib.CreateScrollableTabStrip(parent, opts)
    opts = opts or {}
    local strip = CreateFrame("Frame", nil, parent)
    Mixin(strip, TabStripMixin)
    strip.Buttons, strip.Step = {}, opts.step or SCROLL_STEP
    strip.Template = opts.template or "MinimalTabTemplate"
    strip.Height = opts.height or TAB_HEIGHT
    strip.OnSelect = opts.onSelect or function() end
    local top = opts.top or TAB_TOP
    local left = opts.left or ARROW_LEFT
    -- 右界：右箭头右缘 x 偏移（相对 parent 右缘，负值向内）
    local right = opts.right or ((Internal.Geometry.BodyRight or -18) - (Internal.Geometry.SearchWidth or 160))
    local arrowTop = top - (strip.Height - ARROW_SIZE) / 2 - (opts.nudge or ARROW_Y_NUDGE)
    -- 左右箭头直接相对 parent 定位（同一 y 公式含视觉补偿，x 基准由 opts 给出——不做嵌套锚推算）
    MakeArrow(strip, "ArrowLeft", "left"):SetPoint(
        "TOPLEFT", parent, "TOPLEFT", left, arrowTop)
    MakeArrow(strip, "ArrowRight", "right"):SetPoint(
        "TOPRIGHT", parent, "TOPRIGHT", right - SAFE_GAP, arrowTop)
    strip.Clip = CreateFrame("Frame", nil, strip)
    strip.Clip:SetClipsChildren(true)
    -- 两锚点 y 一致（top），SetHeight 才是有效高度；宽 = 两箭头内侧间距
    strip.Clip:SetPoint("TOPLEFT", parent, "TOPLEFT", left + ARROW_SIZE + ARROW_GAP, top)
    strip.Clip:SetPoint("TOPRIGHT", parent, "TOPRIGHT", right - SAFE_GAP - ARROW_SIZE - ARROW_GAP, top)
    strip.Clip:SetHeight(strip.Height)
    -- 12.x：RegisterForMouseWheel 已移除（实证 _debug.log），滚轮启用改 ScriptRegion 层
    -- EnableMouseWheel（SimpleScriptRegionAPIDocumentation.lua:95）；handler 名为
    -- "OnMouseWheel"；惯例 delta * -1：滚轮向上 = 回滚到开头（ScrollableTabsContainer.lua:27）
    strip.Clip:EnableMouseWheel(true)
    strip.Clip:SetScript("OnMouseWheel", function(_, delta)
        strip:Scroll(-delta * strip.Step)
    end)
    strip.Offset, strip.MaxOffset = 0, 0
    return strip
end
