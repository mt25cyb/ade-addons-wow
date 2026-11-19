------------------------------------------------------------
-- 图标三态（FilePath / FileID / Atlas）公共 API。
-- 底本：ade_apis/Core/Util.lua:48-100（ResolveIcon / ApplyIcon / IconEscape）；
--       ade_AddonFramework/Widget/Icon.lua:13-34（SetAtlas 分支与 useAtlasSize）。
-- 只操作传入的 Texture/Button，不创建框架、不持有状态。
------------------------------------------------------------
local lib = ResolveBOFNamespace("ade_UIKit")
if not lib then return end

--- 解析图标描述。
-- @return "file" | "atlas" | nil, value
function lib.ResolveIcon(icon)
    local kind = type(icon)
    if kind == "number" then return "file", icon end
    if kind == "string" then
        if icon == "" then return nil end
        return "file", icon
    end
    if kind == "table" then
        if type(icon.atlas) == "string" and icon.atlas ~= "" then return "atlas", icon.atlas end
        if icon.fileID ~= nil then return lib.ResolveIcon(icon.fileID) end
        if icon.texture ~= nil then return lib.ResolveIcon(icon.texture) end
    end
    return nil
end

--- 把图标应用到纹理。
-- opts: { trim=true, texcoord={l,r,t,b}, size=n }
function lib.ApplyIcon(texture, icon, opts)
    if not texture then return false end
    local kind, value = lib.ResolveIcon(icon)
    if not kind then
        texture:SetTexture(nil)
        return false
    end
    if kind == "atlas" then
        texture:SetAtlas(value, opts and opts.useAtlasSize or false)
    else
        texture:SetTexture(value)
    end
    if opts and opts.texcoord then
        local c = opts.texcoord
        texture:SetTexCoord(c[1], c[2], c[3], c[4])
    elseif opts and opts.trim then
        texture:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    end
    if opts and opts.size then texture:SetSize(opts.size, opts.size) end
    return true
end

--- 文本内图标转义（|T 或 |A）。
function lib.IconEscape(icon, size)
    local kind, value = lib.ResolveIcon(icon)
    if not kind then return "" end
    size = size or 16
    if kind == "atlas" then
        return ("|A:%s:%d:%d|a"):format(value, size, size)
    end
    if type(value) == "number" then
        return ("|T%d:%d:%d|t"):format(value, size, size)
    end
    return ("|T%s:%d:%d|t"):format(value, size, size)
end

--- 把图标应用到按钮的 Icon 纹理（缺省创建 20×20 CENTER ARTWORK）。
function lib.SetButtonIcon(button, icon, opts)
    if not button then return false end
    if not button.Icon then
        button.Icon = button:CreateTexture(nil, "ARTWORK")
        button.Icon:SetSize(20, 20)
        button.Icon:SetPoint("CENTER")
        button.Icon:SetTexCoord(0, 1, 0, 1)
    end
    local applied = lib.ApplyIcon(button.Icon, icon, opts)
    if applied and opts and opts.size then button.Icon:SetSize(opts.size, opts.size) end
    return applied
end
