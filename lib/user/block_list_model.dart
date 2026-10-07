import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class BlockedUserEntry {
  BlockedUserEntry({
    required this.userId,
    required this.userName,
    this.blockedAt,
  });

  final String userId;
  final String userName;
  final DateTime? blockedAt;
}

class BlockListModel extends ChangeNotifier {
  List<BlockedUserEntry> entries = [];
  bool ready = false;
  bool _disposed = false;

  Set<String> get blockedIds => entries.map((e) => e.userId).toSet();

  bool isBlocked(String? userId) {
    if (userId == null || userId.isEmpty) return false;
    return blockedIds.contains(userId);
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  CollectionReference<Map<String, dynamic>>? get _collection {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return null;
    return FirebaseFirestore.instance.collection('users').doc(uid).collection('blockList');
  }

  Future<void> load() async {
    final col = _collection;
    if (col == null) {
      entries = [];
      ready = true;
      _notify();
      return;
    }
    final snapshot = await col.get();
    if (_disposed) return;
    final byUser = <String, BlockedUserEntry>{};
    for (final doc in snapshot.docs) {
      final data = doc.data();
      final userId = (data['id'] as String?)?.trim().isNotEmpty == true ? data['id'] as String : doc.id;
      final at = data['blockedAt'];
      final entry = BlockedUserEntry(
        userId: userId,
        userName: (data['blockedUserName'] as String?)?.trim().isNotEmpty == true
            ? data['blockedUserName'] as String
            : 'ユーザー',
        blockedAt: at is Timestamp ? at.toDate() : null,
      );
      byUser[userId] = entry;
    }
    entries = byUser.values.toList()
      ..sort((a, b) => (b.blockedAt ?? DateTime.fromMillisecondsSinceEpoch(0))
          .compareTo(a.blockedAt ?? DateTime.fromMillisecondsSinceEpoch(0)));
    ready = true;
    _notify();
  }

  Future<void> blockUser(String posterId) async {
    final col = _collection;
    if (col == null || posterId.isEmpty) return;
    final target = await FirebaseFirestore.instance.collection('users').doc(posterId).get();
    final name = target.data()?['userName'] as String? ?? 'ユーザー';
    await col.doc(posterId).set({
      'id': posterId,
      'blockedAt': FieldValue.serverTimestamp(),
      'blockedUserName': name,
    });
    await load();
  }

  Future<void> unblockUser(String posterId) async {
    final col = _collection;
    if (col == null || posterId.isEmpty) return;
    await col.doc(posterId).delete();
    final legacy = await col.where('id', isEqualTo: posterId).get();
    for (final doc in legacy.docs) {
      await doc.reference.delete();
    }
    await load();
  }
}
