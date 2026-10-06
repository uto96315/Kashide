import 'package:flutter_test/flutter_test.dart';
import 'package:str_gram_beta/domain/post_domain.dart';
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

    test('rejects too short lyrics', () {
      expect(
        validatePostForm(
          singerName: 'A',
          singName: 'B',
          lyrics: '123456789',
          explanationLength: 0,
        ),
        '歌詞は10文字以上選んでください',
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
        validatePostForm(
          singerName: 'A',
          singName: 'B',
          lyrics: '1234567890',
          explanationLength: 10,
        ),
        isNull,
      );
    });
  });

  group('shouldShowPostInFeed', () {
    Post post(String posterId, String text) => Post(
          'a',
          's',
          text,
          posterId,
          0,
          [],
          'u',
          '',
          '',
          'id',
          0,
          '',
          '',
        );

    test('hides short posts from others', () {
      expect(shouldShowPostInFeed(post('other', 'short'), 'me'), isFalse);
      expect(shouldShowPostInFeed(post('other', '1234567890'), 'me'), isTrue);
    });

    test('always shows own posts', () {
      expect(shouldShowPostInFeed(post('me', 'x'), 'me'), isTrue);
    });
  });
}
