const functions = require('firebase-functions');
const admin = require('firebase-admin');

admin.initializeApp();

function publicUserName(raw) {
  if (!raw || typeof raw !== 'string') return '誰か';
  const t = raw.trim();
  if (!t) return '誰か';
  if (t.startsWith('anonymous+') && t.includes('@')) return '匿名ユーザー';
  if (/^匿名ユーザー[\s·．.][\w.\-]+$/.test(t)) return '匿名ユーザー';
  return t;
}

/**
 * 投稿にいいねが付いたら投稿者へプッシュ＋アプリ内通知を作成する。
 * デプロイ: firebase deploy --only functions:notifyOnPostLike
 */
exports.notifyOnPostLike = functions.firestore
  .document('posts/{postId}/likedUsers/{likerId}')
  .onCreate(async (snap, context) => {
    const postId = context.params.postId;
    const likerId = context.params.likerId;
    if (!postId || !likerId) return null;

    const db = admin.firestore();
    const postSnap = await db.collection('posts').doc(postId).get();
    if (!postSnap.exists) return null;

    const posterId = postSnap.data().posterId;
    if (!posterId || posterId === likerId) return null;

    const [posterSnap, likerSnap] = await Promise.all([
      db.collection('users').doc(posterId).get(),
      db.collection('users').doc(likerId).get(),
    ]);

    const likerName = publicUserName(likerSnap.data() && likerSnap.data().userName);
    const fcmToken = posterSnap.data() && posterSnap.data().fcmToken;

    await db.collection('users').doc(posterId).collection('notifications').add({
      type: 'like',
      postId,
      fromUserId: likerId,
      fromUserName: likerName,
      read: false,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    if (!fcmToken) {
      functions.logger.info('No fcmToken for poster', { posterId });
      return null;
    }

    try {
      await admin.messaging().send({
        token: fcmToken,
        notification: {
          title: 'いいねされました',
          body: `${likerName}さんがあなたの歌詞にいいねしました`,
        },
        data: {
          type: 'like',
          postId,
        },
        apns: {
          payload: {
            aps: {
              sound: 'default',
            },
          },
        },
      });
    } catch (e) {
      functions.logger.error('FCM send failed', e);
    }

    return null;
  });

/**
 * 投稿にコメントが付いたら投稿者へプッシュ＋アプリ内通知を作成する。
 * デプロイ: firebase deploy --only functions:notifyOnPostComment
 */
exports.notifyOnPostComment = functions.firestore
  .document('posts/{postId}/comments/{commentId}')
  .onCreate(async (snap, context) => {
    const postId = context.params.postId;
    const commentId = context.params.commentId;
    if (!postId || !commentId) return null;

    const commentData = snap.data() || {};
    const commenterId = commentData.posterId;
    if (!commenterId) return null;

    const rawComment = typeof commentData.comment === 'string' ? commentData.comment.trim() : '';
    const commentPreview =
      rawComment.length > 80 ? `${rawComment.slice(0, 80)}…` : rawComment;

    const db = admin.firestore();
    const postSnap = await db.collection('posts').doc(postId).get();
    if (!postSnap.exists) return null;

    const posterId = postSnap.data().posterId;
    if (!posterId || posterId === commenterId) return null;

    const [posterSnap, commenterSnap] = await Promise.all([
      db.collection('users').doc(posterId).get(),
      db.collection('users').doc(commenterId).get(),
    ]);

    const commenterName = publicUserName(
      commenterSnap.data() && commenterSnap.data().userName,
    );
    const fcmToken = posterSnap.data() && posterSnap.data().fcmToken;

    await db.collection('users').doc(posterId).collection('notifications').add({
      type: 'comment',
      postId,
      commentId,
      commentPreview,
      fromUserId: commenterId,
      fromUserName: commenterName,
      read: false,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    if (!fcmToken) {
      functions.logger.info('No fcmToken for poster', { posterId });
      return null;
    }

    const pushBody = commentPreview
      ? `${commenterName}さん: ${commentPreview}`
      : `${commenterName}さんがあなたの歌詞にコメントしました`;

    try {
      await admin.messaging().send({
        token: fcmToken,
        notification: {
          title: 'コメントされました',
          body: pushBody,
        },
        data: {
          type: 'comment',
          postId,
          commentId,
        },
        apns: {
          payload: {
            aps: {
              sound: 'default',
            },
          },
        },
      });
    } catch (e) {
      functions.logger.error('FCM send failed', e);
    }

    return null;
  });

/**
 * 端末に保存した匿名アカウントへ切り替えるためのカスタムトークンを発行する。
 * デプロイ: firebase deploy --only functions:createAnonymousSwitchToken
 */
exports.createAnonymousSwitchToken = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'ログインが必要です。');
  }
  const targetUid = data && data.uid;
  if (!targetUid || typeof targetUid !== 'string') {
    throw new functions.https.HttpsError('invalid-argument', 'uid が必要です。');
  }

  let target;
  try {
    target = await admin.auth().getUser(targetUid);
  } catch (e) {
    throw new functions.https.HttpsError('not-found', 'ユーザーが見つかりません。');
  }

  const hasPassword = target.providerData.some((p) => p.providerId === 'password');
  if (hasPassword) {
    throw new functions.https.HttpsError(
      'failed-precondition',
      'メールアドレス登録済みのアカウントは通常のログインを使ってください。',
    );
  }

  const token = await admin.auth().createCustomToken(targetUid);
  return { token };
});
