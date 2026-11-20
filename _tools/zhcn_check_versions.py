#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""wow_Locales_zhCN 版本基线核对：语言文件首行版本头 vs 镜像插件 TOC 的 ## Version:。

语言文件首行版本头规范（见 _Locales_zhCN_README.md）：
    -- <插件名> <版本号> · zhCN 本地化（基准 enUS <版本号>）
特殊写法（插件 TOC 无版本号，如 MouseoverActionSettings）：
    -- <插件名> · zhCN 本地化（基准 enUS；该插件 TOC 无版本号）

用法:
  python _tools/zhcn_check_versions.py
  python _tools/zhcn_check_versions.py --plugin VanasKoS
"""
import argparse
import re
import sys
from pathlib import Path

TOOLS_DIR = Path(__file__).resolve().parent          # 仓库根 /_tools/
PROJECT_DIR = TOOLS_DIR.parent / "wow_Locales_zhCN"   # 子项目主目录
MIRROR_DIR = TOOLS_DIR.parent / "z-ref_retail_Interface_AddOns"

# 无首行版本头的套件（如 VanasKoS 的 AceLocale 分段文件）在此手工登记基线版本。
BASELINE_OVERRIDE = {
    "VanasKoS": "12.1.5.1",
}

# 插件名 -> 项目侧代表文件（用于读首行版本头）
HEADER_FILES = {
    "EmberLedger": "EmberLedger/Localization.lua",
    "Prat-3.0": "Prat-3.0_zhCN.lua",
    "MapPinEnhanced": "MapPinEnhanced_zhCN.lua",
    "QuestPrism": "QuestPrism_zhCN.lua",
    "ReputationGuide": "ReputationGuide_zhCN.lua",
    "Krowi_AchievementFilter_Khamuls_ExpMetaAchievementFilter":
        "Krowi_AchievementFilter_Khamuls_ExpMetaAchievementFilter_zhCN.lua",
    "MinimalArchaeology": "MinimalArchaeology_zhCN.lua",
    "MouseoverActionSettings": "MouseoverActionSettings_zhCN.lua",
    "CooldownManagerCentered": "CooldownManagerCentered_zhCN.lua",
    "TLDRMissions": "TLDRMissions_zhCN.lua",
    "VanasKoS": "VanasKoS/VanasKoS_Locale.lua",
    "Fitter": "Fitter_zhCN.lua",
}

# 套件逐模块登记（与 zhcn_sync.py / zhcn_diff_keys.py 的口径一致）
for _m in ["Altoholic", "Altoholic_Achievements", "Altoholic_Agenda", "Altoholic_Characters",
           "Altoholic_Grids", "Altoholic_Guild", "Altoholic_Options", "Altoholic_Search",
           "Altoholic_Summary", "DataStore", "DataStore_Auctions", "DataStore_Characters",
           "DataStore_Crafts", "DataStore_Garrisons", "DataStore_Inventory", "DataStore_Mails",
           "DataStore_Quests"]:
    HEADER_FILES[_m] = f"Altoholic/{_m}_zhCN.lua"

HEADER_RE = re.compile(
    r"^--\s*(?P<name>.+?)\s+(?P<ver>[\w.\-+]+)\s*·\s*zhCN\s*本地化（基准\s*enUS\s*(?P<base>[\w.\-+]+)）",
)
# 套件（Altoholic/DataStore）的旧式版本头：-- <插件名> <版本号> (zhCN 汉化 / Ade)
ALT_HEADER_RE = re.compile(
    r"^--\s*(?P<name>.+?)\s+(?P<base>[\w.\-+]+)\s*\(zhCN\s*汉化\s*/\s*Ade\)",
)
HEADER_NOVER_RE = re.compile(r"^--\s*(?P<name>.+?)\s*·\s*zhCN\s*本地化（基准\s*enUS；.*TOC 无版本号）")
TOC_VERSION_RE = re.compile(r"^##\s*Version:\s*(.+?)\s*$", re.IGNORECASE | re.MULTILINE)


def read_baseline(name: str) -> str:
    """返回项目侧基线版本号；无版本头/未登记返回空串。"""
    if name in BASELINE_OVERRIDE:
        return BASELINE_OVERRIDE[name]
    rel = HEADER_FILES.get(name)
    if not rel:
        return ""
    first = (PROJECT_DIR / rel).read_text(encoding="utf-8", errors="replace").splitlines()[0].strip()
    m = HEADER_RE.match(first)
    if m:
        return m.group("base")
    m = ALT_HEADER_RE.match(first)
    if m:
        return m.group("base")
    if HEADER_NOVER_RE.match(first):
        return "NO_VERSION"
    return ""


def mirror_versions(name: str):
    """读取镜像中该插件全部顶层 TOC 的 ## Version:，返回 (状态, [版本...])。"""
    addon_dir = MIRROR_DIR / name
    if not addon_dir.is_dir():
        return "UNINSTALLED", []
    vers = []
    for toc in sorted(addon_dir.glob("*.toc")):
        text = toc.read_text(encoding="utf-8", errors="replace")
        m = TOC_VERSION_RE.search(text)
        vers.append(f"{toc.name}: {m.group(1)}" if m else f"{toc.name}: (无版本号)")
    if not vers:
        return "NO_TOC", []
    return "OK", vers


def main() -> int:
    parser = argparse.ArgumentParser(description="版本头 vs 镜像 TOC 核对")
    parser.add_argument("--plugin", action="append", help="只核对指定插件（可多次）")
    args = parser.parse_args()

    names = args.plugin or list(HEADER_FILES)
    warn = False
    for name in names:
        baseline = read_baseline(name)
        status, vers = mirror_versions(name)
        print(f"== {name} ==")
        if status == "UNINSTALLED":
            print(f"  基线: {baseline or '(无)'}   镜像: 未安装 -> 跳过")
            continue
        if baseline == "NO_VERSION":
            print("  基线: (TOC 无版本号，语言文件按特殊写法登记)")
        elif not baseline:
            print("  [WARN] 语言文件首行无合法版本头")
            warn = True
        for v in vers:
            print(f"  镜像: {v}")
        if baseline not in ("", "NO_VERSION"):
            mirrored = [v.split(": ", 1)[1] for v in vers if ": " in v]
            if baseline in mirrored:
                print(f"  基线: {baseline}   -> MATCH")
            elif "(无版本号)" in mirrored:
                print(f"  基线: {baseline}   -> TOC 无版本号，无法自动比对")
            else:
                print(f"  基线: {baseline}   -> [WARN] 与镜像 TOC 版本不一致（镜像更新后需对照 enUS 补齐）")
                warn = True
    return 1 if warn else 0


if __name__ == "__main__":
    sys.exit(main())
