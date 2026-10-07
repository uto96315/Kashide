import 'package:flutter_test/flutter_test.dart';
import 'package:str_gram_beta/song/listen_url_utils.dart';

void main() {
  test('isAppleMusicListenUrl', () {
    expect(isAppleMusicListenUrl('https://music.apple.com/jp/album/x/1'), isTrue);
    expect(isAppleMusicListenUrl('https://itunes.apple.com/jp/album/x/id1'), isTrue);
    expect(isAppleMusicListenUrl('https://www.youtube.com/watch?v=1'), isFalse);
    expect(isAppleMusicListenUrl(''), isFalse);
  });
}
