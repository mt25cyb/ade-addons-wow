-- 行看板：一行 = 一条深色条 + 若干元素方块（超宽自动换行）；每条左侧**外部**挂一个移动控件拖整行调序，
-- 同时每个方块本身也可拖动，在行内或跨行重新排序（对齐 MiliUI_Tooltip「玩家 → 显示元素」）。
-- 版面与拖拽机制底本 80:441:z-ref_retail_Interface_AddOns/MiliUI_Tooltip/Options/Tab_Unit.lua
--（STRIP_LINE_H / CHIP_H / CHIP_GAP / 换行 FlowChips / 幽灵 / 目标条高亮 / CursorIn 命中）。
-- 拖拽结束改用 IsMouseButtonDown 轮询：按钮 OnMouseUp 在指针移出按钮后不会触发，这正是旧版整行调序失败的根因。
local AF = ResolveNamespace("ade_AddonFramework")
if not AF then return end
AF.Template = AF.Template or {}
AF.Widget = AF.Widget or {}
local W = {}
AF.Template.Reorder = W      -- 组合模板：元素拖动调整顺序（行看板）
AF.Widget.RowDrag = W       -- 别名兼容

local STRIP_LINE_H = 22
local CHIP_H = 18
local CHIP_GAP = 4
local HANDLE_W = 18
local THRESHOLD = 6

-- 行条/方块配色底本 171、188:224:…/Tab_Unit.lua（0.085 条、0.16 方块）
local STRIP_FILL = { 0.085, 0.085, 0.085, 1 }
local CHIP_FILL = { 0.16, 0.16, 0.16, 1 }

local ghost
local function EnsureGhost()
    if ghost then return ghost end
    ghost = CreateFrame("Frame", nil, UIParent)
    ghost:SetFrameStrata("TOOLTIP")
    local skin = AF.Stylize(ghost, { 0.2, 0.2, 0.2, 0.9 })
    AF.RegisterTheme(ghost, function() skin:SetBorder(AF.ColorTable("accent")) end)
    skin:SetBorder(AF.ThemeColorTable(board, "accent"))
    ghost:SetHeight(CHIP_H)
    ghost.text = ghost:CreateFontString(nil, "OVERLAY")
    ghost.text:SetFontObject(AF.fontSmall)
    ghost.text:SetPoint("CENTER", 0, 0)
    ghost:Hide()
    return ghost
end

-- 100:112:…/Tab_Unit.lua
local function CursorPos(frame)
    local scale = frame:GetEffectiveScale()
    local x, y = GetCursorPosition()
    return x / scale, y / scale
end

local function CursorIn(frame)
    if not frame:IsVisible() then return false end
    local x, y = CursorPos(frame)
    local l, r, t, b = frame:GetLeft(), frame:GetRight(), frame:GetTop(), frame:GetBottom()
    if not l then return false end
    return x >= l and x <= r and y <= t and y >= b
end

function W.Create(parent, opts)
    opts = opts or {}
    local width = opts.width or 300
    local board = CreateFrame("Frame", nil, parent)
    board:SetWidth(HANDLE_W + 6 + width)
    board.rows = opts.rows or {} -- { { { text = "…", icon = … }, … }, … }
    board.strips, board.handles = {}, {}
    -- 落点示意符：一根随主题色的竖直细条，标出方块将要插入的位置（2026-11-14 用户要求）
    local dropMarker = board:CreateTexture(nil, "OVERLAY")
    dropMarker:SetTexture(AF.WHITE)
    dropMarker:SetVertexColor(AF.ThemeColor(board, "accent"))
    dropMarker:SetWidth(2)
    dropMarker:Hide()
    local dragState

    local function AcquireStrip(i)
        local strip = board.strips[i]
        if not strip then
            strip = CreateFrame("Frame", nil, board)
            strip.skin = AF.Stylize(strip, STRIP_FILL, AF.C.EDGE)
            board.strips[i] = strip
        end
        strip:Show()
        return strip
    end

    local function AcquireHandle(i)
        local handle = board.handles[i]
        if not handle then
            handle = CreateFrame("Button", nil, board)
            handle:SetSize(HANDLE_W, HANDLE_W)
            handle.tex = handle:CreateTexture(nil, "ARTWORK")
            AF.NoSnap(handle.tex)
            handle.tex:SetAllPoints()
            handle:SetScript("OnMouseDown", function(_, button)
                if button ~= "LeftButton" then return end
                local x, y = GetCursorPosition()
                dragState = { kind = "row", index = handle.index, startX = x, startY = y, active = false }
            end)
            board.handles[i] = handle
        end
        handle.index = i
        handle:Show()
        return handle
    end

    -- 212:240:…/Tab_Unit.lua 的 FlowChips：超宽自动换行，回传行数。方块走元件池
    local chipPool = {}
    local function AcquireChip()
        board.chipCount = board.chipCount + 1
        local chip = chipPool[board.chipCount]
        if not chip then
            chip = CreateFrame("Frame", nil, board)
            chip:EnableMouse(true)
            chip.skin = AF.Stylize(chip, CHIP_FILL, AF.C.EDGE)
            chip.text = chip:CreateFontString(nil, "OVERLAY")
            chip.text:SetFontObject(AF.fontSmall)
            chip.text:SetPoint("LEFT", 6, 0)
            chip.text:SetPoint("RIGHT", -5, 0)
            chip.text:SetJustifyH("LEFT")
            chip.icon = chip:CreateTexture(nil, "ARTWORK")
            AF.NoSnap(chip.icon)
            chip.icon:SetPoint("LEFT", 4, 0)
            chip.icon:SetSize(CHIP_H - 6, CHIP_H - 6)
            chip:SetScript("OnMouseDown", function(_, button)
                if button ~= "LeftButton" then return end
                local x, y = GetCursorPosition()
                dragState = { kind = "chip", frame = chip, row = chip.rowIndex, chip = chip.chipIndex,
                    startX = x, startY = y, active = false }
            end)
            chipPool[board.chipCount] = chip
        end
        return chip
    end

    local function FlowChips(strip, chips)
        strip.chipList = {} -- 显示顺序的方块 Frame 列表（MiliUI DropTarget 遍历用）
        local x, line = CHIP_GAP, 1
        for c, chipData in ipairs(chips) do
            local chip = AcquireChip()
            chip:SetParent(strip)
            chip.rowIndex, chip.chipIndex = strip.rowIndex, c
            chip.data, chip.lineNo = chipData, line
            strip.chipList[#strip.chipList + 1] = chip
            chip.skin:SetBorder(AF.C.EDGE)
            chip.text:SetTextColor(unpack(AF.C.TEXT_MAIN))
            chip.text:SetText(chipData.text or "")
            chip.icon:SetShown(chipData.icon ~= nil)
            if chipData.icon then AF.ResolveIcon(chip.icon, chipData.icon, chipData.icon) end
            chip.text:ClearAllPoints()
            if chipData.icon then
                chip.text:SetPoint("LEFT", chip.icon, "RIGHT", 3, 0)
            else
                chip.text:SetPoint("LEFT", 6, 0)
            end
            chip.text:SetPoint("RIGHT", -5, 0)
            local w = math.ceil(chip.text:GetStringWidth() or 0) + 12 + (chipData.icon and 18 or 0)
            if x + w + CHIP_GAP > width and x > CHIP_GAP then
                x = CHIP_GAP
                line = line + 1
            end
            chip:SetSize(w, CHIP_H)
            chip:ClearAllPoints()
            chip:SetPoint("TOPLEFT", strip, "TOPLEFT", x, -((line - 1) * STRIP_LINE_H + 2))
            x = x + w + CHIP_GAP
            chip:Show()
        end
        return line
    end

    function board:Rebuild()
        for _, c in ipairs(chipPool) do c:Hide() end
        for _, s in ipairs(self.strips) do s:Hide() end
        for _, h in ipairs(self.handles) do h:Hide() end
        board.chipCount = 0

        local y = 0
        for r, chips in ipairs(self.rows) do
            local strip = AcquireStrip(r)
            strip.rowIndex = r
            local handle = AcquireHandle(r)
            strip:ClearAllPoints()
            strip:SetPoint("TOPLEFT", self, "TOPLEFT", HANDLE_W + 6, -y)
            local lines = FlowChips(strip, chips)
            strip:SetSize(width, lines * STRIP_LINE_H + 4)
            handle:ClearAllPoints()
            handle:SetPoint("TOPLEFT", self, "TOPLEFT", 0, -(y + (strip:GetHeight() - HANDLE_W) / 2))
            AF.ResolveIcon(handle.tex, { atlas = "common-icon-move" }, { atlas = true })
            handle.tex:SetVertexColor(unpack(AF.C.TEXT_MUTED))
            y = y + strip:GetHeight() + 6
        end
        self:SetHeight(math.max(y - 6, 0))
        if opts.onReorder then opts.onReorder(self.rows) end
    end

    -- 344:367:…/Tab_Unit.lua 的 DropTarget：返回 列号 + 锚点数据（要插在它**前面**；nil = 排最后）。
    -- 逐方块比较视觉位置：先比行号（换行后 lineNo 更大的在前），同行再比中心 x 是否在光标右侧。
    -- 旧版遍历数据表拿 GetCenter 恒 nil，导致只能追加到行尾/倒数第二（2026-11-14 用户反馈根因）。
    local function DropTarget(dragChip)
        for _, s in ipairs(board.strips) do
            if s:IsVisible() and CursorIn(s) then
                local x, cy = CursorPos(s)
                local top = s:GetTop()
                local cursorLine = top and math.floor((top - cy) / STRIP_LINE_H) + 1
                for _, chip in ipairs(s.chipList or {}) do
                    if chip ~= dragChip then
                        local centerX = chip:GetLeft() and (chip:GetLeft() + chip:GetWidth() / 2)
                        if centerX and cursorLine and (chip.lineNo > cursorLine
                            or (chip.lineNo == cursorLine and centerX > x)) then
                            return s.rowIndex, chip.data
                        end
                    end
                end
                return s.rowIndex, nil
            end
        end
        local bx, by = CursorPos(board)
        if by < (board:GetBottom() or 0) then return #board.rows + 1, nil end -- 板子下方 = 新建一行
        return nil
    end

    function board:EndDrag()
        if not dragState then return end
        dropMarker:Hide()
        if dragState.active then
            if dragState.kind == "row" then
                local target = DropTarget(nil)
                if target then
                    local moving = table.remove(self.rows, dragState.index)
                    if moving then
                        if target > #self.rows + 1 then target = #self.rows + 1 end
                        table.insert(self.rows, target, moving)
                    end
                end
            else
                -- 414:433:…/Tab_Unit.lua：先从原行移除，再按锚点数据在目标行里找插入位
                local target, anchorData = DropTarget(dragState.frame)
                if target then
                    local srcRow = self.rows[dragState.row]
                    local data = srcRow and srcRow[dragState.chip]
                    if data then
                        table.remove(srcRow, dragState.chip)
                        local trow = self.rows[target]
                        if not trow then trow = {}; self.rows[target] = trow end
                        local at = #trow + 1
                        if anchorData then
                            for i, d in ipairs(trow) do
                                if d == anchorData then at = i; break end
                            end
                        end
                        table.insert(trow, at, data)
                    end
                    -- 行空了就剪掉（MiliUI PruneEmptyRows），避免残留空条
                    for i = #self.rows, 1, -1 do
                        if #self.rows[i] == 0 then table.remove(self.rows, i) end
                    end
                end
            end
            EnsureGhost():Hide()
            self:Rebuild()
        end
        dragState = nil
        for _, s in ipairs(self.strips) do s.skin:SetBorder(AF.C.EDGE) end
    end

    local updater = CreateFrame("Frame", nil, board)
    updater:SetScript("OnUpdate", function()
        if not dragState then return end
        local x, y = GetCursorPosition()
        if not dragState.active then
            if math.abs(x - dragState.startX) > THRESHOLD or math.abs(y - dragState.startY) > THRESHOLD then
                dragState.active = true
                local g = EnsureGhost()
                local label
                if dragState.kind == "row" then
                    local labels = {}
                    for _, chip in ipairs(board.rows[dragState.index] or {}) do
                        labels[#labels + 1] = chip.text or "?"
                    end
                    label = table.concat(labels, "  ")
                else
                    label = dragState.frame and dragState.frame.text:GetText() or "?"
                end
                g.text:SetText(label)
                g:SetWidth(math.min(width, math.max(80, (g.text:GetStringWidth() or 0) + 14)))
                g:Show()
            end
            return
        end
        -- 拖动中：跟随光标 + 高亮目标条；松手（指针离开左键）即结束
        local g = EnsureGhost()
        local s = UIParent:GetEffectiveScale() or 1
        g:ClearAllPoints()
        g:SetPoint("CENTER", UIParent, "BOTTOMLEFT", x / s, y / s + 10)
        local rowIndex, anchorData = DropTarget(dragState.kind == "chip" and dragState.frame or nil)
        for _, strip in ipairs(board.strips) do
            strip.skin:SetBorder(strip.rowIndex == rowIndex and AF.ThemeColorTable(strip, "accent") or AF.C.EDGE)
        end
        -- 落点示意符：仅方块拖拽显示，插在锚点方块左侧（无锚点=插到行尾）
        dropMarker:Hide()
        if dragState.kind == "chip" and rowIndex then
            local strip = board.strips[rowIndex]
            if strip then
                dropMarker:SetParent(strip)
                dropMarker:SetHeight(strip:GetHeight())
                local list = strip.chipList or {}
                if anchorData then
                    local anchorChip
                    for _, c in ipairs(list) do if c.data == anchorData then anchorChip = c; break end end
                    if anchorChip then
                        dropMarker:ClearAllPoints()
                        dropMarker:SetPoint("LEFT", anchorChip, "LEFT", -2, 0)
                        dropMarker:Show()
                    end
                else
                    dropMarker:ClearAllPoints()
                    if #list > 0 then
                        dropMarker:SetPoint("LEFT", list[#list], "RIGHT", 2, 0)
                    else
                        dropMarker:SetPoint("TOPLEFT", strip, "TOPLEFT", 2, 0)
                    end
                    dropMarker:Show()
                end
            end
        end
        if not IsMouseButtonDown("LeftButton") then board:EndDrag() end
    end)

    function board:SetRows(rows)
        self.rows = rows or {}
        self:Rebuild()
    end

    board:Rebuild()
    return board
end
