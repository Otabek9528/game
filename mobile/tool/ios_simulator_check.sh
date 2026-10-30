#!/bin/bash
# Codemagic, workflow ios-check (codemagic.yaml): starts the simulator build
# on an iPhone simulator, takes three screenshots a minute apart, and fails if
# the app isn't running by then (it crashed). Screenshots and the app's log go
# to $CM_EXPORT_DIR, which Codemagic offers for download with the build.
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
xcrun simctl launch "$UDID" "$BUNDLE"

for n in 1 2 3; do
  sleep 20
  xcrun simctl io "$UDID" screenshot "$OUT/iphone_$n.png"
done

xcrun simctl spawn "$UDID" log show --last 5m --style compact --predicate 'process == "Runner"' \
  > "$OUT/iphone_log.txt" 2>&1 || true

if xcrun simctl spawn "$UDID" launchctl list | grep -q "$BUNDLE"; then
  echo "The app is still running after a minute: it starts without crashing."
else
  echo "The app is not running any more: it crashed or closed. See iphone_log.txt in the artifacts."
  exit 1
fi
