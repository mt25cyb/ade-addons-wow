# -*- coding: utf-8 -*-
# BattlePetBreedID 改造产物校验
import io, re, sys
sys.stdout.reconfigure(encoding="utf-8")
D = r"d:/Dev-Workspace/ade-addons-wow/wow_Locales_zhCN/BattlePetBreedID/"

from luaparser import ast
for f in ("BPBIDLocale.lua", "BreedTooltips.lua", "OptionsPanel.lua", "BattlePetBreedID.lua", "BPBIDAccessOptions.lua"):
    ast.parse(io.open(D + f, encoding="utf-8").read())
    print(f, "Lua OK")

t = io.open(D + "BPBIDLocale.lua", encoding="utf-8").read()
ks = re.findall(r'\[\s*"((?:\\.|[^"\\])*)"\s*\]\s*=\s*"((?:\\.|[^"\\])*)"', t)
print("BPBIDLocale 词条:", len(ks))

# 残留检查：调用点内未包裹的英文首字母串（排除已包裹 L[".."]）
for f in ("BreedTooltips.lua", "OptionsPanel.lua"):
    src = io.open(D + f, encoding="utf-8").read()
    bad = [m.group(0) for m in re.finditer(r'(?:SetText|AddLine|CreateCheckbox|CreateButton)\("([A-Za-z][^"]*)"', src)]
    print(f, "残留调用点字面串:", len(bad), bad[:5])

# L 引用计数
for f in ("BreedTooltips.lua", "OptionsPanel.lua"):
    src = io.open(D + f, encoding="utf-8").read()
    print(f, "L[ 引用:", src.count('L["'))

# TOC
toc = io.open(D + "BattlePetBreedID.toc", encoding="utf-8").read()
print("TOC 顺序:", [l for l in toc.splitlines() if l.endswith(".lua")])
