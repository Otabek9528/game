#!/bin/bash
# Codemagic, workflow ios-check (codemagic.yaml): starts the simulator build
# on an iPhone simulator past its first-launch questions, takes screenshots of
# the home screen and the prayers page (light, then dark), and fails if the app
# isn't running by then (it crashed). Screenshots and the app's log go to
# $CM_EXPORT_DIR, which Codemagic offers for download with the build.
#
# Run from mobile/, after `flutter build ios --simulator --debug`.
set -euo pipefail

APP=build/ios/iphonesimulator/Runner.app
BUNDLE=com.vegukin.muslimVegukin
OUT=${CM_EXPORT_DIR:-build/simulator_check}
mkdir -p "$OUT"

# The newest iOS's first iPhone.
UDID=$(xcrun simctl list devices available --json | python3 -c '
import json, sys
devices = json.load(sys.stdin)["devices"]
def version(runtime):
    return [int(p) for p in runtime.rsplit(".iOS-", 1)[1].split("-") if p.isdigit()]
for runtime in sorted((r for r in devices if ".iOS-" in r), key=version, reverse=True):
    for device in devices[runtime]:
        if device["name"].startswith("iPhone"):
            print(device["udid"])
            sys.exit()
sys.exit("No iPhone simulator found")
')
echo "Simulator: $(xcrun simctl list devices | grep "$UDID")"

xcrun simctl boot "$UDID" || true
xcrun simctl bootstatus "$UDID" -b
# Ansan, so prayer times have a place.
xcrun simctl location "$UDID" set 37.3219,126.8309 || true
xcrun simctl install "$UDID" "$APP"
xcrun simctl privacy "$UDID" grant location "$BUNDLE" || true

# The app registers itself with the API the moment it starts: every check run
# was a new "person" in the push panel and the stats. The check is about the
# app starting, not the server, so the API is unreachable from this Mac (the
# simulator uses its network). Prayer times and photos come from other hosts.
API_HOST=vegukin-api.duckdns.org
if echo "127.0.0.1 $API_HOST" | sudo tee -a /etc/hosts >/dev/null; then
  sudo dscacheutil -flushcache || true
  sudo killall -HUP mDNSResponder || true
  echo "$API_HOST blocked for the check"
else
  echo "WARNING: could not block $API_HOST; this run registers as a user"
fi

# Answers to what the first launch asks, which nobody is there to tap: the
# language (Uzbek), and the camera and notification prompts as already shown.
# Location is granted above, so the app finds Ansan by itself.
# Written as a file, before the app has ever run, so no preferences cache holds
# an older copy.
DATA=$(xcrun simctl get_app_container "$UDID" "$BUNDLE" data)
mkdir -p "$DATA/Library/Preferences"
python3 - "$DATA/Library/Preferences/$BUNDLE.plist" <<'PY'
import plistlib, sys
answers = {"app_language": "uz", "permissions_asked": "1", "notifications_asked": "1", "install_id": "-1"}
with open(sys.argv[1], "wb") as f:
    plistlib.dump(answers, f)
PY

xcrun simctl launch "$UDID" "$BUNDLE"
sleep 30
xcrun simctl io "$UDID" screenshot "$OUT/iphone_1_home.png"

# The link the widget opens: the prayers page.
xcrun simctl openurl "$UDID" "muslimvegukin://prayers" || true
sleep 10
xcrun simctl io "$UDID" screenshot "$OUT/iphone_2_prayers.png"

xcrun simctl ui "$UDID" appearance dark || true
sleep 6
xcrun simctl io "$UDID" screenshot "$OUT/iphone_3_prayers_dark.png"

xcrun simctl spawn "$UDID" log show --last 5m --style compact --predicate 'process == "Runner"' \
  > "$OUT/iphone_log.txt" 2>&1 || true

# Read the whole list first: grep -q stops at the first match, and the
# list's writer then dies of a broken pipe, which pipefail counts as failure.
running=$(xcrun simctl spawn "$UDID" launchctl list || true)
if grep -q "$BUNDLE" <<<"$running"; then
  echo "The app is still running after a minute: it starts without crashing."
else
  echo "The app is not running any more: it crashed or closed. See iphone_log.txt in the artifacts."
  exit 1
fi
