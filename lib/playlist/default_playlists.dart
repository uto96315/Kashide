import 'package:cloud_firestore/cloud_firestore.dart';

/// 新規ユーザー向けの初期プレイリストと「自分の投稿」への自動追加。
class DefaultPlaylists {
  DefaultPlaylists._();

  static const favoriteDisplayName = 'お気に入り';
  static const myPostsDisplayName = '自分の投稿';

  static const systemKeyFavorite = 'favorite';
  static const systemKeyMyPosts = 'my_posts';

  static CollectionReference<Map<String, dynamic>> _playlistsRef(String uid) {
    return FirebaseFirestore.instance.collection('users').doc(uid).collection('playlists');
  }

  /// 不足している初期プレイリストを作成し、既存の同名プレイリストに systemKey を付与する。
  static Future<void> ensureForUser(String uid) async {
    final ref = _playlistsRef(uid);
    final snapshot = await ref.get();

    var hasFavorite = false;
    var hasMyPosts = false;

    for (final doc in snapshot.docs) {
      final data = doc.data();
      final key = data['systemKey'] as String?;
      final name = data['playlistName'] as String?;
      if (key == systemKeyFavorite || name == favoriteDisplayName) {
        hasFavorite = true;
        if (key != systemKeyFavorite) {
          await doc.reference.update({'systemKey': systemKeyFavorite});
        }
      }
      if (key == systemKeyMyPosts || name == myPostsDisplayName) {
        hasMyPosts = true;
        if (key != systemKeyMyPosts) {
          await doc.reference.update({'systemKey': systemKeyMyPosts});
        }
      }
    }

    final now = FieldValue.serverTimestamp();
    if (!hasFavorite) {
      await ref.add({
        'playlistName': favoriteDisplayName,
        'systemKey': systemKeyFavorite,
        'createdAt': now,
      });
    }
    if (!hasMyPosts) {
      await ref.add({
        'playlistName': myPostsDisplayName,
        'systemKey': systemKeyMyPosts,
        'createdAt': now,
      });
    }
  }

  static Future<String?> _playlistIdForSystemKey(String uid, String systemKey) async {
    final snap = await _playlistsRef(uid)
        .where('systemKey', isEqualTo: systemKey)
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    return snap.docs.first.id;
  }

  /// 新規投稿を「自分の投稿」プレイリストに追加する。
  static Future<void> addOwnPost({
    required String uid,
    required String postId,
    required String artist,
    required String singName,
    required String youtubeUrl,
    String? lyricText,
  }) async {
    await ensureForUser(uid);
    final playlistId = await _playlistIdForSystemKey(uid, systemKeyMyPosts);
    if (playlistId == null) return;

    final payload = <String, dynamic>{
      'singName': singName,
      'artist': artist,
      'youtubeUrl': youtubeUrl,
      'postId': postId,
      'addAt': DateTime.now(),
    };
    final lyric = lyricText?.trim();
    if (lyric != null && lyric.isNotEmpty) {
      payload['lyricText'] = lyric;
    }

    await _playlistsRef(uid).doc(playlistId).collection('songs').add(payload);
  }

  static bool isSystemPlaylist(String? systemKey) {
    return systemKey == systemKeyFavorite || systemKey == systemKeyMyPosts;
  }
}
