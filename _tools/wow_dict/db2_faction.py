#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""从 wago.tools 的 Faction DB2 CSV（enUS / zhCN）提取声望/阵营名中英文对照 → `faction` 分类。

数据来源：https://wago.tools/db2/Faction?build=12.1.0.69587
- `Name_lang` = 声望/阵营名；`Description_lang` 无需求不读；`ID` 用于对齐 + 同名不同译时消歧。
- **中英文对照是根本**，其余列（ParentFactionID / Expansion / Flags …）仅辅助，不进词典。
- 分组/导入规则见 `db2_common.py`（所有分类一致）。

过滤
1. `ReputationIndex < 0` 的 433 条是内部占位（PLAYER, xxx / Creature / Monster / Beast - xxx），
   不是玩家可见声望名。判据取自 CSV 自带列并经数据验证。
2. zhCN 仍为英文的（未本地化）→ 排除，以「是否含 CJK 字符」判定。

用法：
    python db2_faction.py                      # 统计概览
    python db2_faction.py --preview 20
    python db2_faction.py --show-dropped       # 查看被排除的条目
    python db2_faction.py --csv out.csv
    python db2_faction.py --check
    python db2_faction.py --import-db
"""
import os
import sys
import csv
import argparse

TOOLS = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.dirname(TOOLS)
sys.path.insert(0, TOOLS)

import db2_common as db2  # noqa: E402

BUILD = '12.1.0.69587'
NAME_COL = 'Name_lang'
CATEGORY = 'faction'
SOURCE = 'wago.tools:Faction'
TEMP_DIR = os.path.join(TOOLS, 'temp')
os.makedirs(TEMP_DIR, exist_ok=True)
EN_CSV = os.path.join(TEMP_DIR, '_db2_csv', 'Faction.%s-enUS.csv' % BUILD)
ZH_CSV = os.path.join(TEMP_DIR, '_db2_csv', 'Faction.%s-zhCN.csv' % BUILD)


def load(path):
    """读 CSV → {ID: {'name': Name_lang, 'rep': ReputationIndex}}"""
    out = {}
    with open(path, encoding='utf-8-sig', newline='') as f:
        for row in csv.DictReader(f):
            try:
                i = int((row.get('ID') or '').strip())
            except (TypeError, ValueError):
                continue
            try:
                rep = int((row.get('ReputationIndex') or '-1').strip())
            except (TypeError, ValueError):
                rep = -1
            out[i] = {'name': (row.get(NAME_COL) or '').strip(), 'rep': rep}
    return out


def build_pairs():
    """→ (保留, 未本地化, 内部占位) 三组 [(ID, en, zh)]"""
    en, zh = load(EN_CSV), load(ZH_CSV)
    keep, dropped, internal = [], [], []
    for i in sorted(set(en) & set(zh)):
        a, b = en[i]['name'], zh[i]['name']
        if not a or not b:
            continue
        if en[i]['rep'] < 0:
            internal.append((i, a, b))
            continue
        (keep if db2.has_cjk(b) else dropped).append((i, a, b))
    return keep, dropped, internal


def main():
    ap = argparse.ArgumentParser(description="Faction 声望/阵营名中英文对照提取")
    ap.add_argument('--preview', type=int, default=0)
    ap.add_argument('--csv')
    ap.add_argument('--show-dropped', action='store_true')
    ap.add_argument('--check', action='store_true')
    ap.add_argument('--import-db', action='store_true')
    args = ap.parse_args()

    keep, dropped, internal = build_pairs()
    print("== 规模 ==")
    print("ReputationIndex<0（内部占位，已排除）%d 条" % len(internal))
    print("zhCN 仍为英文（未本地化，已排除）%d 条" % len(dropped))
    print("可用对照 %d 条" % len(keep))

    groups = db2.merge_groups(keep)
    db2.summarize(groups, keep)

    if args.preview:
        print("\n== 预览前 %d 条 ==" % args.preview)
        for g in groups[:args.preview]:
            print("%-46s %-28s id=%s" % (g['en'], g['zh'], ",".join(str(x) for x in g['ids'])))

    if args.show_dropped:
        print("\n== 排除：zhCN 无中文（未本地化）==")
        for i, a, b in dropped[:40]:
            print("  %-8d %-45s %s" % (i, a, b))
        print("  共 %d 条" % len(dropped))
        print("\n== 排除：内部占位（ReputationIndex<0）==")
        for i, a, b in internal[:20]:
            print("  %-8d %-45s %s" % (i, a, b))
        print("  共 %d 条" % len(internal))

    if args.csv:
        out = os.path.join(TEMP_DIR, args.csv)
        with open(out, 'w', encoding='utf-8-sig', newline='') as f:
            w = csv.writer(f)
            w.writerow(['en', 'zh', 'faction_ids'])
            for g in groups:
                w.writerow([g['en'], g['zh'], ",".join(str(x) for x in g['ids'])])
        print("\nOK: written %d rows -> %s" % (len(groups), out))

    if args.check or args.import_db:
        import db as dict_db
        conn = dict_db.get_conn()
        dict_db.init_db(conn)
        new, same, diff = db2.compare_existing(conn, groups, CATEGORY)
        print("\n== 与库中 %s 现有条目比对 ==" % CATEGORY)
        print("新增 %d / 译名一致 %d / 库中已有同名但译名不同 %d（不同实体，照常新增）"
              % (len(new), len(same), len(diff)))
        for g, ex in diff[:20]:
            print("  %-40s CSV=%-24s 库内=%s" % (g['en'], g['zh'], " / ".join(ex)))
        if args.import_db:
            n = db2.import_groups(conn, groups, CATEGORY, SOURCE, dict_db)
            print("\nOK: upserted %d %s entries (source=%s)" % (n, CATEGORY, SOURCE))
            print("%s 现存 %d 条" % (CATEGORY, conn.execute(
                "SELECT COUNT(*) FROM entries WHERE category=?", (CATEGORY,)).fetchone()[0]))
        conn.close()


if __name__ == '__main__':
    main()
