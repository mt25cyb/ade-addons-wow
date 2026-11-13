-- 音效选择：试听/停止用用户已验证的原生 Atlas common-dropdown-icon-play / -stop。
local AF = ResolveNamespace("ade_AddonFramework")
if not AF then return end
AF.Widget = AF.Widget or {}
local W = {}
AF.Widget.SoundPicker = W

function W.Create(parent, opts)
    opts = opts or {}
    local row = CreateFrame("Frame", nil, parent)
    row:SetSize(opts.width or 260, 24)

    local dd = AF.Widget.Dropdown.Create(row, {
        width = (opts.width or 260) - 30,
        items = opts.items or { { text = AF.L["AF_NONE"], value = "" } },
        value = opts.value,
        onSelect = function(v) if opts.onChange then opts.onChange(v) end end,
    })
    dd:SetPoint("LEFT", 0, 0)

    local playing = false
    local btn -- 前置声明：onClick 闭包在创建参数表内就要引用 btn
    btn = AF.Widget.Icon.CreateButton(row, {
        size = 18, atlas = "common-dropdown-icon-play", tooltip = opts.playTooltip,
        onClick = function()
            playing = not playing
            AF.ResolveIcon(btn.texture, { atlas = playing and "common-dropdown-icon-stop" or "common-dropdown-icon-play" }, { atlas = true })
            if opts.onPlay then opts.onPlay(playing, dd:GetValue()) end
        end,
    })
    btn:SetPoint("LEFT", dd, "RIGHT", 6, 0)
    row.dropdown, row.playButton = dd, btn

    function row:SetPlaying(on)
        playing = on and true or false
        AF.ResolveIcon(btn.texture, { atlas = playing and "common-dropdown-icon-stop" or "common-dropdown-icon-play" }, { atlas = true })
    end
    return row
end
