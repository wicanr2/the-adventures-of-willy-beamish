#!/usr/bin/env bash
# Inject the Willy Beamish game + CJK assets into the CI-built base APK
# (assets/assets/games/willybeamish/) and re-sign -> a self-contained 繁中 Android APK that
# installs and plays. Game data is injected LOCALLY (never goes to GitHub/CI). Docker (host clean).
# FOR PERSONAL ARCHIVAL of a game you legally own -- do NOT redistribute.
#
# Usage: tools/inject_android.sh [base.apk]   (default: dist/ci_android/willy-cht-android.apk)
set -e
cd "$(dirname "$0")/.."
BASE="${1:-dist/ci_android/willy-cht-android.apk}"
GAMES="build/android_games"   # contains willybeamish/ (game + dcjk/dtr)
[ -f "$BASE" ] || { echo "base APK not found: $BASE"; exit 1; }
[ -d "$GAMES/willybeamish" ] || { echo "no game bundle at $GAMES/willybeamish"; exit 1; }
[ -f build/android_libs/libc++_shared.so ] || { echo "missing build/android_libs/libc++_shared.so (arm64)"; exit 1; }

docker run --rm -v "$PWD":/work -w /work ubuntu:24.04 bash -c '
  set -e
  export DEBIAN_FRONTEND=noninteractive
  apt-get update -qq >/dev/null 2>&1
  apt-get install -y -qq openjdk-17-jdk-headless wget unzip zip >/dev/null 2>&1
  export ANDROID_SDK_ROOT=/opt/asdk
  mkdir -p "$ANDROID_SDK_ROOT/cmdline-tools"
  cd /tmp
  wget -q https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip -O ct.zip
  unzip -q ct.zip -d "$ANDROID_SDK_ROOT/cmdline-tools"
  mv "$ANDROID_SDK_ROOT/cmdline-tools/cmdline-tools" "$ANDROID_SDK_ROOT/cmdline-tools/latest"
  yes | "$ANDROID_SDK_ROOT/cmdline-tools/latest/bin/sdkmanager" --licenses >/dev/null 2>&1 || true
  "$ANDROID_SDK_ROOT/cmdline-tools/latest/bin/sdkmanager" "build-tools;35.0.0" >/dev/null
  BT="$ANDROID_SDK_ROOT/build-tools/35.0.0"

  cd /work
  rm -rf /tmp/stage
  # game must live at assets/assets/games/<id> (DOUBLE assets) AND be listed in assets/MD5SUMS,
  # else ScummVM neither extracts nor detects it.
  mkdir -p /tmp/stage/assets/assets/games
  cp -r build/android_games/willybeamish /tmp/stage/assets/assets/games/
  cp "'"$BASE"'" /tmp/work.apk

  # Runtime native-lib closure the CI base APK is missing: libscummvm.so -> liboboe.so -> libc++_shared.so
  mkdir -p /tmp/stage/lib/arm64-v8a
  wget -q https://dl.google.com/dl/android/maven2/com/google/oboe/oboe/1.9.0/oboe-1.9.0.aar -O /tmp/oboe.aar
  unzip -q -o /tmp/oboe.aar -d /tmp/oboe
  cp "$(find /tmp/oboe -name liboboe.so -path "*arm64*" | head -1)" /tmp/stage/lib/arm64-v8a/liboboe.so
  cp build/android_libs/libc++_shared.so /tmp/stage/lib/arm64-v8a/libc++_shared.so

  # Append game files to MD5SUMS (paths relative to files/, i.e. "assets/games/<id>/<f>").
  unzip -o -q /tmp/work.apk "assets/MD5SUMS" -d /tmp/md5
  ( cd /tmp/stage/assets && find assets/games -type f | sort | xargs md5sum ) >> /tmp/md5/assets/MD5SUMS
  cp /tmp/md5/assets/MD5SUMS /tmp/stage/assets/MD5SUMS

  ( cd /tmp/stage && zip -qr /tmp/work.apk assets lib )
  zip -q -d /tmp/work.apk "META-INF/*" >/dev/null 2>&1 || true

  "$BT/zipalign" -p -f 4 /tmp/work.apk /tmp/aligned.apk
  keytool -genkeypair -keystore /tmp/debug.ks -alias willy -storepass android -keypass android \
    -dname "CN=Willy-CHT" -keyalg RSA -keysize 2048 -validity 10000 >/dev/null 2>&1
  "$BT/apksigner" sign --ks /tmp/debug.ks --ks-pass pass:android --key-pass pass:android \
    --out /work/dist/willy-cht-android-FULL.apk /tmp/aligned.apk
  "$BT/apksigner" verify /work/dist/willy-cht-android-FULL.apk && echo "SIGNED OK"
  chmod a+rw /work/dist/willy-cht-android-FULL.apk
'
ls -la dist/willy-cht-android-FULL.apk 2>/dev/null && \
  echo "完整中文 APK -> dist/willy-cht-android-FULL.apk (全新安裝即可玩)"
