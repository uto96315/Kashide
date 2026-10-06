# iOS 配布（GitHub Actions のみ）

Xcode Cloud の UI 設定は不要。**Secrets を1回入れたら Actions ボタン1つ**で Firebase App Distribution まで行く。

## 1. Secrets（GitHub → Settings → Secrets and variables → Actions）

| Secret | 内容 |
|--------|------|
| `FIREBASE_OPTIONS_DART_BASE64` | `base64 -i lib/firebase_options.dart \| tr -d '\n'` |
| `FIREBASE_TOKEN` | `firebase login:ci` のトークン |
| `IOS_P12_BASE64` | **Apple Distribution** の .p12 を base64（Ad Hoc 用。Development では不可） |
| `IOS_P12_PASSWORD` | .p12 のパスワード |
| `IOS_PROFILE_BASE64` | Ad Hoc `.mobileprovision` を base64 |

一括ヘルパー: `./scripts/setup_github_ios_ci.sh`

## 2. 配布

GitHub → **Actions** → **iOS Firebase Distribution** → **Run workflow**

または `main` へ push（`lib/` / `ios/` 変更時）

## 3. テスター

Firebase Console → App Distribution → グループ **testers**

Ad Hoc のため端末 UDID 登録が必要な場合あり。
