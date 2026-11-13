#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Wowhead / Google 兜底抓取（词典库「先查词典、缺失再抓」工作流的 Wowhead 侧）。

**保留原词典库的 Google `site:www.wowhead.com` 检索方式**，并做工程化封装与优化：
- `google_site_query(keyword)`：构造原方法的标准 Google 查询 URL（保留 `site:www.wowhead.com`）；
  专有名词默认加引号，规避 wowhead 站内搜索对撇号/特殊字符不友好的问题。
- `wowhead_search_url(keyword, wh_type)`：直接 wowhead 站内搜索 URL（更稳的备选入口）。
- `fetch_zhcn(keyword, wh_type, timeout)`：best-effort 抓取候选中文名；无网络/解析失败返回 None。

设计：本模块只产出「查询入口」与「尽力而为的候选名」，**不主动批量灌数据**；
真正写入由 `resolve.py` 在按需命中后调用 `dict_db.upsert` 完成（且默认标 unconfirmed，禁止臆造）。
"""
import re
import sys
import urllib.parse
import urllib.request

if hasattr(sys.stdout, 'reconfigure'):
    try:
        sys.stdout.reconfigure(encoding='utf-8')
    except Exception:
        pass

GOOGLE = "https://www.google.com/search"
WOWHEAD_SEARCH = "https://www.wowhead.com/search"

# 质量色链接（q0..q9）是 wowhead 结果里最稳定的「实体名」标记
_TITLE = re.compile(r'<a[^>]+class="[^"]*\bq[0-9]\b[^"]*"[^>]*>([^<]+)</a>')
_CJK = re.compile(r'[\u4e00-\u9fff]+')


def google_site_query(keyword, quoted=True):
    """原词典库方法：`{keyword} site:www.wowhead.com`（专有名词加引号更稳）。"""
    q = '"%s"' % keyword if quoted else keyword
    return GOOGLE + "?q=" + urllib.parse.quote(q + " site:www.wowhead.com")


def wowhead_search_url(keyword, wh_type=None):
    """直接 wowhead 站内搜索；wh_type 如 npc/item/quest/spell 可拼成专属页。"""
    if wh_type:
        return "https://www.wowhead.com/%s=%s" % (wh_type, urllib.parse.quote(keyword))
    return WOWHEAD_SEARCH + "?q=" + urllib.parse.quote(keyword)


def _fetch_text(url, timeout=8):
    req = urllib.request.Request(
        url, headers={'User-Agent': 'Mozilla/5.0 (compatible; WoWDictTool/1.0)'})
    with urllib.request.urlopen(req, timeout=timeout) as r:
        return r.read().decode('utf-8', 'replace')


def fetch_zhcn(keyword, wh_type=None, timeout=8):
    """尽力而为：抓 wowhead 搜索结果首项的中文名。失败/无中文返回 None。"""
    try:
        html = _fetch_text(wowhead_search_url(keyword, wh_type), timeout)
    except Exception:
        return None
    for m in _TITLE.finditer(html):
        name = m.group(1).strip()
        if _CJK.search(name):
            return name
    return None


def main():
    import argparse
    ap = argparse.ArgumentParser(description="Wowhead/Google 兜底检索入口")
    ap.add_argument('--keyword', required=True)
    ap.add_argument('--type', default=None, help='wowhead 类型 npc/item/quest/spell...')
    ap.add_argument('--fetch', action='store_true', help='尝试 best-effort 抓中文名')
    args = ap.parse_args()
    print("Google site:wowhead :", google_site_query(args.keyword))
    print("Wowhead search      :", wowhead_search_url(args.keyword, args.type))
    if args.fetch:
        name = fetch_zhcn(args.keyword, args.type)
        print("候选中文名        :", name or "(未取到 / 无网络)")


if __name__ == '__main__':
    main()
