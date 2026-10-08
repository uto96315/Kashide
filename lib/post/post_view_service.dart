import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:str_gram_beta/domain/post_domain.dart';

/// 投稿詳細を開いたときの閲覧数（1ユーザー×1投稿あたり最大 [maxViewsPerUser] 回まで加算）。
class PostViewService {
  PostViewService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  static const maxViewsPerUser = 5;

  final FirebaseFirestore _firestore;

  Future<int> recordDetailView({
    required String postId,
    required String viewerUid,
  }) async {
    if (postId.isEmpty || viewerUid.isEmpty) {
      return await fetchViewCount(postId);
    }

    final postRef = _firestore.collection('posts').doc(postId);
    final userViewRef =
        _firestore.collection('users').doc(viewerUid).collection('postViews').doc(postId);

    try {
      return await _firestore.runTransaction((tx) async {
        final postSnap = await tx.get(postRef);
        if (!postSnap.exists) return 0;

        final postData = postSnap.data()!;
        final viewCount = (postData['viewCount'] as num?)?.toInt() ?? 0;
        final posterId = postData['posterId'] as String?;
        if (posterId == viewerUid) return viewCount;

        final userSnap = await tx.get(userViewRef);
        final userViews =
            userSnap.exists ? (userSnap.data()?['count'] as num?)?.toInt() ?? 0 : 0;
        if (userViews >= maxViewsPerUser) return viewCount;

        tx.set(
          userViewRef,
          {
            'count': userViews + 1,
            'updatedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
        // increment だとセキュリティルールの +1 判定と噛み合わないことがあるため明示的に +1
        tx.update(postRef, {'viewCount': viewCount + 1});
        return viewCount + 1;
      });
    } catch (e, st) {
      debugPrint('recordDetailView failed: $e\n$st');
      return fetchViewCount(postId);
    }
  }

  Future<int> fetchViewCount(String postId) async {
    if (postId.isEmpty) return 0;
    try {
      final snap = await _firestore.collection('posts').doc(postId).get();
      return (snap.data()?['viewCount'] as num?)?.toInt() ?? 0;
    } catch (_) {
      return 0;
    }
  }
}

int viewCountFromFirestore(Map<String, dynamic> data) =>
    (data['viewCount'] as num?)?.toInt() ?? 0;

/// 一覧の [Post.viewCount] を Firestore の値に合わせる（詳細画面から戻ったあとなど）。
Future<void> refreshViewCountInList(List<Post> posts, String postId) async {
  if (postId.isEmpty) return;
  final count = await PostViewService().fetchViewCount(postId);
  final i = posts.indexWhere((p) => p.id == postId);
  if (i >= 0) {
    posts[i].viewCount = count;
  }
}
