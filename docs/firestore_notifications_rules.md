# 通知一覧が「読み込めませんでした」になる場合

Cloud Functions は `users/{uid}/notifications` に書き込むが、**クライアントが読む権限**が Firestore ルールに無いと失敗する。

## 対応（どちらか）

### A. リポジトリのルールをデプロイ（推奨）

```bash
firebase deploy --only firestore:rules --project strgram-beta
```

`firestore.rules` に `notifications` の read/update を含む。

### B. Console で追記のみ

Firebase Console → Firestore → ルール に、既存の `match /users/{userId}` 内へ:

```
match /notifications/{notificationId} {
  allow read, update: if request.auth != null && request.auth.uid == userId;
}
```

保存後、通知タブを開き直す。
