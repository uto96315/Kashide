import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'dart:io';

class HomeModel extends ChangeNotifier {

  String? os; // iOSかandroidか
  bool needToUpDate = false;
  bool versionChecked = false;
  String? nowVersion;
  String? latestVersion;
  String? updateUrl;

  // バージョンを取得する関数
  Future getNowVersions()async{
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    nowVersion = packageInfo.version; // 現在のバージョンを取得
    notifyListeners();
  }

  // 最新のバージョンを取得する
  Future getLatestVersions() async {
    try {
      if (nowVersion == null) await getNowVersions();
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
      needToUpDate = _isNewer(latestVersion, nowVersion);
    } catch (e) {
      debugPrint(e.toString());
      needToUpDate = false;
    }
    versionChecked = true;
    notifyListeners();
  }

  bool _isNewer(String? latest, String? current) {
    if (latest == null || latest.isEmpty || current == null || current.isEmpty) {
      return false;
    }
    final latestParts = latest.split('.');
    final currentParts = current.split('.');
    final length = latestParts.length > currentParts.length
        ? latestParts.length
        : currentParts.length;
    for (var i = 0; i < length; i++) {
      final latestValue = i < latestParts.length ? int.tryParse(latestParts[i]) ?? 0 : 0;
      final currentValue = i < currentParts.length ? int.tryParse(currentParts[i]) ?? 0 : 0;
      if (latestValue != currentValue) return latestValue > currentValue;
    }
    return false;
  }
}