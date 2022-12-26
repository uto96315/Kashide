import 'package:app_review/app_review.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';

class NotificationModel extends ChangeNotifier {
  // todo: 消す
  String? token;

  // 通知のための設定
  // todo: nullになる
  Future getToken() async {
    // FirebaseMessaging.instance.requestPermission();
    token = await FirebaseMessaging.instance.getAPNSToken();
    print(token ?? "取得失敗");
  }
}
