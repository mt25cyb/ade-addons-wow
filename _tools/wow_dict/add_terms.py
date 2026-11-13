#!/usr/bin/env python
# -*- coding: utf-8 -*-
r"""
add_terms.py —— 把「已核实的通用 WoW 术语」写入全局词典 DB（幂等、非破坏性）

背景：原项目（RXPGuides 汉化补全）逐条核实了一批 wowhead CN 官方译名。它们是**通用 WoW 术语**，
      应进全局词典 `_wow_dict.db`（权威库在工作区外部数据目录 D:\Dev-Workspace\_wow_dict\）。

为什么不用 `rebuild`：rebuild = 删库重建并只从 MD 导入，会**清掉 DB2 导入的 1.4 万条数据**
      （zone 881 / faction 412 / achievement 12749 等）。本脚本只做增量：
      ① 补 categories 行并调整 ord；② 词条 upsert（唯一键 category+ref_id+en）。

新增分类：spell（技能/法术，ID 列 `spellID`，wowhead type `spell`）
      —— 不建 detail 表：当前无稳定额外字段，遵循「有实证来源才建表，不建空表」。

用法：
  python _tools/wow_dict/add_terms.py # 写入并打印统计（或走 main.py add-terms）
"""
import os
import sys
import sqlite3

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import db as dict_db  # noqa: E402

# ---------------------------------------------------------------- 分类注册
# 插入 spell 到 item 之后（ord 8），其后分类顺延
NEW_CATEGORY = ('spell', '技能/法术', 'Spell', 'spellID', 'spell', '法术/技能名（ID 为 spellID）', 8)
ORD_SHIFT = [('quest', 9), ('achievement', 10), ('faction', 11), ('gameplay', 12), ('term', 13)]

# ---------------------------------------------------------------- 词条
# (category, en, zh, ref_id, notes)
# source 统一为 wowhead（译名取自 wowhead CN 的客户端数据，非印象/机翻）
TERMS = [
    # ---- 技能/法术：驭空术（skyriding） ----
    ('spell', 'Whirling Surge', '回旋急冲', '361584', '驭空术技能；RXP Skyriding Glyphs 高频句'),
    ('spell', 'Skyward Ascent', '冲天升腾', '372610', '驭空术技能；作向上抬升用'),
    ('spell', 'Second Wind', '复苏之风', '425782',
     '驭空术技能（立即恢复一层充能）。注意：战士同名天赋 Second Wind 也是「复苏之风」，'
     '但 spellID 不同（29838/29842），靠 ref_id 区分'),
    # ---- 技能/法术：职业 ----
    ('spell', 'Flash Heal', '快速治疗', '2061', '牧师'),
    ('spell', "Nature's Cure", '自然之愈', '88423', '德鲁伊；非「自然治愈」'),
    ('spell', 'Resurrection', '复活', '213109', '复活类法术；多职业同名，按 spellID 区分'),
    ('spell', 'Runeforging', '符文熔铸', '53428', '死亡骑士'),
    ('spell', 'Eye of Acherus', '阿彻鲁斯之眼', '57532', '死亡骑士'),
    # ---- 技能/法术：坐骑 / 任务光环 ----
    ('spell', 'Summon Random Favorite Mount', '随机召唤偏好的坐骑', '150544',
     '坐骑召唤；favorite 官方译「偏好」（非「收藏」）'),
    ('spell', 'Tree Disguise', '大树伪装', '30298',
     '任务光环；来自物品 23792 树伪装工具包'),
    # ---- 物品 ----
    ('item', 'Tree Disguise Kit', '树伪装工具包', '23792', '任务物品；施加光环「大树伪装」(30298)'),
    # ---- 玩法 ----
    ('gameplay', 'Skyriding', '驭空术', '', '原称 Dragonriding（驭龙术），10.x 起更名'),
    ('gameplay', 'Lorewalking', '游学探奇', '',
     '11.1.7 玩法；官方译名佐证：任务 85885「Lorewalking: No King Rules Forever」→「游学探奇：王权没有永恒」'),
]


def ensure_category(conn):
    conn.execute(
        "INSERT OR REPLACE INTO categories (key,name_zh,name_en,id_column,wowhead_type,description,ord)"
        " VALUES (?,?,?,?,?,?,?)", NEW_CATEGORY)
    for key, o in ORD_SHIFT:
        conn.execute("UPDATE categories SET ord=? WHERE key=?", (o, key))
    conn.commit()


def main():
    conn = dict_db.get_conn()
    dict_db.init_db(conn)
    ensure_category(conn)

    for cat, en, zh, ref_id, notes in TERMS:
        dict_db.upsert(conn, cat, en, zh=zh, ref_id=ref_id,
                       status='confirmed', notes=notes, source='wowhead')
    conn.commit()

    print('已写入 %d 条术语' % len(TERMS))
    rows = conn.execute(
        "SELECT category, COUNT(*) FROM entries GROUP BY category ORDER BY category").fetchall()
    print('\n分类统计：')
    for c, n in rows:
        print('  %-12s %6d' % (c, n))
    print('  %-12s %6d' % ('TOTAL', sum(n for _, n in rows)))

    print('\nspell 分类内容：')
    for en, zh, rid in conn.execute(
            "SELECT en, zh, ref_id FROM entries WHERE category='spell' ORDER BY CAST(ref_id AS INTEGER)"):
        print('  %-32s %-12s spellID=%s' % (en, zh, rid))
    conn.close()


if __name__ == '__main__':
    sys.stdout.reconfigure(encoding='utf-8')
    main()
