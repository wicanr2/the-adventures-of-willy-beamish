#!/usr/bin/env bash
# Rebuild the Willy Beamish CHT dev environment on a fresh machine, FROM SCRATCH:
#   ISO -> game/ -> extracted/ -> dialogs_en.json -> CJK assets -> patched ScummVM -> ready to package.
# Run from the repo root after extracting the dev tarball.
# Needs: git, C++ toolchain, SDL2/freetype/libpng dev headers, p7zip, python3 + freetype-py/pillow,
#        fonts-noto-cjk (for the dcjk fonts).  (Debian/Ubuntu names in DEV-SETUP.md.)
set -e
cd "$(dirname "$0")"
ROOT="$PWD"
SCUMMVM_COMMIT=ae89011bb942835c5b39b2a2f40be6021d2714df   # keep in sync with .github/workflows/build.yml
SRC="$ROOT/scummvm-src"
ISO=$(ls "$ROOT"/*.iso 2>/dev/null | head -1)

echo "== 0/5  game data (game/) from the ISO =="
if [ ! -f "$ROOT/game/RESOURCE.MAP" ]; then
  [ -n "$ISO" ] || { echo "no game/ and no .iso to extract from — drop your legally-owned ISO in repo root"; exit 1; }
  mkdir -p "$ROOT/game" /tmp/willy_iso
  7z x -y -o/tmp/willy_iso "$ISO" >/dev/null
  # the dgds engine only needs RESOURCE.* (MAP=index, 001=data, RME); copy them into game/
  for f in RESOURCE.MAP RESOURCE.001 RESOURCE.RME; do
    src=$(find /tmp/willy_iso -iname "$f" | head -1)
    [ -n "$src" ] && cp "$src" "$ROOT/game/$f"
  done
  rm -rf /tmp/willy_iso
  echo "   game/: $(ls "$ROOT/game" | tr '\n' ' ')"
fi

echo "== 1/5  extract resources + English dialogue (rebuildable artifacts) =="
[ -d "$ROOT/extracted" ] || python3 tools/dgds_volume.py game --extract extracted/
[ -f "$ROOT/dialogs_en.json" ] || python3 tools/extract_dialogs.py extracted/ dialogs_en.json

echo "== 2/5  CJK assets (beamish_zh{16,24}.dcjk + zh.dtr) =="
mkdir -p build
[ -f build/beamish_zh24.dcjk ] || python3 tools/build_cjk_font.py --size 24 --out build/beamish_zh24.dcjk
[ -f build/beamish_zh16.dcjk ] || python3 tools/build_cjk_font.py --size 16 --out build/beamish_zh16.dcjk
python3 tools/build_translation.py translations/zh.json build/zh.dtr   # always refresh from zh.json
cp -f build/zh.dtr build/beamish_zh24.dcjk build/beamish_zh16.dcjk game/ 2>/dev/null || true

echo "== 3/5  ScummVM source @ $SCUMMVM_COMMIT =="
if [ ! -d "$SRC/.git" ]; then git clone https://github.com/scummvm/scummvm "$SRC"; fi
cd "$SRC"
git checkout -f "$SCUMMVM_COMMIT"
git checkout -- . 2>/dev/null || true   # discard any prior patch so re-running is idempotent

echo "== 4/5  apply Willy CHT patches =="
for p in dgds-cjk android-surface-race android-autostart-beamish; do
  [ -f "$ROOT/patches/$p.patch" ] || continue
  git apply "$ROOT/patches/$p.patch" 2>/dev/null || patch -p1 < "$ROOT/patches/$p.patch" || true
  echo "   applied patches/$p.patch"
done

echo "== 5/5  build (dgds engine only) =="
./configure --disable-all-engines --enable-engine=dgds --enable-release
make -j"$(nproc)"

# Android injection materials (game + assets staged; libc++_shared.so ships in the dev tarball)
cd "$ROOT"
mkdir -p build/android_games/willybeamish
cp -f game/RESOURCE.MAP game/RESOURCE.001 game/RESOURCE.RME build/beamish_zh24.dcjk build/beamish_zh16.dcjk build/zh.dtr \
   build/android_games/willybeamish/ 2>/dev/null || true

cat <<EOF

✅ Built: $SRC/scummvm   (game/ + CJK assets + Android materials ready)

Next — export these so the package scripts find the engine, then build packages:

  export SCUMMVM_SRC="$SRC"
  export SCUMMVM="$SRC/scummvm"

  bash scripts/package_linux.sh             # -> dist/willy-cht-linux-x86_64
  bash scripts/package_appimage.sh          # -> engine-only AppImage
  bash scripts/package_appimage_full.sh     # -> FULL AppImage (含遊戲，下載即玩)
  bash scripts/build_windows.sh             # Docker mingw cross-build
  tools/inject_android.sh                   # FULL Android APK (needs CI base APK in dist/ci_android/)

macOS .app + Android base APK come from CI (.github/workflows/build.yml); see DEV-SETUP.md.
EOF
