import 'package:flutter/foundation.dart';

/// チュートリアル中にカード/一覧表示を実際に切り替えるとき用。
class TimelineViewTutorialCue extends ChangeNotifier {
  bool? _deckOverride;

  bool? get deckOverride => _deckOverride;

  void previewDeck(bool deck) {
    if (_deckOverride == deck) return;
    _deckOverride = deck;
    notifyListeners();
  }

  void reset({bool notify = true}) {
    if (_deckOverride == null) return;
    _deckOverride = null;
    if (notify) notifyListeners();
  }
}
