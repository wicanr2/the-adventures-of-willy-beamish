#!/usr/bin/env bash
# Build a single-file AppImage from the relocatable Linux bundle. Assembles the AppDir
# on the host and runs appimagetool via --appimage-extract-and-run (no FUSE, no Docker).
# Output: dist/Willy-Beamish-CHT-x86_64.AppImage
set -euo pipefail
cd "$(dirname "$0")/.."
BUNDLE="dist/willy-cht-linux-x86_64"
APPDIR="dist/Willy-CHT.AppDir"
OUT="dist/Willy-Beamish-CHT-x86_64.AppImage"
[ -d "$BUNDLE" ] || { echo "run scripts/package_linux.sh first (need $BUNDLE)"; exit 1; }

rm -rf "$APPDIR"
mkdir -p "$APPDIR/usr/bin" "$APPDIR/usr/lib" "$APPDIR/usr/share/willy-cht"
cp "$BUNDLE/bin/scummvm"          "$APPDIR/usr/bin/"
cp -r "$BUNDLE/lib/."             "$APPDIR/usr/lib/"
cp -r "$BUNDLE/share/willy-cht/." "$APPDIR/usr/share/willy-cht/"

cat > "$APPDIR/AppRun" <<'RUN'
#!/usr/bin/env bash
HERE="$(dirname "$(readlink -f "$0")")"
export LD_LIBRARY_PATH="$HERE/usr/lib:${LD_LIBRARY_PATH:-}"
SV="$HERE/usr/bin/scummvm"; EXTRA="$HERE/usr/share/willy-cht"
has_game() { [ -f "$1/resource.map" ] || [ -f "$1/RESOURCE.MAP" ]; }
if [ $# -ge 1 ] && [ -d "$1" ]; then
  exec "$SV" --extrapath="$EXTRA" --path="$1" beamish
fi
APPDIR_OF_IMG="$(dirname "$(readlink -f "${APPIMAGE:-$0}")")"
for base in "$APPDIR_OF_IMG" "$PWD"; do
  has_game "$base" && exec "$SV" --extrapath="$EXTRA" --path="$base" beamish
  for d in "$base"/*/; do
    [ -d "$d" ] && has_game "$d" && exec "$SV" --extrapath="$EXTRA" --path="$d" beamish
  done
done
exec "$SV" --extrapath="$EXTRA"
RUN
chmod +x "$APPDIR/AppRun"

cat > "$APPDIR/willy-cht.desktop" <<'DESK'
[Desktop Entry]
Type=Application
Name=Willy Beamish CHT
Comment=威利奇遇記 繁體中文版 (patched ScummVM)
Exec=AppRun
Icon=willy-cht
Categories=Game;
Terminal=false
DESK

# Icon: a crop of a Chinese dialogue shot, else a solid placeholder.
ICON_SRC=""
for c in autopilot_shots/fix_d1_3_zh24.png screenshots/title.png autopilot_shots/d1_1_zh24.png; do
  [ -f "$c" ] && ICON_SRC="$c" && break
done
if command -v convert >/dev/null 2>&1 && [ -n "$ICON_SRC" ]; then
  convert "$ICON_SRC" -gravity north -crop 256x256+0+0 +repage -resize 256x256 "$APPDIR/willy-cht.png" 2>/dev/null || \
    convert -size 256x256 xc:black -fill white -gravity center -pointsize 40 -annotate 0 "威" "$APPDIR/willy-cht.png"
else
  convert -size 256x256 xc:black -fill white -gravity center -pointsize 40 -annotate 0 "威" "$APPDIR/willy-cht.png" 2>/dev/null || : > "$APPDIR/willy-cht.png"
fi
cp "$APPDIR/willy-cht.png" "$APPDIR/.DirIcon" 2>/dev/null || true

# appimagetool (host, extract-and-run: no FUSE needed)
TOOL=/tmp/appimagetool-x86_64.AppImage
if [ ! -x "$TOOL" ]; then
  curl -fsSL -o "$TOOL" \
    https://github.com/AppImage/appimagetool/releases/download/continuous/appimagetool-x86_64.AppImage
  chmod +x "$TOOL"
fi
ARCH=x86_64 "$TOOL" --appimage-extract-and-run "$APPDIR" "$OUT" 2>&1 | tail -5

ls -la "$OUT" 2>/dev/null && echo "AppImage built: $OUT ($(du -h "$OUT" | cut -f1))" \
  || echo "AppImage build did not produce output (check log above)."
