#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""从 wago.tools 的 UiMap DB2 CSV（enUS / zhCN）提取地区名中英文对照 → `zone` 分类。

数据来源：https://wago.tools/db2/UiMap?build=12.1.0.69587
- `Name_lang` = 地区名；`ID` 用于两语言对齐（辅助定位 + 同名不同译时消歧）。
- **中英文对照是根本**，其余列（ParentUiMapID / Type / Flags …）仅辅助，不进词典。
- 分组/导入规则见 `db2_common.py`（所有分类一致）。

特点：UiMap 中副本的**每一层都是独立记录且同名**（Torghast 109 层、Karazhan 35 层），
但译名一致 → 合并为一条，全部 ID 存入 ref_id。

用法：
    python db2_zone.py                      # 统计概览
    python db2_zone.py --preview 20
    python db2_zone.py --csv out.csv
    python db2_zone.py --check              # 与库中 zone 比对
    python db2_zone.py --import-db
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
CATEGORY = 'zone'
SOURCE = 'wago.tools:UiMap'
TEMP_DIR = os.path.join(TOOLS, 'temp')
os.makedirs(TEMP_DIR, exist_ok=True)
EN_CSV = os.path.join(TEMP_DIR, '_db2_csv', 'UiMap.%s-enUS.csv' % BUILD)
ZH_CSV = os.path.join(TEMP_DIR, '_db2_csv', 'UiMap.%s-zhCN.csv' % BUILD)


def load(path):
    """读 CSV → {ID: Name_lang}"""
    out = {}
    with open(path, encoding='utf-8-sig', newline='') as f:
        for row in csv.DictReader(f):
            try:
                i = int((row.get('ID') or '').strip())
            except (TypeError, ValueError):
                continue
            out[i] = (row.get(NAME_COL) or '').strip()
    return out


def build_pairs():
    en, zh = load(EN_CSV), load(ZH_CSV)
    return [(i, en[i], zh[i]) for i in sorted(set(en) & set(zh)) if en[i] and zh[i]]


def main():
    ap = argparse.ArgumentParser(description="UiMap 地区名中英文对照提取")
    ap.add_argument('--preview', type=int, default=0)
    ap.add_argument('--csv')
    ap.add_argument('--check', action='store_true')
    ap.add_argument('--import-db', action='store_true')
    args = ap.parse_args()

    pairs = build_pairs()
    print("== 规模 ==")
    print("可用对照 %d 条" % len(pairs))
    groups = db2.merge_groups(pairs)
    db2.summarize(groups, pairs)

    if args.preview:
        print("\n== 预览前 %d 条 ==" % args.preview)
        for g in groups[:args.preview]:
            print("%-45s %-30s id=%s" % (g['en'], g['zh'], ",".join(str(x) for x in g['ids'])))

    if args.csv:
        out = os.path.join(TEMP_DIR, args.csv)
        with open(out, 'w', encoding='utf-8-sig', newline='') as f:
            w = csv.writer(f)
            w.writerow(['en', 'zh', 'uimap_ids'])
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
