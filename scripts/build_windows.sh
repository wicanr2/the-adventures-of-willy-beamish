#!/usr/bin/env bash
# Cross-compile the patched ScummVM (dgds engine only) for Windows x86_64 using
# mingw-w64 + SDL2, entirely in Docker (host stays clean; source is copied, not built
# in place). Produces dist/willy-cht-windows-x86_64/ with scummvm.exe + SDL2.dll + assets.
set -e
cd "$(dirname "$0")/.."
SRC="${SCUMMVM_SRC:-$PWD/scummvm-src}"
SDL2VER=2.30.9
IMG="${DOCKER_IMG:-rotd-emu:latest}"
docker run --rm \
  -v "$PWD":/work -v "$SRC":/src:ro -w /work "$IMG" bash -c '
  set -e
  export DEBIAN_FRONTEND=noninteractive
  apt-get update -qq >/dev/null 2>&1
  apt-get install -y -qq g++-mingw-w64-x86-64 mingw-w64-tools curl xz-utils >/dev/null 2>&1
  cd /tmp
  curl -fsSL -o sdl2.tar.gz \
    https://github.com/libsdl-org/SDL/releases/download/release-'"$SDL2VER"'/SDL2-devel-'"$SDL2VER"'-mingw.tar.gz
  tar xf sdl2.tar.gz
  SDLDIR=/tmp/SDL2-'"$SDL2VER"'/x86_64-w64-mingw32
  export PATH="$SDLDIR/bin:$PATH"
  mkdir -p /tmp/build
  cp -a /src/. /tmp/build/ 2>/dev/null || true
  cd /tmp/build
  rm -f scummvm scummvm.exe config.log config.mk 2>/dev/null || true
  find . -name "*.o" -delete 2>/dev/null || true
  HOST=x86_64-w64-mingw32
  ./configure \
    --host=$HOST \
    --disable-all-engines --enable-engine=dgds \
    --with-sdl-prefix="$SDLDIR/bin" \
    --disable-fluidsynth --disable-flac --disable-mad --disable-vorbis \
    --disable-theoradec --disable-faad --disable-mpeg2 --disable-a52 \
    --disable-libcurl --disable-sndio --disable-timidity --disable-sparkle \
    --disable-nuked-opl --disable-eventrecorder \
    >/tmp/wincfg.log 2>&1 || { echo "CONFIGURE FAILED"; tail -30 /tmp/wincfg.log; exit 1; }
  echo "=== configure OK; building (this takes a few min) ==="
  make -j4 >/tmp/winmake.log 2>&1 || { echo "MAKE FAILED"; tail -40 /tmp/winmake.log; exit 1; }
  ls -la scummvm.exe
  x86_64-w64-mingw32-strip scummvm.exe
  echo "stripped -> $(stat -c%s scummvm.exe) bytes"
  mkdir -p /work/dist/willy-cht-windows-x86_64
  cp scummvm.exe /work/dist/willy-cht-windows-x86_64/
  cp "$SDLDIR/bin/SDL2.dll" /work/dist/willy-cht-windows-x86_64/ 2>/dev/null || true
  for dll in libgcc_s_seh-1 libstdc++-6 libwinpthread-1; do
    f=$(find /usr/lib/gcc/$HOST -name "$dll.dll" 2>/dev/null | head -1)
    [ -n "$f" ] && cp "$f" /work/dist/willy-cht-windows-x86_64/ || true
  done
  echo "BUILD_OK"
  chmod -R a+rw /work/dist/willy-cht-windows-x86_64
'

WINBUN="dist/willy-cht-windows-x86_64"
mkdir -p "$WINBUN/extra"
for a in build/zh.dtr build/beamish_zh24.dcjk build/beamish_zh16.dcjk; do
  [ -f "$a" ] && cp -L "$a" "$WINBUN/extra/" || echo "  ! missing $a"
done
# play-willy-cht.bat: CRLF, points scummvm.exe at the sibling extra/ + game/.
printf '@echo off\r\n"%%~dp0scummvm.exe" --extrapath="%%~dp0extra" --path="%%~dp0game" beamish\r\n' > "$WINBUN/play-willy-cht.bat"
cat > "$WINBUN/README.txt" <<'DOC'
威利奇遇記 繁體中文版 (Windows)
================================
1. 把你自己合法擁有的 Willy Beamish 遊戲資料夾（含 RESOURCE.MAP + RESOURCE.001）
   放進本資料夾、改名為 game（即 此資料夾\game\RESOURCE.MAP）。
2. 雙擊 play-willy-cht.bat 啟動。預設中文 24×24；遊戲中按 F8 循環中24/中16/英文。
不含遊戲原始檔；版權屬 Dynamix / Sierra。請勿散布完整包。
DOC
echo "win bundle ready: $(ls "$WINBUN")"
