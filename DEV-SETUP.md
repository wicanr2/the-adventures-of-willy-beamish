# 在另一台電腦重建整個開發環境

這份說明如何從 **dev tarball**（含原始素材與參考資料）在一台全新的機器上，**從零重建**整個《威利奇遇記》繁中化專案 —— 從 ISO 一路到四平台完整打包。

## 這包裡有什麼

| 路徑 | 是什麼 | 重建來源 |
|---|---|---|
| `*.iso` | **遊戲原始光碟映像**（master，受版權，僅供你個人）| 你的合法副本 |
| `攻略/*.pdf` | **參考資料**：《軟體世界》第 34、35 期 Willy 攻略掃描（作者阿寬）| 版權素材，研究用 |
| `docs/攻略/軟體世界-威利奇遇記-完全攻略.md` | 上述攻略**逐頁轉寫**（術語 oracle，免再 OCR）| git |
| `patches/` | ScummVM dgds 引擎 CHT + Android patch（**source of truth**）| git |
| `translations/zh.json` | 譯文（UTF-8）→ `build/zh.dtr` | git |
| `tools/` | 抽字 / 建字型 / 建 dtr / 生名牌 / Android 注入 | git |
| `scripts/` | Linux/AppImage/Windows 打包（含 FULL）| git |
| `docs/` | DESIGN / 設計後記 / QA | git |
| `CONTEXT.md` | 譯名表 / ubiquitous language（含霍尼、電台在地化、忍者家族脈絡）| git |
| `build/android_libs/libc++_shared.so` | Android oboe 依賴的 arm64 runtime（**不易重建**，已附）| 隨包 |
| `setup-dev.sh` | **一鍵**：ISO→game→extracted→dialogs→CJK 資產→clone+patch+build ScummVM | — |
| `dialogs_en.json` | 英文對白 oracle（可由 ISO 重建，已附省時）| 可重建 |
| ~~`game/` `extracted/`~~ | **不在包裡** — `setup-dev.sh` 從 ISO 重建（game 148M / extracted 950M）| ISO |
| ~~`scummvm-src/`~~ | **不在包裡**（~900MB）— `setup-dev.sh` clone @ `ae89011b` 重建 | git clone |
| ~~`dist/`~~ | **不在包裡** — 打包輸出，重建即生成 | 重建 |

## 重建步驟（Debian/Ubuntu）

```bash
tar xzf willy-cht-DEV+MATERIALS.tar.gz && cd willy

# 依賴
sudo apt install build-essential git libsdl2-dev libfreetype-dev libpng-dev \
                 p7zip-full python3-pip docker.io fonts-noto-cjk
python3 -m pip install --user freetype-py pillow   # 重建字型用

# 一鍵：ISO → game/ → extracted/ → dialogs_en.json → CJK 資產 → patched ScummVM
bash setup-dev.sh

# 設環境變數（package 腳本靠這個找引擎）
export SCUMMVM_SRC="$PWD/scummvm-src"
export SCUMMVM="$SCUMMVM_SRC/scummvm"

# 打包
bash scripts/package_linux.sh           # dist/willy-cht-linux-x86_64
bash scripts/package_appimage.sh        # 引擎包 AppImage
bash scripts/package_appimage_full.sh   # FULL AppImage（內嵌遊戲，下載即玩）
bash scripts/build_windows.sh           # Docker mingw 交叉編譯 → Windows zip
```

跑完 `setup-dev.sh`，直接執行 `scummvm-src/scummvm -p game --gfx-mode=2x beamish` 即可遊玩驗證（F8 切中24/中16/英文）。

## 改東西時

- **只改翻譯**：編 `translations/zh.json` → `python3 tools/build_translation.py translations/zh.json build/zh.dtr` → 部署各平台的 `zh.dtr`（Linux `share/willy-cht/`、Win/Mac `extra/`、Android bundle、AppImage 在映像內）。**免重編引擎**。
  - 撈名牌：`python3 tools/gen_ui_names.py`（從 en/zh 平行資料生 `UI:<名>`）。
  - 撈 TTM 畫面字：`python3 tools/extract_ttm_strings.py extracted/ build/ttm_strings.json`。
- **改引擎**：改 `scummvm-src/engines/dgds/*` → `make` → 重產 patch：
  `(cd scummvm-src && git add engines/dgds && git diff --cached -- engines/dgds) > patches/dgds-cjk.patch` → 全平台重編。
- **commit/push**：remote = `git@github.com:wicanr2/the-adventures-of-willy-beamish.git`。
  遊戲 / ISO / `攻略/*.pdf` / `extracted/` / `dist/` / `scummvm-src/` / `screenshots/_*` 全 gitignore，**永不 push**。

## macOS / Android（走 CI）

macOS `.app` 與 Android base APK 由 GitHub Actions 編（`.github/workflows/build.yml`，push `patches/**`、`translations/**`、`tools/**` 觸發）：

```bash
gh run download <run-id> -n willy-cht-macos   -D dist/ci_macos    # macOS .app（arm64）
gh run download <run-id> -n willy-cht-android -D dist/ci_android  # Android base APK
tools/inject_android.sh                                           # 注入遊戲+CJK+oboe → FULL APK
```

## Willy 專案要點（與 ROTD/HOC 的差異）

- 封裝 `RESOURCE.MAP`+`RESOURCE.001`、SDS/DDS 版本 **`" 1.224"`**、對白在 **68 個 `D#.DDS`**（鍵 `<DDS檔號>:<num>`）。
- talkie CD 版：`.cds`/`.tds` 是語音+頭像（無可譯文字），字幕文字在 DDS `_str`。
- game id `beamish`、patch base `ae89011b`。
- 完整 SOP 與所有踩過的坑見 skill `rise-of-the-dragon-cht`（§9 Willy）。
