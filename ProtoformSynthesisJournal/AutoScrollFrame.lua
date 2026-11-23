local settings = {
    MousewheelSpeed = "Slow",
}

ProtoformSynthesisJournalAutoScrollFrameMixin = {}
local mixin = ProtoformSynthesisJournalAutoScrollFrameMixin

local createNewButton, adjustRange, setOffset, updateScrollButtons
local scrollByLine, scrollByPage, scrollByMousewheel
local getButtonHeight, updateDataHeight, getElementFromOffset, getOffsetFromIndex

function mixin:OnLoad()
    local scrollBar = self.ScrollFrame.ScrollBar

    self.offset = 0
    self.range = 0
    self.element = 0
    self.elementOffset = 0
    self.overflow = 0
    self.dataHeight = 0
    self.scrollHeight = nil
    self.scrollWidth = nil
    self.buttonHeight = nil
    self.hasButtons = nil

    scrollBar.PageUpButton:SetPoint("TOP", scrollBar.UpButton, "BOTTOM")
    scrollBar.PageUpButton:SetPoint("BOTTOM", scrollBar.ScrollThumb, "TOP", 0, -2)
    scrollBar.PageDownButton:SetPoint("TOP", scrollBar.ScrollThumb, "BOTTOM", 0, 3)
    scrollBar.PageDownButton:SetPoint("BOTTOM", scrollBar.DownButton, "TOP", 0, 1)

    -- 下列闭包的 self 是父框，不是被绑定的控件
    scrollBar:SetScript("OnValueChanged", function(_, value) setOffset(self, value) end)
    self.ScrollFrame:SetScript("OnMouseWheel", function(_, delta) scrollByMousewheel(self, delta) end)
    scrollBar.TopButton:SetScript("OnClick", function() setOffset(self, 0) end)
    scrollBar.UpButton:SetScript("OnClick", function() scrollByLine(self, 1) end)
    scrollBar.PageUpButton:SetScript("OnClick", function() scrollByPage(self, 1) end)
    scrollBar.BottomButton:SetScript("OnClick", function() setOffset(self, -1) end)
    scrollBar.DownButton:SetScript("OnClick", function() scrollByLine(self, -1) end)
    scrollBar.PageDownButton:SetScript("OnClick", function() scrollByPage(self, -1) end)

    updateScrollButtons(self)
    scrollBar.ScrollThumb:Hide()
end

function mixin:OnShow()
    if self.updateNeeded then
        self:Update()
    end
end

function mixin:OnSizeChanged(w, h)
    w = floor(w + 0.5)
    h = floor(h + 0.5)
    self.scrollWidth = w - 9
    self.scrollHeight = h - 10
    self.ScrollFrame:GetScrollChild():SetSize(self.scrollWidth, self.scrollHeight)
    if self.hasButtons then
        self:Update()
    end
end

function mixin:Update()
    if not self:IsVisible() then
        self.updateNeeded = true
        return
    end
    if not self.template or not self.list or not self.callback then
        return
    end
    if self.updating then
        return
    end
    self.updating = true

    local buttons = self.ScrollFrame.Buttons
    if not buttons then
        buttons = {createNewButton(self)}
        self.ScrollFrame.Buttons = buttons
        buttons[1]:SetPoint("TOPLEFT")
        self.buttonHeight = floor(buttons[1]:GetHeight() + 0.5)
        self.hasButtons = true
    end

    if not self.scrollHeight then
        self:OnSizeChanged(floor(self:GetWidth() + 0.5), floor(self:GetHeight() + 0.5))
    end

    updateDataHeight(self)
    adjustRange(self)
    if self.preUpdateFunc then
        self.preUpdateFunc(self)
    end

    local listSize = #self.list
    local listIndex = self.element + 1
    local remaining = self.scrollHeight + self.overflow
    local buttonWidth = self.scrollWidth - 25
    local buttonIndex = 1
    local lastButton

    while listIndex <= listSize and remaining do
        local buttonHeight = getButtonHeight(self, listIndex)
        if buttonHeight and buttonHeight > 0 then
            if not buttons[buttonIndex] then
                buttons[buttonIndex] = createNewButton(self)
                buttons[buttonIndex]:SetPoint("TOPLEFT", buttons[buttonIndex - 1], "BOTTOMLEFT")
            end

            if remaining < 0 then
                remaining = nil
            else
                remaining = remaining - buttonHeight
            end

            local button = buttons[buttonIndex]
            button.index = listIndex
            button:SetSize(buttonWidth, buttonHeight)
            self.callback(button, self.list[listIndex])
            button:Show()
            lastButton = button
            listIndex = listIndex + 1
            buttonIndex = buttonIndex + 1
        else
            remaining = nil
        end
    end

    for i = buttonIndex, #buttons do
        buttons[i]:Hide()
    end

    local captureButton = self.ScrollFrame.CaptureButton
    if self.range == 0 then
        captureButton:Show()
        captureButton:SetPoint("TOP", lastButton or self.ScrollFrame, lastButton and "BOTTOM" or "TOP")
    else
        captureButton:Hide()
        lastButton = nil
    end
    captureButton.lastButton = lastButton

    if self.postUpdateFunc then
        self.postUpdateFunc(self)
    end
    self.updating = nil
end

function mixin:ScrollToIndex(index)
    local offset
    if index == -1 then
        offset = -1
    elseif self.range == 0 then
        offset = 0
    else
        offset = getOffsetFromIndex(self, index)
    end
    setOffset(self, offset)
end

function createNewButton(self)
    return CreateFrame(self.templateType or "Button", nil, self.ScrollFrame:GetScrollChild(), self.template)
end

function adjustRange(self)
    local range = max(0, self.dataHeight - self.scrollHeight)
    if range ~= self.range then
        self.ScrollFrame.ScrollBar:SetMinMaxValues(0, range)
        local offset = max(0, min(range, self.offset))
        if self.offset == self.range and offset ~= 0 then
            offset = range
        end
        self.range = range
        if self.offset ~= offset or offset == 0 then
            self.offset = offset
            setOffset(self, offset)
        elseif offset == range then
            updateScrollButtons(self)
        end
    end
end

-- 基于 HybridScrollFrame_SetOffset；offset 为绝对像素偏移
function setOffset(self, offset)
    if offset == -1 then
        offset = self.range
    end
    self.offset = floor(max(0, min(self.range, offset)) + 0.5)

    local element, elementOffset, overflow = getElementFromOffset(self, self.offset)
    local changed = self.element ~= element
    self.element = element
    self.overflow = overflow
    self.elementOffset = elementOffset

    if changed then
        self:Update()
    end

    self.ScrollFrame:SetVerticalScroll(self.overflow)
    self.ScrollFrame.ScrollBar:SetValue(self.offset)
    updateScrollButtons(self)
end

function updateScrollButtons(self)
    local scrollBar, range, offset = self.ScrollFrame.ScrollBar, self.range, self.offset
    scrollBar.ScrollThumb:SetShown(range > 0)
    local canScrollUp = range > 0 and offset > 0
    scrollBar.TopButton:SetEnabled(canScrollUp)
    scrollBar.UpButton:SetEnabled(canScrollUp)
    scrollBar.PageUpButton:SetEnabled(canScrollUp)
    local canScrollDown = range > 0 and offset < range
    scrollBar.BottomButton:SetEnabled(canScrollDown)
    scrollBar.DownButton:SetEnabled(canScrollDown)
    scrollBar.PageDownButton:SetEnabled(canScrollDown)
end

function scrollByLine(self, delta)
    local newOffset
    if delta == 1 and self.overflow > 0 then
        newOffset = self.elementOffset
    else
        local buttonHeight
        if delta == 1 and self.element > 0 then
            buttonHeight = getButtonHeight(self, self.element)
        else
            buttonHeight = getButtonHeight(self, self.element + 1)
        end
        newOffset = self.elementOffset - delta * buttonHeight
    end
    newOffset = max(0, min(self.range, newOffset))
    if newOffset ~= self.offset then
        setOffset(self, newOffset)
    end
end

function scrollByPage(self, delta)
    local speed = settings.MousewheelSpeed == "Fast" and 1 or 2 / 3
    local newOffset
    if delta == 1 then
        newOffset = self.elementOffset - delta * (self.scrollHeight * speed - getButtonHeight(self, self.element))
    else
        newOffset = self.elementOffset - delta * self.scrollHeight * speed
    end
    local _, elementOffset = getElementFromOffset(self, newOffset)
    newOffset = max(0, min(self.range, elementOffset))
    if newOffset ~= self.offset then
        setOffset(self, newOffset)
    end
end

function scrollByMousewheel(self, delta)
    if self.range > 0 then
        if settings.MousewheelSpeed == "Slow" then
            scrollByLine(self, delta)
        else
            scrollByPage(self, delta)
        end
    end
end

function getButtonHeight(self, index)
    if self.dynamicButtonHeight then
        if index > 0 and index <= #self.list then
            return self.dynamicButtonHeight(self, index) or 0
        end
        return 0
    end
    return self.buttonHeight
end

function updateDataHeight(self)
    local dataHeight = 0
    if self.dynamicButtonHeight then
        for i = 1, #self.list do
            dataHeight = dataHeight + getButtonHeight(self, i)
        end
    else
        dataHeight = #self.list * self.buttonHeight
    end
    self.dataHeight = dataHeight
end

function getElementFromOffset(self, offset)
    local element, elementOffset, overflow = 0, 0, 0

    if not self.dynamicButtonHeight then
        local buttonHeight = self.buttonHeight
        local roughElement = offset / buttonHeight
        element = floor(roughElement)
        overflow = floor((roughElement - element) * buttonHeight + 0.5)
        elementOffset = element * buttonHeight
    else
        local prior, index = 0, 1
        while prior < offset do
            local buttonHeight = getButtonHeight(self, index)
            local post = prior + buttonHeight
            if buttonHeight and buttonHeight > 0 then
                if post > offset then
                    overflow = buttonHeight - (post - offset)
                else
                    element = element + 1
                    elementOffset = elementOffset + buttonHeight
                end
                prior = post
            else
                prior = offset
            end
            index = index + 1
        end
    end

    return element, elementOffset, overflow
end

function getOffsetFromIndex(self, index)
    local offset = 0
    if not self.dynamicButtonHeight then
        offset = (index + 1) * self.buttonHeight
    else
        for i = 1, index + 1 do
            offset = offset + getButtonHeight(self, i)
        end
    end
    offset = offset - self.scrollHeight / 2
    local _, elementOffset = getElementFromOffset(self, offset)
    return elementOffset
end
