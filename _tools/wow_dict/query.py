#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""一次性模糊查询（按英文片段 LIKE 检索 entries）。

统一入口已提供等价能力：`python main.py lookup --en <kw> --partial`。
本脚本保留为极简兜底，DB 路径自动取自 db.DB_PATH，无需 cd。

用法：
    python query.py "safari hat"
    python query.py "battle pet" "thrall"
"""
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
if HERE not in sys.path:
    sys.path.insert(0, HERE)
import db as dict_db  # noqa: E402

if hasattr(sys.stdout, 'reconfigure'):
    try:
        sys.stdout.reconfigure(encoding='utf-8')
    except Exception:
        pass

terms = sys.argv[1:] or ["safari hat", "battle pet bandage"]
conn = dict_db.get_conn()
for t in terms:
    print("=== %s ===" % t)
    rows = conn.execute(
        "SELECT category,en,zh FROM entries WHERE lower(en) LIKE ?",
        ("%" + t.lower() + "%",),
    ).fetchall()
    if not rows:
        print("  (none)")
    for r in rows:
        print("  ", r)
conn.close()
