import 'package:flutter_test/flutter_test.dart';
import 'package:str_gram_beta/common/genre_browse_scene.dart';

void main() {
  test('genreBrowseImageFor assigns known genres', () {
    expect(genreBrowseImageFor('JPOP'), 'images/card_jpop.jpg');
    expect(genreBrowseImageFor('男性目線'), 'images/card_male.jpg');
    expect(genreBrowseImageFor('女性目線'), 'images/card_female.jpg');
    expect(genreBrowseImageFor('ペット'), 'images/card_pet.jpg');
  });

  test('genreBrowseImageFor falls back for unknown genre', () {
    expect(genreBrowseImageFor('未知のジャンル'), startsWith('images/card_'));
  });
}
