import 'package:flutter_test/flutter_test.dart';
import 'package:str_gram_beta/post/post_lyrics.dart';

void main() {
  test('combineLyricSegments joins with blank line', () {
    expect(combineLyricSegments(['A', 'B']), 'A\n\nB');
  });

  test('lyricFieldsForFirestore stores segments when multiple', () {
    final fields = lyricFieldsForFirestore(segments: ['x', 'y']);
    expect(fields['text'], 'x\n\ny');
    expect(fields['textSegments'], ['x', 'y']);
  });

  test('lyricSegmentsFromFirestore reads array', () {
    expect(
      lyricSegmentsFromFirestore({'textSegments': ['a', 'b']}),
      ['a', 'b'],
    );
  });
}
