# iOS → Firebase App Distribution（Xcode Cloud）

## 1. Firebase Console

1. **Release & Monitor → App Distribution** を有効化
2. **テスターグループ**（例: `testers`）とメール招待
3. iOS アプリ ID: `1:685958858748:ios:ae5d8a6400ffee58ee1479`（`ios/firebase_app_id_file.json`）

## 2. トークン（1回）

ローカルで:

```bash
firebase login:ci
```

表示されたトークンを **Xcode Cloud → Workflow → Environment Variables** に  
`FIREBASE_TOKEN`（Secret）として登録。

任意:

- `FIREBASE_GROUPS` … 既定 `testers`
- `FIREBASE_RELEASE_NOTES` … リリースノート

## 3. Xcode Cloud ワークフロー

1. **Product → Xcode Cloud → Manage Workflows**
2. iOS **Archive** アクション（TestFlight 自動配布は **オフ** にして Distribution だけ使う場合）
3. リポジトリに `ios/ci_scripts/ci_post_clone.sh` / `ios/ci_scripts/ci_post_xcodebuild.sh` があると自動実行される（workspace と同階層）
4. ブランチは配布したいコード（`main` 推奨）を選択して **Start Build**

## 4. 必須: `firebase_options.dart`

`.gitignore` 対象のため **CI ブランチに無いとビルド失敗**します。

- チーム内 private リポジトリなら CI 用ブランチに含める  
- または Workflow Secret で `FIREBASE_OPTIONS_DART_BASE64` を渡し `ci_post_clone.sh` で復元（要スクリプト拡張）

## 5. Ad Hoc 端末

テスターの iPhone は **Apple Developer → Devices** に登録。  
Firebase の端末登録フローを使う場合は、プロファイル更新後に **再ビルド**。

## 6. ローカルだけで配る場合

```bash
./scripts/build_ipa_adhoc.sh
firebase appdistribution:distribute build/ios/ipa/*.ipa \
  --app 1:685958858748:ios:ae5d8a6400ffee58ee1479 \
  --groups testers \
  --release-notes "..."
```

（Mac のキーチェーン許可が必要なことがあります。）
