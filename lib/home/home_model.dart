import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'dart:io';

class HomeModel extends ChangeNotifier {

  String? os; // iOSかandroidか
  bool needToUpDate = false;
  String? nowVersion;
  String? latestVersion;
  String? updateUrl;

  // バージョンを取得する関数
  Future getNowVersions()async{
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    nowVersion = packageInfo.version; // 現在のバージョンを取得
    notifyListeners();
  }

  Future getLatestVersions() async {
    final doc = FirebaseFirestore.instance
        .collection("config").doc("latestVersions");
    final snapshot = await doc.get();
    if(Platform.isAndroid) {
      latestVersion = snapshot["android"];
      updateUrl = "https://play.google.com/store/apps/details?id=com.yuto.mabe.kashide";
    } else {
      latestVersion = snapshot["ios"];
      updateUrl = "https://apps.apple.com/jp/app/kashide/id6444030139";
    }

    await checkNeedToUpdate();
    notifyListeners();
  }

  Future checkNeedToUpdate()async{
    debugPrint("現在のバージョンは");
    debugPrint(nowVersion);
    debugPrint("最新のバージョンは");
    debugPrint(latestVersion);
    if(latestVersion != nowVersion) {
      needToUpDate = true;
      debugPrint("アップデートが必要です");
    }
    debugPrint("現在のバージョンが最新です");
    notifyListeners();
  }
}