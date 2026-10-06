#!/usr/bin/env bash
# Xcode Cloud に貼る Secret 用（リポジトリには載せない）
set -euo pipefail
cd "$(dirname "$0")/.."

OPTS=lib/firebase_options.dart
OUT=.xcode-cloud-secrets.txt

if [[ ! -f "$OPTS" ]]; then
  echo "missing $OPTS"
  exit 1
fi

B64=$(base64 < "$OPTS" | tr -d '\n')
{
  echo "# Xcode Cloud → Workflow → Environment Variables（いずれも Secret）"
  echo "# このファイルは .gitignore 済み。Git に commit しないこと。"
  echo ""
  echo "FIREBASE_OPTIONS_DART_BASE64="
  echo "$B64"
  echo ""
  echo "# 別途: firebase login:ci で取得したトークン"
  echo "FIREBASE_TOKEN="
} > "$OUT"

if command -v pbcopy >/dev/null 2>&1; then
  printf '%s' "$B64" | pbcopy
  echo "FIREBASE_OPTIONS_DART_BASE64 をクリップボードにコピーしました。"
fi
echo "詳細: $OUT"
