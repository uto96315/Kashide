import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/post_domain.dart';

/// 複数箇所の歌詞を1フィールドに保存するときの区切り（表示もこの間隔）。
const postLyricsSegmentGap = '\n\n';

const maxLyricSegments = 5;

String combineLyricSegments(Iterable<String> segments) {
  return segments.map((s) => s.trim()).where((s) => s.isNotEmpty).join(postLyricsSegmentGap);
}

List<String> lyricSegmentsFromFirestore(Map<String, dynamic>? data) {
  if (data == null) return const [];
  final raw = data['textSegments'];
  if (raw is List && raw.isNotEmpty) {
    return raw
        .map((e) => e.toString().trim())
        .where((s) => s.isNotEmpty)
        .toList(growable: false);
  }
  return const [];
}

/// カード・詳細で見せるブロック（2箇所以上なら分割表示）。
List<String> lyricBlocksForDisplay(Post post) {
  if (post.textSegments.length > 1) return post.textSegments;
  final t = post.text.trim();
  if (t.isEmpty) return const [];
  return [post.text];
}

Map<String, dynamic> lyricFieldsForFirestore({
  required List<String> segments,
  bool forUpdate = false,
}) {
  final cleaned = segments.map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
  final combined = combineLyricSegments(cleaned);
  if (cleaned.length > 1) {
    return {'text': combined, 'textSegments': cleaned};
  }
  if (forUpdate) {
    return {'text': combined, 'textSegments': FieldValue.delete()};
  }
  return {'text': combined};
}
