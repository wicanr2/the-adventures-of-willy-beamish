#!/usr/bin/env python3
"""Merge all per-batch translations (build/batches/zh_*.json) into
translations/zh.json, validate Big5, and report coverage vs dialogs_en.json.

Willy Beamish keys dialogs by "<ddsFileNum>:<num>" (already the batch key).
Usage:
  merge_translations.py merge      # merge build/batches/zh_*.json -> translations/zh.json
  merge_translations.py coverage   # just report coverage + Big5 status
"""
import json, sys, glob, os

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ZH = os.path.join(ROOT, 'translations', 'zh.json')
EN = os.path.join(ROOT, 'dialogs_en.json')


def load(p):
    try:
        return json.load(open(p, encoding='utf-8'))
    except FileNotFoundError:
        return {}


def en_keys():
    en = json.load(open(EN, encoding='utf-8'))
    return {f"{x['file']}:{x['num']}": x['text'] for x in en}


def check_big5(zh):
    bad = []
    for k, v in zh.items():
        try:
            v.encode('big5')
        except UnicodeEncodeError as e:
            bad.append((k, v[e.start:e.end]))
    return bad


def main():
    cmd = sys.argv[1] if len(sys.argv) > 1 else 'coverage'
    zh = load(ZH)
    if cmd == 'merge':
        added = 0
        for bf in sorted(glob.glob(os.path.join(ROOT, 'build', 'batches', 'zh_*.json'))):
            batch = json.load(open(bf, encoding='utf-8'))
            for k, v in batch.items():
                if k not in zh:
                    added += 1
                zh[k] = v
        os.makedirs(os.path.dirname(ZH), exist_ok=True)
        json.dump(zh, open(ZH, 'w', encoding='utf-8'), ensure_ascii=False, indent=1)
        print(f"# merged batches -> {ZH} ({added} new, {len(zh)} total)")
    keys = en_keys()
    dlg_done = sum(1 for k in keys if k in zh and zh[k])
    ui = sum(1 for k in zh if k.startswith('UI:'))
    bad = check_big5(zh)
    print(f"dialogue: {dlg_done}/{len(keys)} slots translated "
          f"({100*dlg_done//max(1,len(keys))}%)")
    print(f"UI: {ui} strings, total entries: {len(zh)}")
    if bad:
        print(f"!! {len(bad)} entries have non-Big5 chars:")
        for k, c in bad[:20]:
            print(f"   {k}: {c!r}")
    else:
        print("Big5: all entries OK")


if __name__ == '__main__':
    main()
