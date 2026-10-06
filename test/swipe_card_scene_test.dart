import 'package:flutter_test/flutter_test.dart';
import 'package:str_gram_beta/common/swipe_card_scene.dart';

void main() {
  group('swipeCardSceneFor', () {
    test('ジャニーズ', () {
      expect(swipeCardSceneFor(['ジャニーズ']), 'images/card_johnnys.jpg');
    });

    test('失恋', () {
      expect(swipeCardSceneFor(['失恋ソング']), 'images/card_sad.jpg');
    });

    test('恋愛', () {
      expect(swipeCardSceneFor(['恋愛ソング']), 'images/card_love.jpg');
    });

    test('優先順位: ジャニーズは恋愛より先', () {
      expect(swipeCardSceneFor(['恋愛ソング', 'ジャニーズ']), 'images/card_johnnys.jpg');
    });

    test('デフォルト', () {
      expect(swipeCardSceneFor(['その他']), 'images/card_other.jpg');
      expect(swipeCardSceneFor([]), 'images/card_other.jpg');
    });
  });
}
