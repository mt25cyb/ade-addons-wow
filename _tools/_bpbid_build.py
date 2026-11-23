# -*- coding: utf-8 -*-
# BattlePetBreedID E 类源码改造：包裹 L["英文原文"] + 生成 BPBIDLocale.lua + TOC 登记
# 注意：源码字面 \124c（'|' 的十进制转义）在本脚本中一律用 r"\124c" 原始字符串表达。
import io, re, sys
sys.stdout.reconfigure(encoding="utf-8")

D = r"d:/Dev-Workspace/ade-addons-wow/wow_Locales_zhCN/BattlePetBreedID/"

# ---- 从主档提取词条 ----
master = io.open(r"d:/Dev-Workspace/ade-addons-wow/wow_Locales_zhCN/_Locales_BattlePetBreedID_zhCN.lua", encoding="utf-8").read()
body = master[master.index("return {") + 8 : master.rindex("}")]
pairs = re.findall(r'\[\s*"((?:\\.|[^"\\])*)"\s*\]\s*=\s*"((?:\\.|[^"\\])*)"', body)
trans = dict(pairs)
print("主档词条:", len(pairs))

def patch(path, repls):
    t = io.open(D + path, encoding="utf-8").read()
    for old, new, cnt in repls:
        n = t.count(old)
        assert n == cnt, f"{path}: {old[:60]!r} 命中 {n} 次（期望 {cnt}）"
        t = t.replace(old, new)
    io.open(D + path, "w", encoding="utf-8", newline="\n").write(t)
    print(f"{path}: {len(repls)} 处替换完成")

# ---- BreedTooltips.lua ----
C = r"\124cFFD4A017"   # 颜色码源码字面
R = r"\124r"           # 结束色源码字面
bt = [
    # L 注入
    ('local ceil = math.ceil',
     'local ceil = math.ceil\n\n-- zhCN：全局语言表（key=英文原文，缺键回退），由 BPBIDLocale.lua 提供\nlocal L = internal.L', 1),
    # 当前品种行
    (f'local current = "{C}Current Breed:{R} "',
     f'local current = L["{C}Current Breed:{R} "]', 1),
    ('current = current .. " or " .. internal.RetrieveBreedName',
     'current = current .. L[" or "] .. internal.RetrieveBreedName', 1),
    ('table.concat(collectedPets, ", ")',
     'table.concat(collectedPets, L[", "])', 1),
    (f'breedtip:AddLine("{C}Collected:{R} " .. table.concat',
     f'breedtip:AddLine(L["{C}Collected:{R} "] .. table.concat', 1),
    # 可能品种行（先长串后短串，避免前缀误匹配）
    (f'local possible = "{C}Possible Breed"',
     f'local possible = L["{C}Possible Breed"]', 1),
    (f'possible = possible .. "s:{R} All"',
     f'possible = possible .. L["s:{R} All"]', 1),
    (f'possible = possible .. "s:{R} Unknown"',
     f'possible = possible .. L["s:{R} Unknown"]', 1),
    (f'possible = possible .. "s:{R} " .. internal',
     f'possible = possible .. L["s:{R} "] .. internal', 1),
    ('possible = possible .. " and " .. internal',
     'possible = possible .. L[" and "] .. internal', 1),
    ('possible = possible .. ", and " .. internal',
     'possible = possible .. L[", and "] .. internal', 1),
    ('possible = possible .. ", " .. internal',
     'possible = possible .. L[", "] .. internal', 1),
    (f'possible = possible .. ":{R} " .. internal',
     f'possible = possible .. L[":{R} "] .. internal', 1),
    # 基础属性行
    (f'local speciesbase = "{C}Base Stats:{R} " ..',
     f'local speciesbase = L["{C}Base Stats:{R} "] ..', 1),
    # 品种前缀（3 处）
    (f'"{C}Breed " .. internal.RetrieveBreedName(currentbreed)',
     f'L["{C}Breed "] .. internal.RetrieveBreedName(currentbreed)', 3),
    # 属性行后缀
    (f'.. "*:{R} " ..', f'.. L["*:{R} "] ..', 1),
    (f'.. "* at 25:{R} " ..', f'.. L["* at 25:{R} "] ..', 1),
    (f'local allstatsp2 = ":{R} " ..', f'local allstatsp2 = L[":{R} "] ..', 1),
    (f'.. " at 25:{R} " ..', f'.. L[" at 25:{R} "] ..', 1),
    (f'local allstats25p2 = " at 25:{R} " ..', f'local allstats25p2 = L[" at 25:{R} "] ..', 1),
    # 等级前缀
    ('.hex .. "L" .. level .. " (" .. breed .. ")"',
     '.hex .. L["L"] .. level .. " (" .. breed .. ")"', 1),
]
patch("BreedTooltips.lua", bt)

# ---- OptionsPanel.lua ----
op = [
    ('local addonname, internal = ...',
     'local addonname, internal = ...\n\n-- zhCN：全局语言表（key=英文原文，缺键回退），由 BPBIDLocale.lua 提供\nlocal L = internal.L', 1),
    ('"version "..C_AddOns.GetAddOnMetadata', 'L["version "]..C_AddOns.GetAddOnMetadata', 1),
    ('"created by "..C_AddOns.GetAddOnMetadata', 'L["created by "]..C_AddOns.GetAddOnMetadata', 1),
    ('"Battle Pet BreedID displays the BreedID of pets in your journal, in battle, in chat links, and in item tooltips.")',
     'L["Battle Pet BreedID displays the BreedID of pets in your journal, in battle, in chat links, and in item tooltips."])', 1),
    ('    "Number (3)",\n    "Dual numbers (3/13)",\n    "Letters (B/B)",',
     '    L["Number (3)"],\n    L["Dual numbers (3/13)"],\n    L["Letters (B/B)"],', 1),
    ('    "The number system was created by Blizzard developers', '    L["The number system was created by Blizzard developers', 1),
    ('use it.",\n    "Same as numbers', 'use it."],\n    L["Same as numbers', 1),
    ('exclusively male.",\n    "The letter system', 'exclusively male."],\n    L["The letter system', 1),
    ('is half Health and half Power.",\n}', 'is half Health and half Power."],\n}', 1),
    ('"Show BreedIDs in the Name line...")', 'L["Show BreedIDs in the Name line..."])', 1),
    ('CreateCheckbox("In Battle (on primary pets)"', 'CreateCheckbox(L["In Battle (on primary pets)"]', 1),
    ('CreateCheckbox("On in-battle tooltips"', 'CreateCheckbox(L["On in-battle tooltips"]', 1),
    ('CreateCheckbox("In Item tooltips"', 'CreateCheckbox(L["In Item tooltips"]', 1),
    ('CreateCheckbox("In Chat Link tooltips"', 'CreateCheckbox(L["In Chat Link tooltips"]', 1),
    ('CreateCheckbox("In the Pet Journal scrolling frame"', 'CreateCheckbox(L["In the Pet Journal scrolling frame"]', 1),
    ('CreateCheckbox("Color Pet Journal scrolling frame by rarity."', 'CreateCheckbox(L["Color Pet Journal scrolling frame by rarity."]', 1),
    ('CreateCheckbox("In the Pet Journal description tooltip"', 'CreateCheckbox(L["In the Pet Journal description tooltip"]', 1),
    ('CreateCheckbox("Color Pet Journal tooltip headers by rarity"', 'CreateCheckbox(L["Color Pet Journal tooltip headers by rarity"]', 1),
    ('CreateCheckbox("Enable Battle Pet BreedID Tooltips"', 'CreateCheckbox(L["Enable Battle Pet BreedID Tooltips"]', 1),
    ('"Show Battle Pet BreedID Tooltips...")', 'L["Show Battle Pet BreedID Tooltips..."])', 1),
    ('CreateCheckbox("In Battle", 32, 32', 'CreateCheckbox(L["In Battle"], 32, 32', 1),
    ('CreateCheckbox("On Items"', 'CreateCheckbox(L["On Items"]', 1),
    ('CreateCheckbox("On Chat Links"', 'CreateCheckbox(L["On Chat Links"]', 1),
    ('CreateCheckbox("In the Pet Journal", 32, 32', 'CreateCheckbox(L["In the Pet Journal"], 32, 32', 1),
    ('"In Tooltips, show...")', 'L["In Tooltips, show..."])', 1),
    ('CreateCheckbox("Current pet\'s breed"', 'CreateCheckbox(L["Current pet\'s breed"]', 1),
    ('CreateCheckbox("Current pet\'s possible breeds"', 'CreateCheckbox(L["Current pet\'s possible breeds"]', 1),
    ('CreateCheckbox("Current\'s pet collected breeds"', 'CreateCheckbox(L["Current\'s pet collected breeds"]', 1),
    ('CreateCheckbox("Pet species\' base stats"', 'CreateCheckbox(L["Pet species\' base stats"]', 1),
    ('CreateCheckbox("Current breed\'s base stats"', 'CreateCheckbox(L["Current breed\'s base stats"]', 1),
    ('CreateCheckbox("All breed\'s base stats"', 'CreateCheckbox(L["All breed\'s base stats"]', 1),
    ('CreateCheckbox("Current breed\'s stats at level 25"', 'CreateCheckbox(L["Current breed\'s stats at level 25"]', 1),
    ('CreateCheckbox("Always assume pet will be Rare at level 25"', 'CreateCheckbox(L["Always assume pet will be Rare at level 25"]', 2),
    ('CreateCheckbox("All breeds\' stats at level 25"', 'CreateCheckbox(L["All breeds\' stats at level 25"]', 1),
    ('"Fix Bugs:")', 'L["Fix Bugs:"])', 1),
    ('CreateButton("Defaults"', 'CreateButton(L["Defaults"]', 1),
]
patch("OptionsPanel.lua", op)

# ---- 生成 BPBIDLocale.lua ----
lines = []
for k, v in pairs:
    lines.append('\t["%s"] = "%s",' % (k, v))
locale = (
    "-- BPBIDLocale.lua · zhCN 语言表（E 类：源码级自建多语言改造）\n"
    "-- 由 _tools/_bpbid_build.py 从 _Locales_BattlePetBreedID_zhCN.lua（唯一权威）生成。\n"
    "-- key = 英文原文；缺键回退英文原文；非 zhCN 客户端全部回退（行为与原版一致）。\n"
    "-- TOC 中须位于 BattlePetBreedID.lua 之前（命名空间 internal 的首个使用者）。\n\n"
    "local addonname, internal = ...\n\n"
    "local zhCN = {\n" + "\n".join(lines) + "\n}\n\n"
    "if GetLocale() == \"zhCN\" then\n"
    "\tinternal.L = setmetatable(zhCN, { __index = function(_, k) return k end })\n"
    "else\n"
    "\tinternal.L = setmetatable({}, { __index = function(_, k) return k end })\n"
    "end\n"
)
io.open(D + "BPBIDLocale.lua", "w", encoding="utf-8", newline="\n").write(locale)
print("BPBIDLocale.lua 生成:", len(pairs), "条")

# ---- TOC 首位登记 ----
t = io.open(D + "BattlePetBreedID.toc", encoding="utf-8").read()
if "BPBIDLocale.lua" not in t:
    t = t.replace("BattlePetBreedID.lua\r\n", "BPBIDLocale.lua\r\nBattlePetBreedID.lua\r\n", 1) \
         .replace("BattlePetBreedID.lua\n", "BPBIDLocale.lua\nBattlePetBreedID.lua\n", 1)
    io.open(D + "BattlePetBreedID.toc", "w", encoding="utf-8", newline="\n").write(t)
print("TOC 登记 BPBIDLocale.lua")
