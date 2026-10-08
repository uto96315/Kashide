

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:timeago/timeago.dart' as timeAgo;

import '../domain/comment_domain.dart';
import '../post/post_lyrics.dart';
import '../post/post_view_service.dart';

class PostDetailModel extends ChangeNotifier {
  PostDetailModel(this._postId, commentButtonTapped, this._postViews);

  static const _loadTimeout = Duration(seconds: 25);

  final String _postId;
  final PostViewService _postViews;

  var uid = FirebaseAuth.instance.currentUser?.uid;

  final commentController = TextEditingController();

  /// 投稿本体の読み込みが終わった（成功・失敗どちらでも true）。UI のスピナー制御用。
  bool postReady = false;

  // 投稿関係
  String? postText;
  List<String> textSegments = [];
  String? posterId;
  String? singName;
  String? singerName;
  List genreList = [];
  int? likedCount;
  int viewCount = 0;
  String? explanation;
  String? youtubeLink;

  // 投稿者関係
  String? posterName;
  String? userIconUrl;

  // ユーザー関係
  String? userName;
  String? userImageUrl;

  // コメント関係
  String? comment;
  bool canComment = false;

  // UI関係
  bool counterTextVisible = false;

  Future getPost(String id) async {
    try {
      final doc = FirebaseFirestore.instance.collection('posts').doc(id);
      final snapshot = await doc.get().timeout(_loadTimeout);
      final data = snapshot.data();

      if (!snapshot.exists || data == null) {
        postText = '';
        return;
      }

      postText = data['text'] as String? ?? '';
      textSegments = lyricSegmentsFromFirestore(data);
      posterId = data['posterId'] as String?;
      singName = data['singName'] as String?;
      singerName = data['artist'] as String?;
      genreList = data['genres'] ?? [];
      likedCount = (data['likedCount'] as num?)?.toInt();
      viewCount = viewCountFromFirestore(data);
      explanation = data['explanation'] as String?;
      youtubeLink = data['youtubeLink'] as String? ?? '';

      notifyListeners();

      final poster = posterId?.trim() ?? '';
      if (poster.isNotEmpty) {
        await getPosterData(poster);
      }
    } on TimeoutException {
      debugPrint('getPost timed out for $_postId');
    } catch (e, st) {
      debugPrint('getPost failed: $e\n$st');
    } finally {
      postText ??= '';
      postReady = true;
      notifyListeners();
      unawaited(_safeCountView());
    }
  }

  Future<void> _safeCountView() async {
    try {
      await _countViewIfNeeded();
    } catch (e, st) {
      debugPrint('_countViewIfNeeded failed: $e\n$st');
    }
  }

  Future<void> _countViewIfNeeded() async {
    final viewerUid = uid;
    if (viewerUid == null) return;
    final updated = await _postViews.recordDetailView(postId: _postId, viewerUid: viewerUid);
    if (viewCount != updated) {
      viewCount = updated;
      notifyListeners();
    }
  }

  Future getPosterData(String id) async {
    if (id.isEmpty) return;
    try {
      final doc = FirebaseFirestore.instance.collection('users').doc(id);
      final snapshot = await doc.get().timeout(_loadTimeout);
      final data = snapshot.data();

      posterName = data?['userName'] as String? ?? '';
      userIconUrl = data?['iconUrl'] as String? ?? '';
      notifyListeners();
    } catch (e, st) {
      debugPrint('getPosterData failed: $e\n$st');
      posterName = posterName ?? '';
      userIconUrl = userIconUrl ?? '';
    }
  }

  Future getUserData(String uid) async {
    try {
      final doc = FirebaseFirestore.instance.collection('users').doc(uid);
      final snapshot = await doc.get().timeout(_loadTimeout);
      final data = snapshot.data();
      userImageUrl = data?['iconUrl'] as String?;
      userName = data?['userName'] as String?;
      notifyListeners();
    } catch (e, st) {
      debugPrint('getUserData failed: $e\n$st');
    }
  }

  Future<List<String?>> getUserDataF(String uid) async {
    try {
      final doc = FirebaseFirestore.instance.collection('users').doc(uid);
      final snapshot = await doc.get().timeout(_loadTimeout);
      final data = snapshot.data();
      return [
        data?['userName'] as String?,
        data?['iconUrl'] as String?,
      ];
    } catch (e) {
      debugPrint('getUserDataF failed: $e');
      return const [null, null];
    }
  }

  void showCount(String text) {
    counterTextVisible = text.isNotEmpty;
    notifyListeners();
  }

  void checkComment(String text) {
    canComment = text.isNotEmpty;
    notifyListeners();
  }

  Future addComment(String postId) async {
    comment = commentController.text;
    final doc = FirebaseFirestore.instance.collection('posts').doc(postId).collection('comments');

    await doc.add({
      'comment': comment,
      'createdAt': DateTime.now(),
      'posterId': uid,
    });

    debugPrint('コメントを送信しました');
    canComment = false;
    await getComments(postId);
    notifyListeners();
  }

  List<CommentDomain> commentsList = [];

  Future getComments(String postId) async {
    try {
      final collection = FirebaseFirestore.instance
          .collection('posts')
          .doc(postId)
          .collection('comments')
          .orderBy('createdAt');

      final snapshot = await collection.get().timeout(_loadTimeout);

      final userInfo = await Future.wait(
        snapshot.docs.map((doc) => getUserDataF(doc['posterId'] as String? ?? '')).toList(),
      );

      commentsList = snapshot.docs.asMap().entries.map((entry) {
        final index = entry.key;
        final doc = entry.value;
        final createdAt = doc['createdAt'];
        final at = createdAt is Timestamp ? createdAt.toDate() : DateTime.now();

        return CommentDomain(
          doc.id,
          doc['comment'] as String? ?? '',
          createTimeMessage(at),
          doc['posterId'] as String? ?? '',
          userInfo[index][0] ?? '',
          userInfo[index][1] ?? '',
        );
      }).toList();

      notifyListeners();
    } catch (e, st) {
      debugPrint('getComments failed: $e\n$st');
      commentsList = [];
      notifyListeners();
    }
  }

  String createTimeMessage(DateTime postDateTime) {
    final now = DateTime.now();
    final difference = now.difference(postDateTime);
    return timeAgo.format(now.subtract(difference), locale: 'ja');
  }

  Future<bool> deleteComment(String postId, String commentId) async {
    final doc = FirebaseFirestore.instance
        .collection('posts')
        .doc(postId)
        .collection('comments')
        .doc(commentId);

    try {
      await doc.delete();
    } on FirebaseException catch (e) {
      debugPrint('deleteComment: ${e.code} ${e.message}');
      return false;
    }
    debugPrint('削除しました');

    await getComments(postId);
    notifyListeners();
    return true;
  }

  Future reportComment(String postId, String commentId, String commentText) async {
    final doc = FirebaseFirestore.instance.collection('reportedComments');

    await doc.add({
      'postId': postId,
      'commentId': commentId,
      'commentText': commentText,
      'reportedAt': DateTime.now(),
    });
    debugPrint('報告しました');
    notifyListeners();
  }
}
