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
    "ParchmentReader": [
        ("ParchmentReader_zhCN.lua", "ParchmentReader/Locales/zhCN.lua"),
    ],
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

# E 类（多语言表注入型）：多语言字段内嵌在功能代码中（本例为 local STR = {...}，STR 只是
# 该插件自己的表名），无法用独立文件分发。主档保存「版本头 + 多语言表 + --@@ 行级补丁段」；
# 安装 = 整块替换镜像中的表定义 + 按 --@@ 补丁段重打代码分支（new 子串已存在视为已打，
# 幂等可重复执行）。补丁段从主档文件解析，主档是唯一权威（见 _parse_patch_sections）。
# ⚠ 上游更新若改动了多语言表本身（增删键）或分支代码，需人工把变化合并进主档。
TABLE_INJECT = {
    "TaxiCatalog": [
        {
            "patch": "TaxiCatalog/TaxiCatalog_zhCN.lua",
            "dst": "TaxiCatalog/TaxiCatalog.lua",
            "head": "local STR = {",
        },
        {
            "patch": "TaxiCatalog/TaxiCatalog_Ace3_zhCN.lua",
            "dst": "TaxiCatalog/TaxiCatalog_Ace3.lua",
            "head": "local STR = {",
        },
    ],
}

# D 类（外挂式汉化补丁）：整插件目录，主库存于 wow_Locales_zhCN/Patches/<名>/，
# 安装 = 整目录镜像到 AddOns 根；重装目标插件后需重新镜像一次。
PATCHES = {
    "Retrace_LocalesPatch": "Retrace_LocalesPatch",
    # 由 _temp/_old_ADE 旧版外挂补丁迁移而来（手册 §6 示例即此插件），字典基准 2.3.1
    "CooldownManagerProfiles_LocalesPatch": "CooldownManagerProfiles_LocalesPatch",
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


def _extract_table_block(text: str, head: str) -> str:
    """提取「head ... 匹配 }」的多语言表块（含声明行，括号计数找匹配结尾）。"""
    start = text.index(head)
    depth = 0
    for i in range(start + len(head) - 1, len(text)):
        c = text[i]
        if c == "{":
            depth += 1
        elif c == "}":
            depth -= 1
            if depth == 0:
                return text[start:text.index("\n", i) + 1]
    raise RuntimeError("多语言表块未闭合: " + head)


def _parse_patch_sections(text: str) -> list:
    """解析主档中的 --@@ 行级补丁段，返回 [(old, new), ...]。

    格式（均为注释行，不影响 Lua 语法）：
      --@@ patch <标题>   开始一个补丁
      --@@ old            old 段开始，其后每个 -- 开头行（去掉 --）是一行代码
      --@@ new            new 段开始，同上
      --@@ end            补丁结束
    """
    patches, cur_old, cur_new, mode = [], None, None, None
    for line in text.splitlines():
        s = line.strip()
        if s.startswith("--@@"):
            key = s[4:].strip()
            if key == "old":
                cur_old, cur_new, mode = [], None, "old"
            elif key == "new":
                cur_new, mode = [], "new"
            elif key == "end":
                if cur_old is None or cur_new is None:
                    raise RuntimeError("--@@ 补丁段缺少 old 或 new")
                patches.append(("\n".join(cur_old), "\n".join(cur_new)))
                cur_old, cur_new, mode = None, None, None
            # --@@ patch <标题> 仅作说明，忽略
        elif mode == "old" and line.startswith("--"):
            cur_old.append(line[2:])
        elif mode == "new" and line.startswith("--"):
            cur_new.append(line[2:])
    return patches


def sync_table_inject(name: str, specs, dry_run: bool) -> bool:
    """E 类：多语言表整块替换 + 行级补丁（补丁从主档 --@@ 段解析，幂等）。"""
    all_ok = True
    for spec in specs:
        src_rel, dst_rel = spec["patch"], spec["dst"]
        src, dst = project_path(src_rel), mirror_path(dst_rel)
        if not src.is_file():
            print(f"  [ERROR]     {src_rel}  项目主文件不存在")
            all_ok = False
            continue
        if not dst.is_file():
            print(f"  [UNINSTALLED]  {src_rel}  （镜像无 {dst_rel}）")
            continue
        src_text = src.read_text(encoding="utf-8")
        want_block = _extract_table_block(src_text, spec["head"])
        try:
            lines = _parse_patch_sections(src_text)
        except RuntimeError as e:
            print(f"  [ERROR]     {src_rel}  {e}")
            all_ok = False
            continue
        if not lines:
            print(f"  [WARN]      {src_rel}  主档中没有 --@@ 行级补丁段")
        dst_text = dst.read_text(encoding="utf-8")
        try:
            cur_block = _extract_table_block(dst_text, spec["head"])
        except (ValueError, RuntimeError):
            print(f"  [ERROR]     {dst_rel}  镜像中找不到多语言表块（上游结构变化）")
            all_ok = False
            continue
        pending = [(o, n) for o, n in lines if n not in dst_text]
        lost_old = [o for o, n in lines if o not in dst_text and n not in dst_text]
        if lost_old:
            print(f"  [ERROR]     {dst_rel}  行补丁锚点丢失（上游大改，需人工核对）:")
            for o in lost_old:
                print(f"              - {o[:60]}...")
            all_ok = False
        if cur_block == want_block and not pending and not lost_old:
            print(f"  [EQUAL]  {src_rel}  ->  {dst_rel}")
            continue
        print(f"  [INJECT]  {src_rel}  ->  {dst_rel}" + ("  (dry-run 未写入)" if dry_run else ""))
        if not dry_run:
            new_text = dst_text.replace(cur_block, want_block)
            for o, n in lines:
                if n not in new_text and o in new_text:
                    new_text = new_text.replace(o, n)
            dst.write_text(new_text, encoding="utf-8", newline="\n")
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
        for name, specs in TABLE_INJECT.items():
            print(f"{name}  (E 类多语言表注入 x{len(specs)})")
        for name, dst_name in PATCHES.items():
            print(f"{name}  (D 类补丁目录 -> {dst_name}/)")
        return 0

    names = args.plugin or list(ADDONS) + list(TABLE_INJECT) + list(PATCHES)
    known = set(ADDONS) | set(TABLE_INJECT) | set(PATCHES)
    unknown = [n for n in names if n not in known]
    for n in unknown:
        print(f"[ERROR] 未登记的插件: {n}（先在 ADDONS / TABLE_INJECT / PATCHES 登记）", file=sys.stderr)
    if unknown:
        return 2

    ok = True
    for name in names:
        print(f"== {name} ==")
        if name in PATCHES:
            ok = sync_patch(name, PATCHES[name], args.dry_run) and ok
        elif name in TABLE_INJECT:
            ok = sync_table_inject(name, TABLE_INJECT[name], args.dry_run) and ok
        else:
            ok = sync_plugin(name, ADDONS[name], args.dry_run) and ok

    print("-- 完成%s" % ("（dry-run，未写入）" if args.dry_run else ""))
    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(main())
