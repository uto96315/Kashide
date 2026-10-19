

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:url_launcher/url_launcher.dart';

class PlaylistDetailsModel extends ChangeNotifier {
  PlaylistDetailsModel(this.playlistId);

  String? uid;
  String playlistId;
  List<Map<String, dynamic>> playlistSongs = [];
  bool ready = false;
  bool _disposed = false;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  Future<void> getPlaylistDetail() async {
    ready = false;
    _notify();

    uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      playlistSongs = [];
      ready = true;
      _notify();
      return;
    }

    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('playlists')
        .doc(playlistId)
        .collection('songs')
        .get();

    if (_disposed) return;

    var baseSongs = snapshot.docs.map((song) {
      final data = song.data();
      return {
        'id': song.id,
        'artist': data['artist'],
        'postId': data['postId'],
        'singName': data['singName'],
        'youtubeUrl': data['youtubeUrl'],
        'addAt': data['addAt'],
        'lyricText': _nonEmpty(data['lyricText']) ?? _nonEmpty(data['text']) ?? '',
      };
    }).toList();

    baseSongs = baseSongs.where(_hasSongIdentity).toList();
    baseSongs.sort(_compareByAddAt);

    playlistSongs = baseSongs.cast<Map<String, dynamic>>();
    ready = true;
    _notify();

    final postIds = baseSongs
        .map((s) => s['postId'])
        .whereType<String>()
        .where((id) => id.isNotEmpty)
        .toSet();
    if (postIds.isEmpty || _disposed) return;

    final postTexts = await _fetchPostTextsBatch(postIds);
    if (_disposed) return;

    playlistSongs = baseSongs.map((song) {
      final postId = song['postId'] as String?;
      final fromPost = postId != null ? postTexts[postId] : null;
      final lyric = _nonEmpty(song['lyricText']) ?? fromPost;
      return {
        ...song,
        if (lyric != null) 'lyricText': lyric,
      };
    }).cast<Map<String, dynamic>>().toList();
    _notify();
  }

  /// プレイリスト保存時点の曲情報があれば表示（歌詞は後追い取得・任意）。
  bool _hasSongIdentity(Map<String, dynamic> song) {
    return _nonEmpty(song['artist']) != null && _nonEmpty(song['singName']) != null;
  }

  String? _nonEmpty(dynamic value) {
    if (value is! String) return null;
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  int _compareByAddAt(Map<String, dynamic> a, Map<String, dynamic> b) {
    return _addAtMillis(a['addAt']).compareTo(_addAtMillis(b['addAt']));
  }

  int _addAtMillis(dynamic addAt) {
    if (addAt is Timestamp) return addAt.millisecondsSinceEpoch;
    if (addAt is DateTime) return addAt.millisecondsSinceEpoch;
    return 0;
  }

  Future<Map<String, String>> _fetchPostTextsBatch(Set<String> postIds) async {
    final result = <String, String>{};
    final ids = postIds.toList();
    const chunkSize = 30;
    for (var start = 0; start < ids.length; start += chunkSize) {
      final end = start + chunkSize > ids.length ? ids.length : start + chunkSize;
      final chunk = ids.sublist(start, end);
      final snap = await FirebaseFirestore.instance
          .collection('posts')
          .where(FieldPath.documentId, whereIn: chunk)
          .get();
      for (final doc in snap.docs) {
        final text = _nonEmpty(doc.data()['text']);
        if (text != null) result[doc.id] = text;
      }
    }
    return result;
  }

  Future deleteFromPlaylist(String songId) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;
    final doc = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('playlists')
        .doc(playlistId)
        .collection('songs')
        .doc(songId);

    try {
      await doc.delete();
    } catch (e) {
      debugPrint(e.toString());
    }
    await getPlaylistDetail();
  }

  Future launchURL(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint(e.toString());
    }
  }
}
