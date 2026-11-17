#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""wow_Locales_zhCN key 齐平比对：镜像 enUS 源 vs 子项目 zhCN 主文件。

支持四类取词写法：
  1. 方括号型：L["KEY"] = "value" / ["KEY"] = true（AceLocale、Phanx 式等）
  2. 点号型  ：REP_TXT.Mob.X = "value" / BINDING_NAME_X = "value"（全局变量赋值型，
     需在 ADDONS 中登记 dotted 前缀）
  3. 多行长括号：L["KEY"] = [[跨行值]]（提取前折叠为单行）
  4. 调用点型：源码里只用 `L["KEY"]`、无集中 key 表 → enus_mode="scan"
套装内多语种分段文件（如 VanasKoS 的 AceLocale 同文件多段）用 SEGMENT 模式：
在同一文件内切出 enUS / zhCN 段各自比对。

enUS 基准的三种来源（ADDONS 登记的 enus_mode）：
  * 默认（无 enus_mode）：enUS 文件本身由 L["k"]=v 赋值构成
  * "list"：enUS 文件是字符串清单表（Fitter 的 local strings = { ... }）
  * "scan"：enUS 无 key 表，基准取镜像插件的源码调用点（src_root 下递归 L[...] ，跳过 Libs）

用法:
  python _tools/zhcn_diff_keys.py
  python _tools/zhcn_diff_keys.py --addon VanasKoS
"""
import argparse
import re
import sys
from pathlib import Path

TOOLS_DIR = Path(__file__).resolve().parent          # 仓库根 /_tools/
PROJECT_DIR = TOOLS_DIR.parent / "wow_Locales_zhCN"   # 子项目主目录
MIRROR_DIR = TOOLS_DIR.parent / "z-ref_retail_Interface_AddOns"

# 登记：插件名 -> dict(enus=镜像侧 enUS 路径, zhcn=项目侧文件, dotted=点号前缀正则)
# enus=None 表示 SEGMENT 模式（enUS 与 zhCN 同文件，见 SEGMENT_FILES）
ADDONS = {
    "ReputationGuide": {
        "enus": "ReputationGuide/locales/enUS.lua",
        "zhcn": "ReputationGuide_zhCN.lua",
        "dotted": r"REP_TXT(?:\.\w+)*|BINDING_\w+",
    },
    "Krowi_AchievementFilter_Khamuls_ExpMetaAchievementFilter": {
        "enus": "Krowi_AchievementFilter_Khamuls_ExpMetaAchievementFilter/Localization/enUS.lua",
        "zhcn": "Krowi_AchievementFilter_Khamuls_ExpMetaAchievementFilter_zhCN.lua",
    },
    "MinimalArchaeology": {
        "enus": "MinimalArchaeology/addon/locales/EnUS.lua",
        "zhcn": "MinimalArchaeology_zhCN.lua",
    },
    "MouseoverActionSettings": {
        "enus": "MouseoverActionSettings/Locales/enUS.lua",
        "zhcn": "MouseoverActionSettings_zhCN.lua",
    },
    # AceLocale：enUS isDefault=true，zhCN 覆盖层；译文底子来自社区汉化（5.12.1）
    "CooldownManagerCentered": {
        "enus": "CooldownManagerCentered/locales/enUS.lua",
        "zhcn": "CooldownManagerCentered_zhCN.lua",
    },
    "TLDRMissions": {
        "enus": "TLDRMissions/Locales/enus.lua",
        "zhcn": "TLDRMissions_zhCN.lua",
    },
    # enUS 是「字符串清单表」（local strings = {...}），覆盖层按 key 覆盖
    # （2.12.2 起 Localization/ 目录改名 Locales/）
    "Fitter": {
        "enus": "Fitter/Locales/enUS.lua",
        "zhcn": "Fitter_zhCN.lua",
        "enus_mode": "list",
    },
    # PRAT_L 全局共享表（enUS 建 local L={}; PRAT_L=L，各语言 GetLocale 守卫 + 同表覆盖）。
    "Prat-3.0": {
        "enus": "Prat-3.0/locales/enUS.lua",
        "zhcn": "Prat-3.0_zhCN.lua",
    },
    # QuestPrism_L 全局共享表 + 点号赋值（L.KEY = "value"）；BINDING_* 为 _G 全局。
    # L.HELP_LINES 表值非字符串，extract 的值过滤会跳过，两侧一致不影响齐平。
    "QuestPrism": {
        "enus": "QuestPrism/Locales/enUS.lua",
        "zhcn": "QuestPrism_zhCN.lua",
        "dotted": r"L\.\w+|BINDING_\w+",
    },
    # Phanx 方法：enUS 全量默认 + [TextLocale] 覆盖层（zhCN.lua 有 GetLocale 守卫），
    # enUS 有跨行赋值（extract 预处理已支持）。
    "MapPinEnhanced": {
        "enus": "MapPinEnhanced/locales/enUS.lua",
        "zhcn": "MapPinEnhanced_zhCN.lua",
    },
}

# Altoholic / DataStore 套件（AddonFactory:SetLocale 注册表型，L["KEY"] 方括号写法）。
# 仅登记镜像中带 Locale.xml 的 18 个模块；DataStore_Talents 新版已无本地化机制，不登记。
_SUITE_MODULES = [
    "Altoholic", "Altoholic_Achievements", "Altoholic_Agenda", "Altoholic_Characters",
    "Altoholic_Grids", "Altoholic_Guild", "Altoholic_Options", "Altoholic_Search",
    "Altoholic_Summary", "DataStore", "DataStore_Auctions", "DataStore_Characters",
    "DataStore_Crafts", "DataStore_Garrisons", "DataStore_Inventory", "DataStore_Mails",
    "DataStore_Quests",
]
for _m in _SUITE_MODULES:
    ADDONS[_m] = {
        "enus": f"{_m}/Locales/enUS.lua",
        "zhcn": f"Altoholic/{_m}_zhCN.lua",
    }

# SEGMENT 模式：项目侧文件 = 镜像侧文件（整文件覆盖，段在文件内部）
SEGMENT_FILES = [
    f"VanasKoS/{rel}" for rel in
    ["VanasKoS_Locale.lua"] + [f"modules/{m}_Locale.lua" for m in
        ["ChatNotifier", "CommandLineHandler", "DataGatherer", "DefaultLists", "EventMap",
         "Importer", "LastSeenList", "MinimapButton", "Notifier", "PortraitContextMenu",
         "PvPDataGatherer", "PvPStats", "Synchronizer", "WarnFrame"]]
]

BRACKET_RE = re.compile(
    r'(?:\bL)?\[\s*("(?:\\.|[^"\\])*"|\'(?:\\.|[^\'\\])*\')\s*\]\s*=\s*'
    r'("(?:\\.|[^"\\])*"|\'(?:\\.|[^\'\\])*\'|\[\[.*?\]\]|true|false|-?\d+(?:\.\d+)?)'
)
NEWLOCALE_RE = re.compile(r'NewLocale\(\s*"(?:[^"]+)"\s*,\s*"(?P<locale>\w+)"')


def unescape(s: str) -> str:
    """按 Lua 字符串转义规则还原，用于「未译」比对（\124 与 | 等价）。"""
    def repl(m):
        c = m.group(1)
        if c.isdigit():
            return chr(int(c))
        return {"n": "\n", "t": "\t", "r": "\r", '"': '"', "'": "'", "\\": "\\", "a": "\a",
                "b": "\b", "f": "\f", "v": "\v"}.get(c, c)
    return re.sub(r"\\(\d{1,3}|.)", repl, s)


def parse_value(raw: str):
    """返回还原后的字符串；true -> None（AceLocale：值即 key 本身）。"""
    if raw == "true":
        return None
    if raw.startswith("[["):
        return raw[2:-2]
    body = raw[1:-1]
    if raw.startswith("'"):
        body = body.replace('\\"', '"')  # 单引号串里双引号可能未转义，交给 unescape 处理
    return unescape(body)


def extract(text: str, dotted: str | None) -> dict:
    """按行提取赋值 -> {key: value_or_None}。"""
    # 预处理：把多行长括号字符串 [[...]] 折叠为单行（换行转成 \n 字面量），
    # 否则跨行的 `L["KEY"] = [[多行值]]` 会被逐行扫描漏掉。
    text = re.sub(r"\[\[(.*?)\]\]", lambda m: "[[" + m.group(1).replace("\n", "\\n") + "]]",
                  text, flags=re.S)
    # 再把「key 与值分两行」的赋值并回一行（`["KEY"] =\n    "值"`），否则逐行扫描会漏掉。
    text = re.sub(r"\]\s*=\s*\n\s*(?=[\"'\[])", "] = ", text)
    result = {}
    dot_re = re.compile(r"\b(%s)\s*=\s*(\S.*)$" % dotted) if dotted else None
    for line in text.splitlines():
        line = line.strip()
        if line.startswith("--"):
            continue
        for m in BRACKET_RE.finditer(line):
            key = parse_value(m.group(1))
            if key:
                result[key] = parse_value(m.group(2))
        if dot_re:
            m = dot_re.search(line)
            if m:
                val = m.group(2).strip()
                if re.fullmatch(r'"(?:\\.|[^"\\])*"|\'(?:\\.|[^\'\\])*\'', val):
                    result[m.group(1)] = parse_value(val)
    return result


def extract_segment(text: str, locale: str, dotted: str | None) -> dict:
    """SEGMENT 模式：截取 NewLocale(..., locale) 到下一个 NewLocale 之间的文本再提取。"""
    marks = [(m.start(), m.group("locale")) for m in NEWLOCALE_RE.finditer(text)]
    spans = {loc: (pos, marks[i + 1][0] if i + 1 < len(marks) else len(text))
             for i, (pos, loc) in enumerate(marks)}
    if locale not in spans:
        return {}
    a, b = spans[locale]
    return extract(text[a:b], dotted)


def extract_string_list(text: str) -> dict:
    """list 模式：清单表内的全部字符串字面量作为 key（值记 None）。

    不截取表体——直接全文抓取引号字面量（去掉注释行后）。早期版本用
    `local strings = {...}(.*?)^}` 非贪婪截断到第一个行首 `}`，表内有
    嵌套表/续行时提前结束，导致整段 key 漏提（Fitter 2.12.1 实测漏 ~90 条）。
    行内多串不受影响（findall 不依赖行结构）。"""
    body = re.sub(r"^\s*--.*$", "", text, flags=re.M)
    return {unescape(v): None for v in re.findall(r'"((?:[^"\\]|\\.)*)"', body)}


SCAN_RE = re.compile(r'\bL\s*\[\s*("(?:\\.|[^"\\])*"|\'(?:\\.|[^\'\\])*\')\s*\]')


def extract_scan(root: Path) -> dict:
    """scan 模式：递归扫插件源码的 L[...] 调用点（跳过 Libs/）。"""
    result = {}
    for f in sorted(root.rglob("*.lua")):
        if "Libs" in f.parts:
            continue
        text = f.read_text(encoding="utf-8", errors="replace")
        text = re.sub(r"^\s*--.*$", "", text, flags=re.M)
        for raw in SCAN_RE.findall(text):
            result[unescape(raw[1:-1])] = None
    return result


def compare_dicts(label: str, en: dict, zh: dict) -> bool:
    en_keys, zh_keys = set(en), set(zh)
    missing = sorted(en_keys - zh_keys)
    extra = sorted(zh_keys - en_keys)
    # 刻意保留（不计为未译）：空串（作者留空的描述键）、[X] 单字母 UI 标签、纯格式/符号串
    def kept(k):
        v = en[k]
        return v == "" or re.fullmatch(r"\[[A-Z]\]", v or "") or not re.search(r"[A-Za-z]", v or "")
    untranslated = sorted(
        k for k in en_keys & zh_keys
        if en[k] is not None and zh[k] is not None and en[k] == zh[k] and not kept(k)
    )
    print(f"  [{label}] enUS {len(en_keys)} / zhCN {len(zh_keys)}"
          f" | 缺失 {len(missing)} | 多余 {len(extra)} | 值相同 {len(untranslated)}")
    for k in missing[:20]:
        print(f"    - missing: {k!r}")
    for k in extra[:20]:
        print(f"    - extra: {k!r}")
    for k in untranslated[:20]:
        print(f"    - untranslated: {k!r}")
    return not missing and not untranslated


def main() -> int:
    parser = argparse.ArgumentParser(description="enUS vs zhCN key 齐平比对")
    parser.add_argument("--addon", action="append", help="只比对指定插件（可多次）")
    args = parser.parse_args()

    ok = True
    names = args.addon or (list(ADDONS) + ["VanasKoS"])
    for name in names:
        print(f"== {name} ==")
        cfg = ADDONS.get(name)
        if cfg:
            zh_p = PROJECT_DIR / cfg["zhcn"]
            mode = cfg.get("enus_mode")
            if mode == "scan":
                src_root = MIRROR_DIR / cfg["src_root"]
                if not src_root.is_dir():
                    print(f"  [SKIP] 镜像无插件目录 {cfg['src_root']}（未安装）")
                    continue
                en = extract_scan(src_root)
            else:
                en_p = MIRROR_DIR / cfg["enus"]
                if not en_p.is_file():
                    print(f"  [SKIP] 镜像无 {cfg['enus']}（未安装）")
                    continue
                en_text = en_p.read_text(encoding="utf-8", errors="replace")
                en = (extract_string_list(en_text) if mode == "list"
                      else extract(en_text, cfg.get("dotted")))
            zh = extract(zh_p.read_text(encoding="utf-8", errors="replace"), cfg.get("dotted"))
            ok &= compare_dicts(cfg["zhcn"], en, zh)
        elif name == "VanasKoS":
            for rel in SEGMENT_FILES:
                text = (PROJECT_DIR / rel).read_text(encoding="utf-8", errors="replace")
                en = extract_segment(text, "enUS", None)
                zh = extract_segment(text, "zhCN", None)
                ok &= compare_dicts(rel, en, zh)
        else:
            print(f"  [ERROR] 未登记的插件: {name}")
            ok = False
    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(main())
