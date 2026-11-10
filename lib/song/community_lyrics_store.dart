import 'package:cloud_firestore/cloud_firestore.dart';

/// ユーザーが手入力した全文歌詞（外部APIに無い曲向け）。
class CommunityLyricsStore {
  static String docId(String artist, String title) {
    return '${_compact(artist)}__${_compact(title)}';
  }

  static String _compact(String value) =>
      value.toLowerCase().replaceAll(RegExp(r'[\s.\u3000]'), '');

  Future<String?> fetch(String artist, String title) async {
    final a = artist.trim();
    final t = title.trim();
    if (a.isEmpty || t.isEmpty) return null;
    try {
      final snap = await FirebaseFirestore.instance
          .collection('communityLyrics')
          .doc(docId(a, t))
          .get();
      final text = snap.data()?['plainLyrics']?.toString().trim();
      if (text == null || text.isEmpty) return null;
      return text;
    } catch (_) {
      return null;
    }
  }

  /// 既存ドキュメントは上書きしない（先に入った版を維持）。
  Future<void> saveContributed({
    required String artist,
    required String title,
    required String plainLyrics,
  }) async {
    final body = plainLyrics.trim();
    if (body.length < 40) return;
    final a = artist.trim();
    final t = title.trim();
    if (a.isEmpty || t.isEmpty) return;
    try {
      final ref =
          FirebaseFirestore.instance.collection('communityLyrics').doc(docId(a, t));
      final existing = await ref.get();
      if (existing.exists) return;
      await ref.set({
        'artist': a,
        'singName': t,
        'plainLyrics': body,
        'source': 'manual',
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {}
  }
}
