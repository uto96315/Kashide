import 'package:flutter/foundation.dart';

/// チュートリアル中にカード全体へ縦スライドのデモを載せるとき用。
class SwipeDeckTutorialCue extends ChangeNotifier {
  double _dragDy = 0;

  double get dragDy => _dragDy;

  set dragDy(double value) {
    if (_dragDy == value) return;
    _dragDy = value;
    notifyListeners();
  }

  void reset({bool notify = true}) {
    if (_dragDy == 0) return;
    _dragDy = 0;
    if (notify) notifyListeners();
  }
}
