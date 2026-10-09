# Kashide

気に入った歌詞から曲を選べるサービス

### ペルソナ像
- 歌詞重視派の人(8%程度いる模様 n=90)
- 中々新しい曲にトライできない人
- マイナーソングを知ってほしい人


### 課題点
- 著作権の問題
=> JASRACと正式に契約を結びました。 2022.10.24


### 実装したいNice-to-have機能
- 歌い手にリクエスト機能（クラファンのような形で）
- ランキング機能
- スーパーライク機能

## リリース時
### android
- versionを上げる（pubspec.yaml）
- ```flutter build appbundle --flavor prod -t lib/main.dart``` を実行

## ビルドフレーバー（prod / dev）

本番と配布テストを**別アプリ**として共存させるため `dev` を用意している（Bundle ID が異なる）。

| | prod（本番） | dev（配布テスト） |
|---|---|---|
| iOS | `com.example.kashide` | `com.example.kashide.dev` |
| Android | `com.yuto.mabe.kashide` | `com.yuto.mabe.kashide.dev` |

```bash
# 本番
fvm flutter run --flavor prod -t lib/main.dart
fvm flutter build appbundle --flavor prod -t lib/main.dart

# 配布テスト（App Store 版と共存）
fvm flutter run --flavor dev -t lib/main_dev.dart --dart-define=FLAVOR=dev
fvm flutter build ipa --flavor dev -t lib/main_dev.dart --dart-define=FLAVOR=dev
```

**Android は必ず `--flavor prod` または `--flavor dev` を付ける。**

### 今後やること（未設定）

1. **Firebase**（プロジェクト `strgram-beta`）で iOS / Android アプリを追加  
   - `com.example.kashide.dev` / `com.yuto.mabe.kashide.dev`  
   - 設定を `ios/Firebase/dev/`・`android/app/src/dev/` に配置  
   - `lib/firebase_options.dart`（gitignore 対象・ローカル）の `iosDev` / `androidDev` の `appId` 等を更新
2. **Apple Developer** で App ID `com.example.kashide.dev` と dev 用プロビジョニング
3. **Firestore ルール・Functions**（未デプロイ分があれば）  
   `firebase deploy --only firestore:rules,functions:onFeedbackCreated`

### 気をつけること

- 同じ Bundle ID の IPA/APK を入れると**必ず上書き**される → 実機テストで本番を残すなら **dev ビルドのみ**
- dev の Google ログインを使う場合は、Firebase 取得後に `Info.plist` の URL Types（`REVERSED_CLIENT_ID`）の追加が必要なことがある
