import 'package:flutter_test/flutter_test.dart';
import 'package:str_gram_beta/common/genre_empty_message.dart';

void main() {
  test('genreEmptyMessage by condition', () {
    expect(genreEmptyMessage('genre'), 'このジャンルの投稿はまだありません。');
    expect(genreEmptyMessage('artist'), 'この歌手の投稿はまだありません。');
    expect(genreEmptyMessage('singName'), 'この曲の投稿はまだありません。');
    expect(genreEmptyMessage('poster'), 'この人の投稿はまだありません。');
  });
}
