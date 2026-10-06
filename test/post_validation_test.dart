import 'package:flutter_test/flutter_test.dart';
import 'package:str_gram_beta/post/post_validation.dart';

void main() {
  group('validatePostForm', () {
    test('requires song pick', () {
      expect(
        validatePostForm(singerName: '', singName: '', lyrics: '', explanationLength: 0),
        '曲を一覧から選んでください',
      );
    });

    test('requires lyrics', () {
      expect(
        validatePostForm(singerName: 'A', singName: 'B', lyrics: '', explanationLength: 0),
        '歌詞の範囲を選んでください',
      );
    });

    test('rejects long lyrics', () {
      expect(
        validatePostForm(singerName: 'A', singName: 'B', lyrics: 'x' * 301, explanationLength: 0),
        '歌詞は300文字以内で選んでください',
      );
    });

    test('ok for valid input', () {
      expect(
        validatePostForm(singerName: 'A', singName: 'B', lyrics: '歌詞', explanationLength: 10),
        isNull,
      );
    });
  });
}
