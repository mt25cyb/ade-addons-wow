-- 选项行：label + 控件 + 可选逐项重置按钮。
-- 底本 913:943:z-ref_retail_Interface_AddOns/PrettyTooltip/UI/Editor.lua（第 3 参数决定是否加按钮、偏离默认才显示）
local AF = ResolveNamespace("ade_AddonFramework")
if not AF then return end
AF.Widget = AF.Widget or {}
local W = {}
AF.Widget.Row = W

--- opts.reset = false | true | "changed"（不显示 / 常显 / 仅偏离默认显示）
function W.Create(parent, opts)
    opts = opts or {}
    local width = opts.width or AF.LAYOUT.contentW
    local labelW = opts.labelW or AF.LAYOUT.labelW
    local h = opts.height or 24

    local row = CreateFrame("Frame", nil, parent)
    row:SetSize(width, h)
    row.label = row:CreateFontString(nil, "OVERLAY")
    row.label:SetFontObject(AF.fontNormal)
    row.label:SetPoint("LEFT", 0, 0)
    row.label:SetWidth(labelW)
    -- 同行、文本在左侧的控件：标签右对齐，文字贴紧右侧控件（2026-11-13 用户要求）
    row.label:SetJustifyH("RIGHT")
    row.label:SetText(opts.label or "")

    local control = opts.control
    if control then
        control:SetParent(row)
        control:ClearAllPoints()
        control:SetPoint("LEFT", labelW + 8, 0)
    end
    row.control = control

    local resetMode = opts.reset
    if resetMode then
        local btn = AF.Widget.Icon.CreateButton(row, {
            size = 16, atlas = "common-icon-undo", tooltip = AF.L["AF_RESET_ROW"],
            onClick = function()
                if opts.resetValue then opts.resetValue() end
                if opts.onChange then opts.onChange() end
            end,
        })
        btn:SetPoint("RIGHT", -4, 0)
        row.resetButton = btn
        function row:Refresh()
            if resetMode == "changed" and opts.get then
                local changed = opts.get() ~= opts.default
                btn:SetShown(changed)
                -- 标签是标题类之外的普通文本，不染色；仅用亮度区分
                row.label:SetTextColor(unpack(changed and AF.C.TEXT_MAIN or AF.C.TEXT_MUTED))
            else
                btn:Show()
            end
        end
        row:Refresh()
    end
    return row
end
