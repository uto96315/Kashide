#!/bin/sh
# Xcode Cloud: Archive 後に Ad Hoc IPA を Firebase App Distribution へ
set -e
cd "$CI_PRIMARY_REPOSITORY_PATH"

if [ -z "$FIREBASE_TOKEN" ]; then
  echo "FIREBASE_TOKEN が未設定のため App Distribution をスキップします。"
  exit 0
fi

if ! command -v firebase >/dev/null 2>&1; then
  curl -sL https://firebase.tools | bash
fi

EXPORT_DIR="$CI_PRIMARY_REPOSITORY_PATH/build/ios/export"
mkdir -p "$EXPORT_DIR"

xcodebuild -exportArchive \
  -archivePath "$CI_ARCHIVE_PATH" \
  -exportPath "$EXPORT_DIR" \
  -exportOptionsPlist "$CI_PRIMARY_REPOSITORY_PATH/ios/ExportOptionsAdHoc.plist"

IPA="$(find "$EXPORT_DIR" -name '*.ipa' | head -1)"
if [ -z "$IPA" ]; then
  echo "error: IPA が見つかりません"
  exit 1
fi

FIREBASE_IOS_APP_ID="${FIREBASE_IOS_APP_ID:-1:685958858748:ios:ae5d8a6400ffee58ee1479}"
FIREBASE_GROUPS="${FIREBASE_GROUPS:-testers}"
NOTES="${FIREBASE_RELEASE_NOTES:-Xcode Cloud ${CI_BUILD_NUMBER:-} ${CI_COMMIT:-}}"

firebase appdistribution:distribute "$IPA" \
  --app "$FIREBASE_IOS_APP_ID" \
  --groups "$FIREBASE_GROUPS" \
  --release-notes "$NOTES" \
  --token "$FIREBASE_TOKEN"

echo "App Distribution にアップロードしました: $IPA"
