#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""词典库统一解析入口：先查词典，缺失再按分类用 DB2/Wowhead 工具链补足。

体现词典库原则：**用到中英文对照时，优先检索词典库；词典库没有，才用 DB2/Wowhead 获取新词条。**
本工具只做「按需解析 + 按需写入」，不批量灌数据。

工作流：
  1) 优先检索词典库（en 或 zh，精确 + 模糊）。
  2) 命中 → 直接返回，不触碰任何外部源。
  3) 未命中 → 按 category 选源：
       - item / spell：在本地已下载的 DB2 CSV 中按关键字检索（需先取 CSV，见各导入器头部 URL）。
       - quest / 其它，或本地无 CSV：走 Wowhead / Google `site:www.wowhead.com` 兜底。
  4) 解析到译名 → upsert 入词典库（source 标真实来源；自动抓取的标 unconfirmed，待人工核实）。

用法：
  python resolve.py --en "Thrall"                 # 先查词典（英文）
  python resolve.py --zh "影踪派"                 # 中文检索
  python resolve.py --en "X" --category spell     # 指定分类，未命中走 SpellName CSV
  python resolve.py --en "X" --fetch              # 未命中时尝试外部抓取并写入
"""
import csv
import os
import sys

TOOLS = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, TOOLS)

import db as dict_db                     # noqa: E402
import wowhead as wh                     # noqa: E402

if hasattr(sys.stdout, 'reconfigure'):
    sys.stdout.reconfigure(encoding='utf-8')

BUILD = '12.1.0.69587'
CSV_DIR = os.path.join(TOOLS, 'temp', '_db2_csv')

# 分类 → (DB2 表名, 名称列, id 列名)。覆盖「DB2 有本地化」的分类。
DB2_TABLES = {
    'item':  ('ItemSearchName', 'Display_lang', 'itemID'),
    'spell': ('SpellName', 'Name_lang', 'spellID'),
}


def dict_lookup(conn, keyword, by_zh=False, category=None):
    """先精确，再模糊（仅 en 模糊；zh 精确即可）。"""
    if by_zh:
        q = "SELECT category, en, zh, ref_id, status FROM entries WHERE zh = ?"
        p = [keyword]
    else:
        q = "SELECT category, en, zh, ref_id, status FROM entries WHERE en = ?"
        p = [keyword]
    if category:
        q += " AND category=?"
        p.append(category)
    rows = conn.execute(q, p).fetchall()
    if not rows and not by_zh:
        q2 = ("SELECT category, en, zh, ref_id, status FROM entries WHERE en LIKE ?"
              + (" AND category=?" if category else ""))
        rows = conn.execute(q2, ['%' + keyword + '%'] + ([category] if category else [])).fetchall()
    return rows


def search_db2_csv(category, keyword):
    """在本地 DB2 CSV 中按 en/zh 模糊匹配；返回 (en, zh, id) 或 None。"""
    if category not in DB2_TABLES:
        return None
    table, col, _idcol = DB2_TABLES[category]
    en_csv = os.path.join(CSV_DIR, '%s.%s-enUS.csv' % (table, BUILD))
    zh_csv = os.path.join(CSV_DIR, '%s.%s-zhCN.csv' % (table, BUILD))
    if not (os.path.exists(en_csv) and os.path.exists(zh_csv)):
        return None
    zh = {}
    with open(zh_csv, encoding='utf-8', errors='replace', newline='') as f:
        for r in csv.DictReader(f):
            zh[r['ID']] = (r.get(col) or '').strip()
    kw = keyword.lower()
    with open(en_csv, encoding='utf-8', errors='replace', newline='') as f:
        for r in csv.DictReader(f):
            i = r['ID']
            en = (r.get(col) or '').strip()
            z = zh.get(i, '').strip()
            if not en or not z:
                continue
            if kw in en.lower() or kw in z.lower():
                return (en, z, i)
    return None


def resolve(en=None, zh=None, category=None, fetch=False):
    """先查词典库，缺失按分类走 DB2/Wowhead 兜底。返回结果 dict：
    {source, en, zh, ref_id, status, google, wowhead}
    source ∈ {dict, db2, wowhead, none}。"""
    conn = dict_db.get_conn()
    dict_db.init_db(conn)

    result = {'source': None, 'en': None, 'zh': None, 'ref_id': None,
              'status': None, 'google': None, 'wowhead': None}

    keyword = zh if zh else en
    by_zh = bool(zh)
    if not keyword:
        conn.close()
        return result

    rows = dict_lookup(conn, keyword, by_zh, category)
    if rows:
        cat, e, z, ref_id, status = rows[0]
        result.update(source='dict', en=e, zh=z, ref_id=ref_id, status=status)
        conn.close()
        return result

    if category in DB2_TABLES:
        candidate = search_db2_csv(category, keyword)
        if candidate:
            e, z, i = candidate
            result.update(source='db2', en=e, zh=z, ref_id=str(i), status='confirmed')
            if fetch:
                src = 'wago.tools:%s' % DB2_TABLES[category][0]
                dict_db.upsert(conn, category, e, z, ref_id=str(i),
                               status='confirmed', source=src)
                conn.commit()
            conn.close()
            return result

    result['source'] = 'wowhead'
    result['google'] = wh.google_site_query(keyword)
    result['wowhead'] = wh.wowhead_search_url(keyword, category)
    if fetch and en:
        name = wh.fetch_zhcn(en, category)
        if name:
            dict_db.upsert(conn, category or 'term', en, name,
                           status='unconfirmed', notes='wowhead/google 自动获取，待核实',
                           source='wowhead')
            conn.commit()
            result.update(en=en, zh=name, status='unconfirmed')
    conn.close()
    return result


def main():
    import argparse
    ap = argparse.ArgumentParser(description="词典库解析：先查词典，缺失再抓")
    ap.add_argument('--en', help='英文关键字（默认检索键）')
    ap.add_argument('--zh', help='中文关键字（用 --zh 切换为中文检索）')
    ap.add_argument('--category')
    ap.add_argument('--fetch', action='store_true',
                    help='未命中时尝试外部源并写入词典（自动抓取标 unconfirmed）')
    args = ap.parse_args()
    if not (args.en or args.zh):
        print("需提供 --en 或 --zh")
        return

    r = resolve(args.en, args.zh, args.category, args.fetch)
    if r['source'] == 'dict':
        print("命中词典：%s -> %s (id=%s, %s)" % (r['en'], r['zh'], r['ref_id'], r['status']))
    elif r['source'] == 'db2':
        print("本地 DB2 CSV 命中：%s -> %s (id=%s)" % (r['en'], r['zh'], r['ref_id']))
    elif r['source'] == 'wowhead':
        print("Google :", r['google'])
        print("Wowhead:", r['wowhead'])
        if r.get('zh'):
            print("已按 unconfirmed 写入候选：%s（待人工核实，禁止臆造）" % r['zh'])
    else:
        print("（无结果）")


if __name__ == '__main__':
    main()
