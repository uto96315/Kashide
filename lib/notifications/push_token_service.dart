import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

/// 投稿者へプッシュ通知するために FCM トークンを Firestore に保存する。
class PushTokenService {
  static StreamSubscription<String>? _tokenRefreshSub;

  Future<void> syncForCurrentUser() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    try {
      final messaging = FirebaseMessaging.instance;
      await messaging.requestPermission(alert: true, badge: true, sound: true);

      if (Platform.isIOS) {
        // APNs 登録後に FCM トークンが取れるまで少し待つことがある。
        await messaging.getAPNSToken();
      }

      final token = await messaging.getToken();
      if (token == null || token.isEmpty) return;

      await FirebaseFirestore.instance.collection('users').doc(uid).set(
        {
          'fcmToken': token,
          'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      await _tokenRefreshSub?.cancel();
      _tokenRefreshSub = messaging.onTokenRefresh.listen((next) async {
        final currentUid = FirebaseAuth.instance.currentUser?.uid;
        if (currentUid == null || next.isEmpty) return;
        await FirebaseFirestore.instance.collection('users').doc(currentUid).set(
          {
            'fcmToken': next,
            'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
      });
    } catch (e, st) {
      debugPrint('FCM token sync failed: $e\n$st');
    }
  }
}
