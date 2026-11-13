#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""DB2 CSV（wago.tools）→ 词典库 的**通用**导入框架。

UiMap / Faction / Achievement 及后续 Spell / Item / Quest 等表共用，
保证下面这些规则对**所有分类**一致，避免各表逻辑漂移。

核心规则
1. **中英文对照是根本**，ID 等其余列仅辅助定位。
2. 按 **(英文名, 中文译名) 分组**：
   - 同 en **同译** → 合并为一条，`ref_id` 取**最小 ID**。
     （不存全部 ID：Torghast 这类副本层有 109 个 ID，塞进 ref_id 没必要；且库里若已按
     单个 ID 分开存着同 en 同译的旧行，合成 "a,b" 的新 ref_id 与哪条都不匹配，会凭空多出一行。）
     全部 ID 仅在 `--csv` 导出时给出，供人工核对。
   - 同 en **不同译** → **保留为独立条目**，各自带自己的 ID。
     同名不同译意味着它们是不同实体（不同成就 / 不同资料片声望 / 不同副本层），
     **ID 正是用来消歧的** —— 既不合并也不跳过：合并会丢译名，跳过会丢条目。
3. 英文名比较**大小写不敏感**（DB `en` 列 COLLATE NOCASE，精确归并会产生重复行）。
4. 译名比较前做**全半角标点归一化**：官方存在「邪气鞍座（11)」/「邪气鞍座（11）」
   这类仅格式差异的写法，不归一化会被误判成「同名不同译」。
"""
import re
import sys

if hasattr(sys.stdout, 'reconfigure'):
    try:
        sys.stdout.reconfigure(encoding='utf-8')
    except Exception:
        pass

CJK = re.compile(r'[\u4e00-\u9fff]')
_TRANS = str.maketrans({'（': '(', '）': ')', '，': ',', '：': ':', '！': '!', '？': '?'})


def has_cjk(s):
    """是否含中文（用于判定 zhCN 是否已本地化）"""
    return bool(CJK.search(s or ''))


def norm_zh(s):
    """全半角标点归一化，避免格式差异被误判为不同译名"""
    return (s or '').translate(_TRANS)


def merge_groups(pairs):
    """按 (en.lower(), norm_zh(zh)) 分组 → [{'en','zh','ids'}]，按最小 ID 升序

    - 同 en 同译 → 合并（多个 ID 同指一个译名）
    - 同 en 不同译 → 各自成条目（不同实体，靠 ref_id 区分）
    """
    groups = {}
    for i, a, b in sorted(pairs, key=lambda t: t[0]):
        key = (a.lower(), norm_zh(b))
        g = groups.get(key)
        if g is None:
            groups[key] = {'en': a, 'zh': b, 'ids': [i]}
        elif i not in g['ids']:
            g['ids'].append(i)
    return sorted(groups.values(), key=lambda g: g['ids'][0])


def summarize(groups, pairs):
    """打印分组统计，返回同名不同译的 {en_lower: [zh, ...]}"""
    print("\n== 按（英文名 + 译名）分组 ==")
    print("条目数 %d（由 %d 条对照合并而来）" % (len(groups), len(pairs)))
    print("单个条目最多对应 %d 个 ID" % (max(len(g['ids']) for g in groups) if groups else 0))
    by_en = {}
    for g in groups:
        by_en.setdefault(g['en'].lower(), []).append(g['zh'])
    multi = {k: v for k, v in by_en.items() if len(v) > 1}
    print("同名不同译 %d 个（**保留为独立条目，靠 ID 区分**）" % len(multi))
    for k, v in list(multi.items())[:12]:
        print("   %-40s -> %s" % (k, " / ".join(v)))
    if len(multi) > 12:
        print("   ... 另有 %d 个" % (len(multi) - 12))
    return multi


def compare_existing(conn, groups, category):
    """与库中现有条目比对 → (new, same, diff)。

    diff = 库中有同名条目但译名不同 → 这**不是冲突**，是不同实体，照常新增。
    """
    existing = {}
    for en, zh in conn.execute(
            "SELECT en, zh FROM entries WHERE category=?", (category,)):
        existing.setdefault(en.lower(), []).append(zh)
    new, same, diff = [], [], []
    for g in groups:
        k = g['en'].lower()
        if k not in existing:
            new.append(g)
        elif any(norm_zh(zh) == norm_zh(g['zh']) for zh in existing[k]):
            same.append(g)
        else:
            diff.append((g, existing[k]))
    return new, same, diff


def import_groups(conn, groups, category, source, dict_db):
    """写入词典库。

    同 en 同译、但库中那条没有 ID 的旧行先删掉，由带 ID 的数据取代
    （唯一键含 ref_id，否则会并存一条空 ID 的重复行）。
    """
    for g in groups:
        conn.execute("DELETE FROM entries WHERE category=? AND en=? AND zh=? "
                     "AND (ref_id IS NULL OR ref_id='')", (category, g['en'], g['zh']))
    for g in groups:
        dict_db.upsert(conn, category, g['en'], g['zh'],
                       ref_id=str(min(g['ids'])),
                       status='confirmed', notes='', source=source)
    conn.commit()
    return len(groups)
