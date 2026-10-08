import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:str_gram_beta/common/ThemeColor.dart';

class TimelineTutorialStorage {
  static const _version = 2;

  static String _key(String? uid) => 'timeline_tutorial_v${_version}_${uid ?? 'local'}';

  static Future<bool> shouldShow(String? uid) async {
    final prefs = await SharedPreferences.getInstance();
    return !(prefs.getBool(_key(uid)) ?? false);
  }

  static Future<void> markComplete(String? uid) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key(uid), true);
  }
}

const timelineTutorialStepCount = 3;

String timelineTutorialTitle(int step) {
  switch (step) {
    case 0:
      return 'カードとタイムライン';
    case 1:
      return 'スワイプとボタン';
    case 2:
      return '絞り込み・再生・並び替え';
    default:
      return '';
  }
}

String timelineTutorialBody(int step) {
  switch (step) {
    case 0:
      return '右上の切り替えで、スワイプのカード表示と一覧のタイムライン表示を変えられます。';
    case 1:
      return '右スワイプ／いいねで保存、左スワイプ／✕はカードに出さない（タイムラインには残ります）。真ん中はプレイリストに追加です。';
    case 2:
      return '絞り込みで条件を指定、音符はカードの自動再生（マナーモードでは鳴りません）、並び替えで表示順を変えられます。';
    default:
      return '';
  }
}

/// マイページのメニューから手動起動。自動表示はしない（モーダル競合を避ける）。
class TimelineTutorialFlow {
  static Future<void> run(BuildContext context, {required String? uid}) async {
    for (var step = 0; step < timelineTutorialStepCount; step++) {
      if (!context.mounted) return;
      final last = step >= timelineTutorialStepCount - 1;
      final skipped = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          title: Text('${step + 1} / $timelineTutorialStepCount  ${timelineTutorialTitle(step)}'),
          content: SingleChildScrollView(
            child: Text(timelineTutorialBody(step), style: const TextStyle(height: 1.45)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('スキップ'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: mainColor),
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(last ? 'はじめる' : '次へ'),
            ),
          ],
        ),
      );
      if (!context.mounted) return;
      if (skipped == true) {
        await TimelineTutorialStorage.markComplete(uid);
        return;
      }
    }
    await TimelineTutorialStorage.markComplete(uid);
  }
}
