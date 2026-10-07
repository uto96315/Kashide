# Firebase Analytics（投稿ファネル）

## イベント

| イベント | 意味 |
|----------|------|
| `post_compose_open` | 投稿画面を開いた（作成フロー開始） |
| `post_submit_attempt` | 「投稿する」を押しバリデーション通過 |
| `post_submit_success` | Firestore への投稿成功 |
| `post_submit_validation_failed` | バリデーションエラーで投稿未実行 |
| `post_submit_failure` | 投稿処理の例外 |

パラメータ `source` 例: `home_create_button`, `genre_create_button`, `named_route_post`

## Firebase コンソールでの見方

1. [Analytics](https://console.firebase.google.com/) → プロジェクト `strgram-beta`
2. **探索** → **ファネル分析** を作成
3. ステップ例: `post_compose_open` → `post_submit_attempt` → `post_submit_success`
4. 作成ボタン→投稿完了の割合 ≒ `post_submit_success` / `post_compose_open`（同一 `source` で分解可）

DebugView（開発中）: Xcode 実行引数 `-FIRAnalyticsDebugEnabled` または Android `adb shell setprop debug.firebase.analytics.app <package>`

