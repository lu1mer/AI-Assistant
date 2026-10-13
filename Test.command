#!/bin/bash
set -euo pipefail
export PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:${PATH:-}"
cd -- "$(dirname -- "${BASH_SOURCE[0]}")"
trap 'result=$?; if [ -t 0 ] && [ "${CI:-}" != 1 ]; then read -r -p "Нажмите Enter… " _answer || true; fi; exit "$result"' EXIT
xcodegen generate
SIMULATOR_ID="${SIMULATOR_ID:-$(xcrun simctl list devices available -j | python3 -c 'import json,sys; devices=json.load(sys.stdin)["devices"]; ids=[d["udid"] for group in devices.values() for d in group if d.get("isAvailable") and d["name"].startswith("iPhone")]; print(ids[0] if ids else "")')}"
if [ -z "$SIMULATOR_ID" ]; then
    printf 'ERROR: Установите iPhone Simulator в Xcode → Settings → Components.\n'
    exit 1
fi
mkdir -p build
xcodebuild -project AIAssistant.xcodeproj -scheme AIAssistant \
    -destination "platform=iOS Simulator,id=$SIMULATOR_ID" \
    -parallel-testing-enabled NO \
    -derivedDataPath build/DerivedData CODE_SIGNING_ALLOWED=NO test 2>&1 | tee build/tests.log
printf '\nSUCCESS: Tests passed.\n'
