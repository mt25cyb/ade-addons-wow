#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""WoW 英中词典库 —— 统一入口（facade）。

外部项目 / 脚本只应通过本文件使用词典库能力，不要直接 import 各小脚本：
    import main              # 编程式 API（resolve_name / add_term / query / lookup ...）
    python main.py <子命令>  # 命令行

子命令 → 底层实现（小脚本）：
    resolve      解析专名（先查词典，缺失按分类走 DB2/Wowhead 兜底）→ resolve.py
    add          增量写入一条词条 → db.upsert
    add-terms    写入已核实的通用术语种子（add_terms.py 的 TERMS）→ add_terms.main
    dedupe       清理 (category,en) 重复行 → dedupe.py
    import-md    从 _wow_dict_enUS_to_zhCN.md 导入 → import_md.import_md
    import-db2   从 DB2 CSV 导入某分类（zone/item/spell/faction/achievement）→ db2_*.py
    query        按分类/状态/明细筛选 → db.fetch_entries
    lookup       英→中匹配 → db.lookup
    stats        分类统计 → db
    init/rebuild 建表 / 重建 → db
    export       导出 lua/csv → db.export_*
    wowhead      Wowhead/Google 检索入口 → wowhead.py

约定：所有运行时生成的临时文件 / 缓存（DB2 CSV、--csv 导出等）统一放在本目录 temp/ 下。
"""
import os
import sys
import argparse

HERE = os.path.dirname(os.path.abspath(__file__))
if HERE not in sys.path:
    sys.path.insert(0, HERE)

import db as dict_db
import resolve
import dedupe
import import_md
import add_terms
import wowhead
import db2_zone
import db2_item
import db2_spell
import db2_faction
import db2_achievement

DB2_MODULES = {
    'zone': db2_zone, 'item': db2_item, 'spell': db2_spell,
    'faction': db2_faction, 'achievement': db2_achievement,
}


def _run_module(module, argv):
    """用 sys.argv 委托调用小脚本的 main()：统一入口调度，小脚本仍保留独立运行能力。"""
    saved = sys.argv
    sys.argv = [getattr(module, '__name__', 'mod')] + list(argv)
    try:
        module.main()
    finally:
        sys.argv = saved


# ---- 编程式 API ----------------------------------------------------------
def resolve_name(en=None, zh=None, category=None, fetch=False):
    """解析专名，返回 {source, en, zh, ref_id, status, google, wowhead}。"""
    return resolve.resolve(en=en, zh=zh, category=category, fetch=fetch)


def add_term(category, en, zh='', ref_id='', detail=None, attrs=None,
             status='confirmed', notes='', source='cli', zh_tw=''):
    conn = dict_db.get_conn()
    dict_db.init_db(conn)
    eid = dict_db.upsert(conn, category, en, zh, ref_id, detail=detail, attrs=attrs,
                         status=status, notes=notes, source=source, zh_tw=zh_tw)
    conn.commit()
    conn.close()
    return eid


def query(category=None, status=None, detail=None):
    conn = dict_db.get_conn()
    rows = dict_db.fetch_entries(conn, category, status, detail)
    conn.close()
    return rows


def lookup(en, category=None, partial=False):
    conn = dict_db.get_conn()
    rows = dict_db.lookup(conn, en, category, partial)
    conn.close()
    return rows


# ---- 命令行 --------------------------------------------------------------
def main():
    p = argparse.ArgumentParser(prog='main.py', description='WoW 英中词典库统一入口')
    sub = p.add_subparsers(dest='cmd')

    pr = sub.add_parser('resolve', help='解析专名（先查词典，缺失兜底）')
    pr.add_argument('--en')
    pr.add_argument('--zh')
    pr.add_argument('--category')
    pr.add_argument('--fetch', action='store_true')

    pa = sub.add_parser('add', help='增量写入一条词条')
    pa.add_argument('--category', required=True)
    pa.add_argument('--en', required=True)
    pa.add_argument('--zh', default='')
    pa.add_argument('--zh-tw', default='', help='繁体中文译名')
    pa.add_argument('--ref-id', default='')
    pa.add_argument('--detail', action='append', help='明细真列 key=value，可重复')
    pa.add_argument('--attr', action='append', help='长尾兜底 attrs key=value，可重复')
    pa.add_argument('--status', default='confirmed')
    pa.add_argument('--notes', default='')
    pa.add_argument('--source', default='cli')

    sub.add_parser('add-terms', help='写入已核实通用术语种子')

    pd = sub.add_parser('dedupe', help='清理 (category,en) 重复行')
    g = pd.add_mutually_exclusive_group(required=True)
    g.add_argument('--dry', action='store_true', help='只预演')
    g.add_argument('--apply', action='store_true', help='实际删除冗余行')
    pd.add_argument('--category', default='', help='限定分类（逗号分隔），默认全部')

    pm = sub.add_parser('import-md', help='从 MD 导入（可选位置参数 path）')
    pm.add_argument('path', nargs='?')

    pdb = sub.add_parser('import-db2',
                         help='从 DB2 CSV 导入某分类（其余参数原样转发给表模块）')
    pdb.add_argument('table', choices=list(DB2_MODULES))
    pdb.add_argument('rest', nargs=argparse.REMAINDER,
                     help='转发给 db2_<table>.py 的全部参数（--preview/--csv/--check/--import-db...）')

    pq = sub.add_parser('query', help='按分类/状态/明细筛选')
    pq.add_argument('--category')
    pq.add_argument('--status')
    pq.add_argument('--detail', help='明细真列过滤 key=value')

    pl = sub.add_parser('lookup', help='英→中匹配')
    pl.add_argument('--en', required=True)
    pl.add_argument('--category')
    pl.add_argument('--partial', action='store_true', help='模糊匹配（LIKE %en%）')

    sub.add_parser('stats')
    sub.add_parser('init')
    sub.add_parser('rebuild')
    pe = sub.add_parser('export', help='导出 lua/csv')
    pe.add_argument('--format', choices=['lua', 'csv'], default='lua')
    pe.add_argument('--category')
    pe.add_argument('--output')

    pw = sub.add_parser('wowhead', help='Wowhead/Google 检索入口')
    pw.add_argument('--keyword', required=True)
    pw.add_argument('--type')
    pw.add_argument('--fetch', action='store_true', help='尝试 best-effort 抓中文名')

    args = p.parse_args()
    if not args.cmd:
        p.print_help()
        return

    # import-db2：表名已解析，其余参数原样转发给对应表模块
    if args.cmd == 'import-db2':
        _run_module(DB2_MODULES[args.table], list(args.rest))
        return

    # 非 db 小脚本：其 main() 用顶层参数、不含子命令 token → 去掉子命令（sys.argv[2:]）
    facade_targets = {
        'resolve': resolve, 'add-terms': add_terms, 'dedupe': dedupe,
        'import-md': import_md, 'wowhead': wowhead,
    }
    if args.cmd in facade_targets:
        _run_module(facade_targets[args.cmd], sys.argv[2:])
        return
    # db 子命令（add/query/lookup/stats/init/rebuild/export）：复用 db.main() 自身的子解析器，
    # 需保留子命令 token（sys.argv[1:]）
    _run_module(dict_db, sys.argv[1:])


if __name__ == '__main__':
    main()
