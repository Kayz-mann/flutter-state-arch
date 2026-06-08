#!/usr/bin/env bash
# Local Android verification: build the debug APK (if needed), install it on the
# already-running emulator/device, launch it, confirm it renders, drive the
# counter 0 -> 101, and capture loaded + after screenshots. This is the local
# equivalent of the CI `android-screenshot` job (which runs the same flow
# against API 30 & 34 emulators on a KVM-enabled Linux runner).
#
# Usage: boot an emulator first (e.g. `emulator -avd Pixel_9_Pro`), then:
#   bash tooling/screenshots/local-android.sh
#
# Button locations and the counter value are read from the accessibility tree
# (uiautomator), so this is resolution-independent — no hard-coded pixels. All
# inter-step waits run device-side (adb shell `sleep`) to avoid host sleeps.
set -euo pipefail

ADB="${ADB:-$HOME/Library/Android/sdk/platform-tools/adb}"
PKG="com.example.custom_redux"
OUT="${ARTIFACTS_DIR:-artifacts}"
APK="build/app/outputs/flutter-apk/app-debug.apk"
TMP="$(mktemp -d)"

mkdir -p "$OUT"

# --- helpers ---------------------------------------------------------------

dump_ui() { # $1 = local xml path
  "$ADB" shell uiautomator dump /sdcard/ui.xml >/dev/null 2>&1
  "$ADB" pull /sdcard/ui.xml "$1" >/dev/null 2>&1
}

# Centre "cx cy" of the accessibility node whose content-desc == $2.
center_of() { # $1 = xml, $2 = content-desc
  tr '>' '\n' < "$1" | grep "content-desc=\"$2\"" | head -1 \
    | grep -o 'bounds="[^"]*"' | grep -o '[0-9]\+' \
    | awk 'NR==1{a=$1} NR==2{b=$1} NR==3{c=$1} NR==4{d=$1} END{printf "%d %d", (a+c)/2, (b+d)/2}'
}

# The counter is the only node whose content-desc is purely an integer.
counter_value() { # $1 = xml
  tr '>' '\n' < "$1" | grep -oE 'content-desc="-?[0-9]+"' \
    | grep -oE '\-?[0-9]+' | head -1
}

# --- build + install -------------------------------------------------------

[ -f "$APK" ] || flutter build apk --debug

"$ADB" wait-for-device
"$ADB" install -r "$APK" >/dev/null
"$ADB" shell am force-stop "$PKG"
"$ADB" shell am start -n "$PKG/.MainActivity" >/dev/null

# Wait until the activity is resumed (cold emulators show the Flutter splash for
# several seconds before the first frame), then let Flutter draw past it.
for _ in $(seq 1 40); do
  if "$ADB" shell dumpsys activity activity "$PKG" 2>/dev/null | grep -q "mResumed=true"; then
    break
  fi
  "$ADB" shell 'sleep 1'
done
"$ADB" shell 'sleep 4'

if ! "$ADB" shell pidof "$PKG" >/dev/null 2>&1; then
  echo "ERROR: app is not running after launch"
  "$ADB" logcat -d | tail -200 > "$OUT/android-local-crash.log"
  exit 1
fi

# --- loaded screenshot + locate controls -----------------------------------

"$ADB" exec-out screencap -p > "$OUT/android-local-loaded.png"

dump_ui "$TMP/before.xml"
START="$(counter_value "$TMP/before.xml")"
read -r INCx INCy <<<"$(center_of "$TMP/before.xml" Increment)"
read -r DECx DECy <<<"$(center_of "$TMP/before.xml" Decrement)"
read -r ADDx ADDy <<<"$(center_of "$TMP/before.xml" 'Add 100')"

if [ -z "${INCx:-}" ] || [ -z "${ADDx:-}" ]; then
  echo "ERROR: could not locate buttons in the accessibility tree"
  exit 1
fi

# --- drive the counter: Increment x2 -> Add 100 -> Decrement = +101 ---------

"$ADB" shell "input tap $INCx $INCy; sleep 0.4; input tap $INCx $INCy; sleep 0.4; input tap $ADDx $ADDy; sleep 0.4; input tap $DECx $DECy; sleep 0.8"

dump_ui "$TMP/after.xml"
END="$(counter_value "$TMP/after.xml")"
"$ADB" exec-out screencap -p > "$OUT/android-local-after.png"

EXPECTED="$((START + 101))"
echo "counter ${START} -> ${END} (expected ${EXPECTED})"
if [ "$END" != "$EXPECTED" ]; then
  echo "ERROR: counter did not reach the expected value on this device"
  exit 1
fi

echo "DONE loaded=$(wc -c < "$OUT/android-local-loaded.png")B after=$(wc -c < "$OUT/android-local-after.png")B counter=${START}->${END}"
