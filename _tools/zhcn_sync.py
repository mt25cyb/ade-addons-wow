#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""wow_Locales_zhCN 同步工具：把子项目语言文件同步到只读镜像 z-ref_retail_Interface_AddOns。

⚠ 特例声明：本工具仅服务于 wow_Locales_zhCN 子项目（工作区内唯一允许写入
  z-ref_retail_Interface_AddOns 镜像的例外），勿用于其他项目。

用法:
  python _tools/zhcn_sync.py                 # 同步所有与镜像不一致的文件
  python _tools/zhcn_sync.py --dry-run       # 只报告差异，不写入镜像
  python _tools/zhcn_sync.py --plugin VanasKoS
  python _tools/zhcn_sync.py --list          # 只列出登记表
"""
import argparse
import shutil
import sys
from pathlib import Path

TOOLS_DIR = Path(__file__).resolve().parent         # 仓库根 /_tools/
PROJECT_DIR = TOOLS_DIR.parent / "wow_Locales_zhCN"  # 子项目主目录
MIRROR_DIR = TOOLS_DIR.parent / "z-ref_retail_Interface_AddOns"

# 登记表：插件名 -> [(项目相对路径, 镜像相对路径), ...]
# A 类通常为「项目文件 -> 插件内 zhCN 槽位」；B 类为「项目文件 -> 整体覆盖的插件原文件」。
# 套件子目录（如 VanasKoS）的镜像侧结构必须与项目侧逐文件对应。
ADDONS = {
    "RCT": [
        ("RCT_zhCN.lua", "RCT/Locale/zhCN.lua"),
    ],
    "EmberLedger": [
        ("EmberLedger/Localization.lua", "EmberLedger/Localization.lua"),
    ],
    "Prat-3.0": [
        ("Prat-3.0_zhCN.lua", "Prat-3.0/locales/zhCN.lua"),
    ],
    "MapPinEnhanced": [
        ("MapPinEnhanced_zhCN.lua", "MapPinEnhanced/locales/zhCN.lua"),
    ],
    "QuestPrism": [
        ("QuestPrism_zhCN.lua", "QuestPrism/Locales/zhCN.lua"),
    ],
    "ReputationGuide": [
        ("ReputationGuide_zhCN.lua", "ReputationGuide/locales/zhCN.lua"),
    ],
    "Krowi_AchievementFilter_Khamuls_ExpMetaAchievementFilter": [
        ("Krowi_AchievementFilter_Khamuls_ExpMetaAchievementFilter_zhCN.lua",
         "Krowi_AchievementFilter_Khamuls_ExpMetaAchievementFilter/Localization/zhCN.lua"),
    ],
    "MinimalArchaeology": [
        ("MinimalArchaeology_zhCN.lua", "MinimalArchaeology/addon/locales/ZhCN.lua"),
    ],
    "MouseoverActionSettings": [
        ("MouseoverActionSettings_zhCN.lua", "MouseoverActionSettings/Locales/zhCN.lua"),
    ],
    "TLDRMissions": [
        ("TLDRMissions_zhCN.lua", "TLDRMissions/Locales/zhcn.lua"),  # 落点全小写，作者命名如此
    ],
    "CooldownManagerCentered": [
        ("CooldownManagerCentered_zhCN.lua", "CooldownManagerCentered/locales/zhCN.lua"),
    ],
    "VanasKoS": [
        ("VanasKoS/VanasKoS_Locale.lua", "VanasKoS/VanasKoS_Locale.lua"),
        ("VanasKoS/modules/ChatNotifier_Locale.lua", "VanasKoS/modules/ChatNotifier_Locale.lua"),
        ("VanasKoS/modules/CommandLineHandler_Locale.lua", "VanasKoS/modules/CommandLineHandler_Locale.lua"),
        ("VanasKoS/modules/DataGatherer_Locale.lua", "VanasKoS/modules/DataGatherer_Locale.lua"),
        ("VanasKoS/modules/DefaultLists_Locale.lua", "VanasKoS/modules/DefaultLists_Locale.lua"),
        ("VanasKoS/modules/EventMap_Locale.lua", "VanasKoS/modules/EventMap_Locale.lua"),
        ("VanasKoS/modules/Importer_Locale.lua", "VanasKoS/modules/Importer_Locale.lua"),
        ("VanasKoS/modules/LastSeenList_Locale.lua", "VanasKoS/modules/LastSeenList_Locale.lua"),
        ("VanasKoS/modules/MinimapButton_Locale.lua", "VanasKoS/modules/MinimapButton_Locale.lua"),
        ("VanasKoS/modules/Notifier_Locale.lua", "VanasKoS/modules/Notifier_Locale.lua"),
        ("VanasKoS/modules/PortraitContextMenu_Locale.lua", "VanasKoS/modules/PortraitContextMenu_Locale.lua"),
        ("VanasKoS/modules/PvPDataGatherer_Locale.lua", "VanasKoS/modules/PvPDataGatherer_Locale.lua"),
        ("VanasKoS/modules/PvPStats_Locale.lua", "VanasKoS/modules/PvPStats_Locale.lua"),
        ("VanasKoS/modules/Synchronizer_Locale.lua", "VanasKoS/modules/Synchronizer_Locale.lua"),
        ("VanasKoS/modules/WarnFrame_Locale.lua", "VanasKoS/modules/WarnFrame_Locale.lua"),
    ],
    # 镜像已安装（2026-11-13 重装，Altoholic 12.1.007 / DataStore 2026.10.14，与项目基线一致）。
    # 注意：DataStore_Achievements/Agenda/Containers/Currencies/Pets/Reputations/Spells/Stats
    # 上游本就没有本地化机制（无 Locales/ 目录与 Locale.xml），本项目不维护；
    # DataStore_Talents 新版也移除了 Locale.xml，故其 zhCN 文件暂无落点（保留备查）。
    "Altoholic": [
        ("Altoholic/Altoholic_zhCN.lua", "Altoholic/Locales/zhCN.lua"),
        ("Altoholic/Altoholic_Achievements_zhCN.lua", "Altoholic_Achievements/Locales/zhCN.lua"),
        ("Altoholic/Altoholic_Agenda_zhCN.lua", "Altoholic_Agenda/Locales/zhCN.lua"),
        ("Altoholic/Altoholic_Characters_zhCN.lua", "Altoholic_Characters/Locales/zhCN.lua"),
        ("Altoholic/Altoholic_Grids_zhCN.lua", "Altoholic_Grids/Locales/zhCN.lua"),
        ("Altoholic/Altoholic_Guild_zhCN.lua", "Altoholic_Guild/Locales/zhCN.lua"),
        ("Altoholic/Altoholic_Options_zhCN.lua", "Altoholic_Options/Locales/zhCN.lua"),
        ("Altoholic/Altoholic_Search_zhCN.lua", "Altoholic_Search/Locales/zhCN.lua"),
        ("Altoholic/Altoholic_Summary_zhCN.lua", "Altoholic_Summary/Locales/zhCN.lua"),
        ("Altoholic/DataStore_zhCN.lua", "DataStore/Locales/zhCN.lua"),
        ("Altoholic/DataStore_Auctions_zhCN.lua", "DataStore_Auctions/Locales/zhCN.lua"),
        ("Altoholic/DataStore_Characters_zhCN.lua", "DataStore_Characters/Locales/zhCN.lua"),
        ("Altoholic/DataStore_Crafts_zhCN.lua", "DataStore_Crafts/Locales/zhCN.lua"),
        ("Altoholic/DataStore_Garrisons_zhCN.lua", "DataStore_Garrisons/Locales/zhCN.lua"),
        ("Altoholic/DataStore_Inventory_zhCN.lua", "DataStore_Inventory/Locales/zhCN.lua"),
        ("Altoholic/DataStore_Mails_zhCN.lua", "DataStore_Mails/Locales/zhCN.lua"),
        ("Altoholic/DataStore_Quests_zhCN.lua", "DataStore_Quests/Locales/zhCN.lua"),
        ("Altoholic/DataStore_Talents_zhCN.lua", "DataStore_Talents/Locales/zhCN.lua"),
    ],
    # A-②：镜像已有 zhCN.lua（覆盖层），整体覆盖
    # （2.12.2 起 Localization/ 目录改名 Locales/，旧 Localization/zhCN.lua 落点作废）
    "Fitter": [
        ("Fitter_zhCN.lua", "Fitter/Locales/zhCN.lua"),
    ],
}

# D 类（外挂式汉化补丁）：整插件目录，主库存于 wow_Locales_zhCN/Patches/<名>/，
# 安装 = 整目录镜像到 AddOns 根；重装目标插件后需重新镜像一次。
PATCHES = {
    "Retrace_LocalesPatch": "Retrace_LocalesPatch",
}


def project_path(rel: str) -> Path:
    return PROJECT_DIR / rel


def mirror_path(rel: str) -> Path:
    return MIRROR_DIR / rel


def compare(src: Path, dst: Path, dst_rel: str) -> str:
    """返回单个文件对的同步状态。"""
    if not dst.parent.is_dir():
        # 区分「插件目录整个不存在」与「插件在但无该语言槽位目录」
        addon_name = dst_rel.replace("\\", "/").split("/")[0]
        if (MIRROR_DIR / addon_name).is_dir():
            return "NO_LOCALE"    # 插件在，但上游无本地化机制（如新装 DataStore_Talents）
        return "UNINSTALLED"      # 镜像中无该插件目录 -> 按规则跳过
    if not dst.is_file():
        return "MISSING"          # 插件在但 zhCN 槽位缺失（通常为 A-① 未放包）
    return "DIFF" if src.read_bytes() != dst.read_bytes() else "EQUAL"


def sync_plugin(name: str, pairs, dry_run: bool) -> bool:
    all_ok = True
    for src_rel, dst_rel in pairs:
        src, dst = project_path(src_rel), mirror_path(dst_rel)
        if not src.is_file():
            print(f"  [ERROR]     {src_rel}  项目主文件不存在")
            all_ok = False
            continue
        status = compare(src, dst, dst_rel)
        if status in ("EQUAL", "UNINSTALLED", "NO_LOCALE"):
            print(f"  [{status}]  {src_rel}")
        else:
            print(f"  [SYNC->{status if status == 'MISSING' else 'OVERWRITE'}]  {src_rel}  ->  {dst_rel}"
                  + ("  (dry-run 未写入)" if dry_run else ""))
            if not dry_run:
                dst.parent.mkdir(parents=True, exist_ok=True)
                shutil.copyfile(src, dst)
    return all_ok


def sync_patch(name: str, dst_name: str, dry_run: bool) -> bool:
    """D 类：整插件目录镜像（逐文件比对，镜像侧多余文件不动，只补齐/覆盖差异）。"""
    src_root = PROJECT_DIR / "Patches" / name
    dst_root = MIRROR_DIR / dst_name
    if not src_root.is_dir():
        print(f"  [ERROR]     项目补丁目录不存在: Patches/{name}")
        return False
    all_ok, equal, written = True, 0, 0
    for src in sorted(src_root.rglob("*")):
        if not src.is_file() or "__pycache__" in src.parts:
            continue
        rel = src.relative_to(src_root)
        dst = dst_root / rel
        if dst.is_file() and dst.read_bytes() == src.read_bytes():
            equal += 1
            continue
        written += 1
        print(f"  [PATCH->{'OVERWRITE' if dst.is_file() else 'NEW'}]  {rel.as_posix()}"
              + ("  (dry-run 未写入)" if dry_run else ""))
        if not dry_run:
            dst.parent.mkdir(parents=True, exist_ok=True)
            shutil.copyfile(src, dst)
    if written == 0:
        print(f"  [EQUAL x{equal}]  Patches/{name} -> {dst_name}/")
    return all_ok


def main() -> int:
    parser = argparse.ArgumentParser(description="wow_Locales_zhCN -> z-ref 镜像同步")
    parser.add_argument("--plugin", action="append", help="只处理指定插件（可多次）")
    parser.add_argument("--dry-run", action="store_true", help="只报告，不写入镜像")
    parser.add_argument("--list", action="store_true", help="只列出登记表")
    args = parser.parse_args()

    if not MIRROR_DIR.is_dir():
        print(f"[ERROR] 镜像目录不存在: {MIRROR_DIR}", file=sys.stderr)
        return 2

    if args.list:
        for name, pairs in ADDONS.items():
            print(f"{name}  ({len(pairs)} 个文件)")
        for name, dst_name in PATCHES.items():
            print(f"{name}  (D 类补丁目录 -> {dst_name}/)")
        return 0

    names = args.plugin or list(ADDONS) + list(PATCHES)
    known = set(ADDONS) | set(PATCHES)
    unknown = [n for n in names if n not in known]
    for n in unknown:
        print(f"[ERROR] 未登记的插件: {n}（先在 ADDONS / PATCHES 登记）", file=sys.stderr)
    if unknown:
        return 2

    ok = True
    for name in names:
        print(f"== {name} ==")
        if name in PATCHES:
            ok = sync_patch(name, PATCHES[name], args.dry_run) and ok
        else:
            ok = sync_plugin(name, ADDONS[name], args.dry_run) and ok

    print("-- 完成%s" % ("（dry-run，未写入）" if args.dry_run else ""))
    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(main())
