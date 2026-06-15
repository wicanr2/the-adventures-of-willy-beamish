#!/usr/bin/env bash
# Launch patched ScummVM Willy Beamish headless under Xvfb, screenshot after N sec.
# Usage: run_headless.sh <out.png> [seconds] [extra scummvm args...]
set -u
SV="${SCUMMVM:-/home/anr2/willy/scummvm-src/scummvm}"
GAME=/home/anr2/willy/game
OUT="${1:-/home/anr2/willy/screenshots/smoke.png}"; shift || true
SECS="${1:-12}"; shift || true
mkdir -p "$(dirname "$OUT")"
DISP=:99
Xvfb $DISP -screen 0 1280x960x24 >/tmp/xvfb_willy.log 2>&1 &
XVFB_PID=$!
sleep 1
DISPLAY=$DISP "$SV" -p "$GAME" --no-fullscreen --gfx-mode=2x "$@" beamish >/tmp/scummvm_willy.log 2>&1 &
SV_PID=$!
sleep "$SECS"
DISPLAY=$DISP import -window root "$OUT" 2>/tmp/import_willy.log
echo "screenshot -> $OUT ($(identify -format '%wx%h' "$OUT" 2>/dev/null))"
kill $SV_PID 2>/dev/null; sleep 1; kill -9 $SV_PID 2>/dev/null
kill $XVFB_PID 2>/dev/null
echo "=== scummvm log tail ==="; tail -15 /tmp/scummvm_willy.log
