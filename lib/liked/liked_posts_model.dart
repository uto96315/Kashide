import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:str_gram_beta/domain/post_domain.dart';
import 'package:timeago/timeago.dart' as timeAgo;

class LikedPostsModel extends ChangeNotifier {
  List<Post> posts = [];
  var loading = true;

  Future<void> load() async {
    loading = true;
    notifyListeners();
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      posts = [];
      loading = false;
      notifyListeners();
      return;
    }

    final likes = await FirebaseFirestore.instance.collection('users').doc(uid).collection('likePost').get();
    final ordered = likes.docs.toList()
      ..sort((a, b) => _millis(b.data()['likedAt']).compareTo(_millis(a.data()['likedAt'])));

    final loaded = <Post>[];
    for (final like in ordered) {
      final postDoc = await FirebaseFirestore.instance.collection('posts').doc(like.id).get();
      final data = postDoc.data();
      if (data == null) continue;
      final posterId = data['posterId'] as String? ?? '';
      final user = await FirebaseFirestore.instance.collection('users').doc(posterId).get();
      final userData = user.data();
      final created = data['createdAt'];
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
        0,
        data['explanation'] ?? '',
        data['youtubeLink'] ?? '',
      ));
    }
    posts = loaded;
    loading = false;
    notifyListeners();
  }

  int _millis(dynamic value) => value is Timestamp ? value.millisecondsSinceEpoch : 0;
}
