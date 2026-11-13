#!/usr/bin/env python
# -*- coding: utf-8 -*-
r"""
dedupe.py —— 清理词典库 `_wow_dict.db` 里真正的重复行

## 底层逻辑（合并规则）
词典的根本目的是「英文 → 中文」匹配。

- **同名同译 = 同一词条**：`(category, en, zh)` 三者相同即视为同一条目，**应合并**。
- 合并时把各行的 `ref_id` **全部纳入该词条**（`ref_id` 逗号分隔、多 ID 共存、去重），
  不视为冲突——同一词条可对应多个游戏内 ID（如 `Bilgewater Cartel` 同时是 `1133` 与 `2673`）。
- `ref_id` 是**可多值的属性**，不是合并判据；不同 `ref_id` 只要"同名同译"就并入同一词条。
- **同英文不同中文 = 不同实体**（如国服/台服异译、两件同名物品）：`zh` 不一致 → **不合并**，
  各自保留自己的 `ref_id`；查询时 `D.<cat>_by_id`（ID → 译名）靠 `ref_id` 精准定位。
- **同 ID 但英文名不同**（如 `Offhand Bunch of Orange Carrots` vs `Carrots`，同 item 251663）：
  不在"同名同译"合并范围内，本脚本**只列出供参考，不合并**（属异名同实体，留人工判定）。

## 保守原则（宁少勿错）
- 仅 `(category, en, zh)` 完全相同的多行才合并；保留「有 notes > updated 新 > id 大」的一行，
  被合并行的 id 与 pooled ref_ids 记入 `notes`（`merged_ids:` / `merged_ref_ids:`），不静默丢信息。
- 明细表孤儿行一并清理（ON DELETE CASCADE 之外兜底）。

## 用法
```
python dedupe.py --dry      # 只打印将合并的组 + 参考组
python dedupe.py --apply    # 真删
python dedupe.py --apply --category zone,faction
```
先跑 --dry 复核，再 --apply。
"""
import os
import sys
import argparse
import sqlite3

HERE = os.path.dirname(os.path.abspath(__file__))
if HERE not in sys.path:
    sys.path.insert(0, HERE)
import db as ddb  # noqa: E402


def pool_ref_ids(rows):
    """把组内所有行的 ref_id 去重合并（逗号分隔、保留顺序）。"""
    seen = []
    for r in rows:
        for part in (r['ref_id'] or '').split(','):
            p = part.strip()
            if p and p not in seen:
                seen.append(p)
    return ', '.join(seen)


def pick_keeper(rows):
    """选信息最全的一行作保留行：有 notes > updated 新 > id 大。"""
    return sorted(
        rows,
        key=lambda r: (bool(r['notes']), r['updated'] or '', r['id']),
        reverse=True)[0]


def merged_note(keeper, drops):
    """构造追加到 keeper.notes 的合并说明，不静默丢信息。"""
    pooled = pool_ref_ids(drops)
    parts = []
    if pooled:
        parts.append('merged_ref_ids: ' + pooled)
    parts.append('merged_ids: ' + ','.join(str(r['id']) for r in drops))
    return ' | '.join(parts)


def fetch_rows(conn, ids):
    sql = 'SELECT id, category, en, zh, ref_id, status, notes, updated FROM entries WHERE id IN (%s)' % ','.join('?' * len(ids))
    return [dict(r) for r in conn.execute(sql, ids)]


def main():
    ap = argparse.ArgumentParser()
    g = ap.add_mutually_exclusive_group(required=True)
    g.add_argument('--dry', action='store_true', help='只预演')
    g.add_argument('--apply', action='store_true', help='实际删除冗余行')
    ap.add_argument('--category', default='', help='限定分类（逗号分隔），默认全部')
    args = ap.parse_args()

    conn = ddb.get_conn()
    conn.row_factory = sqlite3.Row
    cats = [c.strip() for c in args.category.split(',') if c.strip()]
    cat_bind = cats if cats else []

    merges = []  # list of (keep_row, [drop_rows])

    # 合并：同名同译 (category, en, zh) 多行 → 合一，ref_id 全部纳入
    sql = ('SELECT GROUP_CONCAT(id) AS ids FROM entries '
           + (('WHERE category IN (%s) ' % ','.join('?' * len(cats))) if cats else '')
           + 'GROUP BY category, en, zh HAVING COUNT(*) > 1')
    for (ids,) in conn.execute(sql, cat_bind):
        ids = [int(i) for i in ids.split(',')]
        rows = fetch_rows(conn, ids)
        keep = pick_keeper(rows)
        drops = [r for r in rows if r['id'] != keep['id']]
        merges.append((keep, drops))

    # 参考：同 (category, ref_id) 但英文名不同（异名同实体，不合并，仅列出）
    sql_ref = ('SELECT category, ref_id, COUNT(DISTINCT en) AS nen, GROUP_CONCAT(DISTINCT en) AS ens '
               'FROM entries WHERE COALESCE(ref_id,"") <> "" '
               + (('AND category IN (%s) ' % ','.join('?' * len(cats))) if cats else '')
               + 'GROUP BY category, ref_id HAVING COUNT(DISTINCT en) > 1')
    ref_groups = list(conn.execute(sql_ref, cat_bind))

    tag = '[DRY-RUN（未改库）]' if args.dry else '[已改库]'
    merged_groups = merged_rows = 0

    for keep, drops in merges:
        pooled = pool_ref_ids([keep] + drops)
        note = merged_note(keep, drops)
        new_notes = (keep['notes'] + ' | ' if keep['notes'] else '') + note
        new_status = 'confirmed' if any(r['status'] == 'confirmed' for r in [keep] + drops) else keep['status']
        print('  ~ %-10s %-34s 保留 id=%s(ref=%s) ← 删 %s'
              % (keep['category'], (keep['en'] or '')[:34], keep['id'],
                 pooled or '-', ','.join(str(r['id']) for r in drops)))
        merged_groups += 1
        merged_rows += len(drops)
        if args.apply:
            conn.execute('UPDATE entries SET ref_id=?, notes=?, status=? WHERE id=?',
                         (pooled, new_notes, new_status, keep['id']))
            conn.execute('DELETE FROM entries WHERE id IN (%s)' % ','.join('?' * len(drops)),
                         [r['id'] for r in drops])
            for r in drops:
                for table in ddb.DETAIL_TABLES:
                    try:
                        conn.execute('DELETE FROM %s WHERE entry_id=?' % table, (r['id'],))
                    except Exception:
                        pass

    if args.apply:
        conn.commit()

    print('%s 合并组 %d · 删除冗余行 %d' % (tag, merged_groups, merged_rows))

    if ref_groups:
        print('\n[参考·未合并] 同 ID 但英文名不同的异名同实体（%d 组，按"只合并同名同译"规则不动）:'
              % len(ref_groups))
        for category, ref_id, nen, ens in ref_groups:
            print('  ? %-10s ref=%s  %s' % (category, ref_id, ens))


if __name__ == '__main__':
    sys.stdout.reconfigure(encoding='utf-8')
    main()
