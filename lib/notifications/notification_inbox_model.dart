import 'package:app_badge_plus/app_badge_plus.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import 'app_notification.dart';

class NotificationInboxModel extends ChangeNotifier {
  List<AppNotification> items = [];
  bool loading = true;
  String? error;

  int get unreadCount => items.where((n) => !n.read).length;

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
      items = await _fetchNotifications(uid);
    } on FirebaseException catch (e) {
      debugPrint('notification inbox load: ${e.code} ${e.message}');
      if (e.code == 'permission-denied') {
        error = '通知を読み込めませんでした（Firestoreの権限設定を確認してください）';
      } else {
        error = '通知を読み込めませんでした';
      }
    } catch (e) {
      error = '通知を読み込めませんでした';
      debugPrint('notification inbox load: $e');
    } finally {
      loading = false;
      notifyListeners();
      _syncAppBadge();
    }
  }

  void _syncAppBadge() {
    final count = unreadCount;
    try {
      // ignore: unawaited_futures
      AppBadgePlus.updateBadge(count);
    } catch (_) {}
  }

  Future<List<AppNotification>> _fetchNotifications(String uid) async {
    final ref = FirebaseFirestore.instance.collection('users').doc(uid).collection('notifications');

    try {
      final snap = await ref.orderBy('createdAt', descending: true).limit(50).get();
      return _mapDocs(snap.docs);
    } on FirebaseException catch (e) {
      if (e.code != 'failed-precondition') {
        rethrow;
      }
      final snap = await ref.limit(50).get();
      final list = _mapDocs(snap.docs);
      list.sort((a, b) {
        final at = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bt = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bt.compareTo(at);
      });
      return list;
    }
  }

  List<AppNotification> _mapDocs(List<QueryDocumentSnapshot<Map<String, dynamic>>> docs) {
    return docs.map(AppNotification.fromDoc).whereType<AppNotification>().toList();
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
    _syncAppBadge();
  }

  AppNotification _copyRead(AppNotification n) => AppNotification(
        id: n.id,
        type: n.type,
        postId: n.postId,
        fromUserId: n.fromUserId,
        fromUserName: n.fromUserName,
        createdAt: n.createdAt,
        read: true,
        commentPreview: n.commentPreview,
      );
}
