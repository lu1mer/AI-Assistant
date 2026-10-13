#!/bin/bash
set -euo pipefail
export PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:${PATH:-}"
PROJECT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
cd "$PROJECT_DIR"
finish() {
    result=$?
    if [ "$result" -ne 0 ]; then
        printf '\nERROR: Сборка не завершена. Подробности выше и в build/build.log (если создан).\n'
    fi
    if [ -t 0 ] && [ "${CI:-}" != '1' ]; then
        read -r -p 'Нажмите Enter, чтобы закрыть окно… ' _answer || true
    fi
    exit "$result"
}
trap finish EXIT
if ! command -v xcodegen >/dev/null 2>&1; then
    printf 'ERROR: Установите XcodeGen (brew install xcodegen), затем повторите запуск.\n'
    exit 1
fi
if ! xcodebuild -version >/dev/null 2>&1; then
    printf 'ERROR: Установите и запустите Xcode, примите лицензию и выберите Xcode в Settings → Locations → Command Line Tools.\n'
    exit 1
fi
if ! xcrun --sdk iphonesimulator --show-sdk-path >/dev/null 2>&1; then
    printf 'ERROR: В Xcode → Settings → Components установите iOS SDK.\n'
    exit 1
fi
mkdir -p build
xcodegen generate
xcodebuild -project AIAssistant.xcodeproj -scheme AIAssistant \
    -configuration Debug -sdk iphonesimulator \
    -destination 'generic/platform=iOS Simulator' \
    -derivedDataPath "$PROJECT_DIR/build/DerivedData" \
    CODE_SIGNING_ALLOWED=NO build 2>&1 | tee build/build.log
printf '\nSUCCESS: %s/build/DerivedData/Build/Products/Debug-iphonesimulator/AIAssistant.app\n' "$PROJECT_DIR"
