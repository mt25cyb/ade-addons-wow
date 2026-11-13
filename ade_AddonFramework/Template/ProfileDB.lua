-- 配置档适配器：库不绑死宿主存档结构。
-- MiliUI_Tooltip/Core/DB.lua 有 List/Create/Delete/Switch/ResetAll；RenameProfile 全库 0 命中，属本库新增接口。
local AF = ResolveNamespace("ade_AddonFramework")
if not AF then return end
AF.Template = AF.Template or {}
AF.Options = AF.Options or {}
local W = {}
AF.Template.ProfileDB = W    -- 组合模板：配置档适配器
AF.Options.ProfileDB = W    -- 别名兼容

local DEFAULT_PROFILE = "Shared"

local function Trim(s) return (tostring(s or ""):gsub("^%s+", ""):gsub("%s+$", "")) end

function W.New(store, opts)
    opts = opts or {}
    store.list = store.list or {}
    store.current = store.current or DEFAULT_PROFILE
    if not store.list[DEFAULT_PROFILE] then store.list[DEFAULT_PROFILE] = {} end

    local db = {}
    function db.Default() return DEFAULT_PROFILE end
    function db.Current() return store.current end
    function db.List()
        local names = {}
        for name in pairs(store.list) do names[#names + 1] = name end
        table.sort(names, function(a, b)
            if a == DEFAULT_PROFILE then return true end
            if b == DEFAULT_PROFILE then return false end
            return a < b
        end)
        return names
    end
    function db.Get(name) return store.list[name or store.current] end
    function db.Exists(name) return store.list[name] ~= nil end

    function db.Create(name, copyFrom)
        name = Trim(name)
        if name == "" then return false, "empty" end
        if store.list[name] then return false, "exists" end
        local src = copyFrom and store.list[copyFrom]
        store.list[name] = src and AF.DB.DeepCopy(src) or {}
        return true, name
    end
    function db.Copy(name) return db.Create(name, store.current) end

    --- 新增：重命名当前配置；共用档不可动、同名拒绝、空名拒绝。
    function db.Rename(old, newName)
        newName = Trim(newName)
        if old == DEFAULT_PROFILE then return false, "shared" end
        if newName == "" then return false, "empty" end
        if not store.list[old] then return false, "missing" end
        if store.list[newName] then return false, "exists" end
        store.list[newName] = store.list[old]
        store.list[old] = nil
        if store.current == old then store.current = newName end
        return true, newName
    end

    function db.Delete(name)
        if name == DEFAULT_PROFILE then return false, "shared" end
        if not store.list[name] then return false, "missing" end
        store.list[name] = nil
        if store.current == name then store.current = DEFAULT_PROFILE end
        return true
    end
    function db.Switch(name)
        if not store.list[name] then return false end
        store.current = name
        if opts.onSwitch then opts.onSwitch(name) end
        return true
    end
    function db.Reset()
        local name = store.current
        store.list[name] = {}
        if opts.onReset then opts.onReset(name) end
        return true
    end
    function db.Export()
        local data = AF.DB.DeepCopy(store.list[store.current] or {})
        return opts.serialize and opts.serialize(data) or data
    end
    --- 新增：仅校验（不落库），供配置页导入框实时反馈；成功返回 true,data；失败返回 false,错误
    function db.Validate(raw)
        if type(raw) ~= "string" or raw:gsub("%s+", "") == "" then return false, "empty" end
        local data, err = raw, nil
        if opts.deserialize then data, err = opts.deserialize(raw) end
        if type(data) ~= "table" then return false, err or "invalid" end
        return true, data
    end
    function db.Import(raw)
        local data = opts.deserialize and opts.deserialize(raw) or raw
        if type(data) ~= "table" then return false end
        return db.ImportData(data)
    end
    --- 新增：直接落库已解码的 data（MiliUI Tab_Share.lua:331,358 的 pendingData 判断逻辑——
    --  导入框实时校验时存下 data，按钮点击用存下的那份，不再二次解码）
    function db.ImportData(data)
        if type(data) ~= "table" then return false end
        store.list[store.current] = data
        if opts.onImport then opts.onImport(data) end
        return true
    end
    return db
end
