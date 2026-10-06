import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:str_gram_beta/domain/post_domain.dart';
import 'package:timeago/timeago.dart' as timeAgo;

class LikedPostsModel extends ChangeNotifier {
  List<Post> posts = [];
  var loading = true;
  bool _disposed = false;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  Future<void> load() async {
    loading = true;
    _notify();
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      posts = [];
      loading = false;
      _notify();
      return;
    }

    final likes = await FirebaseFirestore.instance.collection('users').doc(uid).collection('likePost').get();
    if (_disposed) return;

    final ordered = likes.docs.toList()
      ..sort((a, b) => _millis(b.data()['likedAt']).compareTo(_millis(a.data()['likedAt'])));

    final loaded = <Post>[];
    for (final like in ordered) {
      if (_disposed) return;
      final postDoc = await FirebaseFirestore.instance.collection('posts').doc(like.id).get();
      final data = postDoc.data();
      if (data == null) continue;
      final posterId = data['posterId'] as String? ?? '';
      final user = await FirebaseFirestore.instance.collection('users').doc(posterId).get();
      if (_disposed) return;
      final userData = user.data();
      final created = data['createdAt'];
      final commentCount = await getCommentCount(postDoc.id);
      if (_disposed) return;
      loaded.add(Post(
        data['artist'] ?? '',
        data['singName'] ?? '',
        data['text'] ?? '',
        posterId,
        data['likedCount'] ?? 0,
        data['genres'] ?? [],
        '${userData?['userName'] ?? ''}',
        '${userData?['iconUrl'] ?? ''}',
        created is Timestamp ? timeAgo.format(created.toDate(), locale: 'ja') : '',
        postDoc.id,
        commentCount,
        data['explanation'] ?? '',
        data['youtubeLink'] ?? '',
      ));
    }
    posts = loaded;
    loading = false;
    _notify();
  }

  Future<int> getCommentCount(String id) async {
    final doc = FirebaseFirestore.instance.collection('posts').doc(id).collection('comments');
    final snapshot = await doc.get();
    return snapshot.docs.length;
  }

  int _millis(dynamic value) => value is Timestamp ? value.millisecondsSinceEpoch : 0;
}
