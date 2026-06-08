#!/usr/bin/env bash
# Local Android verification: build the debug APK (if needed), install it on the
# already-running emulator/device, launch it, confirm the process is alive, and
# capture a loaded + after screenshot (driving the counter 0 -> 101). This is the
# local equivalent of the CI `android-screenshot` job (which runs the same flow
# against API 30 & 34 emulators on a KVM-enabled Linux runner).
#
# Usage: boot an emulator first (e.g. `emulator -avd Pixel_9_Pro`), then:
#   bash tooling/screenshots/local-android.sh
#
# All inter-step waits run device-side (adb shell `sleep`) to avoid host sleeps.
set -euo pipefail

ADB="${ADB:-$HOME/Library/Android/sdk/platform-tools/adb}"
PKG="com.example.custom_redux"
OUT="${ARTIFACTS_DIR:-artifacts}"
APK="build/app/outputs/flutter-apk/app-debug.apk"

# Button centres for the loaded screen, in pixels for a 1280x2856 display.
# Override via env if your device resolution differs.
INC="${INC:-590 1301}"   # Increment
DEC="${DEC:-590 1459}"   # Decrement
ADD="${ADD:-590 1616}"   # Add 100

mkdir -p "$OUT"

[ -f "$APK" ] || flutter build apk --debug

"$ADB" wait-for-device
"$ADB" install -r "$APK" >/dev/null
"$ADB" shell am force-stop "$PKG"
"$ADB" shell am start -n "$PKG/.MainActivity" >/dev/null
"$ADB" shell 'sleep 5' # device-side boot settle

if ! "$ADB" shell pidof "$PKG" >/dev/null 2>&1; then
  echo "ERROR: app is not running after launch"
  "$ADB" logcat -d | tail -200 > "$OUT/android-local-crash.log"
  exit 1
fi

"$ADB" exec-out screencap -p > "$OUT/android-local-loaded.png"

# Drive the counter: Increment x2 -> Add 100 -> Decrement = 101.
"$ADB" shell "input tap $INC; sleep 0.6; input tap $INC; sleep 0.6; input tap $ADD; sleep 0.6; input tap $DEC; sleep 1"

"$ADB" exec-out screencap -p > "$OUT/android-local-after.png"

echo "DONE loaded=$(wc -c < "$OUT/android-local-loaded.png")B after=$(wc -c < "$OUT/android-local-after.png")B"
