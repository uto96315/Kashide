import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

class NotificationModel extends ChangeNotifier {
  String? token;

  Future getToken() async {
    try {
      await FirebaseMessaging.instance.requestPermission();
      if (Platform.isIOS) {
        token = await FirebaseMessaging.instance.getAPNSToken();
      } else {
        token = await FirebaseMessaging.instance.getToken();
      }
    } catch (e) {
      debugPrint('通知トークンを取得できませんでした: $e');
    }
  }
}
