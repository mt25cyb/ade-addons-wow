------------------------------------------------------------
-- 快速创建门面：对外 API v6 → v6.5 不变（RegisterTab / CreateWindow 别名）。
-- v6.5 从 KAF 复刻后，行/网格均由 RegisterTab 的 elements 契约驱动，
-- 旧的 StandaloneRow/Grid/List、MarkChanged、RichDescription 门面已随自造模块删除。
------------------------------------------------------------
local lib = ResolveBOFNamespace("ade_UIKit")
if not lib then return end

lib.CreateWindow = lib.RegisterTab

-- 两种颜色选项 spec 创建函数（b051）：宿主不需要了解 MakeOption/With 适配细节。
-- ① ColorOption：单纯颜色行（kind="color"），给 label/get/set/default 即可。
-- ② ToggleColorOption：开关 + 同行色块（截图的「显示职业颜色」结构），
--    主行 toggle 带 with=color；勾选时色块自动禁用（颜色由功能决定），
--    取消勾选后色块可用（走自定义色）；宿主 color spec 自带的 disabled（如 24h 禁用）
--    与勾选禁用取「或」，两者任一成立即禁用。
local function CallDisabled(spec)
    if type(spec) ~= "function" then return spec == true end
    return spec() == true
end

function lib.ColorOption(spec)
    spec = spec or {}
    spec.kind = "color"
    return spec
end

function lib.ToggleColorOption(toggleSpec, colorSpec)
    toggleSpec, colorSpec = toggleSpec or {}, colorSpec or {}
    toggleSpec.kind, colorSpec.kind = "toggle", "color"
    local ownDisabled = colorSpec.disabled
    colorSpec.disabled = function()
        if toggleSpec.get and toggleSpec.get() == true then return true end
        return CallDisabled(ownDisabled)
    end
    toggleSpec.with = colorSpec
    return toggleSpec
end
