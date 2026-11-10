import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// ライト / ダークの見た目（デフォルトはダーク）。
class AppThemeSettings extends ChangeNotifier {
  static const _prefKey = 'app_dark_mode_v1';

  /// `true` = ダークモード（既定）。
  bool darkMode = true;
  bool _ready = false;

  bool get ready => _ready;

  Future<void> initialize() async {
    if (_ready) return;
    final prefs = await SharedPreferences.getInstance();
    darkMode = prefs.getBool(_prefKey) ?? true;
    _ready = true;
    notifyListeners();
  }

  Future<void> setDarkMode(bool value) async {
    if (darkMode == value) return;
    darkMode = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefKey, value);
  }
}
