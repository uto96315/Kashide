import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:package_info_plus/package_info_plus.dart';

class HomeModel extends ChangeNotifier {
  String? os; // iOSかandroidか
  bool needToUpDate = false;
  bool versionChecked = false;
  String? nowVersion;
  String? latestVersion;
  String? updateUrl;

  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _latestVersionSub;

  /// 起動時および Firestore 更新時に必須アップデート要否を反映する。
  Future<void> startVersionMonitoring() async {
    await getNowVersions();
    await _latestVersionSub?.cancel();
    _latestVersionSub = FirebaseFirestore.instance
        .collection('config')
        .doc('latestVersions')
        .snapshots()
        .listen(
      (snapshot) {
        if (!snapshot.exists) {
          needToUpDate = false;
          versionChecked = true;
          notifyListeners();
          return;
        }
        _applyLatestVersionData(snapshot.data());
      },
      onError: (Object e, StackTrace st) {
        debugPrint('latestVersions listen failed: $e\n$st');
      },
    );
  }

  /// フォアグラウンド復帰時の保険（リスナー取りこぼし対策）。
  Future<void> refreshLatestVersions() async {
    try {
      if (nowVersion == null) await getNowVersions();
      final snapshot = await FirebaseFirestore.instance
          .collection('config')
          .doc('latestVersions')
          .get();
      if (!snapshot.exists) {
        needToUpDate = false;
      } else {
        _applyLatestVersionData(snapshot.data());
        return;
      }
    } catch (e, st) {
      debugPrint('refreshLatestVersions failed: $e\n$st');
    }
    versionChecked = true;
    notifyListeners();
  }

  Future getNowVersions() async {
    final packageInfo = await PackageInfo.fromPlatform();
    nowVersion = packageInfo.version;
    notifyListeners();
  }

  void _applyLatestVersionData(Map<String, dynamic>? data) {
    if (data == null) return;
    if (Platform.isAndroid) {
      latestVersion = data['android'] as String?;
      updateUrl =
          'https://play.google.com/store/apps/details?id=com.yuto.mabe.kashide';
    } else {
      latestVersion = data['ios'] as String?;
      updateUrl = 'https://apps.apple.com/jp/app/kashide/id6444030139';
    }
    needToUpDate = _isNewer(latestVersion, nowVersion);
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
      final latestValue =
          i < latestParts.length ? int.tryParse(latestParts[i]) ?? 0 : 0;
      final currentValue =
          i < currentParts.length ? int.tryParse(currentParts[i]) ?? 0 : 0;
      if (latestValue != currentValue) return latestValue > currentValue;
    }
    return false;
  }

  @override
  void dispose() {
    unawaited(_latestVersionSub?.cancel());
    _latestVersionSub = null;
    super.dispose();
  }
}
