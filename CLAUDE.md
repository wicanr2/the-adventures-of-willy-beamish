# CLAUDE.md — Willy Beamish 繁中化

ScummVM `dgds` 引擎遊戲 **The Adventures of Willy Beamish**（Dynamix 1992）的繁體中文化。
姊妹作 `Rise of the Dragon`（`~/rise-of-the-dragon/`）的 engine-side overlay 路線重用 — 詳見 skill `rise-of-the-dragon-cht`。

## 路線
不改遊戲資料；patch ScummVM 在繪字處攔截 → 查表（`zh.dtr`）→ 用點陣 CJK 字型（`beamish_zh{16,24}.dcjk`）重畫到 hi-res 疊圖層。F8 切語言。

## Willy 與 ROTD 的關鍵差異（必讀）
- 封裝：`RESOURCE.MAP` + `RESOURCE.001`（不是 `VOLUME.VGA`）。`tools/dgds_volume.py` 已支援。
- SDS 版本 **`" 1.224"`**（ROTD 是 `" 1.211"`）。
- **對話不在 SDS** — 在 68 個 `D#.DDS`，鍵 `<DDS檔號>:<num>`。
- talkie CD 版：`.cds`/`.tds` 是語音+頭像（無可譯文字）；字幕文字在 DDS `_str`。
- game id = `beamish`、`GID_WILLY`。

## 安全鐵則
遊戲/disc/`extracted/`/`dist/`/`scummvm-src/` 全 gitignore，**永不 push**。只 push 工具、patch、`translations/zh.json`、docs。

## Repo
`github.com/wicanr2/the-adventures-of-willy-beamish.git`
