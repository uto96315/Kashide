import 'package:flutter_test/flutter_test.dart';
import 'package:str_gram_beta/common/genre_empty_message.dart';
import 'package:str_gram_beta/common/swipe_card_scene.dart';

void main() {
  test('app copy and assets helpers smoke', () {
    expect(genreEmptyMessage('genre'), isNotEmpty);
    expect(swipeCardSceneFor(['JPOP']), 'images/card_jpop.jpg');
  });
}
