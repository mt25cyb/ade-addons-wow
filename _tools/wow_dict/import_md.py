#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""将 _wow_dict_enUS_to_zhCN.md 的词条表解析并导入到 _wow_dict.db。

用法：
    python import_md.py            # 导入默认 MD
    python import_md.py path.md    # 导入指定 MD
可重复运行（按 category + ref_id + en 去重 upsert）。

字段流向：
    英文（英文原名） -> entries.en        中文 -> entries.zh
    各分类 ID 列     -> entries.ref_id    说明 -> entries.notes
    其余独有列       -> detail_<分类> 明细表的真列
                        （映射见 db.CATEGORY_DETAIL，不进 JSON attrs）
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import db as dict_db

TOOLS = os.path.dirname(os.path.abspath(__file__))
DB_PATH = dict_db.DB_PATH          # 权威库路径统一取 db.py（外部数据目录，勿在此重复定义）
MD_PATH = os.path.join(TOOLS, '_wow_dict_enUS_to_zhCN.md')


def classify(title):
    rules = [
        (('机制', '术语'), 'term'),
        (('玩法', '游戏内容'), 'gameplay'),
        (('资料片', '版本'), 'expansion'),
        (('种族',), 'race'),
        (('区域', '地理'), 'zone'),
        (('NPC', '角色'), 'npc'),
        (('怪物', '生物'), 'creature'),
        (('物件', '可交互', 'object'), 'object'),
        (('物品',), 'item'),
        (('任务',), 'quest'),
        (('成就',), 'achievement'),
        (('势力', '声望'), 'faction'),
    ]
    for kws, cat in rules:
        if any(k in title for k in kws):
            return cat
    return None


def norm(s):
    if s is None:
        return ''
    s = s.strip()
    if s in ('', '—', '-', '–', 'N/A', 'n/a', '待确认'):
        return ''
    return s


def split_row(line):
    line = line.strip()
    if line.startswith('|'):
        line = line[1:]
    if line.endswith('|'):
        line = line[:-1]
    return [c.strip() for c in line.split('|')]


def load_id_columns(conn):
    """ID 列名取自 categories 注册表，避免与 DB 两处维护。"""
    return {r[0]: (r[1] or '') for r in conn.execute("SELECT key, id_column FROM categories")}


def import_md(path, conn):
    # source 记录「数据真实来源」而非「导入渠道」。
    # 种子 MD 内数据来源多样（官方/wowhead/游戏内/用户确认）且未逐条记录，统一标为「初始数据」。
    source = '初始数据'
    id_columns = load_id_columns(conn)
    with open(path, encoding='utf-8') as f:
        lines = f.readlines()
    cur_cat = None
    i = 0
    n = len(lines)
    inserted = 0
    while i < n:
        stripped = lines[i].strip()
        if stripped.startswith('## '):
            cur_cat = classify(stripped[3:].strip())
            i += 1
            continue
        if stripped.startswith('|') and cur_cat:
            block = []
            while i < n and lines[i].lstrip().startswith('|'):
                block.append(lines[i].rstrip('\n'))
                i += 1
            if len(block) >= 2:
                header = split_row(block[0])
                id_col = id_columns.get(cur_cat, '')
                detail_map = dict_db.CATEGORY_DETAIL.get(cur_cat, ('', {}))[1]
                for bl in block[2:]:
                    cells = split_row(bl)
                    if len(cells) < len(header):
                        cells += [''] * (len(header) - len(cells))
                    else:
                        cells = cells[:len(header)]
                    row = dict(zip(header, cells))
                    en = norm(row.get('英文原名') or row.get('英文'))
                    if not en:
                        continue
                    zh = norm(row.get('中文'))
                    status = 'confirmed' if zh else 'unconfirmed'
                    ref_id = norm(row.get(id_col)) if id_col else ''
                    # 各分类独有列 -> 明细表真列
                    detail = {}
                    for orig, col in detail_map.items():
                        v = norm(row.get(orig))
                        if v:
                            detail[col] = v
                    notes = norm(row.get('说明'))
                    dict_db.upsert(conn, cur_cat, en, zh, ref_id,
                                   detail=detail, status=status,
                                   notes=notes, source=source)
                    inserted += 1
            continue
        i += 1
    conn.commit()
    return inserted


def main():
    path = sys.argv[1] if len(sys.argv) > 1 else MD_PATH
    conn = dict_db.get_conn(DB_PATH)
    dict_db.init_db(conn)
    n = import_md(path, conn)
    conn.close()
    print("OK: imported/upserted %d entries from %s" % (n, path))


if __name__ == '__main__':
    main()
