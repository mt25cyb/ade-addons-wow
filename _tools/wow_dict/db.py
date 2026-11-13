#!/usr/bin/env python3
# -*- coding: utf-8 -*-
r"""WoW 英中词典数据库（SQLite）。

数据库：_wow_dict.db（权威库，不在版本库内：23MB 二进制，存放于工作区外部数据目录
        D:\Dev-Workspace\_wow_dict\_wow_dict.db；可用环境变量 WOW_DICT_DB 覆盖）
脚本与种子 MD：仓库 _tools/wow_dict/（见 _docs/Localization-Terminology-Workflow.md）

表结构（混合式：核心表 + 分类明细表）
- categories   分类注册表（分类键、中英文名、ID 列名、wowhead 类型、说明）
- entries      核心词条表：en / zh 为根本，ref_id 统一 ID，attrs 作长尾兜底
- detail_*     分类明细表：各分类独有字段为真列，entry_id 与 entries 1:1 外键
- v_<category> 核心 + 明细 的联合视图，查询体验等同独立分类表

设计要点
- 「英文 → 中文」匹配是根本目的：en 列 COLLATE NOCASE 且建索引，提供 lookup 命令。
- 各分类额外字段互不相同：由明细表承载真列，不再塞进 JSON。
- npc 与 creature 额外字段一致，共用 detail_npc（分类键仍分开，语义不丢）。
- attrs 保留作长尾兜底：冷门 / 一次性字段不必为此 ALTER TABLE。
- 扩展方式：加字段改 DETAIL_TABLES；给新分类配明细表加 CATEGORY_DETAIL 项。

命令行：
  python db.py init                  # 建表 + 写入分类注册表
  python db.py rebuild               # 删库重建，并从 MD 重新导入
  python db.py add --category npc --en "X" --zh "Y" [--ref-id 1] [--detail zone=多恩岛]
  python db.py query [--category x] [--status confirmed|unconfirmed] [--detail key=val]
  python db.py lookup --en "Thrall" [--partial]      # 英 → 中匹配
  python db.py stats
  python db.py export --format lua|csv [--category x] [--output file]
"""
import os
import sys
import json
import sqlite3
import argparse

# 终端输出统一 UTF-8（Windows 控制台默认 GBK，会让中文导出显示成乱码）
if hasattr(sys.stdout, 'reconfigure'):
    try:
        sys.stdout.reconfigure(encoding='utf-8')
    except Exception:
        pass

TOOLS_DIR = os.path.dirname(os.path.abspath(__file__))
# 权威数据库不在版本库内（23MB 二进制）：默认取工作区外部数据目录，
# 可用环境变量 WOW_DICT_DB 覆盖到其他位置。
DB_PATH = os.environ.get('WOW_DICT_DB') or r'D:\Dev-Workspace\_wow_dict\_wow_dict.db'

# (key, name_zh, name_en, id_column, wowhead_type, description, ord)
CATEGORY_REGISTRY = [
    ('expansion',  '资料片/版本',   'Expansion',  'Value',         '',          '游戏资料片/版本（LE_EXPANSION）', 1),
    ('race',       '种族',          'Race',       'raceID',        '',          '可选种族', 2),
    ('zone',       '地理/区域',     'Zone',       'UiMapID',       'zone',      '地图/区域名（ID 为 DB2 UiMapID）', 3),
    ('npc',        'NPC/角色',      'NPC',        'npcID',         'npc',       '有名有姓的 NPC/角色', 4),
    ('creature',   '怪物/生物',     'Creature',   'npcID',         'npc',       '怪物/生物', 5),
    ('object',     '物件/可交互物', 'Object',     'objectID',      'object',    '场景可交互装置/物体', 6),
    ('item',       '物品',          'Item',       'itemID',        'item',      '背包物品', 7),
    ('spell',      '法术/技能',     'Spell',      'spellID',       'spell',     '法术/技能名', 8),
    ('quest',      '任务',          'Quest',      'questID',       'quest',     '任务名', 9),
    ('achievement','成就',          'Achievement','achievementID', 'achievement','成就名', 10),
    ('faction',    '势力/声望',     'Faction',    'factionID',     'faction',   '势力/声望', 11),
    ('gameplay',   '游戏内容/玩法', 'Gameplay',   '',              '',          '玩法/内容专有名词', 12),
    ('term',       '游戏机制术语',  'Term',       '',              '',          '机制/术语（与日常义不同）', 13),
]

# 明细表：表名 -> 列名列表（均为 TEXT；需要数值/约束可单独改 DDL）
# 原则：只放「会被查询/筛选」或「该分类稳定独有」的字段。
DETAIL_TABLES = {
    'detail_expansion': ['abbr', 'constant', 'release_version', 'release_date'],
    'detail_race':      ['side'],
    'detail_faction':   ['expansion'],
    # npc 与 creature 额外字段一致，共用本表（分类键仍为 npc / creature 两种）
    'detail_npc':       ['zone', 'level', 'creature_type', 'faction_id'],
}

# 分类 -> (明细表名, {MD 表头: 明细列名})
# 未列出的分类表示当前无额外字段，暂不建明细表（遵循「有实证来源才建表，不建空表」）。
CATEGORY_DETAIL = {
    'expansion': ('detail_expansion', {
        '缩写': 'abbr', 'Constant': 'constant',
        '发布版本': 'release_version', '发布时间': 'release_date',
    }),
    'race': ('detail_race', {'阵营': 'side'}),
    'faction': ('detail_faction', {'资料片': 'expansion'}),
    'npc': ('detail_npc', {}),
    'creature': ('detail_npc', {}),
}

SCHEMA = """
CREATE TABLE IF NOT EXISTS categories (
  key TEXT PRIMARY KEY,
  name_zh TEXT,
  name_en TEXT,
  id_column TEXT DEFAULT '',
  wowhead_type TEXT DEFAULT '',
  description TEXT DEFAULT '',
  ord INTEGER DEFAULT 0
);
CREATE TABLE IF NOT EXISTS entries (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  category TEXT NOT NULL REFERENCES categories(key),
  en TEXT NOT NULL COLLATE NOCASE,
  zh TEXT DEFAULT '',
  zh_tw TEXT DEFAULT '',
  ref_id TEXT DEFAULT '',
  status TEXT DEFAULT 'confirmed',
  notes TEXT DEFAULT '',
  source TEXT DEFAULT '',
  attrs TEXT DEFAULT '{}',
  updated TEXT DEFAULT (datetime('now')),
  UNIQUE(category, ref_id, en)
);
CREATE INDEX IF NOT EXISTS idx_entries_cat ON entries(category);
CREATE INDEX IF NOT EXISTS idx_entries_ref ON entries(category, ref_id);
CREATE INDEX IF NOT EXISTS idx_entries_en  ON entries(en COLLATE NOCASE);
"""


def _detail_ddl():
    out = []
    for table, cols in DETAIL_TABLES.items():
        cols_sql = "".join(",\n  %s TEXT DEFAULT ''" % c for c in cols)
        out.append(
            "CREATE TABLE IF NOT EXISTS %s (\n"
            "  entry_id INTEGER PRIMARY KEY REFERENCES entries(id) ON DELETE CASCADE%s\n"
            ");" % (table, cols_sql)
        )
    return "\n".join(out)


def _view_ddl():
    out = []
    for cat, (table, _mapping) in CATEGORY_DETAIL.items():
        cols = DETAIL_TABLES[table]
        extra = "".join(",\n  d.%s" % c for c in cols)
        out.append(
            "CREATE VIEW IF NOT EXISTS v_%s AS\n"
            "SELECT e.id AS entry_id, e.en, e.zh, e.ref_id, e.status, e.notes%s\n"
            "FROM entries e LEFT JOIN %s d ON d.entry_id = e.id\n"
            "WHERE e.category = '%s';" % (cat, extra, table, cat)
        )
    return "\n".join(out)


def get_conn(path=DB_PATH):
    conn = sqlite3.connect(path)
    conn.execute("PRAGMA foreign_keys = ON")
    _ensure_columns(conn)
    return conn


def _ensure_columns(conn):
    """对已存在的库补加新增列（CREATE TABLE IF NOT EXISTS 不会给旧表加列）。"""
    tbl = conn.execute(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='entries'").fetchone()
    if not tbl:
        return
    cols = {r[1] for r in conn.execute("PRAGMA table_info(entries)")}
    if 'zh_tw' not in cols:
        conn.execute("ALTER TABLE entries ADD COLUMN zh_tw TEXT DEFAULT ''")


def init_db(conn):
    conn.executescript(SCHEMA)
    conn.executescript(_detail_ddl())
    conn.executescript(_view_ddl())
    _ensure_columns(conn)
    cur = conn.execute("SELECT COUNT(*) FROM categories")
    if cur.fetchone()[0] == 0:
        conn.executemany(
            "INSERT INTO categories (key,name_zh,name_en,id_column,wowhead_type,description,ord) VALUES (?,?,?,?,?,?,?)",
            CATEGORY_REGISTRY,
        )
        conn.commit()


def upsert(conn, category, en, zh='', ref_id='', detail=None, attrs=None,
           status='confirmed', notes='', source='', zh_tw=''):
    """写入/更新一条词条，同步写入明细表。返回 entries.id。"""
    detail = detail or {}
    attrs = attrs or {}
    conn.execute(
        """INSERT INTO entries (category, en, zh, zh_tw, ref_id, status, notes, source, attrs, updated)
           VALUES (?,?,?,?,?,?,?,?,?, datetime('now'))
           ON CONFLICT(category, ref_id, en) DO UPDATE SET
             zh=excluded.zh, zh_tw=excluded.zh_tw, status=excluded.status, notes=excluded.notes,
             source=excluded.source, attrs=excluded.attrs, updated=datetime('now')""",
        (category, en, zh, zh_tw, ref_id, status, notes, source,
         json.dumps(attrs, ensure_ascii=False)),
    )
    row = conn.execute(
        "SELECT id FROM entries WHERE category=? AND ref_id=? AND en=?",
        (category, ref_id, en)).fetchone()
    if not row:
        return None
    eid = row[0]
    if category in CATEGORY_DETAIL:
        table = CATEGORY_DETAIL[category][0]
        cols = DETAIL_TABLES[table]
        # 仅在显式传入明细值时写行：避免产生全空噪声行，也避免误清空已有明细
        if cols and detail:
            conn.execute(
                "INSERT OR REPLACE INTO %s (entry_id,%s) VALUES (%s)"
                % (table, ",".join(cols), ",".join(["?"] * (len(cols) + 1))),
                [eid] + [str(detail.get(c, '')) for c in cols],
            )
    return eid


def lookup(conn, en, category=None, partial=False):
    """英 → 中匹配（en 列 NOCASE，大小写不敏感）。"""
    if partial:
        q = "SELECT category, en, zh, zh_tw, ref_id, status FROM entries WHERE en LIKE ?"
        params = ['%' + en + '%']
    else:
        q = "SELECT category, en, zh, zh_tw, ref_id, status FROM entries WHERE en = ?"
        params = [en]
    if category:
        q += " AND category=?"
        params.append(category)
    return conn.execute(q + " ORDER BY category, en", params).fetchall()


def fetch_entries(conn, category=None, status=None, detail_filter=None):
    """有明细表的分类走视图（输出含明细真列），否则输出核心列。"""
    if category and category in CATEGORY_DETAIL:
        cols = DETAIL_TABLES[CATEGORY_DETAIL[category][0]]
        q = "SELECT * FROM v_%s" % category
        clauses, params = [], []
        if status:
            clauses.append("status=?")
            params.append(status)
        if detail_filter:
            k, v = detail_filter.split('=', 1)
            k, v = k.strip(), v.strip()
            if k not in cols:
                raise ValueError("未知明细列 %r（%s 可用：%s）" % (k, category, ",".join(cols)))
            clauses.append("%s=?" % k)
            params.append(v)
        if clauses:
            q += " WHERE " + " AND ".join(clauses)
        return conn.execute(q + " ORDER BY en", params).fetchall()

    q = "SELECT category, en, zh, ref_id, status, notes FROM entries"
    clauses, params = [], []
    if category:
        clauses.append("category=?")
        params.append(category)
    if status:
        clauses.append("status=?")
        params.append(status)
    if clauses:
        q += " WHERE " + " AND ".join(clauses)
    rows = conn.execute(q + " ORDER BY category, en", params).fetchall()
    if detail_filter:
        raise ValueError("分类 %s 无明细表，不支持 --detail" % (category or '(全部)'))
    return rows


def lua_str(s):
    s = s.replace('\\', '\\\\').replace('"', '\\"')
    return '"' + s + '"'


def split_ids(ref_id):
    if not ref_id:
        return []
    return [p.strip() for p in ref_id.split(',') if p.strip()]


def export_lua(conn, category=None):
    cats = [category] if category else [r[0] for r in conn.execute("SELECT key FROM categories ORDER BY ord")]
    reg = {c[0]: c for c in CATEGORY_REGISTRY}
    out = ["-- Auto-generated from _wow_dict.db (do not edit by hand)", "local D = {}"]
    for cat in cats:
        rows = conn.execute(
            "SELECT en, zh, zh_tw, ref_id FROM entries WHERE category=? ORDER BY en", (cat,)).fetchall()
        out.append("D.%s = {" % cat)
        for en, zh, zh_tw, ref_id in rows:
            out.append("  [%s] = %s," % (lua_str(en), lua_str(zh) if zh else 'nil'))
        out.append("}")
        out.append("D.%s_tw = {" % cat)
        for en, zh, zh_tw, ref_id in rows:
            out.append("  [%s] = %s," % (lua_str(en), lua_str(zh_tw) if zh_tw else 'nil'))
        out.append("}")
        id_col = reg[cat][3] if cat in reg else ''
        if id_col:
            out.append("D.%s_by_id = {" % cat)
            for en, zh, zh_tw, ref_id in rows:
                if not zh:
                    continue
                for pid in split_ids(ref_id):
                    out.append("  [%s] = %s," % (pid, lua_str(zh)))
            out.append("}")
            out.append("D.%s_by_id_tw = {" % cat)
            for en, zh, zh_tw, ref_id in rows:
                if not zh_tw:
                    continue
                for pid in split_ids(ref_id):
                    out.append("  [%s] = %s," % (pid, lua_str(zh_tw)))
            out.append("}")
    out.append("return D")
    return "\n".join(out)


def export_csv(conn, category=None):
    import csv
    import io
    buf = io.StringIO()
    w = csv.writer(buf)
    if category and category in CATEGORY_DETAIL:
        cols = DETAIL_TABLES[CATEGORY_DETAIL[category][0]]
        rows = conn.execute("SELECT * FROM v_%s ORDER BY en" % category).fetchall()
        w.writerow(['entry_id', 'en', 'zh', 'ref_id', 'status', 'notes'] + cols)
        for r in rows:
            w.writerow(r)
        return buf.getvalue()
    w.writerow(['category', 'en', 'zh', 'ref_id', 'status', 'notes', 'attrs'])
    q = "SELECT category,en,zh,ref_id,status,notes,attrs FROM entries"
    params = []
    if category:
        q += " WHERE category=?"
        params.append(category)
    for r in conn.execute(q + " ORDER BY category, en", params):
        w.writerow(r)
    return buf.getvalue()


def cmd_init(args):
    conn = get_conn()
    init_db(conn)
    conn.close()
    print("OK: database initialized at", DB_PATH)


def cmd_rebuild(args):
    """清空并重建全部表/视图，然后从 MD 全量重新导入。

    不删 DB 文件（受限环境下 os.remove 可能被安全策略拦截），改为 DROP 后重建。
    """
    import import_md as importer
    conn = get_conn()
    conn.execute("PRAGMA foreign_keys = OFF")
    for (name,) in conn.execute("SELECT name FROM sqlite_master WHERE type='view'").fetchall():
        conn.execute('DROP VIEW IF EXISTS "%s"' % name)
    for (name,) in conn.execute(
            "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'").fetchall():
        conn.execute('DROP TABLE IF EXISTS "%s"' % name)
    conn.commit()
    conn.execute("PRAGMA foreign_keys = ON")
    init_db(conn)
    n = importer.import_md(importer.MD_PATH, conn)
    conn.commit()
    conn.close()
    print("OK: rebuilt from %s, %d entries" % (importer.MD_PATH, n))


def _parse_kv(items):
    d = {}
    for a in items or []:
        k, v = a.split('=', 1)
        d[k.strip()] = v.strip()
    return d


def cmd_add(args):
    conn = get_conn()
    init_db(conn)
    eid = upsert(conn, args.category, args.en, args.zh or '', args.ref_id or '',
                 detail=_parse_kv(args.detail), attrs=_parse_kv(args.attr),
                 status=args.status, notes=args.notes or '', source=args.source,
                 zh_tw=args.zh_tw or '')
    conn.commit()
    conn.close()
    print("OK: upserted %s / %s (id=%s)" % (args.category, args.en, eid))


def cmd_query(args):
    conn = get_conn()
    rows = fetch_entries(conn, args.category, args.status, args.detail)
    for r in rows:
        print("\t".join('' if x is None else str(x) for x in r))
    print("-- %d rows" % len(rows))
    conn.close()


def cmd_lookup(args):
    conn = get_conn()
    rows = lookup(conn, args.en, args.category, args.partial)
    if not rows:
        print("(no match)")
    for cat, en, zh, zh_tw, ref_id, status in rows:
        print("%-12s %-40s %-30s %-30s id=%-12s %s"
              % (cat, en, zh or '(未译)', zh_tw or '(未译)', ref_id or '-', status))
    conn.close()


def cmd_stats(args):
    conn = get_conn()
    print("%-12s %-8s %-12s %s" % ("category", "total", "unconfirmed", "detail_table"))
    for (key,) in conn.execute("SELECT key FROM categories ORDER BY ord"):
        total = conn.execute("SELECT COUNT(*) FROM entries WHERE category=?", (key,)).fetchone()[0]
        unconf = conn.execute(
            "SELECT COUNT(*) FROM entries WHERE category=? AND status='unconfirmed'", (key,)).fetchone()[0]
        tbl = CATEGORY_DETAIL.get(key, ('', ''))[0] or '-'
        print("%-12s %-8d %-12d %s" % (key, total, unconf, tbl))
    print("TOTAL %d" % conn.execute("SELECT COUNT(*) FROM entries").fetchone()[0])
    conn.close()


def cmd_export(args):
    conn = get_conn()
    text = export_lua(conn, args.category) if args.format == 'lua' else export_csv(conn, args.category)
    conn.close()
    if args.output:
        with open(args.output, 'w', encoding='utf-8') as f:
            f.write(text)
        print("OK: written to", args.output)
    else:
        print(text)


def main():
    p = argparse.ArgumentParser(description="WoW zhCN dictionary DB tool")
    sub = p.add_subparsers(dest='cmd')
    sub.add_parser('init')
    sub.add_parser('rebuild', help="清空并重建全部表，从 MD 全量重新导入")
    pa = sub.add_parser('add')
    pa.add_argument('--category', required=True)
    pa.add_argument('--en', required=True)
    pa.add_argument('--zh', default='')
    pa.add_argument('--zh-tw', default='', help='繁体中文译名')
    pa.add_argument('--ref-id', default='')
    pa.add_argument('--detail', action='append', help="明细真列 key=value，可重复")
    pa.add_argument('--attr', action='append', help="长尾兜底 attrs key=value，可重复")
    pa.add_argument('--status', default='confirmed')
    pa.add_argument('--notes', default='')
    pa.add_argument('--source', default='cli')
    pq = sub.add_parser('query')
    pq.add_argument('--category')
    pq.add_argument('--status')
    pq.add_argument('--detail', help="明细真列过滤 key=value")
    pl = sub.add_parser('lookup', help="英 → 中匹配")
    pl.add_argument('--en', required=True)
    pl.add_argument('--category')
    pl.add_argument('--partial', action='store_true', help="模糊匹配（LIKE %%en%%）")
    sub.add_parser('stats')
    pe = sub.add_parser('export')
    pe.add_argument('--format', choices=['lua', 'csv'], default='lua')
    pe.add_argument('--category')
    pe.add_argument('--output')
    args = p.parse_args()
    if not args.cmd:
        p.print_help()
        return
    {'init': cmd_init, 'rebuild': cmd_rebuild, 'add': cmd_add, 'query': cmd_query,
     'lookup': cmd_lookup, 'stats': cmd_stats, 'export': cmd_export}[args.cmd](args)


if __name__ == '__main__':
    main()
