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

    if (ordered.isEmpty) {
      posts = [];
      loading = false;
      _notify();
      return;
    }

    final postSnapshots = await Future.wait(
      ordered.map((like) => FirebaseFirestore.instance.collection('posts').doc(like.id).get()),
    );
    if (_disposed) return;

    final docs = <DocumentSnapshot<Map<String, dynamic>>>[];
    for (var i = 0; i < ordered.length; i++) {
      final snap = postSnapshots[i];
      final data = snap.data();
      if (!snap.exists || data == null) continue;
      docs.add(snap);
    }

    if (docs.isEmpty) {
      posts = [];
      loading = false;
      _notify();
      return;
    }

    final userInfo = await Future.wait(
      docs.map((doc) => _getUserData(doc.data()?['posterId'] as String? ?? '')),
    );
    if (_disposed) return;

    final commentCount = await Future.wait(docs.map((doc) => getCommentCount(doc.id)));
    if (_disposed) return;

    posts = docs.asMap().entries.map((entry) {
      final index = entry.key;
      final doc = entry.value;
      final data = doc.data()!;
      final created = data['createdAt'];
      return Post(
        data['artist'] ?? '',
        data['singName'] ?? '',
        data['text'] ?? '',
        data['posterId'] ?? '',
        data['likedCount'] ?? 0,
        data['genres'] ?? [],
        '${userInfo[index][0]}',
        '${userInfo[index][1]}',
        created is Timestamp ? timeAgo.format(created.toDate(), locale: 'ja') : '',
        doc.id,
        commentCount[index],
        data['explanation'] ?? '',
        data['youtubeLink'] ?? '',
      );
    }).toList();

    loading = false;
    _notify();
  }

  Future<List<dynamic>> _getUserData(String posterId) async {
    if (posterId.isEmpty) return ['', ''];
    final snapshot = await FirebaseFirestore.instance.collection('users').doc(posterId).get();
    final data = snapshot.data();
    return [data?['userName'], data?['iconUrl']];
  }

  Future<int> getCommentCount(String id) async {
    final snapshot = await FirebaseFirestore.instance.collection('posts').doc(id).collection('comments').get();
    return snapshot.docs.length;
  }

  int _millis(dynamic value) => value is Timestamp ? value.millisecondsSinceEpoch : 0;
}
