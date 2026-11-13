#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""ItemSearchName DB2 CSV（wago.tools）→ 词典库 `item` 分类。

**`ItemSearchName` 的 ID 就是 itemID**（与 wowhead 的 item 页 ID 一致），
`Display_lang` 是物品显示名。相比逐个查 wowhead，**这是物品名的权威批量来源**。

下载（走代理 127.0.0.1:7890）：
  https://wago.tools/db2/ItemSearchName/csv?build=<build>&locale=<enUS|zhCN>
  → 存为 `temp/_db2_csv/ItemSearchName.<build>-<locale>.csv`

流程沿用 UiMap / Faction / Achievement 的三段式：
  --preview / --csv / --show-dropped  →  --check  →  --import-db
分组与消歧规则见 `db2_common.py`（同 en 同译合并取最小 ID；同 en 不同译各自保留）。
"""
import csv
import os
import re
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import db as dict_db  # noqa: E402
import db2_common as db2  # noqa: E402

if hasattr(sys.stdout, 'reconfigure'):
    sys.stdout.reconfigure(encoding='utf-8')

BUILD = '12.1.0.69587'
TEMP_DIR = os.path.join(dict_db.TOOLS_DIR, 'temp')
os.makedirs(TEMP_DIR, exist_ok=True)
CSV_DIR = os.path.join(TEMP_DIR, '_db2_csv')
EN_CSV = os.path.join(CSV_DIR, 'ItemSearchName.%s-enUS.csv' % BUILD)
ZH_CSV = os.path.join(CSV_DIR, 'ItemSearchName.%s-zhCN.csv' % BUILD)

CATEGORY = 'item'
SOURCE = 'wago.tools:ItemSearchName'

# 官方表中的占位 / 废弃条目（与 Faction 同策略：只看名字里的标记，不猜语义）
DROP_PAT = re.compile(r'\[PH\]|\[DNT\]|DEPRECATED|^\s*[_#]')
NAME_COL = 'Display_lang'


def read_pairs():
    """返回 (pairs, dropped)；pairs = [(id:int, en, zh)]"""
    zh = {}
    with open(ZH_CSV, encoding='utf-8', errors='replace', newline='') as f:
        for r in csv.DictReader(f):
            zh[r['ID']] = (r.get(NAME_COL) or '').strip()
    pairs, dropped = [], []
    with open(EN_CSV, encoding='utf-8', errors='replace', newline='') as f:
        for r in csv.DictReader(f):
            i, en = r['ID'], (r.get(NAME_COL) or '').strip()
            z = zh.get(i, '').strip()
            if not en or not z:
                dropped.append((i, en, z, '缺名'))
                continue
            if not db2.has_cjk(z):
                dropped.append((i, en, z, 'zhCN 无中文'))
                continue
            if DROP_PAT.search(en) or DROP_PAT.search(z):
                dropped.append((i, en, z, '占位/废弃'))
                continue
            pairs.append((int(i), en, z))
    return pairs, dropped


def main():
    import argparse
    ap = argparse.ArgumentParser()
    ap.add_argument('--preview', action='store_true', help='看表头/行数/抽样')
    ap.add_argument('--csv', help='导出合并后的对照到 CSV')
    ap.add_argument('--show-dropped', type=int, default=0, help='打印前 N 条被丢弃的')
    ap.add_argument('--check', action='store_true', help='与库中现有 item 比对，列新增/一致/不同译')
    ap.add_argument('--import-db', action='store_true', help='写入词典库')
    args = ap.parse_args()

    pairs, dropped = read_pairs()
    print('可用对照 %d 条（丢弃 %d 条）' % (len(pairs), len(dropped)))
    from collections import Counter
    print('丢弃原因：', dict(Counter(d[3] for d in dropped)))

    groups = db2.merge_groups(pairs)
    db2.summarize(groups, pairs)

    if args.preview:
        print('\n== 抽样（前 12 条）==')
        for g in groups[:12]:
            print('  %-42s %-28s ID=%s' % (g['en'][:42], g['zh'][:28], min(g['ids'])))

    if args.show_dropped:
        print('\n== 被丢弃抽样 ==')
        for d in dropped[:args.show_dropped]:
            print('  %-10s %-38s %-24s [%s]' % (d[0], d[1][:38], d[2][:24], d[3]))

    if args.csv:
        out = os.path.join(TEMP_DIR, args.csv)
        with open(out, 'w', encoding='utf-8-sig', newline='') as f:
            w = csv.writer(f)
            w.writerow(['en', 'zh', 'itemID'])
            for g in groups:
                w.writerow([g['en'], g['zh'], min(g['ids'])])
        print('\nCSV 已写出：' + out)

    if args.check or args.import_db:
        conn = dict_db.get_conn()
        dict_db.init_db(conn)
        new, same, diff = db2.compare_existing(conn, groups, CATEGORY)
        print('\n== 与库中 item 比对 ==')
        print('新增 %d / 译名一致 %d / 同名不同译 %d' % (len(new), len(same), len(diff)))
        for g, old in diff[:15]:
            print('   %-38s 库:%s  vs  新:%s (ID=%s)' % (g['en'][:38], '/'.join(old), g['zh'], min(g['ids'])))
        if args.import_db:
            n = db2.import_groups(conn, groups, CATEGORY, SOURCE, dict_db)
            print('\n已写入 %d 条（source=%s）' % (n, SOURCE))
            tot = conn.execute('SELECT COUNT(*) FROM entries').fetchone()[0]
            print('item 分类现有 %d 条，TOTAL %d'
                  % (conn.execute("SELECT COUNT(*) FROM entries WHERE category='item'").fetchone()[0], tot))
        conn.close()


if __name__ == '__main__':
    main()
