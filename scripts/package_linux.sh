#!/usr/bin/env bash
# Package the patched ScummVM + Willy-Beamish-CHT language assets into a relocatable
# Linux bundle (bin + bundled libs + assets + launcher) and a .tar.gz. Pure host
# file-ops; nothing installed system-wide. Output: dist/.
#
# The bundle relies on the user's SYSTEM glibc + display stack (GL/X11/Wayland) and
# bundles everything else (SDL2, freetype, fluidsynth, codecs). The user supplies
# their own legally-owned Willy Beamish game data (RESOURCE.MAP + RESOURCE.001).
set -euo pipefail
cd "$(dirname "$0")/.."
SV="${SCUMMVM:-$PWD/scummvm-src/scummvm}"
NAME="willy-cht-linux-x86_64"
OUT="dist/$NAME"
ASSETS=(build/zh.dtr build/beamish_zh24.dcjk build/beamish_zh16.dcjk)

[ -x "$SV" ] || { echo "ERROR: scummvm binary not found at $SV"; exit 1; }
rm -rf "$OUT"; mkdir -p "$OUT/bin" "$OUT/lib" "$OUT/share/willy-cht"

cp "$SV" "$OUT/bin/scummvm"

# Keep these from the user's SYSTEM (glibc/kernel + GPU/display stack must match host).
KEEP_SYSTEM='ld-linux|/libc\.|/libm\.|/libdl\.|/libpthread\.|/librt\.|/libresolv\.|linux-vdso|/libGL|/libGLX|/libGLdispatch|/libX11|/libxcb|/libXext|/libXcursor|/libXi|/libXrandr|/libXfixes|/libXrender|/libwayland|/libdrm|/libgbm|/libEGL|/libOpenGL'
echo "Bundling libraries (excluding system glibc/display stack)..."
ldd "$SV" | awk '{print $3}' | grep -E '^/' | sort -u | while read -r lib; do
  if echo "$lib" | grep -qE "$KEEP_SYSTEM"; then continue; fi
  cp -L "$lib" "$OUT/lib/" 2>/dev/null && echo "  + $(basename "$lib")"
done

for a in "${ASSETS[@]}"; do
  [ -f "$a" ] && cp "$a" "$OUT/share/willy-cht/" || echo "  ! missing asset $a"
done

# Launcher: bundles libs via LD_LIBRARY_PATH; --extrapath makes the engine find the
# CJK assets via SearchMan regardless of the user's game directory.
cat > "$OUT/willy-cht.sh" <<'LAUNCH'
#!/usr/bin/env bash
# 威利奇遇記 繁體中文版 launcher.
# 用法: ./willy-cht.sh [你的遊戲資料夾]
#   給遊戲資料夾 -> 直接啟動並載入；不給 -> 開啟 ScummVM 啟動器自行加入遊戲。
# 遊戲中按 F8 循環顯示模式：中文24 / 中文16 / 英文(原始)。
HERE="$(cd "$(dirname "$0")" && pwd)"
export LD_LIBRARY_PATH="$HERE/lib:${LD_LIBRARY_PATH:-}"
SV="$HERE/bin/scummvm"; EXTRA="$HERE/share/willy-cht"
has_game() { [ -f "$1/resource.map" ] || [ -f "$1/RESOURCE.MAP" ]; }
if [ $# -ge 1 ] && [ -d "$1" ]; then
  exec "$SV" --extrapath="$EXTRA" --path="$1" beamish
fi
for base in "$HERE" "$PWD"; do
  has_game "$base" && exec "$SV" --extrapath="$EXTRA" --path="$base" beamish
  for d in "$base"/*/; do
    [ -d "$d" ] && has_game "$d" && exec "$SV" --extrapath="$EXTRA" --path="$d" beamish
  done
done
exec "$SV" --extrapath="$EXTRA"
LAUNCH
chmod +x "$OUT/willy-cht.sh"

cat > "$OUT/README.txt" <<'DOC'
威利奇遇記 The Adventures of Willy Beamish 繁體中文版 (patched ScummVM bundle)
============================================================================

把 Dynamix《The Adventures of Willy Beamish》(1992) 中文化的 patched ScummVM。
中文是「疊」在原始英文遊戲上的 overlay，不會改動你的遊戲檔。

需要準備
  你自己合法擁有的一份 Willy Beamish 遊戲資料夾（內含 RESOURCE.MAP + RESOURCE.001）。

啟動（三選一）
  1) 自動偵測：把本資料夾放到「遊戲資料夾旁邊」或「遊戲資料夾裡」，執行 ./willy-cht.sh。
  2) 指定路徑：   ./willy-cht.sh /路徑/到/你的/遊戲資料夾
  3) 用啟動器：   ./willy-cht.sh （找不到遊戲時）會開 ScummVM 介面，手動加入遊戲一次即可。

預設就是中文（24×24）。遊戲中按 F8 循環：中文 24×24 → 中文 16×16 → 英文(原始)。

內容
  bin/scummvm          patched ScummVM（dgds 引擎 + CJK 模組）
  lib/                 隨附函式庫（SDL2、freetype、fluidsynth、codecs…）
  share/willy-cht/     語言資產：zh.dtr(中文翻譯)、beamish_zh24/16.dcjk(點陣字型)

說明
  - 本套件相依你系統的 glibc 與顯示(GL/X11/Wayland)堆疊，適用多數現代 x86_64 Linux。
  - 不含、也不重新發布任何遊戲原始檔；版權屬 Dynamix / Sierra 之權利繼承者。
DOC

mkdir -p dist
( cd dist && tar czf "$NAME.tar.gz" "$NAME" )
echo "----"
echo "bundle : $OUT"
echo "tarball: dist/$NAME.tar.gz ($(du -h "dist/$NAME.tar.gz" | cut -f1))"
echo "libs bundled: $(ls "$OUT/lib" | wc -l)"
