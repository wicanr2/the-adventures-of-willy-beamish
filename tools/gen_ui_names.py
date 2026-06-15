#!/usr/bin/env python3
"""Generate UI:<NAME> name-plate translations from the parallel en/zh dialog data.

drawType2 (kDlgFrameBorder) dialogs render the "NAME:" before the first CR as a
separate header plate (drawHeader -> lookupUI("UI:"+trim(name))). To translate the
plate we add UI:<english name> -> <chinese name>. The Chinese name is taken from the
matching translation's own "名字：" prefix, so the plate and body stay consistent.

Usage: gen_ui_names.py            # merge generated UI:<name> entries into translations/zh.json
"""
import json, os, re, collections

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
EN = os.path.join(ROOT, 'dialogs_en.json')
ZH = os.path.join(ROOT, 'translations', 'zh.json')


def en_title(text):
    """Mirror drawType2: title = text before ':' iff ':' is immediately followed by CR."""
    cp = text.find(':')
    if cp < 0 or cp + 1 >= len(text) or text[cp + 1] != '\r':
        return None
    return text[:cp].strip()


def zh_title(text):
    """Chinese prefix before the first fullwidth/ascii colon that precedes the first CR."""
    cr = text.find('\r')
    if cr < 0:
        return None
    head = text[:cr]
    m = re.match(r'^(.*?)[：:]$', head)
    return m.group(1).strip() if m else None


def main():
    en = json.load(open(EN, encoding='utf-8'))
    zh = json.load(open(ZH, encoding='utf-8'))
    # english name -> Counter of chinese names (pick the majority)
    votes = collections.defaultdict(collections.Counter)
    for x in en:
        key = f"{x['file']}:{x['num']}"
        ename = en_title(x['text'])
        if not ename or key not in zh:
            continue
        cname = zh_title(zh[key])
        if cname:
            votes[ename][cname] += 1
    added = 0
    for ename, c in votes.items():
        cname = c.most_common(1)[0][0]
        uikey = f"UI:{ename}"
        if zh.get(uikey) != cname:
            zh[uikey] = cname
            added += 1
    json.dump(zh, open(ZH, 'w', encoding='utf-8'), ensure_ascii=False, indent=1)
    print(f"# generated {len(votes)} name plates, {added} new/updated -> {ZH}")
    # show a sample
    for ename in list(votes)[:12]:
        print(f"   UI:{ename} -> {zh['UI:'+ename]}")


if __name__ == '__main__':
    main()
