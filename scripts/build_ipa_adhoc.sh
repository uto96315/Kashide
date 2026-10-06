#!/usr/bin/env bash
# Ad Hoc IPA（Firebase App Distribution 用）
set -euo pipefail
cd "$(dirname "$0")/.."

if command -v fvm >/dev/null 2>&1; then
  FLUTTER=(fvm flutter)
elif [[ -x .fvm/flutter_sdk/bin/flutter ]]; then
  FLUTTER=(.fvm/flutter_sdk/bin/flutter)
elif command -v flutter >/dev/null 2>&1; then
  FLUTTER=(flutter)
else
  echo "Flutter が見つかりません。fvm install するか PATH に flutter を通してください。"
  exit 1
fi

"${FLUTTER[@]}" pub get
"${FLUTTER[@]}" build ipa --export-method ad-hoc

IPA=(build/ios/ipa/*.ipa)
if [[ -e ${IPA[0]} ]]; then
  echo ""
  echo "IPA: ${IPA[0]}"
  echo "Firebase 例:"
  echo '  firebase appdistribution:distribute "'"${IPA[0]}"'" --app "<IOS_APP_ID>" --groups "testers" --release-notes "..."'
fi
