import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// カード（スワイプ）表示で曲プレビューを自動再生するか。
class CardAutoplaySettings extends ChangeNotifier {
  static const _prefKey = 'card_swipe_autoplay_apple_music';

  bool enabled = false;
  bool _ready = false;

  bool get ready => _ready;

  Future<void> initialize() async {
    if (_ready) return;
    final prefs = await SharedPreferences.getInstance();
    enabled = prefs.getBool(_prefKey) ?? false;
    _ready = true;
    notifyListeners();
  }

  Future<void> setEnabled(bool value) async {
    if (enabled == value) return;
    enabled = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefKey, value);
  }
}
