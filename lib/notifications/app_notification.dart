import 'package:cloud_firestore/cloud_firestore.dart';

class AppNotification {
  AppNotification({
    required this.id,
    required this.type,
    required this.postId,
    required this.fromUserId,
    required this.fromUserName,
    required this.createdAt,
    required this.read,
    this.commentPreview,
  });

  final String id;
  final String type;
  final String postId;
  final String fromUserId;
  final String fromUserName;
  final DateTime? createdAt;
  final bool read;
  final String? commentPreview;

  String get title {
    if (type == 'like') return 'いいねされました';
    if (type == 'comment') return 'コメントされました';
    return '通知';
  }

  String get body {
    final name = fromUserName.isNotEmpty ? fromUserName : '誰か';
    if (type == 'like') {
      return '$nameさんがあなたの歌詞にいいねしました';
    }
    if (type == 'comment') {
      final preview = commentPreview?.trim();
      if (preview != null && preview.isNotEmpty) {
        return '$nameさん: $preview';
      }
      return '$nameさんがあなたの歌詞にコメントしました';
    }
    return '';
  }

  static String _normalizeType(Map<String, dynamic> data) {
    final raw = (data['type'] as String? ?? '').trim().toLowerCase();
    if (raw == 'like' || raw == 'comment') return raw;
    if (data['commentId'] != null || data['commentPreview'] != null) return 'comment';
    return raw;
  }

  static AppNotification? fromDoc(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    final created = data['createdAt'];
    return AppNotification(
      id: doc.id,
      type: _normalizeType(data),
      postId: data['postId'] as String? ?? '',
      fromUserId: data['fromUserId'] as String? ?? '',
      fromUserName: data['fromUserName'] as String? ?? '',
      createdAt: created is Timestamp ? created.toDate() : null,
      read: data['read'] as bool? ?? false,
      commentPreview: data['commentPreview'] as String?,
    );
  }
}
