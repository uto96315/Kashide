#!/usr/bin/env bash
# GitHub Actions 用 Secret を一括登録（ローカル Mac で1回だけ実行）
set -euo pipefail
cd "$(dirname "$0")/.."

REPO="${GITHUB_REPO:-uto96315/Kashide}"

echo "=== Repository: $REPO ==="
echo ""

if ! command -v gh >/dev/null; then
  echo "gh CLI が必要です: brew install gh"
  exit 1
fi

if [[ ! -f lib/firebase_options.dart ]]; then
  echo "lib/firebase_options.dart がありません"
  exit 1
fi

echo "[1/4] FIREBASE_OPTIONS_DART_BASE64"
base64 < lib/firebase_options.dart | tr -d '\n' | gh secret set FIREBASE_OPTIONS_DART_BASE64 --repo "$REPO"
echo "  → 設定済み"

echo ""
echo "[2/4] FIREBASE_TOKEN（firebase login:ci の1行）"
if [[ -n "${FIREBASE_TOKEN:-}" ]]; then
  gh secret set FIREBASE_TOKEN --repo "$REPO" <<< "$FIREBASE_TOKEN"
  echo "  → 環境変数から設定済み"
else
  echo "  次を実行して表示されたトークンをコピー:"
  echo "    firebase login:ci"
  echo "  その後:"
  echo "    gh secret set FIREBASE_TOKEN --repo $REPO"
fi

echo ""
echo "[3/4] iOS 証明書 (.p12)"
echo "  Keychain Access → 証明書「Apple Distribution」または「Apple Development」"
echo "  → 右クリック → 書き出す → .p12"
echo "  例:"
echo "    base64 -i ~/Desktop/Certificates.p12 | gh secret set IOS_P12_BASE64 --repo $REPO"
echo "    gh secret set IOS_P12_PASSWORD --repo $REPO   # p12 のパスワード"

echo ""
echo "[4/4] Ad Hoc プロビジョニングプロファイル"
echo "  developer.apple.com → Profiles → Ad Hoc → Download"
echo "  例:"
echo "    base64 -i ~/Downloads/Kashide.mobileprovision | gh secret set IOS_PROFILE_BASE64 --repo $REPO"

echo ""
echo "=== 完了後 ==="
echo "GitHub → Actions →「iOS Firebase Distribution」→ Run workflow"
