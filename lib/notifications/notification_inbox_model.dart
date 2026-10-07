import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import 'app_notification.dart';

class NotificationInboxModel extends ChangeNotifier {
  List<AppNotification> items = [];
  bool loading = true;
  String? error;

  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  Future<void> load() async {
    final uid = _uid;
    if (uid == null) {
      items = [];
      loading = false;
      notifyListeners();
      return;
    }

    loading = true;
    error = null;
    notifyListeners();

    try {
      final snap = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('notifications')
          .orderBy('createdAt', descending: true)
          .limit(50)
          .get();

      items = snap.docs.map(AppNotification.fromDoc).whereType<AppNotification>().toList();
    } catch (e) {
      error = '通知を読み込めませんでした';
      debugPrint('notification inbox load: $e');
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> markRead(String id) async {
    final uid = _uid;
    if (uid == null) return;
    await FirebaseFirestore.instance.collection('users').doc(uid).collection('notifications').doc(id).set(
      {'read': true},
      SetOptions(merge: true),
    );
    items = items.map((n) => n.id == id ? _copyRead(n) : n).toList();
    notifyListeners();
  }

  AppNotification _copyRead(AppNotification n) => AppNotification(
        id: n.id,
        type: n.type,
        postId: n.postId,
        fromUserId: n.fromUserId,
        fromUserName: n.fromUserName,
        createdAt: n.createdAt,
        read: true,
      );
}
