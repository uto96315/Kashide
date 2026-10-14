import 'package:flutter/foundation.dart';

/// チュートリアルが実カードにスワイプの動きを載せるとき用。
class SwipeDeckSwipeCue extends ChangeNotifier {
  double _dragDx = 0;

  double get dragDx => _dragDx;

  set dragDx(double value) {
    if (_dragDx == value) return;
    _dragDx = value;
    notifyListeners();
  }

  void reset({bool notify = true}) {
    if (_dragDx == 0) return;
    _dragDx = 0;
    if (notify) notifyListeners();
  }
}
