#!/usr/bin/env bash
# Build a SELF-CONTAINED (game-included) single-file AppImage: patched engine + CJK assets +
# the game data, so it's download-and-play with zero setup. FOR PERSONAL ARCHIVAL of a game you
# legally own -- do NOT redistribute (it embeds copyrighted game data).
# Output: dist/Willy-Beamish-CHT-FULL-x86_64.AppImage
set -euo pipefail
cd "$(dirname "$0")/.."
BUNDLE="dist/willy-cht-linux-x86_64"
APPDIR="dist/Willy-CHT-FULL.AppDir"
OUT="dist/Willy-Beamish-CHT-FULL-x86_64.AppImage"
[ -d "$BUNDLE" ] || { echo "run scripts/package_linux.sh first (need $BUNDLE)"; exit 1; }
[ -f game/RESOURCE.MAP ] || { echo "game/ missing RESOURCE.MAP"; exit 1; }

rm -rf "$APPDIR"
mkdir -p "$APPDIR/usr/bin" "$APPDIR/usr/lib" "$APPDIR/usr/share/willy-cht"
cp "$BUNDLE/bin/scummvm"          "$APPDIR/usr/bin/"
cp -r "$BUNDLE/lib/."             "$APPDIR/usr/lib/"
cp -r "$BUNDLE/share/willy-cht/." "$APPDIR/usr/share/willy-cht/"
# embed the game data (copyrighted -> personal archival only)
cp -a game                        "$APPDIR/game"

cat > "$APPDIR/AppRun" <<'RUN'
#!/usr/bin/env bash
HERE="$(dirname "$(readlink -f "$0")")"
export LD_LIBRARY_PATH="$HERE/usr/lib:${LD_LIBRARY_PATH:-}"
SV="$HERE/usr/bin/scummvm"; EXTRA="$HERE/usr/share/willy-cht"
has_game() { [ -f "$1/resource.map" ] || [ -f "$1/RESOURCE.MAP" ]; }
# 1) explicit path
if [ $# -ge 1 ] && [ -d "$1" ]; then
  exec "$SV" --extrapath="$EXTRA" --path="$1" beamish
fi
# 2) the game bundled INSIDE this AppImage -> download-and-play, no setup
if has_game "$HERE/game"; then
  exec "$SV" --extrapath="$EXTRA" --path="$HERE/game" beamish
fi
# 3) fall back to a game next to the .AppImage / CWD
APPDIR_OF_IMG="$(dirname "$(readlink -f "${APPIMAGE:-$0}")")"
for base in "$APPDIR_OF_IMG" "$PWD"; do
  has_game "$base" && exec "$SV" --extrapath="$EXTRA" --path="$base" beamish
done
exec "$SV" --extrapath="$EXTRA"
RUN
chmod +x "$APPDIR/AppRun"

cat > "$APPDIR/willy-cht.desktop" <<'DESK'
[Desktop Entry]
Type=Application
Name=Willy Beamish CHT (FULL)
Comment=威利奇遇記 繁體中文版（含遊戲，自留）
Exec=AppRun
Icon=willy-cht
Categories=Game;
Terminal=false
DESK
ICON_SRC=""
for c in screenshots/title.png screenshots/dialogue_zh24.png; do [ -f "$c" ] && ICON_SRC="$c" && break; done
if command -v convert >/dev/null 2>&1 && [ -n "$ICON_SRC" ]; then
  convert "$ICON_SRC" -gravity center -resize 256x256^ -extent 256x256 "$APPDIR/willy-cht.png" 2>/dev/null || \
    convert -size 256x256 xc:black -fill white -gravity center -pointsize 40 -annotate 0 "威" "$APPDIR/willy-cht.png"
else
  convert -size 256x256 xc:black -fill white -gravity center -pointsize 40 -annotate 0 "威" "$APPDIR/willy-cht.png" 2>/dev/null || : > "$APPDIR/willy-cht.png"
fi
cp "$APPDIR/willy-cht.png" "$APPDIR/.DirIcon" 2>/dev/null || true

TOOL=/tmp/appimagetool-x86_64.AppImage
if [ ! -x "$TOOL" ]; then
  curl -fsSL -o "$TOOL" https://github.com/AppImage/appimagetool/releases/download/continuous/appimagetool-x86_64.AppImage
  chmod +x "$TOOL"
fi
ARCH=x86_64 "$TOOL" --appimage-extract-and-run "$APPDIR" "$OUT" 2>&1 | tail -4
rm -rf "$APPDIR"
ls -la "$OUT" 2>/dev/null && echo "FULL AppImage (含遊戲) -> $OUT ($(du -h "$OUT" | cut -f1))，下載即玩" \
  || echo "AppImage build did not produce output."
