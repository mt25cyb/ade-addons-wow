-- 账号最近记录：始终监听成功施法，选项只控制显示；保留条数由 recentTeleportsCount 决定（1~20）。
local _, addon = ...

-- 显示条数：读设置项 recentTeleportsCount，钳制到 [1, 20]（AstralGate 上限 20）。
local function GetLimit()
    local v = tonumber(addon.db and addon.db.recentTeleportsCount)
    if not v then return 6 end
    v = math.floor(v)
    if v < 1 then return 1 end
    if v > 20 then return 20 end
    return v
end
function addon.Recent.GetDisplayLimit() return GetLimit() end
-- 条目键与收藏共用同一套规则，定义在 Services/Catalog.lua。
local HEARTHSTONE_KEY = addon.Catalog.HearthstoneKey
local function EntryKey(entry) return addon.Catalog.EntryKey(entry) end
-- 炉石键表懒构造，读取时再取，避免加载顺序影响。
local function HearthstoneKeys() return addon.Catalog.GetHearthstoneKeys() end

-- 首次读取时迁移旧角色记录。旧列表没有时间戳，因此优先合并当前角色。
local function History()
 if not addon.db then return end
 if type(addon.db.recentTeleports) ~= "table" then
  local history, seen = {}, {}
  -- Legacy lists have no timestamps. Prefer this character, then merge the
  -- other lists deterministically without pretending their dates are known.
  local characters = addon.db.recentTeleportsByCharacter
  local function merge(list)
   if type(list) ~= "table" then return end
   for _, key in ipairs(list) do
    if type(key) == "string" and not seen[key] and #history < GetLimit() then
     history[#history + 1] = key
     seen[key] = true
    end
   end
  end
  if type(characters) == "table" then
   local current = UnitGUID("player")
   if current then merge(characters[current]) end
   local guids = {}
   for guid in pairs(characters) do
    if type(guid) == "string" and guid ~= current then guids[#guids + 1] = guid end
   end
   table.sort(guids)
   for _, guid in ipairs(guids) do merge(characters[guid]) end
  end
  addon.db.recentTeleports = history
 end
 -- 将旧的各款炉石记录合并，保留最近一次的位置。
 local history, seen = addon.db.recentTeleports, {}
 local keys = HearthstoneKeys()
 local index = 1
 while index <= #history do
  local key = history[index]
  if keys[key] then key = HEARTHSTONE_KEY end
  if seen[key] then
   table.remove(history, index)
  else
   history[index] = key
   seen[key] = true
   index = index + 1
  end
 end
 return history
end

local function UsedSpellID(entry)
 local itemID = entry.isToy and entry.toyID or (entry.isItem and entry.itemID)
 if itemID then
  local _, spellID = C_Item.GetItemSpell(itemID)
  return spellID
 end
 return entry.spellID
end

local castLookup
-- 缓存“施放的法术 ID -> 传送条目键”，避免普通施法反复重建整个目录。
local function UpdateCastLookup(sections)
 castLookup = {}
 for _, section in ipairs(sections) do
  for _, entry in ipairs(section.items or {}) do
   local spellID = UsedSpellID(entry)
   if spellID then castLookup[spellID] = EntryKey(entry) end
  end
 end
 -- 独立识别整个炉石池，不依赖首页当前随机选中了哪一款。
 for _, stone in ipairs(addon.HearthstoneData) do
  if stone.spellID then castLookup[stone.spellID] = HEARTHSTONE_KEY end
  local _, spellID = C_Item.GetItemSpell(stone.id)
  if spellID then castLookup[spellID] = HEARTHSTONE_KEY end
 end
end

-- 历史顺序账号共享。使用完整目录，不受普通列表的隐藏选项影响；不可用项置灰。
function addon.Recent.BuildSection(sections)
 if not addon.db or not addon.db.showRecentTeleports then return end
 local history = History()
 if not history then return end
 UpdateCastLookup(sections)
 local available = {}
 for _, section in ipairs(addon.Catalog.BuildSections(true) or {}) do
  for _, entry in ipairs(section.items or {}) do
   available[EntryKey(entry)] = entry
  end
 end
 local items = {}
 local seen = {}
 for _, key in ipairs(history) do
  if available[key] and not seen[key] then
   items[#items + 1] = available[key]
   seen[key] = true
   if #items == GetLimit() then break end
  end
 end
 if #items > 0 then return { key = "recent", title = addon.L.recentTeleports, items = items } end
end


local frame = CreateFrame("Frame")
-- 12.x 强制：先挂载脚本再注册事件，避免插件安装的 handler 不生效。
frame:SetScript("OnEvent", function(_, event, unit, _, spellID)
 if event ~= "UNIT_SPELLCAST_SUCCEEDED" then
  castLookup = nil
  return
 end
 if unit ~= "player" or not addon.db then return end
 -- Restricted spell identifiers must never be inspected or persisted.
 if issecretvalue and issecretvalue(spellID) then return end
 if not spellID then return end
 local history = History()
 if not history then return end
 -- Match successful casts against the compendium, including item and toy spells.
 -- This also recognizes teleports cast from the spellbook or action bars.
 if not castLookup then UpdateCastLookup(addon.Catalog.BuildSections() or {}) end
 local key = castLookup[spellID]
 if not key then return end
 for index = #history, 1, -1 do
  if history[index] == key then table.remove(history, index) end
 end
 table.insert(history, 1, key)
 while #history > GetLimit() do table.remove(history) end
 -- Do not rebuild protected map buttons inside the spellcast event.
 if addon.db.showRecentTeleports then
  C_Timer.After(0, function()
   addon.MapPanel.Refresh()
  end)
 end
end)
frame:RegisterUnitEvent("UNIT_SPELLCAST_SUCCEEDED", "player")
frame:RegisterEvent("SPELLS_CHANGED")
frame:RegisterEvent("BAG_UPDATE_DELAYED")
frame:RegisterEvent("TOYS_UPDATED")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")
