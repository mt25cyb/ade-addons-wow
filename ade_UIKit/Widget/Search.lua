------------------------------------------------------------
-- 搜索算法。复刻 KAF Libs/Krowi_Options/Search.lua 与 lib.Internal.Search（Search.lua:227-251）：
-- 当前 Tab 或每个 Tab（all）的搜索，broad 勾选时描述也参与；返回 { { Tab, Sections } } 组。
------------------------------------------------------------
local lib = ResolveBOFNamespace("ade_UIKit")
if not lib then return end

local Internal = lib.Internal

local function Plain(text)
    return (tostring(text or ""):gsub("|A.-|a", ""):gsub("|T.-|t", ""):gsub("|K.-|k", "")
        :gsub("|H.-|h(.-)|h", "%1"):gsub("|cn[%w_]*:", "")
        :gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", ""):upper())
end
Internal.Plain = Plain

-- KAF Search.lua:69-84：words[1] 为整文本，命中即最高优先；其余逐词累计。
local function Match(texts, words)
    local count, longest = 0, 0
    for i, word in ipairs(words) do
        for _, text in ipairs(texts) do
            if type(text) == "string" and Plain(text):find(word, 1, true) then
                if i == 1 then return math.max(#words - 1, 1), #word end
                count, longest = count + 1, math.max(longest, #word)
                break
            end
        end
    end
    if count > 0 then return count, longest end
end

-- KAF Search.lua:86-90：描述是散文，只有含全部输入词才命中。
local function MatchAll(texts, words)
    local count, longest = Match(texts, words)
    if count and count >= math.max(#words - 1, 1) then return count, longest end
end

-- KAF Search.lua:93-95：一个数字一个命中——名字先于描述，词多者先，最长者先。
local function Score(inName, count, longest)
    return (inName and 1000000 or 0) + count * 1000 + longest
end

-- KAF Search.lua:39-46：把各 Kind 的多返回值收成字符串表，跳过 nil / 空串。
local function Texts(...)
    local texts = {}
    for i = 1, select("#", ...) do
        local text = select(i, ...)
        if type(text) == "string" and text ~= "" then texts[#texts + 1] = text end
    end
    return texts
end

-- KAF Search.lua:51-60：名字与描述都来自各 Kind 的可选字段。
local function Names(element)
    local kind = Internal.Kinds[element.Kind]
    if kind and kind.Names then return Texts(kind.Names(element)) end
end
local function Descriptions(element)
    local kind = Internal.Kinds[element.Kind]
    if kind and kind.Descriptions then return Texts(kind.Descriptions(element)) end
    return {}
end

-- KAF Search.lua:114-219 的分区遍历（本库简化版）：命中行按 Kind / 名字 / 描述进入结果。
local function SearchRows(elements, words, broad)
    local rows = {}
    for _, raw in ipairs(elements) do
        local element = Internal.NormalizeElement(raw)
        local kind = Internal.Kinds[element.Kind]
        if kind and not kind.Expand then
            -- 不能写 `names and Match(...) or nil`：and/or 会把 Match 的两个返回值截成一个，longest 变 nil，
            -- Score 在描述分支崩 "arithmetic on nil"，整个搜索空手而归（debug log 实证）。
            local names = Names(element)
            local count, longest
            if names then count, longest = Match(names, words) end
            local inName = count ~= nil
            if not count and broad then count, longest = MatchAll(Descriptions(element), words) end
            if count then
                rows[#rows + 1] = { element = element, score = Score(inName, count, longest), length = longest }
            end
        end
    end
    return rows
end

-- KAF Search.lua:227-251：当前 Tab 或每个 Tab：{ { Tab, Sections = { { Id, Name, Rows } } } }，
-- 按 Tab 注册序，只含有命中的 Tab。broad：描述也搜。
function Internal.Search(text, all, current, broad)
    local words = {}
    local whole = Plain(text):gsub("^%s+", ""):gsub("%s+$", "")
    if whole == "" then return {} end
    words[1] = whole
    for word in whole:gmatch("[^, ]+") do words[#words + 1] = word end

    local groups = {}
    for _, registered in ipairs(Internal.Tabs or {}) do
        if all or registered == current then
            local sections = {}
            for _, group in ipairs(registered.Config.groups or {}) do
                for _, id in ipairs(group.sections) do
                    local ok, elements = pcall(registered.Config.elements, id)
                    if ok and elements then
                        local rows = SearchRows(elements, words, broad)
                        if #rows > 0 then
                            table.sort(rows, function(a, b)
                                if a.score ~= b.score then return a.score > b.score end
                                return a.length > b.length
                            end)
                            local found = {}
                            for i, row in ipairs(rows) do found[i] = row.element end
                            sections[#sections + 1] = {
                                Id = id,
                                Name = Internal.Ask(id, registered.Config.sectionName, id),
                                Rows = found,
                            }
                        end
                    end
                end
            end
            if #sections > 0 then groups[#groups + 1] = { Tab = registered, Sections = sections } end
        end
    end
    return groups
end
