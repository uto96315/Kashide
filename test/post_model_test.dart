import 'package:flutter_test/flutter_test.dart';
import 'package:str_gram_beta/post/post_model.dart';
import 'package:str_gram_beta/song/song_quote.dart';

void main() {
  group('PostModel genre', () {
    late PostModel model;

    setUp(() {
      model = PostModel(null);
    });

    tearDown(() {
      model.lyricsController.dispose();
      model.singerNameController.dispose();
      model.singNameController.dispose();
      model.genreController.dispose();
      model.explanationController.dispose();
      model.youtubeLinkController.dispose();
    });

    test('setGenre adds up to three genres', () {
      model.setGenre('JPOP');
      model.setGenre('ロック');
      model.setGenre('洋楽');
      expect(model.genres.length, 3);
      model.setGenre('懐メロ');
      expect(model.genres.length, 3);
      expect(model.genreMaxLength, isFalse);
    });

    test('deleteGenre removes genre', () {
      model.setGenre('JPOP');
      model.deleteGenre('JPOP');
      expect(model.genres, isEmpty);
    });

    test('applyQuote sets canPush when valid', () {
      model.applyQuote(
        const SongQuote(
          artist: 'Artist',
          title: 'Title',
          lyrics: '歌詞',
          listenUrl: 'https://example.com',
        ),
      );
      expect(model.canPush, isTrue);
    });
  });
}
