#!/bin/sh
# Xcode Cloud: Flutter 依存の準備（Archive 前）
set -e
cd "$CI_PRIMARY_REPOSITORY_PATH"

export PATH="$PATH:$HOME/flutter/bin"
if ! command -v flutter >/dev/null 2>&1; then
  git clone https://github.com/flutter/flutter.git -b stable --depth 1 "$HOME/flutter"
  export PATH="$PATH:$HOME/flutter/bin"
fi

flutter --version
flutter precache --ios
flutter pub get

if [ ! -f lib/firebase_options.dart ]; then
  if [ -n "${FIREBASE_OPTIONS_DART_BASE64:-}" ]; then
    echo "$FIREBASE_OPTIONS_DART_BASE64" | base64 --decode > lib/firebase_options.dart
  else
    echo "error: lib/firebase_options.dart がありません。"
    echo "Workflow Environment に FIREBASE_OPTIONS_DART_BASE64（Secret）を設定してください。"
    echo "ローカルで: ./scripts/generate_xcode_cloud_secrets.sh"
    exit 1
  fi
fi

# Xcode が署名・ビルド設定を Flutter 側と揃える
flutter build ios --config-only --release
