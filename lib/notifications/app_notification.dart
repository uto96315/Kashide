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
  });

  final String id;
  final String type;
  final String postId;
  final String fromUserId;
  final String fromUserName;
  final DateTime? createdAt;
  final bool read;

  String get title {
    if (type == 'like') return 'いいねされました';
    return '通知';
  }

  String get body {
    if (type == 'like') {
      final name = fromUserName.isNotEmpty ? fromUserName : '誰か';
      return '$nameさんがあなたの歌詞にいいねしました';
    }
    return '';
  }

  static AppNotification? fromDoc(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    final created = data['createdAt'];
    return AppNotification(
      id: doc.id,
      type: data['type'] as String? ?? '',
      postId: data['postId'] as String? ?? '',
      fromUserId: data['fromUserId'] as String? ?? '',
      fromUserName: data['fromUserName'] as String? ?? '',
      createdAt: created is Timestamp ? created.toDate() : null,
      read: data['read'] as bool? ?? false,
    );
  }
}
