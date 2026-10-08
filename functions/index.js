const functions = require('firebase-functions');
const admin = require('firebase-admin');

admin.initializeApp();

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

    const likerName = (likerSnap.data() && likerSnap.data().userName) || '誰か';
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

    const commenterName =
      (commenterSnap.data() && commenterSnap.data().userName) || '誰か';
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
